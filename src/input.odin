package orui

import "core:log"
import "core:strings"
import "core:unicode/utf8"
import rl "vendor:raylib"

@(private)
handle_input_state :: proc(ctx: ^Context) {

	position := rl.GetMousePosition()
	mouse_down := rl.IsMouseButtonDown(.LEFT)
	pressed := rl.IsMouseButtonPressed(.LEFT)
	released := rl.IsMouseButtonReleased(.LEFT)
	scroll := rl.GetMouseWheelMoveV()

	current := current_buffer(ctx)
	previous := previous_buffer(ctx)

	ctx.prev_focus_id = ctx.focus_id
	ctx.hover[current].count = 0
	ctx.active[current].count = 0

	if released {
		ctx.pointer_capture = 0
		// ctx.selecting = false

		if ctx.focus != 0 && ctx.caret_index == -1 {
			ctx.caret_index = text_caret_from_point(&ctx.elements[ctx.focus], position)
		}
	}

	// if ctx.pointer_capture != 0 && mouse_down {
	// 	el := &ctx.elements[ctx.pointer_capture]
	// 	count := ctx.active[current].count
	// 	ctx.active[current].ids[count] = el.id
	// 	ctx.active[current].count += 1
	// 	return
	// }

	scroll_consumed := false
	click_consumed := false

	for i := ctx.sorted_count - 1; i >= 0; i -= 1 {
		element := &ctx.elements[ctx.sorted[i]]

		if ctx.pointer_capture != 0 && ctx.pointer_capture != ctx.sorted[i] {
			continue
		}

		if element.disabled == .True {
			continue
		}

		if !point_in_element(position, element) {
			continue
		}

		if !scroll_consumed {
			if scroll.x != 0 && scrolls_x(element) {
				scroll_offset := get_scroll_offset(element)
				scroll_offset.x -= scroll.x * SCROLL_FACTOR
				scroll_offset.x = clamp(
					scroll_offset.x,
					0,
					element._content_size.x - inner_width(element),
				)
				set_scroll_offset(element.id, scroll_offset)
				if element.block == .True {
					scroll_consumed = true
				}
			}
			if scroll.y != 0 && scrolls_y(element) {
				scroll_offset := get_scroll_offset(element)
				scroll_offset.y -= scroll.y * SCROLL_FACTOR
				scroll_offset.y = clamp(
					scroll_offset.y,
					0,
					element._content_size.y - inner_height(element),
				)
				set_scroll_offset(element.id, scroll_offset)
				if element.block == .True {
					scroll_consumed = true
				}
			}
		}

		if !click_consumed {
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

			if mouse_down && (pressed || already_active) {
				count := ctx.active[current].count
				ctx.active[current].ids[count] = element.id
				ctx.active[current].count += 1

				if pressed {
					if element.editable {
						ctx.focus = ctx.sorted[i]
						ctx.focus_id = element.id
						start := text_caret_from_point(element, position)
						ctx.text_selection.start = start
						ctx.text_selection.end = start
						ctx.caret_index = start
						ctx.caret_time = 0
						ctx.selecting = true
						ensure_caret_visible(ctx, element, ctx.caret_index)
					} else if ctx.focus != 0 {
						ctx.focus = 0
						ctx.focus_id = 0
						ctx.repeat_key = .KEY_NULL
						ctx.text_selection = {}
					}
				}

				if element.capture == .True {
					ctx.pointer_capture = ctx.sorted[i]
				}
			}

			if element.block == .True {
				click_consumed = true
			}
		}

		if scroll_consumed && click_consumed {
			break
		}
	}

	if ctx.selecting && mouse_down && ctx.focus != 0 {
		el := &ctx.elements[ctx.focus]
		end := text_caret_from_point(el, position)
		ctx.text_selection.end = end
		ctx.caret_index = end
		ctx.caret_time = 0
		ensure_caret_visible(ctx, el, ctx.caret_index)
	}

	if released {
		ctx.selecting = false
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
			ctx.repeat_key = .KEY_NULL
			ctx.text_selection = {}
		} else if rl.IsKeyPressed(.ENTER) && element.overflow == .Visible {
			ctx.focus = 0
			ctx.focus_id = 0
			ctx.repeat_key = .KEY_NULL
			ctx.text_selection = {}
		} else {
			text_view := element.text_view
			ctrl_down := rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.RIGHT_CONTROL)
			cmd_down := rl.IsKeyDown(.LEFT_SUPER) || rl.IsKeyDown(.RIGHT_SUPER)
			shift_down := rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT)

			when ODIN_OS == .Darwin {
				word_modifier := rl.IsKeyDown(.LEFT_ALT) || rl.IsKeyDown(.RIGHT_ALT)
				line_modifier := cmd_down
			} else {
				word_modifier := ctrl_down
				line_modifier := false
			}

			if text_view.length < len(text_view.data) {
				for char := rl.GetCharPressed(); char != 0; char = rl.GetCharPressed() {
					if char == '\r' || char == '\n' {
						continue
					}
					if has_text_selection(ctx) {
						ctx.caret_index = delete_text_selection(ctx, element)
					}
					char_bytes, char_len := utf8.encode_rune(char)
					bytes_inserted := insert_bytes(
						text_view,
						ctx.caret_index,
						char_bytes[:char_len],
					)
					set_caret_index(ctx, element, ctx.caret_index + bytes_inserted)
				}
			}

			if key_pressed(ctx, .LEFT) {
				next :=
					word_modifier ? utf8_prev_word(text_view, ctx.caret_index) : utf8_prev(text_view, ctx.caret_index)
				if shift_down {
					if !has_text_selection(ctx) {
						ctx.text_selection.start = ctx.caret_index
					}
					ctx.text_selection.end = next
				} else {
					clear_text_selection(ctx)
				}
				set_caret_index(ctx, element, next)
			}
			if key_pressed(ctx, .RIGHT) {
				next :=
					word_modifier ? utf8_next_word(text_view, ctx.caret_index) : utf8_next(text_view, ctx.caret_index)
				if shift_down {
					if !has_text_selection(ctx) {
						ctx.text_selection.start = ctx.caret_index
					}
					ctx.text_selection.end = next
				} else {
					clear_text_selection(ctx)
				}
				set_caret_index(ctx, element, next)
			}

			if rl.IsKeyPressed(.HOME) {
				next_index := 0
				if ctrl_down || cmd_down || element.overflow == .Visible {
					next_index = 0
				} else {
					next_index = caret_index_start_of_line(element, ctx.caret_index)
				}
				if shift_down {
					if !has_text_selection(ctx) {
						ctx.text_selection.start = ctx.caret_index
					}
					ctx.text_selection.end = next_index
				} else {
					clear_text_selection(ctx)
				}
				set_caret_index(ctx, element, next_index)
			}
			if rl.IsKeyPressed(.END) {
				next_index := text_view.length
				if ctrl_down || cmd_down || element.overflow == .Visible {
					next_index = text_view.length
				} else {
					next_index = caret_index_end_of_line(element, ctx.caret_index)
				}
				if shift_down {
					if !has_text_selection(ctx) {
						ctx.text_selection.start = ctx.caret_index
					}
					ctx.text_selection.end = next_index
				} else {
					clear_text_selection(ctx)
				}
				set_caret_index(ctx, element, next_index)
			}

			if element.overflow == .Wrap {
				if key_pressed(ctx, .UP) {
					next := caret_index_up(element, ctx.caret_position)
					if shift_down {
						if !has_text_selection(ctx) {
							ctx.text_selection.start = ctx.caret_index
						}
						ctx.text_selection.end = next
					} else {
						clear_text_selection(ctx)
					}
					set_caret_index(ctx, element, next)
				}
				if key_pressed(ctx, .DOWN) {
					next := caret_index_down(element, ctx.caret_position)
					if shift_down {
						if !has_text_selection(ctx) {
							ctx.text_selection.start = ctx.caret_index
						}
						ctx.text_selection.end = next
					} else {
						clear_text_selection(ctx)
					}
					set_caret_index(ctx, element, next)
				}
			}

			if key_pressed(ctx, .BACKSPACE) {
				caret := ctx.caret_index
				if has_text_selection(ctx) {
					caret = delete_text_selection(ctx, element)
				} else {
					prev := utf8_prev(text_view, ctx.caret_index)
					delete_range(text_view, prev, ctx.caret_index)
					caret = prev
				}
				set_caret_index(ctx, element, caret)
			}
			if key_pressed(ctx, .DELETE) {
				if has_text_selection(ctx) {
					caret := delete_text_selection(ctx, element)
					set_caret_index(ctx, element, caret)
				} else {
					next := utf8_next(text_view, ctx.caret_index)
					delete_range(text_view, ctx.caret_index, next)
				}
			}

			if key_pressed(ctx, .ENTER) && element.overflow == .Wrap {
				caret := ctx.caret_index
				if has_text_selection(ctx) {
					caret = delete_text_selection(ctx, element)
				}
				char_bytes, char_len := utf8.encode_rune('\n')
				bytes_inserted := insert_bytes(text_view, caret, char_bytes[:char_len])
				set_caret_index(ctx, element, caret + bytes_inserted)
			}

			if rl.IsKeyPressed(.A) && (ctrl_down || cmd_down) {
				ctx.text_selection.start = 0
				ctx.text_selection.end = text_view.length
				set_caret_index(ctx, element, text_view.length)
			}

			if rl.IsKeyPressed(.C) && (ctrl_down || cmd_down) {
				if has_text_selection(ctx) {
					a, b := get_text_selection(ctx)
					selected_text := string(text_view.data[a:b])
					rl.SetClipboardText(
						strings.clone_to_cstring(selected_text, context.temp_allocator),
					)
				}
			}

			if rl.IsKeyPressed(.X) && (ctrl_down || cmd_down) {
				if has_text_selection(ctx) {
					a, b := get_text_selection(ctx)
					selected_text := string(text_view.data[a:b])
					rl.SetClipboardText(
						strings.clone_to_cstring(selected_text, context.temp_allocator),
					)
					delete_range(text_view, a, b)
					set_caret_index(ctx, element, a)
					clear_text_selection(ctx)
				}
			}

			if rl.IsKeyPressed(.V) && (ctrl_down || cmd_down) {
				clipboard_text := rl.GetClipboardText()
				if clipboard_text != nil {
					text := string(clipboard_text)
					caret := ctx.caret_index
					if has_text_selection(ctx) {
						caret = delete_text_selection(ctx, element)
					}
					text_bytes := transmute([]u8)text
					bytes_inserted := insert_bytes(text_view, caret, text_bytes)
					set_caret_index(ctx, element, caret + bytes_inserted)
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
point_in_element :: proc(p: rl.Vector2, element: ^Element) -> bool {
	if !point_in_rect(p, element._position, element._size) {
		return false
	}

	if element._clip.width > 0 || element._clip.height > 0 {
		return point_in_rect(
			p,
			{f32(element._clip.x), f32(element._clip.y)},
			{f32(element._clip.width), f32(element._clip.height)},
		)
	}

	return true
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

@(private)
set_caret_index :: proc(ctx: ^Context, element: ^Element, index: int) {
	ctx.caret_index = clamp(index, 0, element.text_view.length)
	ctx.caret_time = 0
	ensure_caret_visible(ctx, element, ctx.caret_index)
}

@(private)
has_text_selection :: #force_inline proc(ctx: ^Context) -> bool {
	return ctx.text_selection.start != ctx.text_selection.end
}

@(private)
get_text_selection :: #force_inline proc(ctx: ^Context) -> (int, int) {
	a := min(ctx.text_selection.start, ctx.text_selection.end)
	b := max(ctx.text_selection.start, ctx.text_selection.end)
	return a, b
}

@(private)
clear_text_selection :: #force_inline proc(ctx: ^Context) {
	ctx.text_selection = {}
}

@(private)
delete_text_selection :: #force_inline proc(ctx: ^Context, element: ^Element) -> int {
	a, b := get_text_selection(ctx)
	delete_range(element.text_view, a, b)
	clear_text_selection(ctx)
	return a
}
