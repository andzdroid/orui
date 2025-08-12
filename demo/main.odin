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
	rl.SetTargetFPS(10)

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		{orui.container(
				ctx,
				"container",
				{
					layout = .Flex,
					direction = .TopToBottom,
					position = {.Absolute, {0, 0}},
					width = orui.fixed(width),
					height = orui.fixed(height),
					background_color = rl.BEIGE,
					padding = orui.padding(16),
					margin = orui.margin(16),
					gap = 8,
				},
			)

			{orui.container(
					ctx,
					"top bar",
					{
						layout = .Flex,
						direction = .LeftToRight,
						width = orui.fixed(width),
						height = orui.fixed(100),
						background_color = rl.GREEN,
						padding = orui.padding(8),
					},
				)}

			{orui.container(
					ctx,
					"main section",
					{
						layout = .Flex,
						direction = .LeftToRight,
						width = orui.fixed(width),
						height = orui.fixed(height - 100),
						padding = orui.padding(8),
						gap = 8,
					},
				)

				{orui.container(
						ctx,
						"sidebar",
						{
							layout = .Flex,
							direction = .TopToBottom,
							width = orui.fixed(200),
							height = orui.fixed(height),
							background_color = rl.BLUE,
							padding = orui.padding(8),
							margin = orui.margin(8),
						},
					)}

				{orui.container(
						ctx,
						"content",
						{
							layout = .Flex,
							direction = .TopToBottom,
							width = orui.fixed(width - 200),
							height = orui.fixed(height),
							background_color = rl.RED,
							padding = orui.padding(8),
							margin = orui.margin(8),
						},
					)}
			}
		}
		orui.end(ctx)

		rl.EndDrawing()
	}

	rl.CloseWindow()

	orui.print(ctx)
}
