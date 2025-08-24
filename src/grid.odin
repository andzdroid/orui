package orui

@(private)
grid_distribute_widths :: proc(ctx: ^Context, element: ^Element) {
	grid_auto_place(ctx, element)
	grid_resolve_columns(ctx, element)

	col_gap := element.col_gap > 0 ? element.col_gap : element.gap
	col_count := element.cols

	child := element.children
	for child != 0 {
		child_element := &ctx.elements[child]
		if child_element.position.type == .Absolute {
			child = child_element.next
			continue
		}

		start_col := child_element._grid_col_index
		col_span := max(child_element.col_span, 1)

		area_width: f32 = 0
		for i := 0; i < col_span; i += 1 {
			index := start_col + i
			if index < col_count {
				area_width += element._grid_col_sizes[index]
				if i < col_span - 1 {
					area_width += col_gap
				}
			}
		}

		available := max(area_width - x_margin(child_element), 0)

		switch child_element.width.type {
		case .Percent:
			child_element._size.x = available * child_element.width.value
		case .Grow:
			child_element._size.x = available
		case .Fixed:
		case .Fit:
		}

		min_allowed := max(
			child_element.width.min,
			x_padding(child_element) + x_border(child_element),
		)
		if child_element._size.x < min_allowed {
			child_element._size.x = min_allowed
		}
		max_allowed := available
		if child_element.width.max > 0 && child_element.width.max < max_allowed {
			max_allowed = child_element.width.max
		}
		if child_element._size.x > max_allowed {
			child_element._size.x = max_allowed
		}

		child = child_element.next
	}
}

@(private)
grid_distribute_heights :: proc(ctx: ^Context, element: ^Element) {
	grid_resolve_rows(ctx, element)

	row_gap := element.row_gap > 0 ? element.row_gap : element.gap
	row_count := element.rows

	child := element.children
	for child != 0 {
		child_element := &ctx.elements[child]
		if child_element.position.type == .Absolute {
			child = child_element.next
			continue
		}

		start_row := child_element._grid_row_index
		row_span := max(child_element.row_span, 1)

		area_height: f32 = 0
		for i := 0; i < row_span; i += 1 {
			index := start_row + i
			if index < row_count {
				area_height += element._grid_row_sizes[index]
				if i < row_span - 1 {
					area_height += row_gap
				}
			}
		}

		available := max(area_height - y_margin(child_element), 0)

		switch child_element.height.type {
		case .Percent:
			child_element._size.y = available * child_element.height.value
		case .Grow:
			child_element._size.y = available
		case .Fixed:
		case .Fit:
		}

		min_allowed := max(
			child_element.height.min,
			y_padding(child_element) + y_border(child_element),
		)
		if child_element._size.y < min_allowed {
			child_element._size.y = min_allowed
		}
		max_allowed := available
		if child_element.height.max > 0 && child_element.height.max < max_allowed {
			max_allowed = child_element.height.max
		}
		if child_element._size.y > max_allowed {
			child_element._size.y = max_allowed
		}

		child = child_element.next
	}
}

@(private)
grid_compute_position :: proc(ctx: ^Context, element: ^Element) {
	start_x := element.padding.left + element.border.left
	start_y := element.padding.top + element.border.top

	col_count := element.cols
	row_count := element.rows

	child := element.children
	for child != 0 {
		child_element := &ctx.elements[child]
		if child_element.position.type == .Absolute {
			child = child_element.next
			continue
		}

		col := clamp(child_element._grid_col_index, 0, col_count - 1)
		row := clamp(child_element._grid_row_index, 0, row_count - 1)

		x := start_x + element._grid_col_offsets[col] + child_element.margin.left
		y := start_y + element._grid_row_offsets[row] + child_element.margin.top

		child_element._position = element._position + {x, y}
		if child_element.position.type == .Relative {
			child_element._position += child_element.position.value
		}

		child = child_element.next
	}
}

@(private = "file")
grid_used_columns :: proc(ctx: ^Context, element: ^Element) -> int {
	used := 0
	child := element.children
	for child != 0 {
		child_element := &ctx.elements[child]
		if child_element.position.type != .Absolute {
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
	used := 0
	child := element.children
	for child != 0 {
		child_element := &ctx.elements[child]
		if child_element.position.type != .Absolute {
			span := max(child_element.row_span, 1)
			end_index := child_element._grid_row_index + span
			used = max(used, end_index)
		}
		child = child_element.next
	}
	return used
}

@(private = "file")
grid_auto_place :: proc(ctx: ^Context, element: ^Element) {
	col_limit := element.cols > 0 ? clamp(element.cols, 1, MAX_GRID_TRACKS) : MAX_GRID_TRACKS
	row_limit := element.rows > 0 ? clamp(element.rows, 1, MAX_GRID_TRACKS) : MAX_GRID_TRACKS

	occupied: [MAX_GRID_TRACKS * MAX_GRID_TRACKS]bool
	for i in 0 ..< MAX_GRID_TRACKS * MAX_GRID_TRACKS {
		occupied[i] = false
	}

	current_row := 0
	current_col := 0

	child := element.children
	for child != 0 {
		child_element := &ctx.elements[child]
		if child_element.position.type == .Absolute {
			child = child_element.next
			continue
		}

		col_span := max(child_element.col_span, 1)
		row_span := max(child_element.row_span, 1)

		row := current_row
		col := current_col
		found := false
		attempts := 0
		max_attempts := MAX_GRID_TRACKS * MAX_GRID_TRACKS
		for attempts < max_attempts {
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
					if occupied[r * MAX_GRID_TRACKS + c] {
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

		for r in row ..< row + row_span {
			if r >= row_limit {
				break
			}
			for c in col ..< col + col_span {
				if c >= col_limit {
					break
				}
				occupied[r * MAX_GRID_TRACKS + c] = true
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

@(private = "file")
grid_resolve_columns :: proc(ctx: ^Context, element: ^Element) {
	col_count := element.cols > 0 ? element.cols : grid_used_columns(ctx, element)
	col_count = clamp(col_count, 1, MAX_GRID_TRACKS)
	element.cols = col_count

	inner_width := inner_width(element)
	col_gap := element.col_gap > 0 ? element.col_gap : element.gap

	for i in 0 ..< col_count {
		track := element.col_sizes[i]
		if track.type == .Fixed {
			width := track.value
			width = grid_clamp_size(width, track)
			element._grid_col_sizes[i] = width
		} else if track.type == .Percent && inner_width > 0 {
			width := inner_width * track.value
			width = grid_clamp_size(width, track)
			element._grid_col_sizes[i] = width
		} else if track.type == .Fit {
			max_width: f32 = 0
			child := element.children
			for child != 0 {
				child_element := &ctx.elements[child]
				if child_element.position.type != .Absolute &&
				   child_element._grid_col_index == i &&
				   child_element.col_span == 1 {
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

	total_assigned: f32 = 0
	for i in 0 ..< col_count {
		total_assigned += element._grid_col_sizes[i]
	}
	total_gaps := col_gap * f32(max(col_count - 1, 0))
	remaining := inner_width - total_assigned - total_gaps
	if remaining > 0 {
		total_weight: f32 = 0
		for i in 0 ..< col_count {
			col_size := element.col_sizes[i]
			if col_size.type == .Grow {
				weight := col_size.value
				if weight <= 0 {weight = 1}
				total_weight += weight
			}
		}

		if total_weight > 0 {
			for i in 0 ..< col_count {
				col_size := element.col_sizes[i]
				if col_size.type == .Grow {
					weight := col_size.value
					if weight <= 0 {weight = 1}
					element._grid_col_sizes[i] += remaining * weight / total_weight
				}
			}
		}
	}

	offset: f32 = 0
	for i in 0 ..< col_count {
		element._grid_col_offsets[i] = offset
		offset += element._grid_col_sizes[i] + col_gap
	}
}

@(private = "file")
grid_resolve_rows :: proc(ctx: ^Context, element: ^Element) {
	row_count := element.rows > 0 ? element.rows : grid_used_rows(ctx, element)
	row_count = clamp(row_count, 1, MAX_GRID_TRACKS)
	element.rows = row_count

	inner_height := inner_height(element)
	row_gap := element.row_gap > 0 ? element.row_gap : element.gap

	for i in 0 ..< row_count {
		track := element.row_sizes[i]
		if track.type == .Fixed {
			height := track.value
			height = grid_clamp_size(height, track)
			element._grid_row_sizes[i] = height
		} else if track.type == .Percent && inner_height > 0 {
			height := inner_height * track.value
			height = grid_clamp_size(height, track)
			element._grid_row_sizes[i] = height
		} else if track.type == .Fit {
			max_height: f32 = 0
			child := element.children
			for child != 0 {
				child_element := &ctx.elements[child]
				if child_element.position.type != .Absolute &&
				   child_element._grid_row_index == i &&
				   child_element.row_span == 1 {
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

	total_assigned: f32 = 0
	for i in 0 ..< row_count {
		total_assigned += element._grid_row_sizes[i]
	}
	total_gaps := row_gap * f32(max(row_count - 1, 0))
	remaining := inner_height - total_assigned - total_gaps
	if remaining > 0 {
		total_weight: f32 = 0
		for i in 0 ..< row_count {
			row_size := element.row_sizes[i]
			if row_size.type == .Grow {
				weight := row_size.value
				if weight <= 0 {weight = 1}
				total_weight += weight
			}
		}

		if total_weight > 0 {
			for i in 0 ..< row_count {
				row_size := element.row_sizes[i]
				if row_size.type == .Grow {
					weight := row_size.value
					if weight <= 0 {weight = 1}
					element._grid_row_sizes[i] += remaining * weight / total_weight
				}
			}
		}
	}

	offset: f32 = 0
	for i in 0 ..< row_count {
		element._grid_row_offsets[i] = offset
		offset += element._grid_row_sizes[i] + row_gap
	}
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
