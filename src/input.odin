package orui

import rl "vendor:raylib"

@(private)
handle_input_state :: proc(ctx: ^Context) {
	position := rl.GetMousePosition()
	mouse_down := rl.IsMouseButtonDown(.LEFT)
	ctx.hover_count = 0
	ctx.active_count = 0
	collect_hovered(ctx, 0, position, mouse_down)
}

@(private)
collect_hovered :: proc(ctx: ^Context, index: int, position: rl.Vector2, mouse_down: bool) {
	element := &ctx.elements[index]
	if point_in_rect(position, element._position, element._size) {
		ctx.hover[ctx.hover_count] = element.id
		ctx.hover_count += 1

		if mouse_down {
			already_active := false
			for i := 0; i < ctx.active_prev_count; i += 1 {
				if ctx.active_prev[i] == element.id {
					already_active = true
					break
				}
			}
			if rl.IsMouseButtonPressed(.LEFT) || already_active {
				ctx.active[ctx.active_count] = element.id
				ctx.active_count += 1
			}
		}
	}

	child := element.children
	for child != 0 {
		collect_hovered(ctx, child, position, mouse_down)
		child = ctx.elements[child].next
	}
}

@(private)
point_in_rect :: proc(p: rl.Vector2, pos: rl.Vector2, size: rl.Vector2) -> bool {
	return p.x >= pos.x && p.y >= pos.y && p.x < pos.x + size.x && p.y < pos.y + size.y
}
