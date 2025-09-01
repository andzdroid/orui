package demo

import orui "../../src"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import rl "vendor:raylib"

default_font: rl.Font

cell_style :: proc(element: ^orui.Element) {
	// element.width = orui.grow()
	element.height = orui.grow()
	element.font = &default_font
	element.font_size = 32
	element.letter_spacing = 4
	element.color = rl.WHITE
	element.background_color = {30, 60, 90, 255}
	element.align = {.Center, .Center}
	element.border = orui.border(1)
	element.border_color = rl.WHITE
	element.padding = orui.padding(20)
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

	default_font = rl.GetFontDefault()

	ctx := new(orui.Context)
	defer free(ctx)

	log.infof("orui struct size: %v MB", size_of(ctx^) / f32(1024 * 1024))

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({30, 30, 30, 255})

		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		{orui.container(
				orui.id("flex container"),
				{
					layout = .Flex,
					direction = .TopToBottom,
					width = orui.grow(),
					height = orui.grow(),
					background_color = rl.BEIGE,
				},
			)
			{orui.container(
					orui.id("container"),
					{
						layout = .Grid,
						direction = .LeftToRight,
						width = orui.grow(),
						height = orui.grow(),
						padding = orui.padding(16),
						cols = 3,
						rows = 3,
						col_sizes = []orui.Size{orui.fixed(300), orui.grow()},
						row_sizes = []orui.Size{orui.grow()},
						row_gap = 4,
						col_gap = 16,
					},
				)

				orui.label(
					orui.id("label 1"),
					"Row span 2",
					{row_span = 2, width = orui.grow()},
					cell_style,
				)
				orui.label(
					orui.id("label 2"),
					"Column span 2",
					{col_span = 2, width = orui.grow()},
					cell_style,
				)
				orui.label(orui.id("label 3"), "Cell", {width = orui.fit()}, cell_style)
				orui.label(
					orui.id("label 4"),
					"Column span 3",
					{col_span = 3, width = orui.grow()},
					cell_style,
				)
				orui.label(orui.id("label 5"), "Cell", {width = orui.grow()}, cell_style)
			}
		}

		orui.end()

		rl.EndDrawing()
		// break
	}

	rl.CloseWindow()

	for i in 0 ..< ctx.element_count {
		element := &ctx.elements[i]
		log.infof("element %v", element)
	}
}
