package demo

import orui "../src"
import rl "vendor:raylib"

cell_style :: proc(element: ^orui.Element) {
	// element.width = orui.grow()
	element.height = orui.grow()
	element.font = &font
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
	{orui.container(
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
					cols = 3,
					rows = 3,
					col_sizes = []orui.Size{orui.fixed(300), orui.grow()},
					row_sizes = []orui.Size{orui.grow()},
					row_gap = 4,
					col_gap = 16,
				},
			)

			orui.label(
				orui.id("label 1"),
				"Row span 2",
				{row_span = 2, width = orui.grow()},
				cell_style,
			)
			orui.label(
				orui.id("label 2"),
				"Column span 2",
				{col_span = 2, width = orui.grow()},
				cell_style,
			)
			orui.label(orui.id("label 3"), "Cell", {width = orui.fit()}, cell_style)
			orui.label(
				orui.id("label 4"),
				"Column span 3",
				{col_span = 3, width = orui.grow()},
				cell_style,
			)
			orui.label(orui.id("label 5"), "Cell", {width = orui.grow()}, cell_style)
		}
	}
}
