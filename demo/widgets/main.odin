package demo

import orui "../../src"
import "core:path/filepath"
import "core:strings"
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

tooltip :: proc() {
	orui.container(
		orui.id("tooltip container"),
		{padding = orui.padding(4), position = {.Relative, {}}},
	)

	orui.label(orui.id("tooltip button"), "Button with tooltip", {font_size = 16}, button_style)

	if orui.hovered("tooltip button") {
		orui.label(
			orui.id("tooltip content"),
			"Here is some tooltip text",
			{
				position = {.Absolute, {2, -2}},
				placement = orui.placement(.TopRight, .BottomLeft),
				width = orui.fixed(200),
				font_size = 16,
				color = rl.BLACK,
				background_color = rl.WHITE,
				padding = orui.padding(8, 6),
				border = orui.border(1),
				border_color = {100, 100, 160, 255},
				corner_radius = orui.corner(4),
				overflow = .Wrap,
				layer = 100,
			},
		)
	}
}

tooltip2 :: proc() {
	orui.container(orui.id("tooltip container 2"), {padding = orui.padding(4)})

	orui.label(
		orui.id("tooltip button 2"),
		"Tooltip follows mouse",
		{font_size = 16},
		button_style,
	)

	if orui.hovered("tooltip button 2") {
		orui.label(
			orui.id("tooltip content 2"),
			"This tooltip follows the mouse position!",
			{
				position = {.Absolute, {f32(rl.GetMouseX() + 5), f32(rl.GetMouseY()) - 50}},
				width = orui.fixed(200),
				font_size = 16,
				color = rl.BLACK,
				background_color = rl.WHITE,
				padding = orui.padding(8, 6),
				border = orui.border(1),
				border_color = {100, 100, 160, 255},
				corner_radius = orui.corner(4),
				overflow = .Wrap,
				layer = 100,
			},
		)
	}
}

toggle_button :: proc(toggle_state: ^bool) {
	highlight_color := toggle_state^ ? rl.Color{120, 200, 120, 255} : rl.Color{200, 120, 120, 255}
	normal_color := toggle_state^ ? rl.Color{100, 180, 100, 255} : rl.Color{180, 100, 100, 255}

	if orui.label(
		orui.id("toggle button"),
		"Toggle button",
		{
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

toggle_button2 :: proc(toggle_state: ^int) {
	highlight_color := rl.Color{200, 200, 200, 255}
	normal_color := rl.WHITE
	hovered_color := rl.Color{240, 240, 240, 255}
	active_color := rl.Color{230, 230, 230, 255}

	orui.container(orui.id("toggle button 2"), {})

	if orui.label(
		orui.id("toggle button 2 left"),
		"Left button",
		{
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

dropdown_menu :: proc(open_state: ^bool, value: ^int) {
	just_opened := false

	orui.container(
		orui.id("dropdown container"),
		{padding = orui.padding(2), position = {.Relative, {}}, width = orui.fixed(250)},
	)

	if orui.label(
		orui.id("dropdown button"),
		value^ == 0 ? "Dropdown: Option 1" : value^ == 1 ? "Dropdown: Option 2" : "Dropdown: Option 3",
		{font_size = 16, width = orui.grow()},
		button_style,
	) {
		open_state^ = !open_state^
		just_opened = true
	}

	if open_state^ {
		{orui.container(
				orui.id("dropdown content"),
				{
					position = {.Absolute, {}},
					placement = orui.placement(.Bottom, .Top),
					direction = .TopToBottom,
					padding = orui.padding(4),
					width = orui.fixed(250),
					gap = 1,
					layer = 100,
				},
			)

			if orui.label(orui.id("dropdown option 1"), "Option 1", {}, dropdown_option_style) {
				value^ = 0
				open_state^ = false
			}

			if orui.label(orui.id("dropdown option 2"), "Option 2", {}, dropdown_option_style) {
				value^ = 1
				open_state^ = false
			}

			if orui.label(orui.id("dropdown option 3"), "Option 3", {}, dropdown_option_style) {
				value^ = 2
				open_state^ = false
			}
		}
	}

	if !just_opened && rl.IsMouseButtonReleased(.LEFT) && !orui.hovered("dropdown content") {
		open_state^ = false
	}
}

checkbox :: proc(checked_state: ^bool) {
	orui.container(
		orui.id("checkbox container"),
		{
			direction = .LeftToRight,
			gap = 8,
			width = orui.fit(),
			height = orui.fit(),
			align_cross = .Center,
		},
	)

	{orui.container(
			orui.id("checkbox outer"),
			{
				width = orui.fixed(25),
				height = orui.fixed(25),
				background_color = rl.WHITE,
				padding = orui.padding(5),
				disabled = .True,
				corner_radius = orui.corner(5),
			},
		)

		{orui.container(
				orui.id("checkbox inner"),
				{
					width = orui.grow(),
					height = orui.grow(),
					background_color = checked_state^ ? {200, 120, 120, 255} : orui.hovered("checkbox container") ? rl.LIGHTGRAY : {},
					corner_radius = orui.corner(2),
				},
			)}
	}

	orui.label(
		orui.id("checkbox label"),
		"Checkbox",
		{
			font_size = 16,
			color = rl.BLACK,
			width = orui.fit(),
			height = orui.grow(),
			align = {.Start, .Center},
			padding = orui.padding(12, 0),
			disabled = .True,
		},
	)

	if orui.clicked("checkbox container") {
		checked_state^ = !checked_state^
	}
}

slider :: proc(value: ^f32) {
	orui.container(
		orui.id("slider container"),
		{
			width = orui.fixed(300),
			height = orui.fixed(30),
			align_cross = .Center,
			direction = .LeftToRight,
			position = {.Relative, {}},
		},
	)

	orui.container(
		orui.id("slider track"),
		{
			width = orui.grow(),
			height = orui.fixed(10),
			background_color = {240, 240, 240, 255},
			corner_radius = orui.corner(4),
		},
	)

	if orui.container(
		orui.id("slider handle"),
		{
			width = orui.fixed(10),
			height = orui.fixed(30),
			background_color = orui.hovered() ? {200, 120, 120, 255} : {220, 120, 120, 255},
			corner_radius = orui.corner(4),
			position = {.Absolute, {}},
			placement = {orui.anchor_point(.TopLeft), {value^ * 300, 0}},
		},
	) {
		// TODO: set slider position
	}
}

text_input :: proc(input_buffer: ^strings.Builder) {
	orui.text_input(
		orui.id("text input"),
		input_buffer,
		{
			width = orui.fixed(300),
			height = orui.fit(),
			color = rl.BLACK,
			font_size = 16,
			overflow = .Visible,
			clip = {.Self, {}},
			scroll = orui.scroll(.Horizontal),
			background_color = rl.WHITE,
			border = orui.border(1),
			border_color = orui.focused() ? rl.BLUE : rl.LIGHTGRAY,
			padding = orui.padding(8),
			corner_radius = orui.corner(4),
		},
	)
}

text_area :: proc(input_buffer: ^strings.Builder) {
	orui.text_input(
		orui.id("text area"),
		input_buffer,
		{
			width = orui.fixed(300),
			height = orui.fixed(150),
			color = rl.BLACK,
			font_size = 16,
			overflow = .Wrap,
			clip = {.Self, {}},
			scroll = orui.scroll(.Vertical),
			background_color = rl.WHITE,
			border = orui.border(1),
			border_color = orui.focused() ? rl.BLUE : rl.LIGHTGRAY,
			padding = orui.padding(8),
			corner_radius = orui.corner(4),
		},
	)
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 900, "orui")

	ctx := new(orui.Context)
	defer free(ctx)

	font_path := filepath.join({#directory, "..", "assets", "Inter-Regular.ttf"})
	ctx.default_font = rl.LoadFont(strings.clone_to_cstring(font_path, context.temp_allocator))
	defer rl.UnloadFont(ctx.default_font)

	toggle_state := false
	toggle_state2 := 0
	dropdown_state := false
	dropdown_value := 0
	checkbox_state := false
	slider_value := f32(0.0)

	input_buffer := strings.builder_make()
	defer strings.builder_destroy(&input_buffer)
	strings.write_string(
		&input_buffer,
		"This is a single line text input, and it can scroll horizontally!",
	)

	input_buffer2 := strings.builder_make()
	defer strings.builder_destroy(&input_buffer2)
	strings.write_string(
		&input_buffer2,
		"This is a multi-line text input!\nThe Enter key will add a new line to the text. Any line that exceeds the element width will be wrapped.\n\nMore lines here.",
	)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BEIGE)

		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		{orui.container(
				orui.id("container"),
				{
					direction   = .TopToBottom,
					width       = orui.grow(),
					height      = orui.grow(),
					gap         = 16,
					padding     = orui.padding(50),
					// align_main = .Center,
					align_cross = .Center,
					scroll      = orui.scroll(.Vertical),
				},
			)

			tooltip()
			tooltip2()
			toggle_button(&toggle_state)
			toggle_button2(&toggle_state2)
			dropdown_menu(&dropdown_state, &dropdown_value)
			checkbox(&checkbox_state)
			// slider(&slider_value)
			text_input(&input_buffer)
			text_area(&input_buffer2)
		}

		render_commands := orui.end()
		for command in render_commands {
			orui.render_command(command)
		}

		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}
