package demo

import orui "../src"
import "core:strings"
import rl "vendor:raylib"

text_input1: strings.Builder
text_input2: strings.Builder
scroll_initialised := false

render_test_scroll :: proc() {
	if !scroll_initialised {
		text_input1 = strings.builder_make()
		strings.write_string(
			&text_input1,
			"Hello world! This is a single line text input. This is a single line text input.",
		)
		text_input2 = strings.builder_make()
		strings.write_string(
			&text_input2,
			"Hello world!\nThis is a multi-line text input.\nThere are multiple lines of text.",
		)
		scroll_initialised = true
	}

	orui.container(
		orui.id("container"),
		{
			direction = .TopToBottom,
			width = orui.grow(),
			height = orui.grow(),
			padding = orui.padding(16),
			background_color = rl.BEIGE,
			gap = 16,
			align_cross = .Center,
			scroll = orui.scroll(.Vertical),
		},
	)

	orui.text_input(
		orui.id("text input 1"),
		&text_input1,
		{
			width = orui.fixed(300),
			height = orui.fit(),
			padding = orui.padding(8),
			background_color = orui.hovered() || orui.focused() ? rl.WHITE : {240, 240, 240, 255},
			color = rl.BLACK,
			font_size = 16,
			overflow = .Visible,
			clip = {.Self, {}},
			scroll = orui.scroll(.Auto),
			border = orui.border(1),
			border_color = orui.focused() ? rl.BLACK : rl.LIGHTGRAY,
		},
	)

	{orui.container(
			orui.id("text input 2 container"),
			{width = orui.fixed(300), height = orui.fixed(300), position = {.Relative, {}}},
		)

		orui.text_input(
			orui.id("text input 2"),
			&text_input2,
			{
				width = orui.fixed(300),
				height = orui.fixed(300),
				padding = orui.padding(8),
				background_color = orui.hovered() || orui.focused() ? rl.WHITE : {240, 240, 240, 255},
				color = rl.BLACK,
				font_size = 16,
				overflow = .Wrap,
				clip = {.Self, {}},
				scroll = orui.scroll(.Auto),
				border = orui.border(1),
				border_color = orui.focused() ? rl.BLACK : rl.LIGHTGRAY,
			},
		)

		orui.scrollbar(
			orui.to_id("text input 2"),
			{
				position = {.Absolute, {-5, 0}},
				placement = orui.placement(.Right, .Right),
				width = orui.fixed(6),
				height = orui.percent(0.9),
			},
			{direction = .TopToBottom, width = orui.percent(1), background_color = rl.LIGHTGRAY},
		)
	}


	{orui.container(
			orui.id("scroll container"),
			{
				position = {.Relative, {}},
				layout = .Flex,
				direction = .TopToBottom,
				width = orui.fixed(400),
				height = orui.fixed(400),
				padding = orui.padding(0, 0),
				background_color = rl.LIGHTGRAY,
				gap = 8,
				clip = {.Self, {}},
				scroll = orui.scroll(.Auto),
				corner_radius = orui.corner(8),
			},
		)

		for i in 0 ..< 25 {
			background: rl.Color =
				i % 3 == 0 ? {4, 41, 64, 255} : i % 3 == 1 ? {0, 92, 83, 255} : {159, 193, 49, 255}
			orui.label(
				orui.id("element", i),
				"Element",
				{
					width = orui.fixed(800),
					height = orui.fixed(200),
					background_color = background,
					font_size = 16,
					color = rl.WHITE,
					align = {.Center, .Center},
					margin = orui.margin(16),
				},
			)
		}

		orui.scrollbar(
			orui.to_id("scroll container"),
			{
				position = {.Absolute, {5, 0}},
				placement = orui.placement(.Right, .Left),
				width = orui.fixed(10),
				height = orui.percent(1),
				background_color = {214, 213, 142, 255},
				corner_radius = orui.corner(4),
			},
			{
				direction = .TopToBottom,
				width = orui.percent(1),
				background_color = rl.DARKGRAY,
				corner_radius = orui.corner(4),
			},
			0,
		)

		orui.scrollbar(
			orui.to_id("scroll container"),
			{
				position = {.Absolute, {0, 15}},
				placement = orui.placement(.Bottom, .Bottom),
				width = orui.percent(1),
				height = orui.fixed(10),
				background_color = {214, 213, 142, 255},
				corner_radius = orui.corner(4),
			},
			{
				direction = .LeftToRight,
				height = orui.percent(1),
				background_color = rl.DARKGRAY,
				corner_radius = orui.corner(4),
			},
			1,
		)
	}
}
