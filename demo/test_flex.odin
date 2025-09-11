package demo

import orui "../src"
import "core:fmt"
import rl "vendor:raylib"

render_test_flex :: proc() {
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

	{row("row 1", "Start", .Start, .Start)}
	{row("row 2", "Center", .Center, .Center)}
	{row("row 3", "End", .End, .End)}
	{row("row 4", "Space between", .SpaceBetween, .Center)}
	{row("row 5", "Space around", .SpaceAround, .Center)}
	{row("row 6", "Space evenly", .SpaceEvenly, .Center)}
}

row :: proc(
	id: string,
	title: string,
	align_main: orui.MainAlignment,
	align_cross: orui.CrossAlignment,
) {
	orui.container(
		orui.id(id),
		{
			direction = .TopToBottom,
			width = orui.grow(),
			height = orui.grow(),
			padding = orui.padding(8),
			gap = 8,
		},
	)

	orui.label(
		orui.id(fmt.tprintf("%v label", id)),
		title,
		{font = &font, font_size = 16, color = rl.WHITE},
	)

	{orui.container(
			orui.id(fmt.tprintf("%v container", id)),
			{
				width = orui.grow(),
				height = orui.grow(),
				gap = 8,
				align_main = align_main,
				align_cross = align_cross,
				background_color = {50, 50, 50, 255},
				padding = orui.padding(8),
			},
		)

		for i in 0 ..< 5 {
			orui.container(
				orui.id(fmt.tprintf("%v container %v", id, i)),
				{
					width = orui.fixed(100),
					height = orui.percent(0.7),
					background_color = {90, 120, 150, 255},
					corner_radius = orui.corner(9),
				},
			)
		}
	}
}
