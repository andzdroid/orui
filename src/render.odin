package orui

import "core:log"
import "core:strings"
import rl "vendor:raylib"

CORNER_SEGMENTS :: 16
MISSING_COLOR :: rl.Color{0, 0, 0, 0}

@(private)
render :: proc(ctx: ^Context) {
	render_element(ctx, 0)
}

@(private)
render_element :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.background_color.a > 0 {
		render_background(element)
	}

	if element.border_color.a > 0 {
		render_border(element)
	}

	if element.has_text {
		render_wrapped_text(element)
	}

	if element.has_texture {
		render_texture(element)
	}

	child := element.children
	for child != 0 {
		render_element(ctx, child)
		child = ctx.elements[child].next
	}
}

@(private)
render_background :: proc(element: ^Element) {
	if has_round_corners(element) {
		render_rounded_background(element)
	} else {
		size := element._size
		position := element._position
		draw_rectangle({position.x, position.y}, {size.x, size.y}, element.background_color)
	}
}

@(private)
render_rounded_background :: proc(element: ^Element) {
	size := element._size
	position := element._position
	radius := clamp_corner_radius(element)

	// central vertical rectangle
	if size.x - (radius.top_left + radius.top_right) > 0 {
		draw_rectangle(
			{position.x + radius.top_left, position.y},
			{size.x - (radius.top_left + radius.top_right), size.y},
			element.background_color,
		)
	}

	// left bar
	if radius.top_left + radius.bottom_left < size.y {
		draw_rectangle(
			{position.x, position.y + radius.top_left},
			{radius.top_left, size.y - (radius.top_left + radius.bottom_left)},
			element.background_color,
		)
	}

	// right bar
	if radius.top_right + radius.bottom_right < size.y {
		draw_rectangle(
			{position.x + size.x - radius.top_right, position.y + radius.top_right},
			{radius.top_right, size.y - (radius.top_right + radius.bottom_right)},
			element.background_color,
		)
	}

	// corners
	if radius.top_left > 0 {
		rl.DrawCircleSector(
			{position.x + radius.top_left, position.y + radius.top_left},
			radius.top_left,
			180,
			270,
			CORNER_SEGMENTS,
			element.background_color,
		)
	}

	if radius.top_right > 0 {
		rl.DrawCircleSector(
			{position.x + size.x - radius.top_right, position.y + radius.top_right},
			radius.top_right,
			270,
			360,
			CORNER_SEGMENTS,
			element.background_color,
		)
	}

	if radius.bottom_left > 0 {
		rl.DrawCircleSector(
			{position.x + radius.bottom_left, position.y + size.y - radius.bottom_left},
			radius.bottom_left,
			90,
			180,
			CORNER_SEGMENTS,
			element.background_color,
		)
	}

	if radius.bottom_right > 0 {
		rl.DrawCircleSector(
			{position.x + size.x - radius.bottom_right, position.y + size.y - radius.bottom_right},
			radius.bottom_right,
			0,
			90,
			CORNER_SEGMENTS,
			element.background_color,
		)
	}
}

@(private)
render_border :: proc(element: ^Element) {
	if has_round_corners(element) {
		render_rounded_border(element)
	} else {
		render_straight_border(element)
	}
}

@(private)
render_straight_border :: proc(element: ^Element) {
	if element.border.top == element.border.left &&
	   element.border.left == element.border.right &&
	   element.border.right == element.border.bottom {
		rl.DrawRectangleLinesEx(
			{element._position.x, element._position.y, element._size.x, element._size.y},
			element.border.top,
			element.border_color,
		)
	} else {
		if element.border.top > 0 {
			draw_rectangle(
				{element._position.x, element._position.y},
				{element._size.x, element.border.top},
				element.border_color,
			)
		}
		if element.border.right > 0 {
			draw_rectangle(
				{
					element._position.x + element._size.x - element.border.right,
					element._position.y,
				},
				{element.border.right, element._size.y},
				element.border_color,
			)
		}
		if element.border.bottom > 0 {
			draw_rectangle(
				{
					element._position.x,
					element._position.y + element._size.y - element.border.bottom,
				},
				{element._size.x, element.border.bottom},
				element.border_color,
			)
		}
		if element.border.left > 0 {
			draw_rectangle(
				{element._position.x, element._position.y},
				{element.border.left, element._size.y},
				element.border_color,
			)
		}
	}
}

@(private)
render_rounded_border :: proc(element: ^Element) {
	size := element._size
	position := element._position
	radius := clamp_corner_radius(element)
	border := element.border
	color := element.border_color

	if border.left > 0 {
		draw_rectangle(
			{position.x, position.y + radius.top_left},
			{border.left, size.y - (radius.top_left + radius.bottom_left)},
			color,
		)
	}

	if border.right > 0 {
		draw_rectangle(
			{position.x + size.x - border.right, position.y + radius.top_right},
			{border.right, size.y - (radius.top_right + radius.bottom_right)},
			color,
		)
	}

	if border.top > 0 {
		draw_rectangle(
			{position.x + radius.top_left, position.y},
			{size.x - (radius.top_left + radius.top_right), border.top},
			color,
		)
	}

	if border.bottom > 0 {
		draw_rectangle(
			{position.x + radius.bottom_left, position.y + size.y - border.bottom},
			{size.x - (radius.bottom_left + radius.bottom_right), border.bottom},
			color,
		)
	}

	if radius.top_left > 0 {
		rl.DrawRing(
			{position.x + radius.top_left, position.y + radius.top_left},
			radius.top_left - border.top,
			radius.top_left,
			180,
			270,
			CORNER_SEGMENTS,
			color,
		)
	}

	if radius.top_right > 0 {
		rl.DrawRing(
			{position.x + size.x - radius.top_right, position.y + radius.top_right},
			radius.top_right - border.top,
			radius.top_right,
			270,
			360,
			CORNER_SEGMENTS,
			color,
		)
	}

	if radius.bottom_right > 0 {
		rl.DrawRing(
			{position.x + size.x - radius.bottom_right, position.y + size.y - radius.bottom_right},
			radius.bottom_right - border.bottom,
			radius.bottom_right,
			0,
			90,
			CORNER_SEGMENTS,
			color,
		)
	}

	if radius.bottom_left > 0 {
		rl.DrawRing(
			{position.x + radius.bottom_left, position.y + size.y - radius.bottom_left},
			radius.bottom_left - border.bottom,
			radius.bottom_left,
			90,
			180,
			CORNER_SEGMENTS,
			color,
		)
	}
}

@(private)
render_texture :: proc(element: ^Element) {
	source := element.texture_source
	if source.width == 0 && source.height == 0 {
		source = {0, 0, f32(element.texture^.width), f32(element.texture^.height)}
	}

	color := element.color
	if color == MISSING_COLOR {
		color = rl.WHITE
	}

	rl.DrawTexturePro(
		element.texture^,
		source,
		{element._position.x, element._position.y, element._size.x, element._size.y},
		{},
		0,
		color,
	)
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
					next_width := line_width + space_width + (2 * letter_spacing) + word_width
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


@(private)
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

@(private)
clamp_corner_radius :: proc(element: ^Element) -> Corners {
	scale: f32 = 1
	width := element._size.x
	height := element._size.y
	radius := element.corner_radius

	top_sum := radius.top_left + radius.top_right
	bottom_sum := radius.bottom_left + radius.bottom_right
	left_sum := radius.top_left + radius.bottom_left
	right_sum := radius.top_right + radius.bottom_right

	if top_sum > width {
		s := width / top_sum
		if s < scale {scale = s}
	}
	if bottom_sum > width {
		s := width / bottom_sum
		if s < scale {scale = s}
	}
	if left_sum > height {
		s := height / left_sum
		if s < scale {scale = s}
	}
	if right_sum > height {
		s := height / right_sum
		if s < scale {scale = s}
	}

	if scale < 1 {
		return {
			top_left = radius.top_left * scale,
			top_right = radius.top_right * scale,
			bottom_right = radius.bottom_right * scale,
			bottom_left = radius.bottom_left * scale,
		}
	}

	return radius
}

@(private)
draw_rectangle :: proc(position: rl.Vector2, size: rl.Vector2, color: rl.Color) {
	rl.DrawRectanglePro({position.x, position.y, size.x, size.y}, {}, 0, color)
}
