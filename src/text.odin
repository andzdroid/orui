package orui

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
find_next_space :: proc(text: string, start_index: int) -> (int, int) {
	index := start_index
	text_len := len(text)

	for index < text_len && text[index] == ' ' {
		index += 1
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

	space_width := measure_text_width(" ", element.font, element.font_size, letter_spacing)

	line_count := 1
	line_width: f32 = 0
	max_line_width: f32 = 0

	// scan text
	index := 0
	for index < text_len {
		if text[index] == '\n' {
			line_width = 0
			line_count += 1
			index += 1
			continue
		}

		for index < text_len && text[index] != '\n' {
			word_start, word_end := find_next_space(text, index)

			word := text[word_start:word_end]
			word_width := measure_text_width(word, element.font, element.font_size, letter_spacing)
			next_width := line_width + word_width
			if line_width > 0 {
				next_width += letter_spacing
			}

			if !width_definite ||
			   next_width <= inner_available ||
			   abs(next_width - inner_available) < 0.0001 {
				line_width = next_width
				if line_width > max_line_width {
					max_line_width = line_width
				}
				index = word_end
				continue
			}

			// handle first word of a new line
			line_width = word_width
			if line_width > max_line_width {
				max_line_width = line_width
			}
			index = word_end
			line_count += 1
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
render_wrapped_text :: proc(element: ^Element) {
	text := element.text
	text_len := len(text)
	if text_len == 0 {
		return
	}

	y_offset := calculate_text_offset(element)
	x_start := element._position.x + element.padding.left + element.border.left
	y_start := element._position.y + element.padding.top + element.border.top + y_offset
	line_height := measure_text_height(element.font_size, element.line_height)
	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	inner_width := inner_width(element)

	y := y_start
	index := 0
	for index < text_len {
		if text[index] == '\n' {
			y += line_height
			index += 1
			continue
		}

		line_start := index
		line_width: f32 = 0

		for index < text_len && text[index] == ' ' {
			index += 1
		}
		line_start = index

		for index < text_len && text[index] != '\n' {
			word_start, word_end := find_next_space(text, index)

			word := text[word_start:word_end]
			word_width := measure_text_width(word, element.font, element.font_size, letter_spacing)

			next_width := line_width + word_width
			if line_width > 0 {
				next_width += letter_spacing
			}

			if next_width <= inner_width || abs(next_width - inner_width) < 0.0001 {
				line_width = next_width
				index = word_end
				continue
			}

			index = word_start
			break
		}

		line_end := min(index, text_len)

		if line_start == line_end {
			break
		}

		if line_start < line_end {
			// trim trailing spaces
			trim_end := line_end
			for trim_end > line_start && text[trim_end - 1] == ' ' {
				trim_end -= 1
			}

			if line_start < trim_end {
				actual_width := measure_text_width(
					text[line_start:trim_end],
					element.font,
					element.font_size,
					letter_spacing,
				)
				render_text_line(
					element,
					text[line_start:trim_end],
					actual_width,
					x_start,
					y,
					letter_spacing,
					inner_width,
				)
			}
		}

		y += line_height
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
