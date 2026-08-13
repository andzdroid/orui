package demo

import orui "../src"
import "core:math/ease"
import "core:strings"
import rl "vendor:raylib"

animation_ease: ease.Ease = .Quadratic_Out
animation_text_input: strings.Builder

render_test_animation :: proc() {
	if cap(animation_text_input.buf) == 0 {
		animation_text_input = strings.builder_make()
		strings.write_string(&animation_text_input, "text input")
	}

	orui.container(
		orui.id("container"),
		{
			direction = .TopToBottom,
			width = orui.grow(),
			height = orui.grow(),
			padding = {16, 24, 16, 16},
			background_color = rl.BEIGE,
			gap = 14,
			scroll = orui.scroll(.Vertical),
		},
	)

	orui.scrollbar(
		orui.to_id("container"),
		{
			position = {.Absolute, {-5, 0}},
			placement = orui.placement(.Right, .Right),
			width = orui.fixed(8),
			height = orui.grow(),
			margin = orui.margin(2, 18),
		},
		{
			direction = .TopToBottom,
			width = orui.percent(1),
			background_color = rl.DARKGRAY,
			corner_radius = orui.corner(4),
		},
	)

	orui.label(
		orui.id("title"),
		"Animation",
		{width = orui.grow(), font_size = 24, color = rl.BLACK, align = {.Center, .Center}},
	)

	animation_ease_row()
	animation_button_row()
	animation_input_row()
	animation_size_row()
	animation_progress_row()
	animation_target_row()
	animation_scroll_row()
}

animation_ease_row :: proc() {
	orui.container(
		orui.id("ease row"),
		{
			direction = .LeftToRight,
			width = orui.grow(),
			height = orui.fit(),
			padding = orui.padding(14),
			gap = 10,
			align_main = .Center,
			align_cross = .Center,
		},
	)
	animation_ease_button("ease linear", "Linear", .Linear)
	animation_ease_button("ease quadratic", "Quadratic", .Quadratic_Out)
	animation_ease_button("ease cubic", "Cubic", .Cubic_In_Out)
	animation_ease_button("ease back", "Back", .Back_Out)
	animation_ease_button("ease bounce", "Bounce", .Bounce_Out)

}

animation_ease_button :: proc(id, text: string, easing: ease.Ease) {
	button_id := orui.id(id)
	selected := animation_ease == easing
	target_bg := rl.Color{245, 245, 245, 255}
	target_border := rl.Color{170, 170, 170, 255}
	target_text := rl.Color{40, 40, 40, 255}

	if selected {
		target_bg = {65, 125, 210, 255}
		target_border = {45, 90, 170, 255}
		target_text = rl.WHITE
	}
	if orui.hovered() {
		target_bg = selected ? rl.Color{55, 110, 195, 255} : rl.Color{230, 238, 250, 255}
	}
	if orui.active() {
		target_bg = selected ? rl.Color{40, 90, 170, 255} : rl.Color{210, 225, 245, 255}
	}

	if orui.label(
		button_id,
		text,
		{
			width = orui.fixed(105),
			padding = orui.padding(10, 7),
			background_color = orui.animate("background", target_bg),
			border = orui.border(1),
			border_color = orui.animate("border", target_border),
			corner_radius = orui.corner(4),
			color = orui.animate("text", target_text),
			font_size = 16,
			align = {.Center, .Center},
			cursor = .Pointing_Hand,
		},
	) {
		animation_ease = easing
	}
}

animation_button_row :: proc() {
	orui.container(
		orui.id("button row"),
		{width = orui.grow(), height = orui.fit(), align_main = .Center, align_cross = .Center},
	)

	target_bg := rl.Color{248, 239, 222, 255}
	target_border := rl.Color{166, 137, 103, 255}
	button_id := orui.id("button")

	if orui.hovered() {
		target_bg = {199, 232, 214, 255}
		target_border = {53, 134, 104, 255}
	}
	if orui.active() {
		target_bg = {119, 170, 205, 255}
		target_border = {38, 82, 130, 255}
	}

	orui.label(
		button_id,
		"Click, hover, hold",
		{
			width = orui.fixed(260),
			padding = orui.padding(14, 10),
			background_color = orui.animate("background", target_bg, 0.3, animation_ease),
			border = orui.border(1),
			border_color = orui.animate("border", target_border, 0.3, animation_ease),
			corner_radius = orui.corner(4),
			color = rl.BLACK,
			font_size = 16,
			align = {.Center, .Center},
			cursor = .Pointing_Hand,
		},
	)
}

animation_input_row :: proc() {
	orui.container(
		orui.id("input row"),
		{width = orui.grow(), height = orui.fit(), align_main = .Center, align_cross = .Center},
	)

	input_id := orui.id("animated input")
	target_bg := rl.Color{250, 242, 225, 255}
	target_border := rl.Color{172, 142, 104, 255}
	if orui.hovered() {
		target_bg = {220, 244, 231, 255}
		target_border = {42, 145, 112, 255}
	}
	if orui.focused() {
		target_bg = {211, 226, 255, 255}
		target_border = {61, 104, 190, 255}
	}
	if orui.active() {
		target_bg = {185, 208, 246, 255}
		target_border = {45, 82, 155, 255}
	}

	orui.text_input(
		input_id,
		&animation_text_input,
		{
			width = orui.fixed(310),
			padding = orui.transition(
				"padding",
				orui.active() || orui.focused(),
				orui.padding(10, 8),
				orui.padding(14, 8),
				0.3,
				animation_ease,
			),
			background_color = orui.animate("background", target_bg, 0.3, animation_ease),
			border = orui.border(1),
			border_color = orui.animate("border color", target_border, 0.3, animation_ease),
			corner_radius = orui.corner(4),
			color = rl.BLACK,
			font_size = 16,
			overflow = .Visible,
			clip = {.Self, {}},
			scroll = orui.scroll(.Horizontal),
		},
	)
}

animation_size_row :: proc() {
	orui.container(
		orui.id("size row"),
		{width = orui.grow(), height = orui.fit(), align_main = .Center, align_cross = .Center},
	)

	size_id := orui.id("size demo")
	hovered := orui.hovered()
	active := orui.active()
	target_bg := rl.Color{236, 224, 204, 255}
	target_border := rl.Color{152, 122, 86, 255}

	if hovered {
		target_bg = {190, 226, 210, 255}
		target_border = {54, 132, 102, 255}
	}
	if active {
		target_bg = {170, 200, 238, 255}
		target_border = {46, 88, 154, 255}
	}

	orui.container(
		size_id,
		{
			width = orui.transition(
				"width",
				hovered,
				orui.fixed(130),
				orui.fixed(310),
				0.3,
				animation_ease,
			),
			height = orui.transition(
				"height",
				hovered,
				orui.fixed(46),
				orui.fixed(88),
				0.3,
				animation_ease,
			),
			background_color = orui.animate("background", target_bg, 0.3, animation_ease),
			border = orui.transition(
				"border",
				active,
				orui.border(1),
				orui.border(8),
				0.3,
				animation_ease,
			),
			border_color = orui.animate("border color", target_border, 0.3, animation_ease),
			corner_radius = orui.transition(
				"corner",
				hovered,
				orui.corner(2),
				orui.corner(16),
				0.3,
				animation_ease,
			),
			align_main = .Center,
			align_cross = .Center,
			cursor = .Pointing_Hand,
		},
	)
	orui.label(
		orui.id("size label"),
		"Resize",
		{
			color = {34, 38, 42, 255},
			font_size = orui.transition(
				"font size",
				hovered,
				f32(15),
				f32(24),
				0.3,
				animation_ease,
			),
			align = {.Center, .Center},
			block = .False,
		},
	)
}

animation_progress_row :: proc() {
	time := f32(rl.GetTime())
	phase := int(time / 0.9) % 5
	target_progress: f32

	switch phase {
	case 0:
		target_progress = 0.16
	case 1:
		target_progress = 0.58
	case 2:
		target_progress = 0.36
	case 3:
		target_progress = 0.88
	case:
		target_progress = 0.68
	}

	orui.container(
		orui.id("progress row"),
		{width = orui.grow(), height = orui.fit(), align_main = .Center, align_cross = .Center},
	)
	orui.container(
		orui.id("progress track"),
		{
			width = orui.fixed(500),
			height = orui.fixed(28),
			background_color = {224, 226, 222, 255},
			border = orui.border(1),
			border_color = {170, 174, 168, 255},
			corner_radius = orui.corner(4),
			clip = {.Self, {}},
		},
	)
	orui.container(
		orui.id("progress fill"),
		{
			width = orui.animate("width", orui.percent(target_progress), 0.55, animation_ease),
			height = orui.percent(1),
			background_color = {76, 135, 198, 255},
			corner_radius = orui.corner(3),
		},
	)
}

animation_target_row :: proc() {
	time := f32(rl.GetTime())
	phase := int(time / 1.15) % 4
	target_position: rl.Vector2
	target_color: rl.Color

	switch phase {
	case 0:
		target_position = {18, 18}
		target_color = {230, 95, 80, 255}
	case 1:
		target_position = {390, 24}
		target_color = {75, 135, 235, 255}
	case 2:
		target_position = {430, 72}
		target_color = {245, 185, 70, 255}
	case:
		target_position = {68, 74}
		target_color = {80, 175, 120, 255}
	}

	orui.container(
		orui.id("target row"),
		{
			direction = .LeftToRight,
			width = orui.grow(),
			height = orui.fit(),
			padding = orui.padding(14),
			gap = 16,
			align_main = .Center,
			align_cross = .Center,
		},
	)

	orui.container(
		orui.id("stage"),
		{
			position = {.Relative, {}},
			width = orui.fixed(500),
			height = orui.fixed(125),
			background_color = {32, 36, 42, 255},
			corner_radius = orui.corner(4),
			clip = {.Self, {}},
		},
	)
	orui.container(
		orui.id("orb"),
		{
			position = {
				.Absolute,
				orui.animate("position", target_position, 0.55, animation_ease),
			},
			width = orui.fixed(30),
			height = orui.fixed(30),
			background_color = orui.animate("color", target_color, 0.55, animation_ease),
			corner_radius = orui.corner(15),
		},
	)
}

animation_scroll_row :: proc() {
	time := f32(rl.GetTime())
	phase := int(time / 1.35) % 4
	target_offset: rl.Vector2

	switch phase {
	case 0:
		target_offset = {0, 0}
	case 1:
		target_offset = {360, 0}
	case 2:
		target_offset = {360, 360}
	case:
		target_offset = {0, 360}
	}

	orui.container(
		orui.id("scroll row"),
		{width = orui.grow(), height = orui.fit(), align_main = .Center, align_cross = .Center},
	)
	orui.container(
		orui.id("scroll frame"),
		{
			position = {.Relative, {}},
			width = orui.fit(),
			height = orui.fit(),
			padding = {0, 16, 16, 0},
		},
	)
	{orui.container(
			orui.id("scroll viewport"),
			{
				width = orui.fixed(450),
				height = orui.fixed(450),
				background_color = {235, 235, 235, 255},
				border = orui.border(1),
				border_color = {170, 170, 170, 255},
				corner_radius = orui.corner(4),
				clip = {.Self, {}},
				scroll = {.Manual, orui.animate("offset", target_offset, 0.7, animation_ease)},
			},
		)
		{orui.container(
				orui.id("scroll content"),
				{
					direction = .TopToBottom,
					width = orui.fixed(820),
					height = orui.fixed(820),
					padding = orui.padding(10),
					gap = 8,
					background_color = {248, 248, 248, 255},
				},
			)
			for row in 0 ..< 6 {
				{orui.container(
						orui.id("scroll content row", row),
						{
							direction = .LeftToRight,
							width = orui.grow(),
							height = orui.fit(),
							gap = 8,
						},
					)
					for col in 0 ..< 6 {
						color := rl.Color{210, 225, 245, 255}
						if (row + col) % 2 == 0 {
							color = {230, 235, 220, 255}
						}
						orui.label(
							orui.id("tile", row * 10 + col),
							"tile",
							{
								width = orui.fixed(120),
								height = orui.fixed(120),
								background_color = color,
								corner_radius = orui.corner(4),
								color = {55, 55, 55, 255},
								font_size = 14,
								align = {.Center, .Center},
							},
						)
					}
				}
			}
		}
	}
	orui.scrollbar(
		orui.to_id("scroll viewport"),
		{
			position = {.Absolute, {-4, 0}},
			placement = orui.placement(.TopRight, .TopRight),
			width = orui.fixed(8),
			height = orui.grow(),
			background_color = {210, 210, 210, 255},
			corner_radius = orui.corner(4),
		},
		{
			direction = .TopToBottom,
			width = orui.percent(1),
			background_color = {80, 125, 185, 255},
			corner_radius = orui.corner(4),
		},
	)
	orui.scrollbar(
		orui.to_id("scroll viewport"),
		{
			position = {.Absolute, {0, -4}},
			placement = orui.placement(.BottomLeft, .BottomLeft),
			width = orui.grow(),
			height = orui.fixed(8),
			background_color = {210, 210, 210, 255},
			corner_radius = orui.corner(4),
		},
		{
			direction = .LeftToRight,
			height = orui.percent(1),
			background_color = {80, 125, 185, 255},
			corner_radius = orui.corner(4),
		},
		1,
	)
}
