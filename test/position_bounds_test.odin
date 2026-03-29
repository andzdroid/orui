package orui_test

import orui "../src"
import "core:testing"

@(test)
element_shift_stays_within_window :: proc(t: ^testing.T) {
	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 100, 100, 0)
	{orui.container(
			orui.id("popover"),
			{
				layout = .None,
				position = {.Fixed, {90, 90}},
				bounds = {.Window, .Shift, 4},
				width = orui.fixed(20),
				height = orui.fixed(20),
			},
		)
	}
	orui.end()

	popover := find_element(ctx, orui.to_id("popover"))
	testing.expect(t, popover != nil)
	expect_f32(t, popover._position.x, 76, "popover x")
	expect_f32(t, popover._position.y, 76, "popover y")
}

@(test)
element_flip_stays_within_window :: proc(t: ^testing.T) {
	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 100, 100, 0)
	{orui.container(
			orui.id("anchor"),
			{
				layout = .None,
				position = {.Fixed, {80, 80}},
				width = orui.fixed(16),
				height = orui.fixed(16),
			},
		)
		{orui.container(
				orui.id("popover"),
				{
					layout = .None,
					position = {.Absolute, {}},
					placement = orui.placement(.BottomLeft, .TopLeft),
					bounds = {.Window, .Flip, 4},
					width = orui.fixed(20),
					height = orui.fixed(20),
				},
			)
		}
	}
	orui.end()

	popover := find_element(ctx, orui.to_id("popover"))
	testing.expect(t, popover != nil)
	expect_f32(t, popover._position.x, 76, "popover x")
	expect_f32(t, popover._position.y, 60, "popover y")
}
