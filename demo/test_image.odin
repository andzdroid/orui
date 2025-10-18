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
			padding = {16, 24, 16, 16},
			background_color = rl.BEIGE,
			gap = 16,
			align_cross = .Center,
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

	orui.label(
		orui.id("title"),
		"Texture fit",
		{width = orui.grow(), font_size = 24, color = rl.BLACK, align = {.Center, .Center}},
	)

	orui.label(
		orui.id("1 label"),
		"Fill (default)",
		{font_size = 16, color = rl.BLACK, margin = {16, 0, 0, 0}},
	)
	orui.image(
		orui.id("1"),
		&texture,
		{width = orui.fixed(150), height = orui.fixed(150), background_color = rl.BLACK},
	)

	orui.label(
		orui.id("2 label"),
		"Fill with padding",
		{font_size = 16, color = rl.BLACK, margin = {16, 0, 0, 0}},
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

	orui.label(
		orui.id("3a label"),
		"Contain, align start",
		{font_size = 16, color = rl.BLACK, margin = {16, 0, 0, 0}},
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

	orui.label(
		orui.id("3b label"),
		"Contain, align center",
		{font_size = 16, color = rl.BLACK, margin = {16, 0, 0, 0}},
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

	orui.label(
		orui.id("3c label"),
		"Contain, align end",
		{font_size = 16, color = rl.BLACK, margin = {16, 0, 0, 0}},
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

	orui.label(
		orui.id("4 label"),
		"Cover",
		{font_size = 16, color = rl.BLACK, margin = {16, 0, 0, 0}},
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

	orui.label(
		orui.id("5 label"),
		"None",
		{font_size = 16, color = rl.BLACK, margin = {16, 0, 0, 0}},
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

	orui.label(
		orui.id("6 label"),
		"Cover with padding",
		{font_size = 16, color = rl.BLACK, margin = {16, 0, 0, 0}},
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
