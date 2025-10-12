package demo

import orui "../../src"
import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

close_icon: rl.Texture2D

@(deferred_none = orui.end_element)
window :: proc(id: string, title: string, position: rl.Vector2, dragging: bool, layer: int) {
	orui.element(
		orui.id(fmt.tprintf("%s window container", id)),
		{
			direction = .TopToBottom,
			position = {.Fixed, position},
			width = orui.percent(0.4),
			height = orui.percent(0.4),
			background_color = {30, 30, 30, 255},
			border = orui.border(1),
			border_color = {100, 100, 100, 255},
			layer = layer,
		},
	)

	{orui.container(
			orui.id(fmt.tprintf("%s top bar", id)),
			{
				width = orui.grow(),
				height = orui.fixed(32),
				background_color = {60, 60, 60, 255},
				padding = {4, 8, 4, 8},
				align_cross = .Center,
				border = {0, 0, 1, 0},
				border_color = {150, 150, 150, 255},
				align_main = .SpaceBetween,
				capture = .True,
			},
		)
		orui.label(
			orui.id(fmt.tprintf("%s title", id)),
			title,
			{font_size = 16, color = rl.WHITE, disabled = .True},
		)

		orui.image(
			orui.id(fmt.tprintf("%s close icon", id)),
			&close_icon,
			{
				width = orui.fixed(24),
				height = orui.fixed(24),
				color = orui.active() ? {220, 220, 220, 255} : orui.hovered() ? rl.WHITE : {200, 200, 200, 255},
			},
		)
	}
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

	ctx := new(orui.Context)
	defer free(ctx)

	font_path := filepath.join({#directory, "..", "assets", "Inter-Regular.ttf"})
	ctx.default_font = rl.LoadFont(strings.clone_to_cstring(font_path, context.temp_allocator))
	defer rl.UnloadFont(ctx.default_font)

	close_icon = rl.LoadTexture("close.png")
	defer rl.UnloadTexture(close_icon)

	// Setup 3D camera for the cube
	camera := rl.Camera3D {
		position   = {4.0, 4.0, 4.0},
		target     = {0.0, 0.0, 0.0},
		up         = {0.0, 1.0, 0.0},
		fovy       = 60.0,
		projection = .PERSPECTIVE,
	}


	window_offset1: rl.Vector2 = {200, 200}
	window_offset2: rl.Vector2 = {350, 350}
	dragging1 := false
	dragging2 := false
	layer1 := 2
	layer2 := 3

	render_cube_event := 1

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
					width = orui.grow(),
					height = orui.grow(),
					align_main = .Center,
					align_cross = .Center,
				},
			)

			{window("window1", "Custom render event", window_offset1, dragging1, layer1)
				{orui.container(
						orui.id("window1 content"),
						{
							direction = .TopToBottom,
							width = orui.grow(),
							height = orui.grow(),
							gap = 8,
						},
					)
					{orui.container(
							orui.id("custom event"),
							{
								width = orui.grow(),
								height = orui.grow(),
								padding = orui.padding(16),
								custom_event = &render_cube_event,
							},
						)}
				}
			}

			{window("window2", "Window 2", window_offset2, dragging2, layer2)
				{orui.container(
						orui.id("window2 content"),
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
							font_size = 16,
							color = rl.WHITE,
							padding = orui.padding(16),
							align = {.Start, .Start},
							overflow = .Wrap,
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
						if orui.label(
							orui.id("ok button"),
							"Confirm",
							{
								width = orui.fit(),
								height = orui.fit(),
								font_size = 16,
								color = rl.WHITE,
								padding = {10, 20, 10, 20},
								background_color = orui.active() ? {100, 120, 100, 255} : orui.hovered() ? {110, 140, 110, 255} : {60, 80, 60, 255},
								border = orui.border(1),
								border_color = {100, 100, 100, 255},
								corner_radius = orui.corner(4),
							},
						) {
							log.info("ok button clicked")
						}
						if orui.label(
							orui.id("cancel button"),
							"Cancel",
							{
								width = orui.fit(),
								height = orui.fit(),
								font_size = 16,
								color = rl.WHITE,
								padding = {10, 20, 10, 20},
								background_color = orui.active() ? {120, 100, 100, 255} : orui.hovered() ? {140, 120, 120, 255} : {80, 60, 60, 255},
								border = orui.border(1),
								border_color = {100, 100, 100, 255},
								corner_radius = orui.corner(4),
							},
						) {
							log.info("cancel button clicked")
						}
					}
				}
			}
		}

		if rl.IsMouseButtonPressed(.LEFT) && orui.hovered("window1 top bar") {
			dragging1 = true
			layer1 = 3
			layer2 = 2
		}
		if rl.IsMouseButtonPressed(.LEFT) && orui.hovered("window2 top bar") {
			dragging2 = true
			layer1 = 2
			layer2 = 3
		}

		if dragging1 {
			window_offset1.x += rl.GetMouseDelta().x
			window_offset1.y += rl.GetMouseDelta().y

			if rl.IsMouseButtonUp(.LEFT) {
				dragging1 = false
			}
		}

		if dragging2 {
			window_offset2.x += rl.GetMouseDelta().x
			window_offset2.y += rl.GetMouseDelta().y

			if rl.IsMouseButtonUp(.LEFT) {
				dragging2 = false
			}
		}

		render_commands := orui.end()
		for command in render_commands {
			if command.type == .Custom {
				data := command.data.(orui.RenderCommandDataCustom)
				if data.custom_event == &render_cube_event {
					rl.BeginScissorMode(
						i32(data.rectangle.x),
						i32(data.rectangle.y),
						i32(data.rectangle.width),
						i32(data.rectangle.height),
					)

					// Begin 3D mode with camera
					rl.BeginMode3D(camera)

					// Draw the rotating cube
					rl.DrawCubeWires({}, 2.0, 2.0, 2.0, rl.WHITE)
					rl.DrawCube({}, 1.8, 1.8, 1.8, rl.BEIGE)

					// You can also rotate the cube by rotating the camera around it
					camera.position.x = f32(4.0 * math.cos(rl.GetTime()))
					camera.position.z = f32(4.0 * math.sin(rl.GetTime()))

					rl.EndMode3D()
					rl.EndScissorMode()
				}
			} else {
				orui.render_command(command)
			}
		}
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}
