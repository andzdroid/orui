package orui_test

import orui "../src"
import "core:testing"

@(test)
fit_height_child_is_not_clamped_by_vertical_scroll_parent :: proc(t: ^testing.T) {
	item_count := 10
	row_height := f32(30)
	gap := f32(5)
	viewport_height := f32(120)
	expected_content_height := f32(item_count) * row_height + f32(item_count - 1) * gap

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 200, 120, 0)
	{orui.container(
			orui.id("scroll-parent"),
			{
				layout = .Flex,
				direction = .TopToBottom,
				width = orui.percent(1),
				height = orui.percent(1),
				gap = gap,
				scroll = orui.scroll(.Vertical),
				clip = {.Self, {}},
			},
		)
		{orui.container(
				orui.id("fit-child"),
				{
					layout = .Flex,
					direction = .TopToBottom,
					width = orui.percent(1),
					height = orui.fit(),
					gap = gap,
				},
			)
			for i in 0 ..< item_count {
				orui.container(
					orui.id("row", i),
					{width = orui.percent(1), height = orui.fixed(row_height)},
				)
			}
		}
	}
	orui.end()

	fit_child := find_element(ctx, orui.to_id("fit-child"))
	scroll_parent := find_element(ctx, orui.to_id("scroll-parent"))
	testing.expect(t, fit_child != nil)
	testing.expect(t, scroll_parent != nil)
	testing.expect_value(t, fit_child._size.y, expected_content_height)
	testing.expect_value(t, scroll_parent._content_size.y, expected_content_height)
	testing.expect_value(t, scroll_parent._size.y, viewport_height)
	testing.expect(t, fit_child._size.y > scroll_parent._size.y)
}

@(test)
fit_width_child_is_not_clamped_by_horizontal_scroll_parent :: proc(t: ^testing.T) {
	item_count := 10
	col_width := f32(40)
	gap := f32(6)
	viewport_width := f32(120)
	expected_content_width := f32(item_count) * col_width + f32(item_count - 1) * gap

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 120, 200, 0)
	{orui.container(
			orui.id("scroll-parent"),
			{
				layout = .Flex,
				direction = .LeftToRight,
				width = orui.percent(1),
				height = orui.percent(1),
				gap = gap,
				scroll = orui.scroll(.Horizontal),
				clip = {.Self, {}},
			},
		)
		{orui.container(
				orui.id("fit-child"),
				{
					layout = .Flex,
					direction = .LeftToRight,
					width = orui.fit(),
					height = orui.percent(1),
					gap = gap,
				},
			)
			for i in 0 ..< item_count {
				orui.container(
					orui.id("col", i),
					{width = orui.fixed(col_width), height = orui.percent(1)},
				)
			}
		}
	}
	orui.end()

	fit_child := find_element(ctx, orui.to_id("fit-child"))
	scroll_parent := find_element(ctx, orui.to_id("scroll-parent"))
	testing.expect(t, fit_child != nil)
	testing.expect(t, scroll_parent != nil)
	testing.expect_value(t, fit_child._size.x, expected_content_width)
	testing.expect_value(t, scroll_parent._content_size.x, expected_content_width)
	testing.expect_value(t, scroll_parent._size.x, viewport_width)
	testing.expect(t, fit_child._size.x > scroll_parent._size.x)
}
