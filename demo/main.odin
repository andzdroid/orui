package demo

import orui "../src"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

SAMPLE_COUNT :: 240

texture: rl.Texture2D

Scene :: enum {
	Test_Flex,
	Test_Grid,
	Test_Text,
	Test_Image,
	Test_Placement,
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

	rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT})
	rl.InitWindow(1280, 900, "orui")
	rl.SetTargetFPS(120)

	texture = rl.LoadTexture("icon.png")
	defer rl.UnloadTexture(texture)

	ctx := new(orui.Context)
	defer free(ctx)

	ctx.default_font = rl.GetFontDefault()
	defer rl.UnloadFont(ctx.default_font)

	log.infof("orui struct size: %v MB", size_of(ctx^) / mem.Megabyte)

	elapsed1_samples: [SAMPLE_COUNT]time.Duration
	elapsed2_samples: [SAMPLE_COUNT]time.Duration
	sample_index := 0

	debug := false
	scene := 0

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		avg1, avg2: time.Duration
		for sample in elapsed1_samples do avg1 += sample
		for sample in elapsed2_samples do avg2 += sample
		avg1 /= SAMPLE_COUNT
		avg2 /= SAMPLE_COUNT

		start_time := time.now()
		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		switch Scene(scene) {
		case .Test_Flex:
			render_test_flex()
		case .Test_Grid:
			render_test_grid()
		case .Test_Image:
			render_test_image()
		case .Test_Text:
			render_test_text()
		case .Test_Placement:
			render_test_placement()
		}

		if debug {
			{orui.container(
					orui.id("debug"),
					{
						position = {.Fixed, {}},
						width = orui.percent(1),
						direction = .TopToBottom,
						padding = orui.padding(8),
						gap = 4,
						background_color = {0, 0, 0, 220},
					},
				)

				fps := rl.GetFPS()
				orui.label(
					orui.id("debug fps"),
					fmt.tprintf("FPS: %v", fps),
					{font_size = 16, color = rl.WHITE},
				)
				orui.label(
					orui.id("debug elapsed 1"),
					fmt.tprintf("Elapsed 1: %v", avg1),
					{font_size = 16, color = rl.WHITE},
				)
				orui.label(
					orui.id("debug elapsed 2"),
					fmt.tprintf("Elapsed 2: %v", avg2),
					{font_size = 16, color = rl.WHITE},
				)
			}
		}

		elapsed1 := time.since(start_time)

		start_time = time.now()
		render_commands := orui.end()
		elapsed2 := time.since(start_time)

		for render_command in render_commands {
			orui.render_command(render_command)
		}

		if ctx.focus == 0 {
			if rl.IsKeyReleased(.Q) {
				debug = !debug
			}

			if rl.IsKeyReleased(.D) {
				scene = (scene + 1) % len(Scene)
			}
			if rl.IsKeyReleased(.A) {
				scene = (scene - 1 + len(Scene)) % len(Scene)
			}
		}

		if debug {
			elapsed1_samples[sample_index] = elapsed1
			elapsed2_samples[sample_index] = elapsed2
			sample_index = (sample_index + 1) % SAMPLE_COUNT
		}

		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	for i in 0 ..< ctx.element_count {
		element := &ctx.elements[i]
		log.infof("%v", element)
	}

	rl.CloseWindow()
}
