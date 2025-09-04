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

	texture := rl.LoadTexture("icon.png")
	defer rl.UnloadTexture(texture)

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
					direction = .TopToBottom,
					width = orui.grow(),
					height = orui.grow(),
					gap = 16,
					padding = orui.padding(50),
					align_main = .Center,
					align_cross = .Center,
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

		orui.end()

		rl.EndDrawing()
		// break
	}

	rl.CloseWindow()
}
