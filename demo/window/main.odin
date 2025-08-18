package demo

import orui "../../src"
import rl "vendor:raylib"

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 900, "orui")

	default_font := rl.GetFontDefault()

	ctx := new(orui.Context)
	defer free(ctx)

	close_icon := rl.LoadTexture("close.png")
	defer rl.UnloadTexture(close_icon)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		{orui.container(
				orui.id("container"),
				{
					direction = .TopToBottom,
					width = orui.fixed(width),
					height = orui.fixed(height),
					padding = orui.padding(16),
					gap = 16,
					align_main = .Center,
					align_cross = .Center,
				},
			)

			{orui.container(
					orui.id("window"),
					{
						direction = .TopToBottom,
						width = orui.percent(0.5),
						height = orui.percent(0.5),
						background_color = {30, 30, 30, 255},
						border = orui.border(1),
						border_color = {100, 100, 100, 255},
					},
				)

				{orui.container(
						orui.id("top bar"),
						{
							width = orui.grow(),
							height = orui.fixed(32),
							background_color = {60, 60, 60, 255},
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
						{font = &default_font, font_size = 16, color = rl.WHITE},
					)

					orui.image(
						orui.id("close icon"),
						&close_icon,
						{
							width = orui.fixed(24),
							height = orui.fixed(24),
							color = orui.active() ? {220, 220, 220, 255} : orui.hovered() ? rl.WHITE : {200, 200, 200, 255},
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
							color = rl.WHITE,
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
						orui.label(
							orui.id("ok button"),
							"Confirm",
							{
								width = orui.fit(),
								height = orui.fit(),
								font = &default_font,
								font_size = 14,
								color = rl.WHITE,
								padding = {10, 20, 10, 20},
								background_color = orui.active() ? {100, 120, 100, 255} : orui.hovered() ? {120, 140, 120, 255} : {60, 80, 60, 255},
								border = orui.border(1),
								border_color = {100, 100, 100, 255},
								corner_radius = orui.corner(4),
							},
						)
						orui.label(
							orui.id("cancel button"),
							"Cancel",
							{
								width = orui.fit(),
								height = orui.fit(),
								font = &default_font,
								font_size = 14,
								color = rl.WHITE,
								padding = {10, 20, 10, 20},
								background_color = orui.active() ? {120, 100, 100, 255} : orui.hovered() ? {140, 120, 120, 255} : {80, 60, 60, 255},
								border = orui.border(1),
								border_color = {100, 100, 100, 255},
								corner_radius = orui.corner(4),
							},
						)
					}
				}
			}
		}

		orui.end()

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
