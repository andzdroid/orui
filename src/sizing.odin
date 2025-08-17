package orui

import "core:log"
import "core:strings"
import rl "vendor:raylib"

/*
Border/padding box: size of element (_size)
Content box: border box - padding
Margin box: border box + margin
*/

measure_text_width :: proc(
	text: string,
	font: ^rl.Font,
	font_size: f32,
	letter_spacing: f32,
) -> f32 {
	if len(text) == 0 {
		return 0
	}

	width: f32 = 0
	count := 0
	for codepoint in text {
		index := codepoint - 32
		count += 1

		if codepoint != '\n' {
			if font.glyphs[index].advanceX > 0 {
				width += f32(font.glyphs[index].advanceX)
			} else {
				width += font.recs[index].width + f32(font.glyphs[index].offsetX)
			}
		}
	}

	scale := font_size / f32(font.baseSize)
	letter_spacing := letter_spacing > 0 ? letter_spacing : 1
	return width * scale + letter_spacing * f32(count - 1)
}

measure_text_height :: proc(font_size: f32, line_height_multiplier: f32) -> f32 {
	line_height := line_height_multiplier > 0 ? line_height_multiplier : 1
	return font_size * line_height
}

// Set fixed widths and fit widths.
fit_widths :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.width.type == .Fixed {
		element._size.x = element.width.value
	}

	if (element.width.type == .Fit || element.width.type == .Grow) && element.has_text {
		text_width := measure_text_width(
			element.text,
			element.font,
			element.font_size,
			element.letter_spacing,
		)
		element._size.x = text_width + x_padding(element)
	}

	child := element.children
	for child != 0 {
		fit_widths(ctx, child)
		child = ctx.elements[child].next
	}

	if element.layout != .Flex {
		return
	}

	if element._size.x > 0 || element.width.type == .Percent {
		return
	}

	if element.direction == .LeftToRight {
		// sum of child widths
		sum: f32 = 0
		child_count := 0
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			if child_element.position.type == .Absolute {
				child = child_element.next
				continue
			}

			child_count += 1

			if child_element.width.type == .Percent {
				child = child_element.next
				continue
			}

			sum += child_element._size.x + x_margin(child_element)
			child = child_element.next
		}
		gaps := element.gap * f32(max(child_count - 1, 0))
		element._size.x = sum + gaps + x_padding(element)
	} else {
		// max of child widths
		max_child: f32 = 0
		child = element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			if child_element.position.type == .Absolute {
				child = child_element.next
				continue
			}

			if child_element.width.type == .Percent {
				child = child_element.next
				continue
			}

			child_width := child_element._size.x + x_margin(child_element)
			if child_width > max_child {
				max_child = child_width
			}
			child = child_element.next
		}
		element._size.x = max_child + x_padding(element)
	}

	apply_width_contraints(ctx, element)
}

// Set percent widths and grow widths.
distribute_widths :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.width.type == .Percent {
		percent_width, definite := parent_inner_width(ctx, element)
		if definite {
			element._size.x = percent_width * element.width.value
		}
		apply_width_contraints(ctx, element)
	}

	if element.layout == .Flex {
		if element.direction == .LeftToRight {
			element_inner_width := inner_width(element)
			has_definite := element._size.x > 0

			sum_with_margins: f32 = 0
			total_weight: f32 = 0
			child_count := 0
			child := element.children
			for child != 0 {
				child_element := &ctx.elements[child]
				if child_element.position.type == .Absolute {
					child = child_element.next
					continue
				}

				base: f32 = 0
				switch child_element.width.type {
				case .Fixed:
					base = child_element._size.x
				case .Percent:
					base = element_inner_width * child_element.width.value
				case .Fit:
					base = child_element._size.x
				case .Grow:
					base = child_element._size.x
					weight := child_element.width.value
					if weight <= 0 {weight = 1}
					total_weight += weight
				}

				child_element._size.x = base
				apply_width_contraints(ctx, child_element)
				sum_with_margins += child_element._size.x + x_margin(child_element)
				child_count += 1
				child = child_element.next
			}

			gaps := element.gap * f32(max(child_count - 1, 0))
			remaining := element_inner_width - sum_with_margins - gaps
			if remaining > 0 && total_weight > 0 {
				child = element.children
				for child != 0 {
					child_element := &ctx.elements[child]
					if child_element.width.type == .Grow {
						weight := child_element.width.value
						if weight <= 0 {weight = 1}
						add := remaining * (weight / total_weight)
						child_element._size.x += add
						apply_width_contraints(ctx, child_element)
					}
					child = child_element.next
				}
			}
		} else {
			element_inner_width := inner_width(element)
			has_definite := element._size.x > 0

			child := element.children
			for child != 0 {
				child_element := &ctx.elements[child]

				if child_element.position.type == .Absolute {
					child = child_element.next
					continue
				}

				if child_element.width.type == .Percent {
					available_width := element_inner_width - x_margin(child_element)
					child_element._size.x = available_width * child_element.width.value
				} else if child_element.width.type == .Grow {
					child_element._size.x = element_inner_width - x_margin(child_element)
				}

				apply_width_contraints(ctx, child_element)
				child = child_element.next
			}
		}
	}

	child := element.children
	for child != 0 {
		distribute_widths(ctx, child)
		child = ctx.elements[child].next
	}
}

wrap_text :: proc(ctx: ^Context) {
	for i in 0 ..< ctx.element_count {
		element := &ctx.elements[i]
		if !element.has_text {
			continue
		}

		text := element.text
		text_len := len(text)

		inner_available: f32 = 0
		width_definite := false

		if element._size.x > 0 {
			inner_available = inner_width(element)
			width_definite = true
		} else if element.width.type == .Percent {
			parent_inner, parent_definite := parent_inner_width(ctx, element)
			if parent_definite {
				inner_available = parent_inner * element.width.value - x_padding(element)
				if inner_available < 0 {
					inner_available = 0
				}
				width_definite = true
			}
		}

		space_width := measure_text_width(
			" ",
			element.font,
			element.font_size,
			element.letter_spacing,
		)

		line_count := 1
		current_line_width: f32 = 0
		max_line_width: f32 = 0

		// scan text
		index := 0
		for index < text_len {
			if text[index] == '\n' {
				if current_line_width > max_line_width {
					max_line_width = current_line_width
				}
				current_line_width = 0
				line_count += 1
				index += 1

				// Skip spaces at start of line
				for index < text_len && text[index] == ' ' {
					index += 1
				}
				continue
			}

			// check next word
			word_start := index
			for index < text_len && text[index] != ' ' && text[index] != '\n' {
				index += 1
			}
			word := text[word_start:index]
			if len(word) > 0 {
				word_width := measure_text_width(
					word,
					element.font,
					element.font_size,
					element.letter_spacing,
				)
				if current_line_width == 0 {
					current_line_width = word_width
				} else {
					next_width := current_line_width + space_width + word_width
					if !width_definite || next_width <= inner_available {
						current_line_width = next_width
					} else {
						if current_line_width > max_line_width {
							max_line_width = current_line_width
						}
						current_line_width = word_width
						line_count += 1
					}
				}
			}

			for index < text_len && text[index] == ' ' {
				index += 1
			}
		}

		if current_line_width > max_line_width {
			max_line_width = current_line_width
		}

		element._line_count = line_count
		element._measured_size.x = max_line_width

		if element.height.type != .Fixed {
			if element.height.type == .Percent {
				_, parent_definite := parent_inner_height(ctx, element)
				if !parent_definite {
					line_height_px := measure_text_height(element.font_size, element.line_height)
					element._size.y = line_height_px * f32(line_count) + y_padding(element)
				}
			} else {
				line_height_px := measure_text_height(element.font_size, element.line_height)
				element._size.y = line_height_px * f32(line_count) + y_padding(element)
			}
		}

		if element.width.type == .Fit {
			element._size.x = max_line_width + x_padding(element)
			apply_width_contraints(ctx, element)
		}
	}
}

// Set fixed heights and fit heights.
fit_heights :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.height.type == .Fixed {
		element._size.y = element.height.value
	}

	if (element.height.type == .Fit || element.height.type == .Grow) && element.has_text {
		lines := element._line_count > 0 ? element._line_count : 1
		line_height_px := measure_text_height(element.font_size, element.line_height)
		element._size.y = line_height_px * f32(lines) + y_padding(element)
	}

	child := element.children
	for child != 0 {
		fit_heights(ctx, child)
		child = ctx.elements[child].next
	}

	if element.layout != .Flex {
		return
	}

	if element._size.y > 0 || element.height.type == .Percent {
		return
	}

	if element.direction == .TopToBottom {
		// sum of child heights
		sum: f32 = 0
		child_count := 0
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			if child_element.position.type == .Absolute {
				child = child_element.next
				continue
			}

			child_count += 1

			if child_element.height.type == .Percent {
				child = child_element.next
				continue
			}

			sum += child_element._size.y + y_margin(child_element)
			child = child_element.next
		}
		gap := element.gap * f32(max(child_count - 1, 0))
		element._size.y = sum + gap + y_padding(element)
	} else {
		// max of child heights
		max_child: f32 = 0
		child = element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			if child_element.position.type == .Absolute {
				child = child_element.next
				continue
			}

			if child_element.height.type == .Percent {
				child = child_element.next
				continue
			}

			child_height := child_element._size.y + y_margin(child_element)
			if child_height > max_child {
				max_child = child_height
			}
			child = child_element.next
		}
		element._size.y = max_child + y_padding(element)
	}

	apply_height_contraints(ctx, element)
}

// Set percent heights and grow heights.
distribute_heights :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.height.type == .Percent {
		percent_height, definite := parent_inner_height(ctx, element)
		if definite {
			element._size.y = percent_height * element.height.value
		}
		apply_height_contraints(ctx, element)
	}

	if element.layout == .Flex {
		if element.direction == .TopToBottom {
			element_inner_height := inner_height(element)
			has_definite := element._size.y > 0

			sum_with_margins: f32 = 0
			total_weight: f32 = 0
			child_count := 0
			child := element.children
			for child != 0 {
				child_element := &ctx.elements[child]
				if child_element.position.type == .Absolute {
					child = child_element.next
					continue
				}

				base: f32 = 0
				switch child_element.height.type {
				case .Fixed:
					base = child_element._size.y
				case .Percent:
					base = element_inner_height * child_element.height.value
				case .Fit:
					base = child_element._size.y
				case .Grow:
					base = child_element._size.y
					weight := child_element.height.value
					if weight <= 0 {weight = 1}
					total_weight += weight
				}

				child_element._size.y = base
				apply_height_contraints(ctx, child_element)
				sum_with_margins += child_element._size.y + y_margin(child_element)
				child_count += 1
				child = child_element.next
			}

			gaps := element.gap * f32(max(child_count - 1, 0))
			remaining := element_inner_height - sum_with_margins - gaps
			if remaining > 0 && total_weight > 0 {
				child = element.children
				for child != 0 {
					child_element := &ctx.elements[child]
					if child_element.height.type == .Grow {
						weight := child_element.height.value
						if weight <= 0 {weight = 1}
						add := remaining * (weight / total_weight)
						child_element._size.y += add
						apply_height_contraints(ctx, child_element)
					}
					child = child_element.next
				}
			}
		} else {
			element_inner_height := inner_height(element)
			has_definite := element._size.y > 0

			child := element.children
			for child != 0 {
				child_element := &ctx.elements[child]

				if child_element.position.type == .Absolute {
					child = child_element.next
					continue
				}

				if child_element.height.type == .Percent {
					available_height := element_inner_height - y_margin(child_element)
					child_element._size.y = available_height * child_element.height.value
				} else if child_element.height.type == .Grow {
					child_element._size.y = element_inner_height - y_margin(child_element)
				}

				apply_height_contraints(ctx, child_element)
				child = child_element.next
			}
		}
	}

	child := element.children
	for child != 0 {
		distribute_heights(ctx, child)
		child = ctx.elements[child].next
	}
}

apply_width_contraints :: proc(ctx: ^Context, element: ^Element) {
	if element.layout != .Flex {
		return
	}

	min := max(element.width.min, x_padding(element))

	apply_max := false
	max: f32 = 0

	parent_width, parent_definite := parent_inner_width(ctx, element)
	if parent_definite {
		max = parent_width - x_margin(element)
		apply_max = true
	}

	if element.width.max > 0 {
		if apply_max {
			if element.width.max < max {
				max = element.width.max
			}
		} else {
			max = element.width.max
			apply_max = true
		}
	}

	if element._size.x < min {
		element._size.x = min
	}
	if apply_max && element._size.x > max {
		element._size.x = max
	}
}

apply_height_contraints :: proc(ctx: ^Context, element: ^Element) {
	if element.layout != .Flex {
		return
	}

	min := max(element.height.min, y_padding(element))

	apply_max := false
	max: f32 = 0

	parent_height, parent_definite := parent_inner_height(ctx, element)
	if parent_definite {
		max = parent_height - y_margin(element)
		apply_max = true
	}

	if element.height.max > 0 {
		if apply_max {
			if element.height.max < max {
				max = element.height.max
			}
		} else {
			max = element.height.max
			apply_max = true
		}
	}

	if element._size.y < min {
		element._size.y = min
	}
	if apply_max && element._size.y > max {
		element._size.y = max
	}
}
