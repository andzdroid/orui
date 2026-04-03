package demo

import orui "../src"
import rl "vendor:raylib"

GRID_DENSE_SIZE :: 80

render_test_grid_dense :: proc() {
	orui.container(
		orui.id("container"),
		{
			direction = .TopToBottom,
			width = orui.grow(),
			height = orui.grow(),
			padding = orui.padding(16),
			background_color = rl.BEIGE,
			gap = 16,
		},
	)

	orui.label(
		orui.id("title"),
		"Grid Dense",
		{width = orui.grow(), font_size = 24, color = rl.BLACK, align = {.Center, .Center}},
	)

	orui.container(
		orui.id("dense"),
		{
			layout = .Grid,
			direction = .LeftToRight,
			width = orui.grow(),
			height = orui.grow(),
			padding = orui.padding(4),
			background_color = rl.BEIGE,
			gap = 4,
			cols = GRID_DENSE_SIZE,
			rows = GRID_DENSE_SIZE,
			col_sizes = []orui.Size{orui.fixed(8)},
			row_sizes = []orui.Size{orui.fixed(8)},
			scroll = orui.scroll(.Auto),
		},
	)

	for i in 0 ..< GRID_DENSE_SIZE * GRID_DENSE_SIZE {
		{orui.container(
				orui.id("cell", i),
				{
					layout = .None,
					width = orui.fixed(8),
					height = orui.fixed(8),
					background_color = rl.BLUE,
				},
			)}
	}
}
