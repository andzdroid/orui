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
		x := element._position.x + element.padding.left
		y := element._position.y + element.padding.top
		rl.DrawTextEx(
			element.font^,
			strings.unsafe_string_to_cstring(element.text),
			{x, y},
			element.font_size,
			element.letter_spacing,
			element.color,
		)
	}

	child := element.children
	for child != 0 {
		render_element(ctx, child)
		child = ctx.elements[child].next
	}
}
