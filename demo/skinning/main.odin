package demo

import orui "../../src"
import rl "vendor:raylib"

Skin :: enum {
	Dark,
	Light,
}

button_style :: proc(skin: Skin) -> proc(element: ^orui.Element) {
	switch skin {
	case .Dark:
		return dark_button_style
	case .Light:
		return light_button_style
	}
	return dark_button_style
}

dark_button_style :: proc(element: ^orui.Element) {
	element.background_color =
		orui.active() ? {100, 100, 120, 255} : orui.hovered() ? {120, 120, 140, 255} : {60, 60, 80, 255}
	element.border = orui.border(1)
	element.border_color = {100, 100, 120, 255}
	element.corner_radius = orui.corner(4)
	element.color = rl.WHITE
}

light_button_style :: proc(element: ^orui.Element) {
	element.background_color =
		orui.active() ? {180, 150, 130, 255} : orui.hovered() ? {200, 170, 150, 255} : {220, 190, 170, 255}
	element.border = orui.border(1)
	element.border_color = {100, 100, 100, 255}
	element.corner_radius = orui.corner(4)
	element.color = rl.BLACK
}

window_style :: proc(skin: Skin) -> proc(element: ^orui.Element) {
	switch skin {
	case .Dark:
		return dark_window_style
	case .Light:
		return light_window_style
	}
	return dark_window_style
}

dark_window_style :: proc(element: ^orui.Element) {
	element.background_color = {30, 30, 50, 255}
	element.border = orui.border(1)
	element.border_color = {100, 100, 120, 255}
	element.corner_radius = orui.corner(4)
}

light_window_style :: proc(element: ^orui.Element) {
	element.background_color = {240, 210, 180, 255}
	element.border = orui.border(1)
	element.border_color = {100, 100, 100, 255}
	element.corner_radius = orui.corner(4)
}

button :: proc(id: string, label: string, font: ^rl.Font, skin: Skin) -> bool {
	return orui.label(
		orui.id(id),
		label,
		{
			width = orui.fit(),
			height = orui.fit(),
			font = font,
			font_size = 14,
			padding = {10, 20, 10, 20},
		},
		button_style(skin),
	)
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 900, "orui")

	default_font := rl.GetFontDefault()

	ctx := new(orui.Context)
	defer free(ctx)

	skin := Skin.Dark

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(skin == .Dark ? rl.BLACK : rl.BEIGE)

		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		{orui.container(
				orui.id("container"),
				{
					direction = .TopToBottom,
					width = orui.grow(),
					height = orui.grow(),
					align_main = .SpaceBetween,
					align_cross = .Center,
				},
			)

			{orui.container(
					orui.id("toggle"),
					{
						direction = .LeftToRight,
						width = orui.grow(),
						padding = orui.padding(16),
						align_main = .Center,
					},
				)

				if button("toggle button", "Toggle skin", &default_font, skin) {
					skin = skin == .Dark ? .Light : .Dark
				}
			}

			{orui.container(orui.id("spacer top"), {width = orui.grow(), height = orui.grow()})}

			{orui.container(
					orui.id("window"),
					{
						direction = .TopToBottom,
						width = orui.percent(0.4),
						height = orui.percent(0.4),
					},
					window_style(skin),
				)

				{orui.container(
						orui.id("top bar"),
						{
							width = orui.grow(),
							height = orui.fixed(32),
							background_color = skin == .Dark ? {60, 60, 100, 255} : {220, 190, 150, 255},
							padding = {4, 8, 4, 8},
							align_cross = .Center,
							border = {0, 0, 1, 0},
							border_color = {150, 150, 150, 255},
							align_main = .SpaceBetween,
						},
					)
					orui.label(
						orui.id("title"),
						"Window title",
						{
							font = &default_font,
							font_size = 16,
							color = skin == .Dark ? rl.WHITE : rl.BLACK,
						},
					)
				}

				{orui.container(
						orui.id("content"),
						{
							direction = .TopToBottom,
							width = orui.grow(),
							height = orui.grow(),
							gap = 8,
						},
					)

					orui.label(
						orui.id("text"),
						"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam vitae libero eu velit ultrices porta eget eu felis. Ut est mi, tempor vel ullamcorper non, mollis eget ante. Donec tempus ex facilisis lorem elementum, nec tempor justo euismod. Ut vehicula at mauris at accumsan. Morbi id faucibus libero, sit amet finibus mauris. Fusce mauris quam, elementum ut consequat sit amet, vehicula ut nisl. Pellentesque in nibh efficitur, posuere velit sit amet, suscipit diam.",
						{
							width = orui.grow(),
							height = orui.grow(),
							font = &default_font,
							font_size = 14,
							color = skin == .Dark ? rl.WHITE : rl.BLACK,
							padding = orui.padding(16),
							align = {.Start, .Start},
						},
					)

					{orui.container(
							orui.id("bottom row"),
							{
								direction = .LeftToRight,
								width = orui.grow(),
								height = orui.fit(),
								align_main = .End,
								align_cross = .Center,
								padding = orui.padding(8),
								gap = 16,
							},
						)
						button("ok button", "Confirm", &default_font, skin)
						button("cancel button", "Cancel", &default_font, skin)
					}
				}
			}

			{orui.container(
					orui.id("spacer bottom"),
					{width = orui.grow(), height = orui.grow(2)},
				)}
		}

		orui.end()

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
