package orui

import rl "vendor:raylib"

@(private)
handle_input_state :: proc(ctx: ^Context) {
	position := rl.GetMousePosition()
	mouse_down := rl.IsMouseButtonDown(.LEFT)

	current := current_buffer(ctx)
	previous := previous_buffer(ctx)

	if rl.IsMouseButtonReleased(.LEFT) {
		ctx.pointer_capture = 0
	}

	if ctx.pointer_capture != 0 && mouse_down {
		el := &ctx.elements[ctx.pointer_capture]
		count := ctx.active[current].count
		ctx.active[current].ids[count] = el.id
		ctx.active[current].count += 1
		return
	}

	for i := ctx.sorted_count - 1; i >= 0; i -= 1 {
		element := &ctx.elements[ctx.sorted[i]]

		if element.disabled == .True {
			continue
		}

		if !point_in_rect(position, element._position, element._size) {
			continue
		}

		count := ctx.hover[current].count
		ctx.hover[current].ids[count] = element.id
		ctx.hover[current].count += 1

		already_active := false
		for i := 0; i < ctx.active[previous].count; i += 1 {
			if ctx.active[previous].ids[i] == element.id {
				already_active = true
				break
			}
		}

		if mouse_down && (rl.IsMouseButtonPressed(.LEFT) || already_active) {
			count := ctx.active[current].count
			ctx.active[current].ids[count] = element.id
			ctx.active[current].count += 1

			if element.capture == .True {
				ctx.pointer_capture = i
			}
		}

		if element.block == .True {
			break
		}
	}
}

@(private)
point_in_rect :: proc(p: rl.Vector2, pos: rl.Vector2, size: rl.Vector2) -> bool {
	return p.x >= pos.x && p.y >= pos.y && p.x < pos.x + size.x && p.y < pos.y + size.y
}
