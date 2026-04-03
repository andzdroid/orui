package orui_test

import orui "../src"
import "core:testing"

@(test)
flex_row_base_size_ignores_percent_and_absolute_children :: proc(t: ^testing.T) {
	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 200, 120, 0)
	{orui.container(
			orui.id("row"),
			{
				layout = .Flex,
				direction = .LeftToRight,
				width = orui.fit(),
				height = orui.fit(),
				gap = 10,
				padding = orui.padding(5),
				border = orui.border(2),
			},
		)
		{orui.container(
				orui.id("fixed"),
				{width = orui.fixed(40), height = orui.fixed(20), margin = orui.margin(3, 2)},
			)
		}
		{orui.container(
				orui.id("percent"),
				{width = orui.percent(0.5), height = orui.fixed(30), margin = orui.margin(4)},
			)
		}
		{orui.container(
				orui.id("absolute"),
				{position = {.Absolute, {}}, width = orui.fixed(100), height = orui.fixed(100)},
			)
		}
	}
	orui.end()

	row := find_element(ctx, orui.to_id("row"))
	testing.expect(t, row != nil)
	expect_f32(t, row._size.x, 70, "row width")
	expect_f32(t, row._size.y, 52, "row height")
}

@(test)
flex_column_base_size_uses_max_width_and_non_percent_heights :: proc(t: ^testing.T) {
	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 200, 120, 0)
	{orui.container(
			orui.id("column"),
			{
				layout = .Flex,
				direction = .TopToBottom,
				width = orui.fit(),
				height = orui.fit(),
				gap = 7,
				padding = orui.padding(4),
				border = orui.border(1),
			},
		)
		{orui.container(
				orui.id("child-1"),
				{width = orui.fixed(40), height = orui.fixed(10), margin = orui.margin(2, 1)},
			)
		}
		{orui.container(
				orui.id("child-2"),
				{width = orui.fixed(18), height = orui.percent(0.5), margin = orui.margin(3, 4)},
			)
		}
		{orui.container(
				orui.id("child-3"),
				{width = orui.fixed(22), height = orui.fixed(15), margin = orui.margin(1, 2)},
			)
		}
		{orui.container(
				orui.id("absolute"),
				{position = {.Absolute, {}}, width = orui.fixed(100), height = orui.fixed(100)},
			)
		}
	}
	orui.end()

	column := find_element(ctx, orui.to_id("column"))
	testing.expect(t, column != nil)
	expect_f32(t, column._size.x, 54, "column width")
	expect_f32(t, column._size.y, 55, "column height")
}

@(test)
flex_wrapped_row_height_matches_wrapped_lines :: proc(t: ^testing.T) {
	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 120, 120, 0)
	{orui.container(
			orui.id("wrap-row"),
			{
				layout = .Flex,
				direction = .LeftToRight,
				flex_wrap = .Wrap,
				width = orui.fixed(60),
				height = orui.fit(),
				gap = 5,
			},
		)
		{orui.container(orui.id("a"), {width = orui.fixed(30), height = orui.fixed(10)})}
		{orui.container(orui.id("b"), {width = orui.fixed(30), height = orui.fixed(20)})}
	}
	orui.end()

	wrap_row := find_element(ctx, orui.to_id("wrap-row"))
	testing.expect(t, wrap_row != nil)
	expect_f32(t, wrap_row._size.x, 60, "wrapped row width")
	expect_f32(t, wrap_row._size.y, 35, "wrapped row height")
}

@(test)
flex_grid_children_contribute_to_parent_base_size :: proc(t: ^testing.T) {
	col_sizes := []orui.Size{orui.fit()}
	row_sizes := []orui.Size{orui.fit()}

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 200, 120, 0)
	{orui.container(
			orui.id("parent"),
			{
				layout = .Flex,
				direction = .LeftToRight,
				width = orui.fit(),
				height = orui.fit(),
				gap = 10,
			},
		)
		{orui.container(
				orui.id("grid"),
				{
					layout = .Grid,
					width = orui.fit(),
					height = orui.fit(),
					cols = 1,
					rows = 1,
					col_sizes = col_sizes,
					row_sizes = row_sizes,
					margin = orui.margin(2, 1),
				},
			)
			{orui.container(orui.id("cell"), {width = orui.fixed(30), height = orui.fixed(20)})}
		}
		{orui.container(orui.id("sibling"), {width = orui.fixed(10), height = orui.fixed(12)})}
	}
	orui.end()

	parent := find_element(ctx, orui.to_id("parent"))
	grid := find_element(ctx, orui.to_id("grid"))
	testing.expect(t, parent != nil)
	testing.expect(t, grid != nil)
	expect_f32(t, grid._size.x, 30, "grid width")
	expect_f32(t, grid._size.y, 20, "grid height")
	expect_f32(t, parent._size.x, 54, "parent width")
	expect_f32(t, parent._size.y, 22, "parent height")
}

@(test)
grow_height_child_uses_remaining_space_in_column_flex :: proc(t: ^testing.T) {
	viewport_height := f32(200)
	header_height := f32(40)
	gap := f32(10)
	row_height := f32(30)
	row_gap := f32(4)
	item_count := 6
	expected_child_height := viewport_height - header_height - gap
	expected_content_height := f32(item_count) * row_height + f32(item_count - 1) * row_gap

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 200, i32(viewport_height), 0)
	{orui.container(
			orui.id("parent"),
			{
				layout = .Flex,
				direction = .TopToBottom,
				width = orui.percent(1),
				height = orui.percent(1),
				gap = gap,
			},
		)
		{orui.container(
				orui.id("header"),
				{width = orui.percent(1), height = orui.fixed(header_height)},
			)
		}
		{orui.container(
				orui.id("content"),
				{
					layout = .Flex,
					direction = .TopToBottom,
					width = orui.percent(1),
					height = orui.grow(),
					gap = row_gap,
					scroll = orui.scroll(.Vertical),
					clip = {.Self, {}},
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

	parent := find_element(ctx, orui.to_id("parent"))
	content := find_element(ctx, orui.to_id("content"))
	testing.expect(t, parent != nil)
	testing.expect(t, content != nil)
	expect_f32(t, parent._size.y, viewport_height, "parent height")
	expect_f32(t, content._size.y, expected_child_height, "grow child height")
	expect_f32(t, content._content_size.y, expected_content_height, "grow child content height")
	testing.expect(t, content._content_size.y > content._size.y)
}

@(test)
grow_width_child_uses_remaining_space_in_row_flex :: proc(t: ^testing.T) {
	viewport_width := f32(220)
	sidebar_width := f32(60)
	gap := f32(10)
	col_width := f32(30)
	col_gap := f32(4)
	item_count := 6
	expected_child_width := viewport_width - sidebar_width - gap
	expected_content_width := f32(item_count) * col_width + f32(item_count - 1) * col_gap

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, i32(viewport_width), 160, 0)
	{orui.container(
			orui.id("parent"),
			{
				layout = .Flex,
				direction = .LeftToRight,
				width = orui.percent(1),
				height = orui.percent(1),
				gap = gap,
			},
		)
		{orui.container(
				orui.id("sidebar"),
				{width = orui.fixed(sidebar_width), height = orui.percent(1)},
			)
		}
		{orui.container(
				orui.id("content"),
				{
					layout = .Flex,
					direction = .LeftToRight,
					width = orui.grow(),
					height = orui.percent(1),
					gap = col_gap,
					scroll = orui.scroll(.Horizontal),
					clip = {.Self, {}},
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

	parent := find_element(ctx, orui.to_id("parent"))
	content := find_element(ctx, orui.to_id("content"))
	testing.expect(t, parent != nil)
	testing.expect(t, content != nil)
	expect_f32(t, parent._size.x, viewport_width, "parent width")
	expect_f32(t, content._size.x, expected_child_width, "grow child width")
	expect_f32(t, content._content_size.x, expected_content_width, "grow child content width")
	testing.expect(t, content._content_size.x > content._size.x)
}
