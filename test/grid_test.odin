package orui_test

import orui "../src"
import "core:testing"

@(test)
grid_auto_place_tracks_used_rows_and_columns :: proc(t: ^testing.T) {
	col_sizes := []orui.Size{orui.fixed(10)}
	row_sizes := []orui.Size{orui.fixed(10)}

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 100, 100, 0)
	{orui.container(
			orui.id("grid"),
			{
				layout = .Grid,
				direction = .LeftToRight,
				width = orui.fit(),
				height = orui.fit(),
				cols = 3,
				rows = 3,
				col_sizes = col_sizes,
				row_sizes = row_sizes,
			},
		)
		{orui.container(
				orui.id("a"),
				{col_span = 2, width = orui.fixed(1), height = orui.fixed(1)},
			)}
		{orui.container(
				orui.id("b"),
				{row_span = 2, width = orui.fixed(1), height = orui.fixed(1)},
			)}
		{orui.container(orui.id("c"), {width = orui.fixed(1), height = orui.fixed(1)})}
		{orui.container(
				orui.id("d"),
				{col_span = 2, width = orui.fixed(1), height = orui.fixed(1)},
			)}
	}
	orui.end()

	grid := find_element(ctx, orui.to_id("grid"))
	a := find_element(ctx, orui.to_id("a"))
	b := find_element(ctx, orui.to_id("b"))
	c := find_element(ctx, orui.to_id("c"))
	d := find_element(ctx, orui.to_id("d"))
	testing.expect(t, grid != nil)
	testing.expect(t, a != nil)
	testing.expect(t, b != nil)
	testing.expect(t, c != nil)
	testing.expect(t, d != nil)

	testing.expect_value(t, grid.cols, 3)
	testing.expect_value(t, grid.rows, 3)
	expect_f32(t, grid._size.x, 30, "grid width")
	expect_f32(t, grid._size.y, 30, "grid height")

	testing.expect_value(t, a._grid_col_index, 0)
	testing.expect_value(t, a._grid_row_index, 0)
	testing.expect_value(t, b._grid_col_index, 2)
	testing.expect_value(t, b._grid_row_index, 0)
	testing.expect_value(t, c._grid_col_index, 0)
	testing.expect_value(t, c._grid_row_index, 1)
	testing.expect_value(t, d._grid_col_index, 0)
	testing.expect_value(t, d._grid_row_index, 2)
}

@(test)
grid_fit_size_matches_track_bases :: proc(t: ^testing.T) {
	col_sizes := []orui.Size{orui.fit()}
	row_sizes := []orui.Size{orui.fit()}

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 120, 120, 0)
	{orui.container(
			orui.id("grid"),
			{
				layout = .Grid,
				direction = .LeftToRight,
				width = orui.fit(),
				height = orui.fit(),
				cols = 2,
				rows = 2,
				col_sizes = col_sizes,
				row_sizes = row_sizes,
				gap = 4,
			},
		)
		{orui.container(orui.id("a"), {width = orui.fixed(10), height = orui.fixed(20)})}
		{orui.container(orui.id("b"), {width = orui.fixed(30), height = orui.fixed(5)})}
		{orui.container(orui.id("c"), {width = orui.fixed(15), height = orui.fixed(8)})}
	}
	orui.end()

	grid := find_element(ctx, orui.to_id("grid"))
	grid_state := find_grid_state(ctx, grid)
	testing.expect(t, grid != nil)
	testing.expect(t, grid_state != nil)
	testing.expect_value(t, grid.cols, 2)
	testing.expect_value(t, grid.rows, 2)
	expect_f32(t, grid_state.col_sizes[0], 15, "column 0 width")
	expect_f32(t, grid_state.col_sizes[1], 30, "column 1 width")
	expect_f32(t, grid_state.row_sizes[0], 20, "row 0 height")
	expect_f32(t, grid_state.row_sizes[1], 8, "row 1 height")
	expect_f32(t, grid._size.x, 49, "grid width")
	expect_f32(t, grid._size.y, 32, "grid height")
}

@(test)
wrapped_flex_in_fit_row_keeps_height :: proc(t: ^testing.T) {
	col_sizes := []orui.Size{orui.fit()}
	row_sizes := []orui.Size{orui.fit()}

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 320, 240, 0)
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
			},
		)
		{orui.container(
				orui.id("wrap-row"),
				{
					layout = .Flex,
					direction = .LeftToRight,
					flex_wrap = .Wrap,
					width = orui.fixed(140),
					height = orui.fit(),
					gap = 12,
				},
			)
			{orui.container(orui.id("a"), {width = orui.fixed(110), height = orui.fixed(60)})}
			{orui.container(orui.id("b"), {width = orui.fixed(110), height = orui.fixed(90)})}
		}
	}
	orui.end()

	grid := find_element(ctx, orui.to_id("grid"))
	grid_state := find_grid_state(ctx, grid)
	wrap_row := find_element(ctx, orui.to_id("wrap-row"))
	testing.expect(t, grid != nil)
	testing.expect(t, grid_state != nil)
	testing.expect(t, wrap_row != nil)
	expect_f32(t, wrap_row._size.y, 162, "wrapped flex height")
	expect_f32(t, grid_state.row_sizes[0], 162, "grid row height")
	expect_f32(t, grid._size.y, 162, "grid height")
}

@(test)
flex_in_fit_row_keeps_height :: proc(t: ^testing.T) {
	col_sizes := []orui.Size{orui.fit()}
	row_sizes := []orui.Size{orui.fit()}

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 240, 200, 0)
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
			},
		)
		{orui.container(
				orui.id("row"),
				{
					layout = .Flex,
					direction = .LeftToRight,
					width = orui.fit(),
					height = orui.fit(),
					gap = 10,
				},
			)
			{orui.container(orui.id("a"), {width = orui.fixed(30), height = orui.fixed(20)})}
			{orui.container(orui.id("b"), {width = orui.fixed(40), height = orui.fixed(35)})}
		}
	}
	orui.end()

	grid := find_element(ctx, orui.to_id("grid"))
	grid_state := find_grid_state(ctx, grid)
	row := find_element(ctx, orui.to_id("row"))
	testing.expect(t, grid != nil)
	testing.expect(t, grid_state != nil)
	testing.expect(t, row != nil)
	expect_f32(t, row._size.y, 35, "flex height")
	expect_f32(t, grid_state.row_sizes[0], 35, "grid row height")
	expect_f32(t, grid._size.y, 35, "grid height")
}

@(test)
flex_in_fit_column_keeps_width :: proc(t: ^testing.T) {
	col_sizes := []orui.Size{orui.fit()}
	row_sizes := []orui.Size{orui.fit()}

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 240, 200, 0)
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
			},
		)
		{orui.container(
				orui.id("column"),
				{
					layout = .Flex,
					direction = .TopToBottom,
					width = orui.fit(),
					height = orui.fit(),
					gap = 6,
				},
			)
			{orui.container(orui.id("a"), {width = orui.fixed(40), height = orui.fixed(10)})}
			{orui.container(orui.id("b"), {width = orui.fixed(60), height = orui.fixed(14)})}
		}
	}
	orui.end()

	grid := find_element(ctx, orui.to_id("grid"))
	grid_state := find_grid_state(ctx, grid)
	column := find_element(ctx, orui.to_id("column"))
	testing.expect(t, grid != nil)
	testing.expect(t, grid_state != nil)
	testing.expect(t, column != nil)
	expect_f32(t, column._size.x, 60, "flex width")
	expect_f32(t, grid_state.col_sizes[0], 60, "grid column width")
	expect_f32(t, grid._size.x, 60, "grid width")
}

@(test)
resolved_tracks_size_percent_and_grow_children :: proc(t: ^testing.T) {
	col_sizes := []orui.Size{orui.grow()}
	row_sizes := []orui.Size{orui.grow(), orui.grow()}

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 200, 200, 0)
	{orui.container(
			orui.id("grid"),
			{
				layout = .Grid,
				width = orui.fixed(100),
				height = orui.fixed(120),
				cols = 1,
				rows = 2,
				col_sizes = col_sizes,
				row_sizes = row_sizes,
			},
		)
		{orui.container(
				orui.id("percent"),
				{width = orui.percent(0.5), height = orui.percent(0.5)},
			)
		}
		{orui.container(orui.id("grow"), {width = orui.grow(), height = orui.grow()})}
	}
	orui.end()

	grid := find_element(ctx, orui.to_id("grid"))
	grid_state := find_grid_state(ctx, grid)
	percent := find_element(ctx, orui.to_id("percent"))
	grow := find_element(ctx, orui.to_id("grow"))
	testing.expect(t, grid != nil)
	testing.expect(t, grid_state != nil)
	testing.expect(t, percent != nil)
	testing.expect(t, grow != nil)
	expect_f32(t, grid_state.col_sizes[0], 100, "resolved column width")
	expect_f32(t, grid_state.row_sizes[0], 60, "resolved row 0 height")
	expect_f32(t, grid_state.row_sizes[1], 60, "resolved row 1 height")
	expect_f32(t, percent._size.x, 50, "percent child width")
	expect_f32(t, percent._size.y, 30, "percent child height")
	expect_f32(t, grow._size.x, 100, "grow child width")
	expect_f32(t, grow._size.y, 60, "grow child height")
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
	grid_state := find_grid_state(ctx, grid)
	testing.expect(t, grid != nil)
	testing.expect(t, grid_state != nil)
	expect_f32(t, grid_state.col_sizes[0], 60, "column 0 width")
	expect_f32(t, grid_state.col_sizes[1], 70, "column 1 width")
	expect_f32(t, grid_state.col_sizes[2], 70, "column 2 width")
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
	grid_state := find_grid_state(ctx, grid)
	testing.expect(t, grid != nil)
	testing.expect(t, grid_state != nil)
	expect_f32(t, grid_state.row_sizes[0], 40, "row 0 height")
	expect_f32(t, grid_state.row_sizes[1], 35, "row 1 height")
	expect_f32(t, grid_state.row_sizes[2], 35, "row 2 height")
	expect_f32(t, grid._content_size.y, 130, "grid content height")
}
