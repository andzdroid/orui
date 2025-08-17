package demo

import orui "../../src"
import "core:fmt"
import "core:log"
import "core:mem"
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

	log.infof("orui struct size: %v MB", size_of(ctx^) / f32(1024 * 1024))

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
					},
				)

				{orui.container(
						orui.id("top bar"),
						{
							width = orui.grow(),
							height = orui.fixed(32),
							background_color = orui.active() ? {100, 100, 100, 255} : orui.hovered() ? {120, 120, 120, 255} : {60, 60, 60, 255},
							padding = {4, 8, 4, 8},
							align_cross = .Center,
						},
					)
					orui.label(
						orui.id("title"),
						"Window title",
						{font = &default_font, font_size = 16, color = rl.WHITE},
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
								background_color = orui.active() ? {100, 100, 100, 255} : orui.hovered() ? {120, 120, 120, 255} : {60, 60, 60, 255},
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
								background_color = orui.active() ? {100, 100, 100, 255} : orui.hovered() ? {120, 120, 120, 255} : {60, 60, 60, 255},
							},
						)
					}
				}
			}
		}

		orui.end()

		rl.EndDrawing()
		// break
	}

	rl.CloseWindow()

	for i in 0 ..< ctx.element_count {
		element := &ctx.elements[i]
		fmt.printf("element %v: %v\n", i, element)
	}
}
