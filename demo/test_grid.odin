package demo

import orui "../src"
import rl "vendor:raylib"

cell_style :: proc(element: ^orui.Element) {
	element.width = orui.grow()
	element.height = orui.grow()
	element.font_size = 32
	element.letter_spacing = 4
	element.color = rl.WHITE
	element.background_color = {30, 60, 90, 255}
	element.align = {.Center, .Center}
	element.border = orui.border(1)
	element.border_color = rl.WHITE
	element.padding = orui.padding(20)
}

render_test_grid :: proc() {
	orui.container(
		orui.id("flex container"),
		{
			layout = .Flex,
			direction = .TopToBottom,
			width = orui.grow(),
			height = orui.grow(),
			background_color = rl.BEIGE,
		},
	)

	{orui.container(
			orui.id("container"),
			{
				layout = .Grid,
				direction = .LeftToRight,
				width = orui.grow(),
				height = orui.grow(),
				padding = orui.padding(16),
				cols = 6,
				rows = 6,
				col_sizes = []orui.Size{orui.percent(1.0 / 6)},
				row_sizes = []orui.Size{orui.percent(1.0 / 6)},
				row_gap = 4,
				col_gap = 16,
			},
		)

		orui.label(orui.id("label 1"), "Row span 2", {row_span = 2}, cell_style)
		orui.label(orui.id("label 2"), "Column span 2", {col_span = 2}, cell_style)
		orui.label(orui.id("label 3"), "Cell", {}, cell_style)
		orui.label(orui.id("label 4"), "Cell", {}, cell_style)
		orui.label(orui.id("label 5"), "Cell", {}, cell_style)
		orui.label(orui.id("label 6"), "Cell", {}, cell_style)
		orui.label(orui.id("label 7"), "Column span 3", {col_span = 3}, cell_style)
		orui.label(orui.id("label 8"), "Cell", {}, cell_style)
		orui.label(orui.id("label 9"), "Cell", {}, cell_style)
		orui.label(orui.id("label 10"), "3x2", {row_span = 2, col_span = 3}, cell_style)
		orui.label(orui.id("label 11"), "Cell", {}, cell_style)
		orui.label(orui.id("label 12"), "Cell", {}, cell_style)
		orui.label(orui.id("label 13"), "Cell", {}, cell_style)
		orui.label(orui.id("label 14"), "2x3", {row_span = 3, col_span = 2}, cell_style)
		orui.label(orui.id("label 15"), "Cell", {}, cell_style)
		orui.label(orui.id("label 16"), "Cell", {}, cell_style)
		orui.label(orui.id("label 17"), "Cell", {}, cell_style)
		orui.label(orui.id("label 18"), "Cell", {}, cell_style)
		orui.label(orui.id("label 19"), "4x1", {col_span = 4}, cell_style)
	}
}
