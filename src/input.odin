package orui

import "core:log"
import "core:strings"
import "core:unicode/utf8"
import rl "vendor:raylib"

@(private)
handle_input_state :: proc(ctx: ^Context) {
	position := rl.GetMousePosition()
	mouse_down := rl.IsMouseButtonDown(.LEFT)

	current := current_buffer(ctx)
	previous := previous_buffer(ctx)

	if ctx.focus != 0 && ctx.caret_index == -1 {
		if rl.IsMouseButtonReleased(.LEFT) {
			ctx.caret_index = text_caret_from_point(&ctx.elements[ctx.focus], position)
		}
	}

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

	handle_keyboard_input(ctx)
}

@(private)
handle_keyboard_input :: proc(ctx: ^Context) {
	if ctx.focus != 0 {
		element := &ctx.elements[ctx.focus]
		if !element.editable {
			ctx.focus = 0
			ctx.focus_id = 0
		} else {
			text_view := element.text_view

			if text_view.length < len(text_view.data) {
				for char := rl.GetCharPressed(); char != 0; char = rl.GetCharPressed() {
					if char == '\r' || char == '\n' {
						continue
					}

					char_bytes, char_len := utf8.encode_rune(char)
					insert_bytes(text_view, ctx.caret_index, char_bytes[:char_len])
					ctx.caret_index += char_len
					ctx.caret_index = min(ctx.caret_index, text_view.length)
				}
			}

			if key_pressed(ctx, .LEFT) {
				ctx.caret_index = utf8_prev(text_view, ctx.caret_index)
				ctx.caret_time = 0
			}
			if key_pressed(ctx, .RIGHT) {
				ctx.caret_index = utf8_next(text_view, ctx.caret_index)
				ctx.caret_time = 0
			}
			if rl.IsKeyPressed(.HOME) {
				ctx.caret_index = 0
				ctx.caret_time = 0
			}
			if rl.IsKeyPressed(.END) {
				ctx.caret_index = text_view.length
				ctx.caret_time = 0
			}

			if element.overflow == .Wrap {
				if key_pressed(ctx, .UP) {
					ctx.caret_index = caret_index_up(element, ctx.caret_position)
					ctx.caret_time = 0
				}
				if key_pressed(ctx, .DOWN) {
					ctx.caret_index = caret_index_down(element, ctx.caret_position)
					ctx.caret_time = 0
				}
			}

			if key_pressed(ctx, .BACKSPACE) {
				prev := utf8_prev(text_view, ctx.caret_index)
				delete_range(text_view, prev, ctx.caret_index)
				ctx.caret_index = prev
				ctx.caret_time = 0
			}
			if key_pressed(ctx, .DELETE) {
				next := utf8_next(text_view, ctx.caret_index)
				delete_range(text_view, ctx.caret_index, next)
				ctx.caret_time = 0
			}

			if key_pressed(ctx, .ENTER) {
				if element.overflow == .Wrap {
					char_bytes, char_len := utf8.encode_rune('\n')
					insert_bytes(text_view, ctx.caret_index, char_bytes[:char_len])
					ctx.caret_index += char_len
					ctx.caret_index = min(ctx.caret_index, text_view.length)
				}
			}
		}
	}
}

@(private)
point_in_rect :: proc(p: rl.Vector2, pos: rl.Vector2, size: rl.Vector2) -> bool {
	return p.x >= pos.x && p.y >= pos.y && p.x < pos.x + size.x && p.y < pos.y + size.y
}

@(private)
key_pressed :: proc(ctx: ^Context, key: rl.KeyboardKey) -> bool {
	now := rl.GetTime()

	if rl.IsKeyPressed(key) {
		ctx.repeat_key = key
		ctx.repeat_time = now + KEY_REPEAT_DELAY
		return true
	}

	if ctx.repeat_key == key && rl.IsKeyDown(key) {
		if now >= ctx.repeat_time {
			ctx.repeat_time += KEY_REPEAT_INTERVAL
			return true
		}
	}

	if ctx.repeat_key == key && rl.IsKeyReleased(key) {
		ctx.repeat_key = .KEY_NULL
	}

	return false
}
