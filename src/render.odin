package orui

import "core:strings"
import rl "vendor:raylib"

CORNER_SEGMENTS :: 16
MISSING_COLOR :: rl.Color{0, 0, 0, 0}

@(private)
render :: proc(ctx: ^Context) {
	ctx.sorted_count = 0
	render_element(ctx, 0)
}

@(private)
render_element :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	ctx.sorted[ctx.sorted_count] = index
	ctx.sorted_count += 1

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
