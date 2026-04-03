package demo

import orui "../../src"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 900, "orui")
	defer rl.CloseWindow()

	ctx := new(orui.Context)
	defer free(ctx)

	orui.init(ctx)
	defer orui.destroy(ctx)

	font_path, _ := filepath.join(
		{#directory, "..", "..", "assets", "Inter-Regular.ttf"},
		context.temp_allocator,
	)
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
					direction = .TopToBottom,
					width = orui.grow(),
					height = orui.grow(),
					gap = 16,
					padding = orui.padding(50),
					align_main = .Center,
					align_cross = .Center,
					scroll = orui.scroll(.Vertical),
				},
			)

			// relative container so that tooltip is placed relative to it
			{orui.container(orui.id("tooltip container"), {position = {.Relative, {}}})
				button("button1", "Button with tooltip")
				tooltip(
					"button1",
					"Here is some tooltip text",
					proc(element: ^orui.Element) {
						// align tooltip's bottom-left corner with the container's top-right corner
						element.placement = orui.placement(.TopRight, .BottomLeft)
					},
				)
			}

			// placing tooltip manually with x/y position, so this container does not have relative positioning
			{orui.container(orui.id("tooltip container 2"), {})
				button("button2", "Tooltip follows mouse")
				tooltip(
					"button2",
					"This tooltip follows the mouse position!",
					proc(element: ^orui.Element) {
						element.position = {
							.Absolute,
							{f32(rl.GetMouseX() + 5), f32(rl.GetMouseY()) - 50},
						}
					},
				)
			}

			toggle_button("toggle button", "Toggle button", &toggle_state)

			toggle_buttons(
				"toggle buttons",
				[]string{"Left button", "Middle button", "Right button"},
				&toggle_state2,
			)

			dropdown(
				"dropdown",
				fmt.tprintf("Dropdown: Option %d", dropdown_value + 1),
				[]string{"Option 1", "Option 2", "Option 3"},
				&dropdown_state,
				&dropdown_value,
			)

			checkbox("checkbox", "Checkbox", &checkbox_state)
			text_input("text input", &input_buffer)
			text_area("text area", &input_buffer2)
		}

		render_commands := orui.end()
		for command in render_commands {
			orui.render_command(command)
		}

		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
}

button :: proc {
	_button,
	_button_id,
}

_button :: proc(id: string, label: string, modifiers: ..orui.ElementModifier) -> bool {
	return _button_id(orui.to_id(id), label, ..modifiers)
}

_button_id :: proc(id: orui.Id, label: string, modifiers: ..orui.ElementModifier) -> bool {
	return orui.label(
		orui.id(id),
		label,
		{
			background_color = orui.active() ? {220, 190, 170, 255} : orui.hovered() ? {250, 220, 200, 255} : {240, 210, 190, 255},
			border = orui.border(1),
			border_color = {100, 100, 100, 255},
			corner_radius = orui.corner(4),
			color = rl.BLACK,
			padding = orui.padding(10, 8),
			align = {.Center, .Center},
			font_size = 16,
		},
		..modifiers,
	)
}

tooltip :: proc(id: string, label: string, modifiers: ..orui.ElementModifier) {
	if orui.hovered(id) {
		orui.label(
			orui.id(id, 1),
			label,
			{
				position = {.Absolute, {2, -2}},
				bounds = {.Window, .Flip, 8},
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
			..modifiers,
		)
	}
}

toggle_button :: proc(
	id: string,
	label: string,
	toggle_state: ^bool,
	modifiers: ..orui.ElementModifier,
) {
	highlight_color := toggle_state^ ? rl.Color{120, 200, 120, 255} : rl.Color{200, 120, 120, 255}
	normal_color := toggle_state^ ? rl.Color{100, 180, 100, 255} : rl.Color{180, 100, 100, 255}

	if orui.label(
		orui.id(id),
		label,
		{
			font_size = 16,
			padding = orui.padding(10, 8),
			background_color = orui.hovered() ? highlight_color : normal_color,
			color = rl.WHITE,
			border = orui.border(1),
			border_color = {100, 100, 100, 255},
			corner_radius = orui.corner(4),
		},
		..modifiers,
	) {
		toggle_state^ = !toggle_state^
	}
}

toggle_buttons :: proc(id: string, labels: []string, toggle_state: ^int) {
	highlight_color := rl.Color{200, 200, 200, 255}
	normal_color := rl.WHITE
	hovered_color := rl.Color{240, 240, 240, 255}
	active_color := rl.Color{230, 230, 230, 255}

	orui.container(orui.id(id), {})

	for label, i in labels {
		if orui.label(
			orui.id(id, i),
			label,
			{
				font_size = 16,
				padding = orui.padding(10, 8),
				background_color = toggle_state^ == i ? highlight_color : orui.active() ? active_color : orui.hovered() ? hovered_color : normal_color,
				color = rl.BLACK,
				border = orui.border(1),
				border_color = {100, 100, 100, 255},
			},
		) {
			toggle_state^ = i
		}
	}
}

dropdown :: proc(
	id: string,
	label: string,
	options: []string,
	open_state: ^bool,
	value: ^int,
) -> bool {
	just_opened := false
	changed := false

	orui.container(
		orui.id(id),
		{padding = orui.padding(2), position = {.Relative, {}}, width = orui.fixed(250)},
	)

	if button(orui.to_id(id, 1), label, proc(element: ^orui.Element) {
			element.width = orui.grow()
		}) {
		open_state^ = !open_state^
		just_opened = true
	}

	if open_state^ {
		// this container holds the dropdown options
		orui.container(
			orui.id(id, 2),
			{
				position = {.Absolute, {}},
				placement = orui.placement(.Bottom, .Top),
				bounds = {.Window, .Flip, 8},
				direction = .TopToBottom,
				padding = orui.padding(4),
				width = orui.fixed(250),
				gap = 1,
				layer = 100,
			},
		)

		for option, i in options {
			if button(orui.to_id(id, 3 + i), option, proc(element: ^orui.Element) {
					element.width = orui.grow()
				}) {
				value^ = i
				open_state^ = false
				changed = true
			}
		}
	}

	if !just_opened && rl.IsMouseButtonReleased(.LEFT) && !orui.hovered("dropdown content") {
		open_state^ = false
	}

	return changed
}

checkbox :: proc(id: string, label: string, checked_state: ^bool) {
	orui.container(
		orui.id(id),
		{
			direction = .LeftToRight,
			gap = 8,
			width = orui.fit(),
			height = orui.fit(),
			align_cross = .Center,
		},
	)

	// listen for clicks on the container, not the checkbox/label
	if orui.clicked(id) {
		checked_state^ = !checked_state^
	}

	{orui.container(
			orui.id(id, 1),
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
				orui.id(id, 2),
				{
					width = orui.grow(),
					height = orui.grow(),
					background_color = checked_state^ ? {200, 120, 120, 255} : orui.hovered("checkbox container") ? rl.LIGHTGRAY : {},
					corner_radius = orui.corner(2),
				},
			)}
	}

	orui.label(
		orui.id(id, 3),
		label,
		{
			font_size = 16,
			color = rl.BLACK,
			width = orui.fit(),
			height = orui.grow(),
			align = {.Start, .Center},
			disabled = .True,
		},
	)
}

text_input :: proc(id: string, input_buffer: ^strings.Builder, modifiers: ..orui.ElementModifier) {
	orui.text_input(
		orui.id(id),
		input_buffer,
		{
			width            = orui.fixed(300),
			height           = orui.fit(),
			color            = rl.BLACK,
			font_size        = 16,
			background_color = rl.WHITE,
			border           = orui.border(1),
			border_color     = orui.focused() ? rl.BLUE : rl.LIGHTGRAY,
			padding          = orui.padding(8),
			corner_radius    = orui.corner(4),

			// these make the text input single-line and horizontally scrollable
			overflow         = .Visible,
			clip             = {.Intersect, {}},
			scroll           = orui.scroll(.Horizontal),
		},
		..modifiers,
	)
}

text_area :: proc(id: string, input_buffer: ^strings.Builder) {
	orui.text_input(
		orui.id(id),
		input_buffer,
		{
			width            = orui.fixed(300),
			height           = orui.fixed(150),
			color            = rl.BLACK,
			font_size        = 16,
			background_color = rl.WHITE,
			border           = orui.border(1),
			border_color     = orui.focused() ? rl.BLUE : rl.LIGHTGRAY,
			padding          = orui.padding(8),
			corner_radius    = orui.corner(4),

			// these make the text input multi-line and vertically scrollable
			overflow         = .Wrap,
			clip             = {.Intersect, {}},
			scroll           = orui.scroll(.Vertical),
		},
	)
}
