package demo

import orui "../src"
import "core:fmt"
import "core:log"
import "core:os"
import rl "vendor:raylib"

button_background :: proc(element: ^orui.Element) {
	element.background_color =
		orui.active() && orui.hovered() ? {190, 90, 50, 255} : orui.hovered() ? {200, 110, 70, 255} : {200, 100, 60, 255}
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
	rl.SetTargetFPS(120)

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)

	log.infof("orui struct size: %v MB", size_of(ctx^) / f32(1024 * 1024))

	default_font := rl.GetFontDefault()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		{orui.container(
				orui.id("container"),
				{
					layout = .Flex,
					direction = .TopToBottom,
					position = {.Absolute, {0, 0}},
					width = orui.fixed(width),
					height = orui.fixed(height),
					background_color = {30, 30, 30, 255},
					padding = orui.padding(16),
					gap = 16,
				},
			)

			{orui.container(
					orui.id("top bar"),
					{
						layout = .Flex,
						direction = .LeftToRight,
						width = orui.grow(),
						height = orui.fixed(100),
						background_color = {50, 50, 50, 255},
						padding = orui.padding(8),
						gap = 8,
					},
				)

				for i in 0 ..< 4 {
					orui.label(
						orui.id(fmt.tprintf("top bar label %v", i)),
						fmt.tprintf("Button %v", i),
						{
							font = &default_font,
							font_size = 14,
							color = rl.WHITE,
							padding = orui.padding(10),
							width = orui.grow(),
							height = orui.grow(),
							align = {.End, .End},
						},
						button_background,
					)
				}

				{orui.container(orui.id("gap1"), {width = orui.grow(5), height = orui.grow()})}

				for i in 0 ..< 4 {
					orui.label(
						orui.id(fmt.tprintf("top bar label2 %v", i)),
						fmt.tprintf("Button %v", i),
						{
							font = &default_font,
							font_size = 14,
							color = rl.WHITE,
							padding = orui.padding(10),
							width = orui.fit(),
							height = orui.grow(),
						},
						button_background,
					)
				}
			}

			{orui.container(
					orui.id("main section"),
					{
						layout = .Flex,
						direction = .LeftToRight,
						width = orui.grow(),
						height = orui.grow(),
						gap = 16,
					},
				)

				{orui.container(
						orui.id("sidebar"),
						{
							layout = .Flex,
							direction = .TopToBottom,
							width = orui.fixed(200),
							height = orui.grow(),
							background_color = {50, 50, 50, 255},
							padding = orui.padding(8),
							gap = 8,
						},
					)

					for i in 0 ..< 5 {
						orui.label(
							orui.id(fmt.tprintf("sidebar label %v", i)),
							fmt.tprintf("Row %v", i),
							{
								font = &default_font,
								font_size = 20,
								color = rl.WHITE,
								padding = orui.padding(10),
								width = orui.grow(),
								align = {.Center, .Start},
							},
							button_background,
						)
					}

					{orui.container(orui.id("gap"), {width = orui.grow(), height = orui.grow()})}

					for i in 0 ..< 5 {
						orui.label(
							orui.id(fmt.tprintf("bottom label %v", i)),
							fmt.tprintf("Button %v", i),
							{
								font = &default_font,
								font_size = 20,
								color = rl.WHITE,
								padding = orui.padding(10),
								width = orui.grow(),
							},
							button_background,
						)
					}
				}

				{orui.container(
						orui.id("content"),
						{
							layout = .Flex,
							direction = .TopToBottom,
							width = orui.grow(),
							height = orui.grow(),
							background_color = {50, 50, 50, 255},
							padding = orui.padding(8),
							gap = 8,
						},
					)

					{orui.container(
							orui.id("fit content"),
							{
								layout = .Flex,
								direction = .LeftToRight,
								background_color = {70, 70, 70, 255},
								width = orui.grow(),
								padding = orui.padding(10),
								margin = orui.margin(25),
								gap = 10,
							},
						)

						orui.label(
							orui.id("button"),
							"Hello world! this is some very very long text that should wrap while the container should fit the height",
							{
								font = &default_font,
								font_size = 20,
								color = rl.WHITE,
								background_color = {30, 30, 30, 255},
								padding = orui.padding(10),
								margin = orui.margin(5),
								width = orui.percent(0.3),
								align = {.Center, .Start},
							},
						)

						{orui.container(
								orui.id("box b"),
								{
									width = orui.fixed(200),
									height = orui.fixed(200),
									background_color = {100, 200, 60, 255},
									margin = orui.margin(20),
								},
							)}

						{orui.container(
								orui.id("box c"),
								{
									position = {.Relative, {100, 100}},
									width = orui.fixed(200),
									height = orui.fixed(200),
									background_color = {200, 60, 100, 255},
									margin = orui.margin(20),
								},
							)}
					}
				}
			}

			if orui.active("button") {
				orui.label(
					orui.id("clicked"),
					"Clicked!",
					{
						font = &default_font,
						font_size = 20,
						color = rl.BLACK,
						background_color = rl.WHITE,
						padding = {10, 40, 10, 40},
						position = {.Absolute, rl.GetMousePosition() - {0, 50}},
					},
				)
			}
		}
		orui.end()

		rl.DrawFPS(10, 10)

		rl.EndDrawing()
		// break
	}

	rl.CloseWindow()

	orui.print(ctx)
}
