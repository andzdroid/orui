package demo

import orui "../../src"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:time"
import rl "vendor:raylib"

labels :: [?]string {
	"Hello world! Click me!",
	"Hello world! This is a very long label that should wrap across multiple lines of text, and the containing box should increase in height to fit the text. Click me again!",
	"This is a label",
	"This is another label",
}

button_style :: proc(element: ^orui.Element) {
	color := rl.Color{200, 100, 60, 255}
	element.background_color =
		orui.active() ? rl.ColorBrightness(color, -0.1) : orui.hovered() ? rl.ColorBrightness(color, 0.1) : color
	element.color = rl.WHITE
	element.border = orui.border(4)
	element.border_color = orui.hovered() ? {200, 200, 200, 255} : {150, 150, 150, 255}
}

grid_cell_style :: proc(element: ^orui.Element) {
	element.width = orui.grow()
	element.height = orui.grow()
	element.background_color = {30, 30, 60, 255}
	element.font_size = 16
	element.color = rl.WHITE
	element.border = orui.border(1)
	element.border_color = orui.hovered() ? {200, 200, 200, 255} : {150, 150, 150, 255}
	element.align = {.Center, .Center}
	element.corner_radius = orui.corner(8)
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

	default_allocator := context.allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, default_allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	defer {
		if len(tracking_allocator.allocation_map) > 0 {
			log.errorf("%v allocations not freed", len(tracking_allocator.allocation_map))
			for _, entry in tracking_allocator.allocation_map {
				log.errorf(" - %v bytes at %v", entry.size, entry.location)
			}
		} else {
			log.info("No allocations were leaked")
		}
		mem.tracking_allocator_destroy(&tracking_allocator)
	}

	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 900, "orui")
	rl.SetTargetFPS(120)

	ctx := new(orui.Context)
	defer free(ctx)

	log.infof("orui struct size: %v MB", size_of(ctx^) / f32(1024 * 1024))

	default_font := rl.GetFontDefault()

	texture := rl.LoadTexture("icon.png")
	defer rl.UnloadTexture(texture)

	label_index := 0
	labels := labels

	elapsed1 := time.Duration(0)
	elapsed2 := time.Duration(0)
	iterations := 0
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		start_time := time.now()
		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		{orui.container(
				orui.id("container"),
				{
					direction = .TopToBottom,
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
						width = orui.grow(),
						height = orui.fixed(100),
						background_color = {50, 50, 50, 255},
						padding = orui.padding(8),
						align_main = .SpaceBetween,
					},
				)

				{orui.container(
						orui.id("top bar left"),
						{height = orui.grow(), width = orui.grow(), gap = 8},
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
								width = orui.fit(),
								height = orui.grow(),
								align = {.End, .End},
								corner_radius = orui.corner(8),
							},
							button_style,
						)
					}
				}

				{orui.container(
						orui.id("top bar right"),
						{
							height = orui.grow(),
							width = orui.grow(),
							gap = 8,
							align_main = .End,
							align_cross = .End,
						},
					)
					for i in 0 ..< 4 {
						orui.label(
							orui.id(fmt.tprintf("top bar label2 %v", i)),
							fmt.tprintf("Button %v", i),
							{
								font = &default_font,
								font_size = 14,
								color = rl.WHITE,
								padding = orui.padding(10),
							},
							button_style,
						)
					}
				}
			}

			{orui.container(
					orui.id("main section"),
					{width = orui.grow(), height = orui.grow(), gap = 16},
				)

				{orui.container(
						orui.id("sidebar"),
						{
							direction = .TopToBottom,
							width = orui.fixed(200),
							height = orui.grow(),
							background_color = {50, 50, 50, 255},
							padding = orui.padding(8),
							gap = 8,
							align_cross = .Center,
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
								align = {.Center, .Center},
							},
							button_style,
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
								align = {.Center, .Center},
							},
							button_style,
						)
					}
				}

				{orui.container(
						orui.id("content"),
						{
							direction = .TopToBottom,
							width = orui.fit(),
							height = orui.fit(),
							background_color = {50, 50, 50, 255},
							padding = orui.padding(16),
							gap = 8,
							corner_radius = orui.corner(16),
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

						if orui.label(
							orui.id("button"),
							labels[label_index],
							{
								font = &default_font,
								font_size = 20,
								color = rl.WHITE,
								background_color = orui.active() ? {100, 100, 100, 255} : orui.hovered() ? {120, 120, 120, 255} : {30, 30, 30, 255},
								padding = orui.padding(10),
								margin = orui.margin(5),
								width = orui.percent(0.3),
								align = {.Center, .Start},
							},
						) {
							label_index = (label_index + 1) % len(labels)
						}

						{orui.container(
								orui.id("box b"),
								{
									width = orui.fixed(200),
									height = orui.fixed(100),
									background_color = {100, 200, 60, 255},
									margin = orui.margin(20),
								},
							)}

						{orui.container(
								orui.id("box c"),
								{
									position = {.Relative, {0, -50}},
									width = orui.fixed(200),
									height = orui.fixed(100),
									background_color = {20, 30, 60, 255},
									margin = orui.margin(20),
									align_main = .Center,
									align_cross = .Center,
									corner_radius = orui.corner(10),
								},
							)

							orui.image(
								orui.id("image"),
								&texture,
								{width = orui.fixed(50), height = orui.fixed(50)},
							)
						}
					}

					{orui.container(
							orui.id("grid container"),
							{
								width = orui.grow(),
								height = orui.grow(),
								layout = .Grid,
								cols = 3,
								rows = 3,
								col_sizes = []orui.Size{orui.grow()},
								row_sizes = []orui.Size{orui.grow()},
								gap = 4,
								background_color = {20, 20, 20, 255},
								padding = orui.padding(4),
							},
						)

						orui.label(
							orui.id("grid 1"),
							"Grid cell 1",
							{font = &default_font},
							grid_cell_style,
						)

						orui.label(
							orui.id("grid 2"),
							"Grid cell 2",
							{font = &default_font},
							grid_cell_style,
						)

						orui.label(
							orui.id("grid 3"),
							"Grid cell 3",
							{font = &default_font, row_span = 2},
							grid_cell_style,
						)

						orui.label(
							orui.id("grid 4"),
							"Grid cell 4",
							{font = &default_font, col_span = 3},
							grid_cell_style,
						)

						orui.label(
							orui.id("grid 5"),
							"Grid cell 5",
							{font = &default_font, col_span = 2},
							grid_cell_style,
						)

					}
				}
			}

			if orui.active("button") {
				orui.label(
					orui.id("button active"),
					"button active!",
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
		elapsed1 += time.since(start_time)

		start_time = time.now()
		orui.end()
		elapsed2 += time.since(start_time)
		iterations += 1

		rl.DrawFPS(10, 10)

		rl.EndDrawing()

		// break
	}

	log.infof("elapsed 1: %v", elapsed1 / time.Duration(iterations))
	log.infof("elapsed 2: %v", elapsed2 / time.Duration(iterations))
	rl.CloseWindow()
}
