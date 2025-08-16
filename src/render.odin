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

	x_start := element._position.x + element.padding.left
	y_start := element._position.y + element.padding.top
	line_height := measure_text_height(element.font_size, element.line_height)
	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1

	space_width := measure_text_width(" ", element.font, element.font_size, letter_spacing)
	inner_width := inner_width(element)

	x := x_start
	y := y_start

	index := 0
	for index < text_len {
		if text[index] == '\n' {
			x = x_start
			y += line_height
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
			word_width := measure_text_width(word, element.font, element.font_size, letter_spacing)

			if x != x_start {
				next_x := x + space_width + word_width
				if next_x > x_start + inner_width {
					x = x_start
					y += line_height
				} else {
					x += space_width
				}
			}

			rl.DrawTextEx(
				element.font^,
				strings.clone_to_cstring(word, context.temp_allocator),
				{x, y},
				element.font_size,
				letter_spacing,
				element.color,
			)

			x += word_width
		}

		for index < text_len && text[index] == ' ' {
			index += 1
		}
	}
}
