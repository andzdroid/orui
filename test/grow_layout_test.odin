package orui_test

import orui "../src"
import "core:testing"

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

@(test)
grid_grow_columns_respect_explicit_max :: proc(t: ^testing.T) {
	track_a := orui.grow()
	track_a.max = 60
	track_b := orui.grow()
	track_c := orui.grow()
	col_sizes := []orui.Size{track_a, track_b, track_c}
	row_sizes := []orui.Size{orui.fixed(40)}

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 220, 80, 0)
	{orui.container(
			orui.id("grid"),
			{
				layout = .Grid,
				width = orui.fixed(220),
				height = orui.fixed(60),
				cols = 3,
				rows = 1,
				gap = 10,
				col_sizes = col_sizes,
				row_sizes = row_sizes,
			},
		)
		for i in 0 ..< 3 {
			orui.container(orui.id("cell", i), {width = orui.fixed(20), height = orui.fixed(40)})
		}
	}
	orui.end()

	grid := find_element(ctx, orui.to_id("grid"))
	testing.expect(t, grid != nil)
	expect_f32(t, grid._grid_col_sizes[0], 60, "column 0 width")
	expect_f32(t, grid._grid_col_sizes[1], 70, "column 1 width")
	expect_f32(t, grid._grid_col_sizes[2], 70, "column 2 width")
	expect_f32(t, grid._content_size.x, 220, "grid content width")
}

@(test)
grid_grow_rows_respect_explicit_min_when_shrinking :: proc(t: ^testing.T) {
	row_a := orui.grow()
	row_a.min = 40
	row_b := orui.grow()
	row_c := orui.grow()
	col_sizes := []orui.Size{orui.fixed(40)}
	row_sizes := []orui.Size{row_a, row_b, row_c}

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 80, 130, 0)
	{orui.container(
			orui.id("grid"),
			{
				layout = .Grid,
				width = orui.fixed(60),
				height = orui.fixed(130),
				cols = 1,
				rows = 3,
				gap = 10,
				col_sizes = col_sizes,
				row_sizes = row_sizes,
			},
		)
		for i in 0 ..< 3 {
			orui.container(orui.id("cell", i), {width = orui.fixed(40), height = orui.fixed(50)})
		}
	}
	orui.end()

	grid := find_element(ctx, orui.to_id("grid"))
	testing.expect(t, grid != nil)
	expect_f32(t, grid._grid_row_sizes[0], 40, "row 0 height")
	expect_f32(t, grid._grid_row_sizes[1], 35, "row 1 height")
	expect_f32(t, grid._grid_row_sizes[2], 35, "row 2 height")
	expect_f32(t, grid._content_size.y, 130, "grid content height")
}
