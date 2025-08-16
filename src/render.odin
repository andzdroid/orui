package orui

import "core:strings"
import rl "vendor:raylib"

render :: proc(ctx: ^Context) {
	render_element(ctx, 0)
}

render_element :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.background_color.a > 0 {
		rl.DrawRectangle(
			i32(element._position.x),
			i32(element._position.y),
			i32(element._size.x),
			i32(element._size.y),
			element.background_color,
		)
	}

	if element.has_text {
		render_wrapped_text(element)
	}

	child := element.children
	for child != 0 {
		render_element(ctx, child)
		child = ctx.elements[child].next
	}
}

render_wrapped_text :: proc(element: ^Element) {
	text := element.text
	text_len := len(text)
	if text_len == 0 {
		return
	}

	y_offset := calculate_text_offset(element)
	x_start := element._position.x + element.padding.left
	y_start := element._position.y + element.padding.top + y_offset
	line_height := measure_text_height(element.font_size, element.line_height)
	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	space_width := measure_text_width(" ", element.font, element.font_size, letter_spacing)
	inner_width := inner_width(element)

	y := y_start
	index := 0
	for index < text_len {
		line_start := index
		line_width: f32 = 0

		// skip leading spaces
		// TODO: remove this, leading spaces should be rendered
		// needs changes to word wrapping logic?
		for index < text_len && text[index] == ' ' {
			index += 1
		}
		line_start = index

		for index < text_len && text[index] != '\n' {
			word_start := index
			for index < text_len && text[index] != ' ' && text[index] != '\n' {
				index += 1
			}

			if word_start < index {
				word := text[word_start:index]
				word_width := measure_text_width(
					word,
					element.font,
					element.font_size,
					letter_spacing,
				)

				if line_width == 0 {
					line_width = word_width
				} else {
					next_width := line_width + space_width + word_width
					if next_width <= inner_width {
						line_width = next_width
					} else {
						index = word_start
						break
					}
				}
			}

			for index < text_len && text[index] == ' ' {
				index += 1
			}
		}

		line_end := index

		if index < text_len && text[index] == '\n' {
			index += 1
		}

		if line_start < line_end {
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
				render_line(
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

render_line :: proc(
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

calculate_text_offset :: proc(element: ^Element) -> f32 {
	content_height := inner_height(element)

	line_height := measure_text_height(element.font_size, element.line_height)
	text_height := line_height * f32(element._line_count)

	offset: f32 = 0

	switch element.align.y {
	case .Start:
	case .Center:
		offset = (content_height - text_height) / 2
	case .End:
		offset = (content_height - text_height)
	}

	if offset < 0 {
		offset = 0
	}

	return offset
}


calculate_line_offset :: proc(element: ^Element, line_width: f32, available_width: f32) -> f32 {
	switch element.align.x {
	case .Start:
		return 0
	case .Center:
		return (available_width - line_width) / 2
	case .End:
		return available_width - line_width
	}
	return 0
}
