package demo

import orui "../src"
import rl "vendor:raylib"

text_view1: orui.TextView
text_view2: orui.TextView
scroll_initialised := false

render_test_scroll :: proc() {
	if !scroll_initialised {
		text_view1 = orui.text_view(
			"Hello world! This is a single line text input. This is a single line text input.",
			128,
		)

		text_view2 = orui.text_view(
			"Hello world!\nThis is a multi-line text input.\nThere are multiple lines of text.",
			512,
		)

		scroll_initialised = true
	}

	orui.container(
		orui.id("container"),
		{
			direction        = .TopToBottom,
			width            = orui.grow(),
			height           = orui.grow(),
			padding          = orui.padding(16),
			background_color = rl.BEIGE,
			gap              = 16,
			// align_main       = .Center,
			align_cross      = .Center,
			scroll           = orui.scroll(.Vertical),
		},
	)

	orui.text_input(
		orui.id("text input 1"),
		&text_view1,
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

	orui.text_input(
		orui.id("text input 2"),
		&text_view2,
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


	{orui.container(
			orui.id("scroll container"),
			{
				layout = .Flex,
				direction = .TopToBottom,
				width = orui.percent(0.5),
				height = orui.percent(0.75),
				padding = orui.padding(16),
				background_color = rl.LIGHTGRAY,
				gap = 16,
				clip = {.Self, {}},
				scroll = orui.scroll(.Auto),
				corner_radius = orui.corner(8),
			},
		)

		for i in 0 ..< 50 {
			orui.label(
				orui.id(123456789 + i),
				"Element",
				{
					width = orui.grow(),
					height = orui.fixed(200),
					background_color = {30, 60, 180, 255},
					font_size = 16,
					color = rl.WHITE,
					align = {.Center, .Center},
				},
			)
		}
	}
}
