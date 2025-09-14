package orui

import rl "vendor:raylib"

CORNER_SEGMENTS :: 16
MISSING_COLOR :: rl.Color{0, 0, 0, 0}

@(private)
render :: proc(ctx: ^Context) {
	ctx.sorted_count = 0
	collect_elements(ctx, 0, 0)
	sort_elements(ctx)

	for i := 0; i < ctx.sorted_count; i += 1 {
		index := ctx.sorted[i]
		render_element(ctx, index)
	}
}

@(private = "file")
collect_elements :: proc(ctx: ^Context, index: int, parent_layer: int) {
	element := &ctx.elements[index]
	element._layer = element.layer == 0 ? parent_layer : element.layer

	ctx.sorted[ctx.sorted_count] = index
	ctx.sorted_count += 1

	child := ctx.elements[index].children
	for child != 0 {
		collect_elements(ctx, child, element._layer)
		child = ctx.elements[child].next
	}
}

@(private = "file")
sort_elements :: proc(ctx: ^Context) {
	for i := 1; i < ctx.sorted_count; i += 1 {
		key := ctx.sorted[i]
		layer := ctx.elements[key]._layer
		j := i - 1
		for j >= 0 && ctx.elements[ctx.sorted[j]]._layer > layer {
			ctx.sorted[j + 1] = ctx.sorted[j]
			j -= 1
		}
		ctx.sorted[j + 1] = key
	}
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
		if element.overflow == .Wrap {
			render_wrapped_text(element)
		} else {
			if element.overflow == .Hidden {
				rl.BeginScissorMode(
					i32(element._position.x),
					i32(element._position.y),
					i32(element._size.x),
					i32(element._size.y),
				)
			}
			render_text(element)
			if element.overflow == .Hidden {
				rl.EndScissorMode()
			}
		}
	}

	if element.has_texture {
		render_texture(element)
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

	container_x := element._position.x + element.padding.left + element.border.left
	container_y := element._position.y + element.padding.top + element.border.top
	container_width := element._size.x - x_padding(element) - x_border(element)
	container_height := element._size.y - y_padding(element) - y_border(element)

	dest: rl.Rectangle

	switch element.texture_fit {
	case .Fill:
		dest = {container_x, container_y, container_width, container_height}
	case .Contain:
		source_aspect := source.width / source.height
		container_aspect := container_width / container_height

		if source_aspect > container_aspect {
			// image is wider
			dest.width = container_width
			dest.height = container_width / source_aspect
		} else {
			// image is taller
			dest.width = container_height * source_aspect
			dest.height = container_height
		}
	case .Cover:
		source_aspect := source.width / source.height
		container_aspect := container_width / container_height

		if source_aspect > container_aspect {
			// image is wider
			dest.width = container_height * source_aspect
			dest.height = container_height
		} else {
			// image is taller
			dest.width = container_width
			dest.height = container_width / source_aspect
		}
	case .None:
		dest.width = source.width
		dest.height = source.height
	case .ScaleDown:
		// same as contain, but only scale down
		source_aspect := source.width / source.height
		container_aspect := container_width / container_height

		if source.width <= container_width && source.height <= container_height {
			dest.width = source.width
			dest.height = source.height
		} else {
			if source_aspect > container_aspect {
				// image is wider
				dest.width = container_width
				dest.height = container_width / source_aspect
			} else {
				// image is taller
				dest.width = container_height * source_aspect
				dest.height = container_height
			}
		}
	}

	dest.x = container_x + calculate_alignment_offset(element.align.x, container_width, dest.width)
	dest.y =
		container_y + calculate_alignment_offset(element.align.y, container_height, dest.height)

	// clip image to container
	// don't use scissor mode, it's sloooow
	clamp_left := max(dest.x, container_x)
	clamp_top := max(dest.y, container_y)
	clamp_right := min(dest.x + dest.width, container_x + container_width)
	clamp_bottom := min(dest.y + dest.height, container_y + container_height)

	clip_left := clamp_left - dest.x
	clip_top := clamp_top - dest.y
	clip_right := (dest.x + dest.width) - clamp_right
	clip_bottom := (dest.y + dest.height) - clamp_bottom

	source_scale_x := source.width / dest.width
	source_scale_y := source.height / dest.height

	adjusted_source := rl.Rectangle {
		source.x + clip_left * source_scale_x,
		source.y + clip_top * source_scale_y,
		source.width - (clip_left + clip_right) * source_scale_x,
		source.height - (clip_top + clip_bottom) * source_scale_y,
	}

	adjusted_dest := rl.Rectangle {
		clamp_left,
		clamp_top,
		clamp_right - clamp_left,
		clamp_bottom - clamp_top,
	}

	if adjusted_dest.width > 0 && adjusted_dest.height > 0 {
		rl.DrawTexturePro(element.texture^, adjusted_source, adjusted_dest, {}, 0, color)
	}
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
