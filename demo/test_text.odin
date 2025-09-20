package demo

import orui "../src"
import rl "vendor:raylib"

text_view: orui.TextView

button_style :: proc(element: ^orui.Element) {
	element.background_color =
		orui.active() ? {220, 190, 170, 255} : orui.hovered() ? {250, 220, 200, 255} : {240, 210, 190, 255}
	element.border = orui.border(1)
	element.border_color = {100, 100, 100, 255}
	element.corner_radius = orui.corner(4)
	element.color = rl.BLACK
	element.padding = orui.padding(10, 8)
}

render_test_text :: proc() {
	if text_view.length == 0 {
		text_view = orui.text_view("Hello world!", 128)
	}

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

	orui.text_input(
		orui.id("text input"),
		&text_view,
		{
			width = orui.fixed(300),
			padding = orui.padding(8),
			background_color = orui.hovered() || orui.focused() ? rl.WHITE : {240, 240, 240, 255},
			color = rl.BLACK,
			font_size = 14,
			overflow = .Visible,
			clip = {.Self, {}},
			border = orui.border(1),
			border_color = orui.focused() ? rl.BLACK : rl.LIGHTGRAY,
		},
	)

	orui.label(
		orui.id("text output"),
		string(text_view.data[:text_view.length]),
		{font_size = 14},
		button_style,
	)


	orui.label(
		orui.id("1"),
		"Dropdown: Option 1",
		{font_size = 14, letter_spacing = 5},
		button_style,
	)

	orui.label(orui.id("2"), "Dropdown: Option 2", {font_size = 14}, button_style)

	orui.label(
		orui.id("3"),
		"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam vitae libero eu velit ultrices porta eget eu felis. Ut est mi, tempor vel ullamcorper non, mollis eget ante. Donec tempus ex facilisis lorem elementum, nec tempor justo euismod. Ut vehicula at mauris at accumsan. Morbi id faucibus libero, sit amet finibus mauris. Fusce mauris quam, elementum ut consequat sit amet, vehicula ut nisl. Pellentesque in nibh efficitur, posuere velit sit amet, suscipit diam.",
		{
			font_size = 12,
			height = orui.grow(),
			width = orui.grow(),
			overflow = .Wrap,
			align = {.End, .End},
		},
		button_style,
	)

	orui.label(
		orui.id("4"),
		"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam vitae libero eu velit ultrices porta eget eu felis. Ut est mi, tempor vel ullamcorper non, mollis eget ante. Donec tempus ex facilisis lorem elementum, nec tempor justo euismod. Ut vehicula at mauris at accumsan. Morbi id faucibus libero, sit amet finibus mauris. Fusce mauris quam, elementum ut consequat sit amet, vehicula ut nisl. Pellentesque in nibh efficitur, posuere velit sit amet, suscipit diam.",
		{font_size = 12, width = orui.fixed(300), letter_spacing = 3},
		button_style,
	)

	orui.label(
		orui.id("5"),
		"Line 1\nLine 2",
		{font_size = 14, width = orui.fixed(200)},
		button_style,
	)

	{orui.container(
			orui.id("align container"),
			{
				layout = .Grid,
				direction = .LeftToRight,
				width = orui.fit(),
				height = orui.fit(),
				cols = 3,
				rows = 3,
				col_sizes = []orui.Size{orui.grow()},
				row_sizes = []orui.Size{orui.grow()},
				gap = 4,
			},
		)
		orui.label(
			orui.id("align start start"),
			"Lorem",
			{
				font_size = 12,
				width = orui.fixed(100),
				height = orui.fixed(100),
				align = {.Start, .Start},
			},
			button_style,
		)

		orui.label(
			orui.id("align center start"),
			"Lorem",
			{
				font_size = 12,
				width = orui.fixed(100),
				height = orui.fixed(100),
				align = {.Center, .Start},
			},
			button_style,
		)

		orui.label(
			orui.id("align end start"),
			"Lorem",
			{
				font_size = 12,
				width = orui.fixed(100),
				height = orui.fixed(100),
				align = {.End, .Start},
			},
			button_style,
		)

		orui.label(
			orui.id("align start center"),
			"Lorem",
			{
				font_size = 12,
				width = orui.fixed(100),
				height = orui.fixed(100),
				align = {.Start, .Center},
			},
			button_style,
		)

		orui.label(
			orui.id("align center center"),
			"Lorem",
			{
				font_size = 12,
				width = orui.fixed(100),
				height = orui.fixed(100),
				align = {.Center, .Center},
			},
			button_style,
		)

		orui.label(
			orui.id("align end center"),
			"Lorem",
			{
				font_size = 12,
				width = orui.fixed(100),
				height = orui.fixed(100),
				align = {.End, .Center},
			},
			button_style,
		)

		orui.label(
			orui.id("align start end"),
			"Lorem",
			{
				font_size = 12,
				width = orui.fixed(100),
				height = orui.fixed(100),
				align = {.Start, .End},
			},
			button_style,
		)

		orui.label(
			orui.id("align center end"),
			"Lorem",
			{
				font_size = 12,
				width = orui.fixed(100),
				height = orui.fixed(100),
				align = {.Center, .End},
			},
			button_style,
		)

		orui.label(
			orui.id("align end end"),
			"Lorem",
			{
				font_size = 12,
				width = orui.fixed(100),
				height = orui.fixed(100),
				align = {.End, .End},
			},
			button_style,
		)
	}
}
