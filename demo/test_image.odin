package demo

import orui "../src"
import rl "vendor:raylib"

render_test_image :: proc() {
	orui.container(
		orui.id("container"),
		{
			direction = .TopToBottom,
			width = orui.grow(),
			height = orui.grow(),
			gap = 16,
			padding = orui.padding(50),
			align_main = .Center,
			align_cross = .Center,
			background_color = rl.BEIGE,
		},
	)

	orui.image(
		orui.id("1"),
		&texture,
		{width = orui.fixed(150), height = orui.fixed(150), background_color = rl.BLACK},
	)

	orui.image(
		orui.id("2"),
		&texture,
		{
			width = orui.fixed(150),
			height = orui.fixed(50),
			padding = orui.padding(16, 8),
			background_color = rl.BLACK,
		},
	)

	orui.image(
		orui.id("3a"),
		&texture,
		{
			width = orui.fixed(150),
			height = orui.fixed(50),
			background_color = rl.BLACK,
			texture_fit = .Contain,
			align = {.Start, .Start},
		},
	)

	orui.image(
		orui.id("3b"),
		&texture,
		{
			width = orui.fixed(150),
			height = orui.fixed(50),
			background_color = rl.BLACK,
			texture_fit = .Contain,
			align = {.Center, .Center},
		},
	)

	orui.image(
		orui.id("3c"),
		&texture,
		{
			width = orui.fixed(150),
			height = orui.fixed(50),
			background_color = rl.BLACK,
			texture_fit = .Contain,
			align = {.End, .End},
		},
	)

	orui.image(
		orui.id("4"),
		&texture,
		{
			width = orui.fixed(150),
			height = orui.fixed(50),
			background_color = rl.BLACK,
			texture_fit = .Cover,
			align = {.Start, .Center},
		},
	)

	orui.image(
		orui.id("5"),
		&texture,
		{
			width = orui.fixed(150),
			height = orui.fixed(75),
			padding = orui.padding(16, 8),
			background_color = rl.BLACK,
			texture_fit = .None,
		},
	)

	orui.image(
		orui.id("6"),
		&texture,
		{
			width = orui.fixed(150),
			height = orui.fixed(50),
			padding = orui.padding(32, 8),
			background_color = rl.BLACK,
			texture_fit = .Cover,
		},
	)
}
