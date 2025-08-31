package orui

import rl "vendor:raylib"

@(private)
handle_input_state :: proc(ctx: ^Context) {
	position := rl.GetMousePosition()
	mouse_down := rl.IsMouseButtonDown(.LEFT)

	ctx.hover_count = 0
	ctx.active_count = 0

	if rl.IsMouseButtonReleased(.LEFT) {
		ctx.pointer_capture = 0
	}

	if ctx.pointer_capture != 0 && mouse_down {
		el := &ctx.elements[ctx.pointer_capture]
		ctx.active[ctx.active_count] = el.id
		ctx.active_count += 1
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

		ctx.hover[ctx.hover_count] = element.id
		ctx.hover_count += 1

		already_active := false
		for i := 0; i < ctx.active_prev_count; i += 1 {
			if ctx.active_prev[i] == element.id {
				already_active = true
				break
			}
		}

		if mouse_down && (rl.IsMouseButtonPressed(.LEFT) || already_active) {
			ctx.active[ctx.active_count] = element.id
			ctx.active_count += 1

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
