package demo

import orui "../src"
import "core:log"
import "core:os"
import rl "vendor:raylib"

main :: proc() {
	mode: int = 0
	when ODIN_OS == .Linux || ODIN_OS == .Darwin {
		mode = os.S_IRUSR | os.S_IWUSR | os.S_IRGRP | os.S_IROTH
	}

	logh, logh_err := os.open("log.txt", (os.O_CREATE | os.O_TRUNC | os.O_RDWR), mode)
	if logh_err == os.ERROR_NONE {
		os.stdout = logh
		os.stderr = logh
	}

	logger_allocator := context.allocator
	logger :=
		logh_err == os.ERROR_NONE ? log.create_file_logger(logh, allocator = logger_allocator) : log.create_console_logger(allocator = logger_allocator)
	context.logger = logger

	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 900, "orui")
	rl.SetTargetFPS(1)

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)

	default_font := rl.GetFontDefault()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		{orui.container(
				"container",
				{
					layout = .Flex,
					direction = .TopToBottom,
					position = {.Absolute, {0, 0}},
					width = orui.fixed(width),
					height = orui.fixed(height),
					background_color = rl.BEIGE,
					padding = orui.padding(16),
					gap = 8,
				},
			)

			{orui.container(
					"top bar",
					{
						layout = .Flex,
						direction = .LeftToRight,
						width = orui.grow(),
						height = orui.fixed(100),
						background_color = {80, 180, 50, 255},
						padding = orui.padding(8),
					},
				)}

			{orui.container(
					"main section",
					{
						layout = .Flex,
						direction = .LeftToRight,
						width = orui.grow(),
						height = orui.grow(),
						gap = 5,
						background_color = {200, 200, 80, 255},
					},
				)

				{orui.container(
						"sidebar",
						{
							layout           = .Flex,
							direction        = .TopToBottom,
							width            = orui.fixed(200),
							height           = orui.grow(),
							background_color = {50, 80, 200, 255},
							// padding = orui.padding(8),
							margin           = orui.margin(6),
						},
					)}

				{orui.container(
						"content",
						{
							layout = .Flex,
							direction = .TopToBottom,
							width = orui.grow(),
							height = orui.grow(),
							background_color = {200, 50, 80, 255},
							padding = orui.padding(8),
							margin = orui.margin(7),
							gap = 5,
						},
					)

					{orui.container(
							"fit content",
							{
								layout = .Flex,
								direction = .LeftToRight,
								width = orui.fit(),
								height = orui.fit(),
								background_color = {0, 100, 0, 255},
								padding = orui.padding(10),
								margin = orui.margin(25),
								gap = 10,
							},
						)

						{orui.container(
								"box a",
								{
									layout = .Flex,
									direction = .TopToBottom,
									width = orui.fit(),
									height = orui.fixed(200),
									background_color = {100, 100, 200, 255},
									margin = orui.margin(20),
								},
							)

							orui.label(
								"label",
								"Hello world! here is some more text and more text to see how it looks",
								{
									font = &default_font,
									font_size = 20,
									color = rl.WHITE,
									background_color = rl.BLACK,
									padding = orui.padding(10),
									margin = orui.margin(5),
									width = orui.grow(),
								},
							)
						}

						{orui.container(
								"box b",
								{
									width = orui.fixed(200),
									height = orui.fixed(200),
									background_color = {100, 200, 100, 255},
									margin = orui.margin(20),
								},
							)}

						{orui.container(
								"box c",
								{
									position = {.Relative, {100, 100}},
									width = orui.fixed(200),
									height = orui.fixed(200),
									background_color = {200, 100, 100, 255},
									margin = orui.margin(20),
								},
							)}
					}
				}
			}
		}
		orui.end()

		rl.EndDrawing()
		// break
	}

	rl.CloseWindow()

	orui.print(ctx)
}
