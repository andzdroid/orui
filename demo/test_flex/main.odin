package demo

import orui "../../src"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import rl "vendor:raylib"

default_font: rl.Font

row :: proc(
	id: string,
	title: string,
	align_main: orui.MainAlignment,
	align_cross: orui.CrossAlignment,
) {
	orui.container(
		orui.id(id),
		{
			direction = .TopToBottom,
			width = orui.grow(),
			height = orui.grow(),
			padding = orui.padding(8),
			gap = 8,
		},
	)

	orui.label(
		orui.id(fmt.tprintf("%v label", id)),
		title,
		{font = &default_font, font_size = 16, color = rl.WHITE},
	)

	{orui.container(
			orui.id(fmt.tprintf("%v container", id)),
			{
				width = orui.grow(),
				height = orui.grow(),
				gap = 8,
				align_main = align_main,
				align_cross = align_cross,
				background_color = {50, 50, 50, 255},
				padding = orui.padding(8),
			},
		)

		for i in 0 ..< 5 {
			orui.container(
				orui.id(fmt.tprintf("%v container %v", id, i)),
				{
					width = orui.fixed(100),
					height = orui.percent(0.7),
					background_color = {90, 120, 150, 255},
					corner_radius = orui.corner(9),
				},
			)
		}
	}
}

main :: proc() {
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
				orui.id("container"),
				{
					direction = .TopToBottom,
					width = orui.fixed(width),
					height = orui.fixed(height),
					padding = orui.padding(16),
					gap = 16,
				},
			)

			{row("row 1", "Start", .Start, .Start)}
			{row("row 2", "Center", .Center, .Center)}
			{row("row 3", "End", .End, .End)}
			{row("row 4", "Space between", .SpaceBetween, .Center)}
			{row("row 5", "Space around", .SpaceAround, .Center)}
			{row("row 6", "Space evenly", .SpaceEvenly, .Center)}
		}

		orui.end()

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
