package orui

@(private)
// Assign child elements to grid cells.
grid_auto_place :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	allocator := ctx.allocator[current_buffer(ctx)]
	col_limit := element.cols
	row_limit := element.rows

	cells := col_limit * row_limit
	occupied := make([]bool, cells, allocator)

	current_row := 0
	current_col := 0

	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		col_span := max(child_element.col_span, 1)
		row_span := max(child_element.row_span, 1)

		row := current_row
		col := current_col
		found := false
		attempts := 0
		for attempts < cells {
			free := true
			for r in row ..< row + row_span {
				if r >= row_limit {
					free = false
					break
				}
				for c in col ..< col + col_span {
					if c >= col_limit {
						free = false
						break
					}
					if occupied[r * col_limit + c] {
						free = false
						break
					}
				}
			}
			if free {
				found = true
				break
			}

			if element.direction == .LeftToRight {
				col, row = increment_column(col + 1, row, col_limit, row_limit)
			} else {
				col, row = increment_row(col, row + 1, col_limit, row_limit)
			}
			attempts += 1
		}

		child_element._grid_col_index = col
		child_element._grid_row_index = row

		for r in row ..< min(row + row_span, row_limit) {
			for c in col ..< min(col + col_span, col_limit) {
				occupied[r * col_limit + c] = true
			}
		}

		if element.direction == .LeftToRight {
			current_col, current_row = increment_column(col + col_span, row, col_limit, row_limit)
		} else {
			current_col, current_row = increment_row(col, row + row_span, col_limit, row_limit)
		}

		child = child_element.next
	}
}

@(private)
// Calculate column fixed/fit widths. NOT the widths of the grid cells.
grid_fit_columns :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	element.cols = grid_used_columns(ctx, element)

	for i in 0 ..< element.cols {
		track := element.col_sizes[min(i, len(element.col_sizes) - 1)]
		if track.type == .Fixed {
			width := grid_clamp_size(track.value, track)
			element._grid_col_sizes[i] = width
		} else if track.type == .Fit || track.type == .Grow {
			max_width: f32 = 0
			child := element.children
			for child != 0 {
				child_element := &elements[child]
				if child_element.position.type != .Absolute &&
				   child_element.position.type != .Fixed &&
				   child_element._grid_col_index == i &&
				   child_element.col_span <= 1 {
					width := child_element._size.x + x_margin(child_element)
					if width > max_width {
						max_width = width
					}
				}
				child = child_element.next
			}
			max_width = grid_clamp_size(max_width, track)
			element._grid_col_sizes[i] = max_width
		}
	}
}

@(private)
// Set grid container width to fit its columns (not grid cells)
grid_fit_width :: proc(ctx: ^Context, element: ^Element) {
	if element.width.type == .Fixed || element.width.type == .Percent {
		return
	}

	col_gap := element.col_gap > 0 ? element.col_gap : element.gap
	total: f32 = 0
	for i in 0 ..< element.cols {
		total += element._grid_col_sizes[i]
	}
	gaps := col_gap * f32(max(element.cols - 1, 0))
	total += gaps + x_padding(element) + x_border(element)

	min := max(element.width.min, x_padding(element) + x_border(element))
	max := element.width.max > 0 ? element.width.max : total
	total = clamp(total, min, max)
	element._size.x = total
}

@(private)
// Set percent and grow column widths.
grid_distribute_columns :: proc(ctx: ^Context, element: ^Element) {
	element_inner_width := inner_width(element)
	gap := element.col_gap > 0 ? element.col_gap : element.gap
	gaps := gap * f32(max(element.cols - 1, 0))
	element_inner_width -= gaps

	sum_with_margins: f32 = 0
	total_weight: f32 = 0
	for i in 0 ..< element.cols {
		track := element.col_sizes[min(i, len(element.col_sizes) - 1)]
		base: f32 = 0

		switch track.type {
		case .Fixed:
			base = element._grid_col_sizes[i]
		case .Percent:
			base = grid_clamp_size(element_inner_width * track.value, track)
			element._grid_col_sizes[i] = base
		case .Fit:
			base = element._grid_col_sizes[i]
		case .Grow:
			base = element._grid_col_sizes[i]
			weight := track.value
			if weight <= 0 {weight = 1}
			total_weight += weight
		}
		sum_with_margins += base + x_margin(element)
	}

	remaining := element_inner_width - sum_with_margins
	if remaining > 0 && total_weight > 0 {
		for i in 0 ..< element.cols {
			track := element.col_sizes[min(i, len(element.col_sizes) - 1)]
			if track.type == .Grow {
				weight := track.value
				if weight <= 0 {weight = 1}
				element._grid_col_sizes[i] += remaining * (weight / total_weight)
			}
		}
	}

	offset: f32 = 0
	total_width: f32 = 0
	for i in 0 ..< element.cols {
		element._grid_col_offsets[i] = offset
		offset += element._grid_col_sizes[i] + gap
		total_width += element._grid_col_sizes[i]
	}
	element._content_size.x = total_width + gap * f32(max(element.cols - 1, 0))
}

@(private)
// Set width of grid cells.
// Flex and grow sizes are relative to the column/row size, not the parent size.
grid_distribute_widths :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	col_gap := element.col_gap > 0 ? element.col_gap : element.gap

	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		start_col := child_element._grid_col_index
		col_span := max(child_element.col_span, 1)

		// calculate cell width across its column span
		cell_width: f32 = 0
		for i := 0; i < col_span; i += 1 {
			index := start_col + i
			if index < element.cols {
				cell_width += element._grid_col_sizes[index]
				if i < col_span - 1 {
					cell_width += col_gap
				}
			}
		}

		available := max(cell_width - x_margin(child_element), 0)

		if child_element.width.type == .Percent {
			child_element._size.x = available * child_element.width.value
		} else if child_element.width.type == .Grow {
			child_element._size.x = available
		}

		min_allowed := max(
			child_element.width.min,
			x_padding(child_element) + x_border(child_element),
		)
		max_allowed :=
			child_element.width.max > 0 ? min(child_element.width.max, available) : available
		child_element._size.x = clamp(child_element._size.x, min_allowed, max_allowed)

		child = child_element.next
	}
}

@(private)
// Calculate row heights. NOT the heights of the grid cells.
grid_fit_rows :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	element.rows = grid_used_rows(ctx, element)

	for i in 0 ..< element.rows {
		track := element.row_sizes[min(i, len(element.row_sizes) - 1)]
		if track.type == .Fixed {
			height := grid_clamp_size(track.value, track)
			element._grid_row_sizes[i] = height
		} else if track.type == .Fit || track.type == .Grow {
			max_height: f32 = 0
			child := element.children
			for child != 0 {
				child_element := &elements[child]
				if child_element.position.type != .Absolute &&
				   child_element.position.type != .Fixed &&
				   child_element._grid_row_index == i &&
				   child_element.row_span <= 1 {
					height := child_element._size.y + y_margin(child_element)
					if height > max_height {
						max_height = height
					}
				}
				child = child_element.next
			}
			max_height = grid_clamp_size(max_height, track)
			element._grid_row_sizes[i] = max_height
		}
	}
}

@(private)
// Set grid container height to fit its rows (not grid cells)
grid_fit_height :: proc(ctx: ^Context, element: ^Element) {
	if element.height.type == .Fixed || element.height.type == .Percent {
		return
	}

	row_gap := element.row_gap > 0 ? element.row_gap : element.gap
	total: f32 = 0
	for i in 0 ..< element.rows {
		total += element._grid_row_sizes[i]
	}
	gaps := row_gap * f32(max(element.rows - 1, 0))
	total += gaps + y_padding(element) + y_border(element)

	min := max(element.height.min, y_padding(element) + y_border(element))
	max := element.height.max > 0 ? element.height.max : total
	total = clamp(total, min, max)
	element._size.y = total
}

@(private)
// Set percent and grow row heights.
grid_distribute_rows :: proc(ctx: ^Context, element: ^Element) {
	element_inner_height := inner_height(element)
	gap := element.row_gap > 0 ? element.row_gap : element.gap
	gaps := gap * f32(max(element.rows - 1, 0))
	element_inner_height -= gaps

	sum_with_margins: f32 = 0
	total_weight: f32 = 0
	for i in 0 ..< element.rows {
		track := element.row_sizes[min(i, len(element.row_sizes) - 1)]
		base: f32 = 0

		switch track.type {
		case .Fixed:
			base = element._grid_row_sizes[i]
		case .Percent:
			base = grid_clamp_size(element_inner_height * track.value, track)
			element._grid_row_sizes[i] = base
		case .Fit:
			base = element._grid_row_sizes[i]
		case .Grow:
			base = element._grid_row_sizes[i]
			weight := track.value
			if weight <= 0 {weight = 1}
			total_weight += weight
		}
		sum_with_margins += base + y_margin(element)
	}

	remaining := element_inner_height - sum_with_margins
	if remaining > 0 && total_weight > 0 {
		for i in 0 ..< element.rows {
			track := element.row_sizes[min(i, len(element.row_sizes) - 1)]
			if track.type == .Grow {
				weight := track.value
				if weight <= 0 {weight = 1}
				element._grid_row_sizes[i] += remaining * (weight / total_weight)
			}
		}
	}

	offset: f32 = 0
	total_height: f32 = 0
	for i in 0 ..< element.rows {
		element._grid_row_offsets[i] = offset
		offset += element._grid_row_sizes[i] + gap
		total_height += element._grid_row_sizes[i]
	}
	element._content_size.y = total_height + gap * f32(max(element.rows - 1, 0))
}

@(private)
// Set heights of grid cells.
// Flex and grow sizes are relative to the column/row size, not the parent size.
grid_distribute_heights :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	row_gap := element.row_gap > 0 ? element.row_gap : element.gap

	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		start_row := child_element._grid_row_index
		row_span := max(child_element.row_span, 1)

		cell_height: f32 = 0
		for i := 0; i < row_span; i += 1 {
			index := start_row + i
			if index < element.rows {
				cell_height += element._grid_row_sizes[index]
				if i < row_span - 1 {
					cell_height += row_gap
				}
			}
		}

		available := max(cell_height - y_margin(child_element), 0)

		if child_element.height.type == .Percent {
			child_element._size.y = available * child_element.height.value
		} else if child_element.height.type == .Grow {
			child_element._size.y = available
		}

		min_allowed := max(
			child_element.height.min,
			y_padding(child_element) + y_border(child_element),
		)
		max_allowed :=
			child_element.height.max > 0 ? min(child_element.height.max, available) : available
		child_element._size.y = clamp(child_element._size.y, min_allowed, max_allowed)

		child = child_element.next
	}
}

@(private)
grid_compute_position :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	start_x := element.padding.left + element.border.left
	start_y := element.padding.top + element.border.top

	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		col := clamp(child_element._grid_col_index, 0, element.cols - 1)
		row := clamp(child_element._grid_row_index, 0, element.rows - 1)

		x := start_x + element._grid_col_offsets[col] + child_element.margin.left
		y := start_y + element._grid_row_offsets[row] + child_element.margin.top

		child_element._position = element._position + {x, y}
		child_element._position -= get_scroll_offset(element)

		if child_element.position.type == .Relative {
			child_element._position += child_element.position.value
		}

		child = child_element.next
	}
}

@(private = "file")
grid_used_columns :: proc(ctx: ^Context, element: ^Element) -> int {
	elements := &ctx.elements[current_buffer(ctx)]
	used := 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type != .Absolute && child_element.position.type != .Fixed {
			span := max(child_element.col_span, 1)
			end_index := child_element._grid_col_index + span
			used = max(used, end_index)
		}
		child = child_element.next
	}
	return used
}

@(private = "file")
grid_used_rows :: proc(ctx: ^Context, element: ^Element) -> int {
	elements := &ctx.elements[current_buffer(ctx)]
	used := 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type != .Absolute && child_element.position.type != .Fixed {
			span := max(child_element.row_span, 1)
			end_index := child_element._grid_row_index + span
			used = max(used, end_index)
		}
		child = child_element.next
	}
	return used
}

@(private = "file")
grid_clamp_size :: proc(size: f32, track: Size) -> f32 {
	size := max(size, track.min)
	if track.max > 0 {
		size = min(size, track.max)
	}
	return size
}

@(private = "file")
increment_column :: proc(col: int, row: int, col_limit: int, row_limit: int) -> (int, int) {
	col := col
	row := row
	if col >= col_limit {
		col = 0
		row += 1
		if row >= row_limit {
			row = 0
		}
	}
	return col, row
}

@(private = "file")
increment_row :: proc(col: int, row: int, col_limit: int, row_limit: int) -> (int, int) {
	col := col
	row := row
	if row >= row_limit {
		row = 0
		col += 1
		if col >= col_limit {
			col = 0
		}
	}
	return col, row
}
