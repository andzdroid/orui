package demo

import orui "../../src"
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

dropdown_option_style :: proc(element: ^orui.Element) {
	element.height = orui.fixed(36)
	element.width = orui.grow()
	element.font_size = 16
	element.background_color =
		orui.active() ? {220, 190, 170, 255} : orui.hovered() ? {250, 220, 200, 255} : {240, 210, 190, 255}
	element.border = orui.border(1)
	element.border_color = {100, 100, 100, 255}
	element.color = rl.BLACK
	element.padding = orui.padding(10, 8)
	element.align = {.Center, .Center}
}

tooltip :: proc(font: ^rl.Font) {
	{orui.container(
			orui.id("tooltip container"),
			{padding = orui.padding(4), position = {.Relative, {}}},
		)

		orui.label(
			orui.id("tooltip button"),
			"Button with tooltip",
			{font = font, font_size = 16},
			button_style,
		)

		if orui.hovered("tooltip button") {
			orui.label(
				orui.id("tooltip content"),
				"Here is some tooltip text",
				{
					position = {.Absolute, {150, -45}},
					width = orui.fixed(200),
					font = font,
					font_size = 16,
					color = rl.BLACK,
					background_color = rl.WHITE,
					padding = orui.padding(8, 6),
					border = orui.border(1),
					border_color = {100, 100, 160, 255},
					corner_radius = orui.corner(4),
				},
			)
		}
	}
}

tooltip2 :: proc(font: ^rl.Font) {
	{orui.container(orui.id("tooltip container 2"), {padding = orui.padding(4)})

		orui.label(
			orui.id("tooltip button 2"),
			"Tooltip follows mouse",
			{font = font, font_size = 16},
			button_style,
		)

		if orui.hovered("tooltip button 2") {
			orui.label(
				orui.id("tooltip content"),
				"This tooltip follows the mouse position!",
				{
					position = {.Absolute, {f32(rl.GetMouseX() + 5), f32(rl.GetMouseY()) - 50}},
					width = orui.fixed(200),
					font = font,
					font_size = 16,
					color = rl.BLACK,
					background_color = rl.WHITE,
					padding = orui.padding(8, 6),
					border = orui.border(1),
					border_color = {100, 100, 160, 255},
					corner_radius = orui.corner(4),
				},
			)
		}
	}
}

toggle_button :: proc(font: ^rl.Font, toggle_state: ^bool) {
	highlight_color := toggle_state^ ? rl.Color{120, 200, 120, 255} : rl.Color{200, 120, 120, 255}
	normal_color := toggle_state^ ? rl.Color{100, 180, 100, 255} : rl.Color{180, 100, 100, 255}

	if orui.label(
		orui.id("toggle button"),
		"Toggle button",
		{
			font = font,
			font_size = 16,
			padding = orui.padding(10, 8),
			background_color = orui.hovered() ? highlight_color : normal_color,
			color = rl.WHITE,
			border = orui.border(1),
			border_color = {100, 100, 100, 255},
			corner_radius = orui.corner(4),
		},
	) {
		toggle_state^ = !toggle_state^
	}
}

toggle_button2 :: proc(font: ^rl.Font, toggle_state: ^int) {
	highlight_color := rl.Color{200, 200, 200, 255}
	normal_color := rl.WHITE
	hovered_color := rl.Color{240, 240, 240, 255}
	active_color := rl.Color{230, 230, 230, 255}

	{orui.container(orui.id("toggle button 2"), {})
		if orui.label(
			orui.id("toggle button 2 left"),
			"Left button",
			{
				font = font,
				font_size = 16,
				padding = orui.padding(10, 8),
				background_color = toggle_state^ == 0 ? highlight_color : orui.active() ? active_color : orui.hovered() ? hovered_color : normal_color,
				color = rl.BLACK,
				border = orui.border(1),
				border_color = {100, 100, 100, 255},
				corner_radius = {4, 0, 0, 4},
			},
		) {
			toggle_state^ = 0
		}

		if orui.label(
			orui.id("toggle button 2 middle"),
			"Middle button",
			{
				font = font,
				font_size = 16,
				padding = orui.padding(10, 8),
				background_color = toggle_state^ == 1 ? highlight_color : orui.active() ? active_color : orui.hovered() ? hovered_color : normal_color,
				color = rl.BLACK,
				border = orui.border(1),
				border_color = {100, 100, 100, 255},
			},
		) {
			toggle_state^ = 1
		}

		if orui.label(
			orui.id("toggle button 2 right"),
			"Right button",
			{
				font = font,
				font_size = 16,
				padding = orui.padding(10, 8),
				background_color = toggle_state^ == 2 ? highlight_color : orui.active() ? active_color : orui.hovered() ? hovered_color : normal_color,
				color = rl.BLACK,
				border = orui.border(1),
				border_color = {100, 100, 100, 255},
				corner_radius = {0, 4, 4, 0},
			},
		) {
			toggle_state^ = 2
		}
	}
}

dropdown_menu :: proc(font: ^rl.Font, open_state: ^bool, value: ^int) {
	just_opened := false

	{orui.container(
			orui.id("dropdown container"),
			{padding = orui.padding(4), position = {.Relative, {}}, width = orui.fixed(250)},
		)

		if orui.label(
			orui.id("dropdown button"),
			value^ == 0 ? "Dropdown: Option 1" : value^ == 1 ? "Dropdown: Option 2" : "Dropdown: Option 3",
			{font = font, font_size = 16, height = orui.fixed(36), width = orui.grow()},
			button_style,
		) {
			open_state^ = !open_state^
			just_opened = true
		}

		if open_state^ {
			{orui.container(
					orui.id("dropdown content"),
					{
						position = {.Absolute, {0, 38}},
						direction = .TopToBottom,
						padding = orui.padding(4),
						width = orui.fixed(250),
						gap = 1,
					},
				)

				if orui.label(
					orui.id("dropdown option 1"),
					"Option 1",
					{font = font},
					dropdown_option_style,
				) {
					value^ = 0
					open_state^ = false
				}

				if orui.label(
					orui.id("dropdown option 2"),
					"Option 2",
					{font = font},
					dropdown_option_style,
				) {
					value^ = 1
					open_state^ = false
				}

				if orui.label(
					orui.id("dropdown option 3"),
					"Option 3",
					{font = font},
					dropdown_option_style,
				) {
					value^ = 2
					open_state^ = false
				}
			}
		}
	}

	if !just_opened && rl.IsMouseButtonReleased(.LEFT) && !orui.hovered("dropdown content") {
		open_state^ = false
	}
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 900, "orui")

	default_font := rl.GetFontDefault()

	ctx := new(orui.Context)
	defer free(ctx)

	toggle_state := false
	toggle_state2 := 0
	dropdown_state := false
	dropdown_value := 0

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

			tooltip(&default_font)
			tooltip2(&default_font)
			toggle_button(&default_font, &toggle_state)
			toggle_button2(&default_font, &toggle_state2)
			dropdown_menu(&default_font, &dropdown_state, &dropdown_value)
		}

		orui.end()

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
