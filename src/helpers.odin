package orui

@(private)
x_padding :: proc(e: ^Element) -> f32 {
	return e.padding.left + e.padding.right
}

@(private)
y_padding :: proc(e: ^Element) -> f32 {
	return e.padding.top + e.padding.bottom
}

@(private)
x_margin :: proc(e: ^Element) -> f32 {
	return e.margin.left + e.margin.right
}

@(private)
y_margin :: proc(e: ^Element) -> f32 {
	return e.margin.top + e.margin.bottom
}

@(private)
x_border :: proc(e: ^Element) -> f32 {
	return e.border.left + e.border.right
}

@(private)
y_border :: proc(e: ^Element) -> f32 {
	return e.border.top + e.border.bottom
}

@(private)
inner_width :: proc(e: ^Element) -> f32 {
	return max(0, e._size.x - x_padding(e) - x_border(e))
}

@(private)
inner_height :: proc(e: ^Element) -> f32 {
	return max(0, e._size.y - y_padding(e) - y_border(e))
}

@(private)
inner_main :: proc(e: ^Element) -> f32 {
	if e.direction == .LeftToRight {
		return inner_width(e)
	} else {
		return inner_height(e)
	}
}

@(private)
parent_inner_width :: proc(ctx: ^Context, e: ^Element) -> (w: f32, definite: bool) {
	if e.parent == 0 {
		root := &ctx.elements[0]
		return root._size.x, true
	}

	parent := &ctx.elements[e.parent]
	if parent.layout == .Grid {
		width: f32 = 0
		col_span := max(e.col_span, 1)
		for i := e._grid_col_index; i < e._grid_col_index + col_span; i += 1 {
			width += parent._grid_col_sizes[i]
		}
		gap := parent.col_gap > 0 ? parent.col_gap : parent.gap
		gap_count := max(col_span - 1, 0)
		width += gap * f32(gap_count)
		return width, true
	} else {
		return inner_width(parent), parent._size.x > 0
	}
}

@(private)
parent_inner_height :: proc(ctx: ^Context, e: ^Element) -> (h: f32, definite: bool) {
	if e.parent == 0 {
		root := &ctx.elements[0]
		return root._size.y, true
	}

	parent := &ctx.elements[e.parent]
	if parent.layout == .Grid {
		height: f32 = 0
		row_span := max(e.row_span, 1)
		for i := e._grid_row_index; i < e._grid_row_index + row_span; i += 1 {
			height += parent._grid_row_sizes[i]
		}
		gap := parent.row_gap > 0 ? parent.row_gap : parent.gap
		gap_count := max(row_span - 1, 0)
		height += gap * f32(gap_count)
		return height, true
	} else {
		return inner_height(parent), parent._size.y > 0
	}
}

@(private)
has_round_corners :: proc(corners: Corners) -> bool {
	return(
		corners.top_left > 0 ||
		corners.top_right > 0 ||
		corners.bottom_right > 0 ||
		corners.bottom_left > 0 \
	)
}
