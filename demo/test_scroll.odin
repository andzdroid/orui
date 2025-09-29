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
