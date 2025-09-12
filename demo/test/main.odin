package demo

import orui "../../src"
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

	default_font := rl.GetFontDefault()

	ctx := new(orui.Context)
	defer free(ctx)

	frame := 0
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BEIGE)

		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		{orui.container(
				orui.id("container"),
				{
					position = {.Relative, {}},
					direction = .TopToBottom,
					width = orui.grow(),
					height = orui.grow(),
					gap = 16,
					padding = orui.padding(50),
					align_main = .Center,
					align_cross = .Center,
					background_color = rl.WHITE,
				},
			)

			{orui.container(
					orui.id("absolute"),
					{
						position = {.Absolute, {}},
						width = orui.percent(1),
						height = orui.percent(1),
						background_color = rl.RED,
					},
				)}

		}

		orui.end()

		rl.EndDrawing()

		free_all(context.temp_allocator)
		// break
	}

	rl.CloseWindow()
}
