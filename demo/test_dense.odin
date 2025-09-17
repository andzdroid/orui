package demo

import orui "../src"
import "core:fmt"
import rl "vendor:raylib"

id_buffer: [32]byte

row_id :: proc(i: int) -> int {
	return 123456789 + i
}

cell_id :: proc(i: int, j: int) -> int {
	return 123456789 + i * 80 + j
}

render_dense_row :: proc(i: int) {
	orui.container(
		orui.id(row_id(i)),
		{
			direction = .LeftToRight,
			width = orui.grow(),
			padding = orui.padding(2),
			background_color = rl.LIGHTGRAY,
			gap = 2,
		},
	)

	for j in 0 ..< 80 {
		{orui.container(
				orui.id(cell_id(i, j)),
				{
					layout = .None,
					width = orui.fixed(4),
					height = orui.fixed(4),
					background_color = rl.WHITE,
				},
			)}
	}
}

render_dense :: proc() {
	orui.container(
		orui.id("dense"),
		{
			direction = .TopToBottom,
			width = orui.grow(),
			height = orui.grow(),
			background_color = rl.BEIGE,
		},
	)

	for i in 0 ..< 80 {
		render_dense_row(i)
	}
}
