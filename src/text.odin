package orui

import "core:math"
import "core:strings"
import rl "vendor:raylib"

@(private)
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

@(private)
measure_text_height :: proc(font_size: f32, line_height_multiplier: f32) -> f32 {
	line_height := line_height_multiplier > 0 ? line_height_multiplier : 1
	return font_size * line_height
}

@(private)
// Find the next space or new line character
find_next_space :: proc(text: string, start_index: int) -> (start: int, end: int) {
	index := start_index
	text_len := len(text)

	if text[index] == ' ' {
		for index < text_len && text[index] == ' ' {
			index += 1
		}
		return start_index, index
	}

	for index < text_len && text[index] != ' ' && text[index] != '\n' {
		index += 1
	}

	return start_index, index
}

@(private)
wrap_text_element :: proc(ctx: ^Context, element: ^Element) {
	text := element.text
	text_len := len(text)

	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	inner_available: f32 = 0
	width_definite := false

	if element._size.x > 0 {
		inner_available = inner_width(element)
		width_definite = true
	} else if element.width.type == .Percent {
		parent_inner, parent_definite := parent_inner_width(ctx, element)
		if parent_definite {
			inner_available =
				parent_inner * element.width.value - x_padding(element) - x_border(element)
			if inner_available < 0 {
				inner_available = 0
			}
			width_definite = true
		}
	}

	line_count := 1
	line_width: f32 = 0
	max_line_width: f32 = 0
	pending_space: f32 = 0
	line_started_by_newline := true

	// scan text
	index := 0
	for index < text_len {
		if text[index] == '\n' {
			// include trailing spaces on hard wrapped lines
			line_width += pending_space
			pending_space = 0
			if line_width > max_line_width {
				max_line_width = line_width
			}
			line_width = 0
			line_count += 1
			line_started_by_newline = true
			index += 1
			continue
		}

		for index < text_len && text[index] != '\n' {
			word_start, word_end := find_next_space(text, index)

			token := text[word_start:word_end]
			token_width := measure_text_width(
				token,
				element.font,
				element.font_size,
				letter_spacing,
			)

			// tokens beginning with space are all space
			if text[word_start] == ' ' {
				// drop leading spaces on soft wrapped lines
				if line_width == 0 && !line_started_by_newline {
					index = word_end
					continue
				}

				if line_width > 0 {
					line_width += letter_spacing
				}

				pending_space = token_width
				index = word_end
				continue
			}

			joining_space := pending_space > 0 ? letter_spacing : 0
			next_width := line_width + pending_space + token_width + joining_space

			// add token to line if it fits
			if !width_definite || next_width <= inner_available + 0.0001 {
				line_width = next_width
				if line_width > max_line_width {
					max_line_width = line_width
				}
				pending_space = 0
				index = word_end
				line_started_by_newline = false
				continue
			}

			// soft wrap, drop pending spaces
			line_count += 1
			line_width = token_width
			if line_width > max_line_width {
				max_line_width = line_width
			}
			pending_space = 0
			index = word_end
			line_started_by_newline = false
		}
	}

	if pending_space > 0 {
		final_width := line_width + pending_space
		if final_width > max_line_width {
			max_line_width = final_width
		}
	}

	element._line_count = line_count

	if element.height.type != .Fixed {
		if element.height.type == .Percent {
			_, parent_definite := parent_inner_height(ctx, element)
			if !parent_definite {
				line_height_px := measure_text_height(element.font_size, element.line_height)
				element._size.y =
					line_height_px * f32(line_count) + y_padding(element) + y_border(element)
			}
		} else {
			line_height_px := measure_text_height(element.font_size, element.line_height)
			element._size.y =
				line_height_px * f32(line_count) + y_padding(element) + y_border(element)
		}
	}

	if element.width.type == .Fit {
		element._size.x = max_line_width + x_padding(element) + x_border(element)
		flex_clamp_width(ctx, element)
	}
}

@(private)
render_text_line :: proc(
	element: ^Element,
	text: string,
	line_width: f32,
	x_start: f32,
	y: f32,
	letter_spacing: f32,
	inner_width: f32,
) {
	line_offset := calculate_line_offset(element, line_width, inner_width)
	x := x_start + line_offset

	rl.DrawTextEx(
		element.font^,
		strings.clone_to_cstring(text, context.temp_allocator),
		{x, y},
		element.font_size,
		letter_spacing,
		element.color,
	)
}

@(private)
render_text :: proc(element: ^Element) {
	if len(element.text) == 0 {
		return
	}

	y_offset := calculate_text_offset(element)
	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	line_width := measure_text_width(element.text, element.font, element.font_size, letter_spacing)
	inner_width := inner_width(element)

	x := element._position.x + element.padding.left + element.border.left
	y := element._position.y + element.padding.top + element.border.top + y_offset

	render_text_line(element, element.text, line_width, x, y, letter_spacing, inner_width)

	render_caret(
		element,
		element.text,
		0,
		len(element.text),
		line_width,
		x,
		y,
		letter_spacing,
		inner_width,
	)
}

@(private)
render_wrapped_text :: proc(element: ^Element) {
	text := element.text
	text_len := len(element.text)
	if text_len == 0 {
		return
	}

	y_offset := calculate_text_offset(element)
	x_start := element._position.x + element.padding.left + element.border.left
	y_start := element._position.y + element.padding.top + element.border.top + y_offset
	line_height := measure_text_height(element.font_size, element.line_height)
	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	inner_width := inner_width(element)

	active := current_context.focus_id == element.id

	y := y_start
	index := 0
	line_start := 0
	line_width: f32 = 0
	pending_space: f32 = 0
	line_started_by_newline := true
	last_nonspace_end := index

	for index < text_len {
		if text[index] == '\n' {
			// include trailing spaces on hard wrapped lines
			joining_space := (line_width > 0 && pending_space > 0) ? letter_spacing : 0
			actual_width := line_width + pending_space + joining_space
			if line_start < index {
				render_text_line(
					element,
					text[line_start:index],
					actual_width,
					x_start,
					y,
					letter_spacing,
					inner_width,
				)

				render_caret(
					element,
					text,
					line_start,
					index,
					actual_width,
					x_start,
					y,
					letter_spacing,
					inner_width,
				)
			}

			y += line_height
			index += 1
			line_start = index
			line_width = 0
			pending_space = 0
			last_nonspace_end = index
			line_started_by_newline = true
			continue
		}

		// build line until soft wrap or new line
		for index < text_len && text[index] != '\n' {
			word_start, word_end := find_next_space(text, index)
			token := text[word_start:word_end]
			is_space := text[word_start] == ' '
			token_width := measure_text_width(
				token,
				element.font,
				element.font_size,
				letter_spacing,
			)

			if is_space {
				// drop leading spaces on soft wrapped lines
				if line_width == 0 && !line_started_by_newline {
					index = word_end
					line_start = index
					last_nonspace_end = index
					continue
				}
				if line_width > 0 {
					line_width += letter_spacing
				}
				pending_space = token_width
				index = word_end
				continue
			}

			joining_space := pending_space > 0 ? letter_spacing : 0
			next_width := line_width + pending_space + token_width + joining_space

			if next_width <= inner_width + 0.0001 {
				line_width = next_width
				last_nonspace_end = word_end
				pending_space = 0
				index = word_end
				line_started_by_newline = false
				continue
			}

			// soft wrap
			if line_start < last_nonspace_end {
				actual_width := line_width
				render_text_line(
					element,
					text[line_start:last_nonspace_end],
					actual_width,
					x_start,
					y,
					letter_spacing,
					inner_width,
				)

				render_caret(
					element,
					text,
					line_start,
					index,
					actual_width,
					x_start,
					y,
					letter_spacing,
					inner_width,
				)
			}

			y += line_height
			line_start = word_start
			line_width = 0
			pending_space = 0
			last_nonspace_end = word_start
			line_started_by_newline = false
			index = word_start
			break
		}

		if index >= text_len {
			if line_start < index {
				joining_space := pending_space > 0 ? letter_spacing : 0
				actual_width := line_width + pending_space + joining_space
				render_text_line(
					element,
					text[line_start:index],
					actual_width,
					x_start,
					y,
					letter_spacing,
					inner_width,
				)

				render_caret(
					element,
					text,
					line_start,
					index,
					actual_width,
					x_start,
					y,
					letter_spacing,
					inner_width,
				)
			}
		}
	}
}

@(private)
// Vertical offset
calculate_text_offset :: proc(element: ^Element) -> f32 {
	content_height := inner_height(element)
	line_height := measure_text_height(element.font_size, element.line_height)
	line_count := element._line_count > 0 ? element._line_count : 1
	text_height := line_height * f32(line_count)
	return calculate_alignment_offset(element.align.y, content_height, text_height)
}

@(private)
// Horizontal offset
calculate_line_offset :: proc(element: ^Element, line_width: f32, available_width: f32) -> f32 {
	return calculate_alignment_offset(element.align.x, available_width, line_width)
}

@(private)
render_caret :: proc(
	element: ^Element,
	text: string,
	line_start: int,
	line_end: int,
	line_width: f32,
	x_start: f32,
	y: f32,
	letter_spacing: f32,
	inner_width: f32,
) {
	if current_context.focus_id != element.id || current_context.caret_index == -1 {
		return
	}

	blink_cycle := math.mod(current_context.caret_time, 1.0)
	if blink_cycle >= 0.5 {
		return
	}

	caret := current_context.caret_index
	if caret < line_start || caret > line_end {
		return
	}

	prefix_width := measure_text_width(
		text[line_start:caret],
		element.font,
		element.font_size,
		letter_spacing,
	)
	line_offset := calculate_line_offset(element, line_width, inner_width)
	line_height := measure_text_height(element.font_size, element.line_height)

	current_context.caret_position = {x_start + line_offset + prefix_width, y}
	rl.DrawRectanglePro(
		{current_context.caret_position.x, current_context.caret_position.y, 1, line_height},
		{},
		0,
		element.color,
	)
}
