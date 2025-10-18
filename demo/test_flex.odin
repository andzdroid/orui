package demo

import orui "../src"
import "core:fmt"
import rl "vendor:raylib"

render_test_flex :: proc() {
	orui.container(
		orui.id("container"),
		{
			direction = .TopToBottom,
			width = orui.percent(1),
			height = orui.percent(1),
			padding = {16, 24, 16, 16},
			background_color = rl.BEIGE,
			gap = 16,
			scroll = orui.scroll(.Vertical),
		},
	)

	orui.scrollbar(
		orui.to_id("container"),
		{
			position = {.Absolute, {-5, 0}},
			placement = orui.placement(.Right, .Right),
			width = orui.fixed(8),
			height = orui.percent(0.98),
		},
		{
			direction = .TopToBottom,
			width = orui.percent(1),
			background_color = rl.DARKGRAY,
			corner_radius = orui.corner(4),
		},
	)

	{orui.container(orui.id("group 1"), {width = orui.grow(), direction = .LeftToRight, gap = 8})
		{row("row 1", "Start", .Start, .Start)}
		{row("row 2", "Center", .Center, .Center)}
		{row("row 3", "End", .End, .End)}
	}

	{orui.container(orui.id("group 2"), {width = orui.grow(), direction = .LeftToRight, gap = 8})
		{row("row 4", "Space between", .SpaceBetween, .Center)}
		{row("row 5", "Space around", .SpaceAround, .Center)}
		{row("row 6", "Space evenly", .SpaceEvenly, .Center)}
	}

	{orui.container(orui.id("group 3"), {width = orui.grow(), direction = .LeftToRight, gap = 8})
		{row_wrapped("row wrapped 1", "Start (wrapped)", .Start, .Start, .Start)}
		{row_wrapped("row wrapped 2", "Center (wrapped)", .Center, .Center, .Center)}
		{row_wrapped("row wrapped 3", "End (wrapped)", .End, .End, .End)}
	}
	{orui.container(orui.id("group 4"), {width = orui.grow(), direction = .LeftToRight, gap = 8})
		{row_wrapped(
				"row wrapped 4",
				"Space between (wrapped)",
				.SpaceBetween,
				.Center,
				.SpaceBetween,
			)}
		{row_wrapped(
				"row wrapped 5",
				"Space around (wrapped)",
				.SpaceAround,
				.Center,
				.SpaceAround,
			)}
		{row_wrapped(
				"row wrapped 6",
				"Space evenly (wrapped)",
				.SpaceEvenly,
				.Center,
				.SpaceEvenly,
			)}
	}
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
			width = orui.percent(0.33),
			height = orui.fit(),
			padding = orui.padding(8),
			gap = 8,
		},
	)

	orui.label(orui.id(id, 1), title, {font_size = 16, color = rl.BLACK})

	{orui.container(
			orui.id(id, 2),
			{
				width = orui.grow(),
				height = orui.fixed(200),
				gap = 8,
				align_main = align_main,
				align_cross = align_cross,
				background_color = {50, 50, 50, 255},
				padding = orui.padding(8),
			},
		)

		for i in 0 ..< 5 {
			orui.container(
				orui.id(id, 3 + i),
				{
					width = orui.fixed(25),
					height = orui.fixed(25),
					background_color = {90, 120, 150, 255},
					corner_radius = orui.corner(4),
				},
			)
		}
	}
}

row_wrapped :: proc(
	id: string,
	title: string,
	align_main: orui.MainAlignment,
	align_cross: orui.CrossAlignment,
	align_content: orui.MainAlignment,
) {
	orui.container(
		orui.id(id),
		{
			direction = .TopToBottom,
			width = orui.percent(0.33),
			height = orui.fit(),
			padding = orui.padding(8),
			gap = 8,
		},
	)

	orui.label(orui.id(id, 1), title, {font_size = 16, color = rl.BLACK})

	{orui.container(
			orui.id(id, 2),
			{
				width = orui.grow(),
				height = orui.fixed(500),
				gap = 20,
				align_main = align_main,
				align_cross = align_cross,
				align_content = align_content,
				background_color = {50, 50, 50, 255},
				padding = orui.padding(8),
				flex_wrap = .Wrap,
			},
		)

		for i in 0 ..< 15 {
			orui.container(
				orui.id(id, 3 + i),
				{
					width = i % 3 == 0 ? orui.fixed(75) : orui.fixed(50),
					height = i % 4 == 0 ? orui.fixed(50) : orui.fixed(25),
					background_color = {90, 120, 150, 255},
					corner_radius = orui.corner(4),
				},
			)
		}
	}
}
