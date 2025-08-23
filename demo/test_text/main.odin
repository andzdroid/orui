package demo

import orui "../../src"
import "core:log"
import "core:os"
import rl "vendor:raylib"

button_style :: proc(element: ^orui.Element) {
	element.background_color =
		orui.active() ? {220, 190, 170, 255} : orui.hovered() ? {250, 220, 200, 255} : {240, 210, 190, 255}
	element.border = orui.border(1)
	element.border_color = {100, 100, 100, 255}
	element.corner_radius = orui.corner(4)
	element.color = rl.BLACK
	element.padding = orui.padding(10, 8)
	element.align = {.Center, .Center}
}

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
					direction = .TopToBottom,
					width = orui.grow(),
					height = orui.grow(),
					gap = 16,
					padding = orui.padding(50),
					align_main = .Center,
					align_cross = .Center,
				},
			)

			orui.label(
				orui.id("1"),
				"Dropdown: Option 1",
				{font = &default_font, font_size = 16, letter_spacing = 5},
				button_style,
			)

			orui.label(
				orui.id("2"),
				"Dropdown: Option 2",
				{font = &default_font, font_size = 16},
				button_style,
			)

			orui.label(
				orui.id("3"),
				"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam vitae libero eu velit ultrices porta eget eu felis. Ut est mi, tempor vel ullamcorper non, mollis eget ante. Donec tempus ex facilisis lorem elementum, nec tempor justo euismod. Ut vehicula at mauris at accumsan. Morbi id faucibus libero, sit amet finibus mauris. Fusce mauris quam, elementum ut consequat sit amet, vehicula ut nisl. Pellentesque in nibh efficitur, posuere velit sit amet, suscipit diam.",
				{font = &default_font, font_size = 16},
				button_style,
			)

			orui.label(
				orui.id("4"),
				"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam vitae libero eu velit ultrices porta eget eu felis. Ut est mi, tempor vel ullamcorper non, mollis eget ante. Donec tempus ex facilisis lorem elementum, nec tempor justo euismod. Ut vehicula at mauris at accumsan. Morbi id faucibus libero, sit amet finibus mauris. Fusce mauris quam, elementum ut consequat sit amet, vehicula ut nisl. Pellentesque in nibh efficitur, posuere velit sit amet, suscipit diam.",
				{
					font = &default_font,
					font_size = 16,
					width = orui.fixed(300),
					letter_spacing = 3,
				},
				button_style,
			)
		}

		orui.end()

		rl.EndDrawing()
		// break
	}

	rl.CloseWindow()
}
