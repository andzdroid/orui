package demo

import orui "../src"
import "core:fmt"
import rl "vendor:raylib"

render_test_placement :: proc() {
	{orui.container(
			orui.id("container"),
			{
				direction = .TopToBottom,
				width = orui.grow(),
				height = orui.grow(),
				padding = orui.padding(16),
				background_color = rl.BEIGE,
				gap = 16,
				align_main = .Center,
				align_cross = .Center,
			},
		)

		{orui.container(
				orui.id("anchor"),
				{
					layout = .Flex,
					direction = .TopToBottom,
					position = {.Relative, {}},
					background_color = rl.DARKBLUE,
					align_main = .Center,
					align_cross = .Center,
				},
			)

			orui.label(
				orui.id("anchor label"),
				"Anchor",
				{
					font = &font,
					font_size = 16,
					color = rl.WHITE,
					margin = orui.margin(32),
					align = {.Center, .Center},
				},
			)

			placement("top left", {.Absolute, {-8, -8}}, orui.placement(.TopLeft, .BottomRight))
			placement("top", {.Absolute, {0, -8}}, orui.placement(.Top, .Bottom))
			placement("top right", {.Absolute, {8, -8}}, orui.placement(.TopRight, .BottomLeft))
			placement("left", {.Absolute, {-8, 0}}, orui.placement(.Left, .Right))
			placement("right", {.Absolute, {8, 0}}, orui.placement(.Right, .Left))
			placement("bottom left", {.Absolute, {-8, 8}}, orui.placement(.BottomLeft, .TopRight))
			placement("bottom", {.Absolute, {0, 8}}, orui.placement(.Bottom, .Top))
			placement("bottom right", {.Absolute, {8, 8}}, orui.placement(.BottomRight, .TopLeft))

			placement("fixed top left", {.Fixed, {8, 8}}, orui.placement(.TopLeft, .TopLeft))
			placement("fixed top", {.Fixed, {0, 8}}, orui.placement(.Top, .Top))
			placement("fixed top right", {.Fixed, {-8, 8}}, orui.placement(.TopRight, .TopRight))
			placement("fixed left", {.Fixed, {8, 0}}, orui.placement(.Left, .Left))
			placement("fixed right", {.Fixed, {-8, 0}}, orui.placement(.Right, .Right))
			placement(
				"fixed bottom left",
				{.Fixed, {8, -8}},
				orui.placement(.BottomLeft, .BottomLeft),
			)
			placement("fixed bottom", {.Fixed, {0, -8}}, orui.placement(.Bottom, .Bottom))
			placement(
				"fixed bottom right",
				{.Fixed, {-8, -8}},
				orui.placement(.BottomRight, .BottomRight),
			)
		}
	}
}

placement :: proc(id: string, position: orui.Position, placement: orui.Placement) {
	{orui.container(
			orui.id(fmt.tprintf("%v container", id)),
			{
				position = position,
				placement = placement,
				background_color = rl.BLACK,
				padding = orui.padding(16),
				align_main = .Center,
				align_cross = .Center,
			},
		)
		orui.label(
			orui.id(id),
			id,
			{font = &font, font_size = 16, color = rl.WHITE, align = {.Center, .Center}},
		)
	}
}
