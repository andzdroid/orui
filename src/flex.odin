package orui

// MARK: should wrap
@(private)
flex_should_wrap :: proc(element: ^Element) -> bool {
	if element.flex_wrap != .Wrap {
		return false
	}
	if element.direction == .TopToBottom {
		// column wrapping is not supported
		return false
	}
	// don't wrap if scrolling on the main axis
	return(
		inner_width(element) > 0 &&
		element.scroll.direction != .Horizontal &&
		element.scroll.direction != .Auto \
	)
}

// MARK: fit width
@(private)
// Set width of element to fit its children
flex_fit_width :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	if element._size.x > 0 || element.width.type == .Percent {
		return
	}

	if element.direction == .LeftToRight {
		flex_fit_width_row(ctx, element)
	} else {
		flex_fit_width_column(ctx, element)
	}

	flex_clamp_width(ctx, element)
}

// MARK: fit width row
@(private)
// sum of child widths
flex_fit_width_row :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	sum: f32 = 0
	child_count := 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		child_count += 1

		if child_element.width.type == .Percent {
			child = child_element.next
			continue
		}

		sum += child_element._size.x + x_margin(child_element)
		child = child_element.next
	}
	gaps := element.gap * f32(max(child_count - 1, 0))
	element._size.x = sum + gaps + x_padding(element) + x_border(element)
}

// MARK: fit width column
@(private)
// max of child widths
flex_fit_width_column :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	max_child: f32 = 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if child_element.width.type == .Percent {
			child = child_element.next
			continue
		}

		child_width := child_element._size.x + x_margin(child_element)
		if child_width > max_child {
			max_child = child_width
		}
		child = child_element.next
	}
	element._size.x = max_child + x_padding(element) + x_border(element)
}

// MARK: distribute widths
@(private)
// Set widths of children to grow into their parent
flex_distribute_widths :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	if element.direction == .LeftToRight {
		if flex_should_wrap(element) {
			flex_distribute_widths_row_wrapped(ctx, element)
		} else {
			flex_distribute_widths_row_unwrapped(ctx, element)
		}
	} else {
		flex_distribute_widths_column(ctx, element)
	}
}

// MARK: widths row wrapped
@(private)
// split children into wrapped lines and distribute space on each line
flex_distribute_widths_row_wrapped :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	element_inner_width := inner_width(element)

	max_line_width: f32 = 0
	current_line := 0
	line_first := 0
	line_last := 0
	line_width: f32 = 0
	line_total_weight: f32 = 0
	line_child_count := 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		base: f32 = 0
		switch child_element.width.type {
		case .Fixed:
			base = child_element._size.x
		case .Percent:
			base = element_inner_width * child_element.width.value
		case .Fit:
			base = child_element._size.x
		case .Grow:
			base = child_element._size.x
		}
		child_element._size.x = base
		flex_clamp_width(ctx, child_element)

		element_width := child_element._size.x + x_margin(child_element)
		new_line_width := line_width + (line_child_count > 0 ? element.gap : 0) + element_width
		// line is full
		if line_child_count > 0 && new_line_width > element_inner_width {
			remaining := element_inner_width - line_width
			flex_distribute_widths_line(ctx, line_first, line_last, remaining, line_total_weight)
			if remaining > 0 && line_total_weight > 0 {
				// at least one grow element filled the remaining space
				line_width = element_inner_width
			}
			if line_width > max_line_width {
				max_line_width = line_width
			}

			// start new line with this child
			line_first = child
			line_last = child
			line_width = element_width
			line_total_weight =
				(child_element.width.type == .Grow ? (child_element.width.value <= 0 ? 1 : child_element.width.value) : 0)
			line_child_count = 1
			current_line += 1
			child_element._line = current_line
			child = child_element.next
			continue
		}

		// add child to current line
		if line_child_count == 0 {
			line_first = child
			line_width = element_width
			line_total_weight = 0
			line_child_count = 1
		} else {
			line_width += element.gap + element_width
			line_child_count += 1
		}
		if child_element.width.type == .Grow {
			weight := child_element.width.value
			if weight <= 0 {weight = 1}
			line_total_weight += weight
		}
		line_last = child
		child_element._line = current_line
		child = child_element.next
	}

	// finalize the last line
	if line_child_count > 0 {
		remaining := element_inner_width - line_width
		flex_distribute_widths_line(ctx, line_first, line_last, remaining, line_total_weight)
		if remaining > 0 && line_total_weight > 0 {
			// at least one grow element filled the remaining space
			line_width = element_inner_width
		}
		if line_width > max_line_width {
			max_line_width = line_width
		}
	}

	element._content_size.x = max_line_width
	element._line_count = current_line + 1
}

// MARK: widths row unwrapped
@(private)
// Sum child widths, then distribute remaining space according to weight
flex_distribute_widths_row_unwrapped :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	element_inner_width := inner_width(element)

	width: f32 = 0
	total_weight: f32 = 0
	child_count := 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		base: f32 = 0
		switch child_element.width.type {
		case .Fixed:
			base = child_element._size.x
		case .Percent:
			base = element_inner_width * child_element.width.value
		case .Fit:
			base = child_element._size.x
		case .Grow:
			base = child_element._size.x
			weight := child_element.width.value
			if weight <= 0 {weight = 1}
			total_weight += weight
		}

		child_element._size.x = base
		flex_clamp_width(ctx, child_element)
		width += child_element._size.x + x_margin(child_element)
		child_count += 1
		child = child_element.next
	}

	gaps := element.gap * f32(max(child_count - 1, 0))
	remaining := element_inner_width - width - gaps
	if remaining > 0 && total_weight > 0 {
		child = element.children
		for child != 0 {
			child_element := &elements[child]
			if child_element.width.type == .Grow {
				weight := child_element.width.value
				if weight <= 0 {weight = 1}
				add := remaining * (weight / total_weight)
				child_element._size.x += add
				flex_clamp_width(ctx, child_element)
			}
			child = child_element.next
		}
	}

	element._content_size.x = width + gaps
}

// MARK: widths column
@(private)
// Set percent and grow widths of children according to parent width
flex_distribute_widths_column :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	element_inner_width := inner_width(element)

	max_width: f32 = 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]

		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		width := child_element._size.x + x_margin(child_element)
		if width > max_width {
			max_width = width
		}

		if child_element.width.type == .Percent {
			available_width := element_inner_width - x_margin(child_element)
			child_element._size.x = available_width * child_element.width.value
		} else if child_element.width.type == .Grow {
			child_element._size.x = element_inner_width - x_margin(child_element)
		}

		flex_clamp_width(ctx, child_element)
		child = child_element.next
	}

	element._content_size.x = max_width
}

// MARK: widths line
@(private)
flex_distribute_widths_line :: proc(
	ctx: ^Context,
	first_index: int,
	last_index: int,
	remaining_space: f32,
	total_weight: f32,
) {
	if remaining_space <= 0 || total_weight <= 0 {
		return
	}

	elements := &ctx.elements[current_buffer(ctx)]
	child := first_index
	for child != 0 {
		child_element := &elements[child]

		if child_element.width.type == .Grow {
			weight := child_element.width.value
			if weight <= 0 {weight = 1}
			child_element._size.x += remaining_space * (weight / total_weight)
			flex_clamp_width(ctx, child_element)
		}

		if child == last_index {
			break
		}

		child = child_element.next
	}
}

// MARK: fit height
@(private)
// Set height of element to fit its children
flex_fit_height :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	if element._size.y > 0 || element.height.type == .Percent {
		return
	}

	if element.direction == .TopToBottom {
		flex_fit_height_column(ctx, element)
	} else {
		if flex_should_wrap(element) {
			flex_fit_height_row_wrapped(ctx, element)
		} else {
			flex_fit_height_row_unwrapped(ctx, element)
		}
	}

	flex_clamp_height(ctx, element)
}

// MARK: fit height column
@(private)
// sum of child heights
flex_fit_height_column :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	sum: f32 = 0
	child_count := 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		child_count += 1

		if child_element.height.type == .Percent {
			child = child_element.next
			continue
		}

		sum += child_element._size.y + y_margin(child_element)
		child = child_element.next
	}
	gap := element.gap * f32(max(child_count - 1, 0))
	element._size.y = sum + gap + y_padding(element) + y_border(element)
}

// MARK: fit height row wrapped
@(private)
flex_fit_height_row_wrapped :: proc(ctx: ^Context, element: ^Element) {
	if element._line_count <= 1 {
		flex_fit_height_row_unwrapped(ctx, element)
		return
	}

	elements := &ctx.elements[current_buffer(ctx)]
	element_inner_width := inner_width(element)
	total_height: f32 = 0
	current_line := 0
	line_height: f32 = 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if child_element.height.type == .Percent {
			child = child_element.next
			continue
		}

		if child_element._line != current_line {
			total_height += line_height
			line_height = 0
			current_line = child_element._line
		}

		child_height := child_element._size.y + y_margin(child_element)
		if child_height > line_height {
			line_height = child_height
		}
		child = child_element.next
	}
	total_height += line_height
	gap := element.gap * f32(element._line_count - 1)
	element._size.y = total_height + gap + y_padding(element) + y_border(element)
}

// MARK: fit height row unwrapped
@(private)
// max of child heights
flex_fit_height_row_unwrapped :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	max_child: f32 = 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if child_element.height.type == .Percent {
			child = child_element.next
			continue
		}

		child_height := child_element._size.y + y_margin(child_element)
		if child_height > max_child {
			max_child = child_height
		}
		child = child_element.next
	}
	element._size.y = max_child + y_padding(element) + y_border(element)
}

// MARK: distribute heights
@(private)
// Set heights of children to grow into their parent
flex_distribute_heights :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	if element.direction == .TopToBottom {
		flex_distribute_heights_column(ctx, element)
	} else {
		if flex_should_wrap(element) {
			flex_distribute_heights_row_wrapped(ctx, element)
		} else {
			flex_distribute_heights_row_unwrapped(ctx, element)
		}
	}
}

// MARK: heights column
@(private)
// sum child heights, then distribute remaining space according to weight
flex_distribute_heights_column :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	element_inner_height := inner_height(element)

	width: f32 = 0
	total_weight: f32 = 0
	child_count := 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		base: f32 = 0
		switch child_element.height.type {
		case .Fixed:
			base = child_element._size.y
		case .Percent:
			base = element_inner_height * child_element.height.value
		case .Fit:
			base = child_element._size.y
		case .Grow:
			base = child_element._size.y
			weight := child_element.height.value
			if weight <= 0 {weight = 1}
			total_weight += weight
		}

		child_element._size.y = base
		flex_clamp_height(ctx, child_element)
		width += child_element._size.y + y_margin(child_element)
		child_count += 1
		child = child_element.next
	}

	gaps := element.gap * f32(max(child_count - 1, 0))
	remaining := element_inner_height - width - gaps
	if remaining > 0 && total_weight > 0 {
		child = element.children
		for child != 0 {
			child_element := &elements[child]
			if child_element.height.type == .Grow {
				weight := child_element.height.value
				if weight <= 0 {weight = 1}
				add := remaining * (weight / total_weight)
				child_element._size.y += add
				flex_clamp_height(ctx, child_element)
			}
			child = child_element.next
		}
	}

	element._content_size.y = width + gaps
}

// MARK: heights row wrapped
@(private)
// 1) resolve percent heights and compute per-line max height
// 2) stretch Grow items to the max height of the line
flex_distribute_heights_row_wrapped :: proc(ctx: ^Context, element: ^Element) {
	if element._line_count <= 1 {
		flex_distribute_heights_row_unwrapped(ctx, element)
		return
	}

	elements := &ctx.elements[current_buffer(ctx)]
	element_inner_height := inner_height(element)

	total_height: f32 = 0
	current_line := 0
	line_height: f32 = 0
	line_first := 0
	line_last := 0

	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if line_first != 0 && child_element._line != current_line {
			// second pass: stretch Grow items to the line height
			flex_distribute_heights_line(ctx, line_first, line_last, line_height)
			total_height += line_height
			line_first = 0
			line_last = 0
		}

		if line_first == 0 {
			line_first = child
			current_line = child_element._line
		}

		if child_element.height.type == .Percent {
			available_height := element_inner_height - y_margin(child_element)
			child_element._size.y = available_height * child_element.height.value
			flex_clamp_height(ctx, child_element)
		}

		height := child_element._size.y + y_margin(child_element)
		if height > line_height {
			line_height = height
		}

		line_last = child
		child = child_element.next
	}

	if line_first != 0 {
		flex_distribute_heights_line(ctx, line_first, line_last, line_height)
		total_height += line_height
	}

	total_height += element.gap * f32(element._line_count - 1)
	element._content_size.y = total_height
}

// MARK: heights row unwrapped
@(private)
// set percent and grow heights of children according to parent height
flex_distribute_heights_row_unwrapped :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	element_inner_height := inner_height(element)

	max_height: f32 = 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]

		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		height := child_element._size.y + y_margin(child_element)
		if height > max_height {
			max_height = height
		}

		if child_element.height.type == .Percent {
			available_height := element_inner_height - y_margin(child_element)
			child_element._size.y = available_height * child_element.height.value
		} else if child_element.height.type == .Grow {
			child_element._size.y = element_inner_height - y_margin(child_element)
		}

		flex_clamp_height(ctx, child_element)
		child = child_element.next
	}

	element._content_size.y = max_height
}

@(private)
flex_distribute_heights_line :: proc(
	ctx: ^Context,
	first_index: int,
	last_index: int,
	line_height: f32,
) {
	elements := &ctx.elements[current_buffer(ctx)]
	child := first_index
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if child_element.height.type != .Grow {
			child = child_element.next
			continue
		}

		child_element._size.y = line_height - y_margin(child_element)
		flex_clamp_height(ctx, child_element)

		if child == last_index {
			break
		}

		child = child_element.next
	}
}

// MARK: clamp width
@(private)
flex_clamp_width :: proc(ctx: ^Context, element: ^Element) {
	if element.layout != .Flex {
		return
	}

	min := max(element.width.min, x_padding(element) + x_border(element))

	apply_max := false
	max: f32 = 0

	parent_width, parent_definite := parent_inner_width(ctx, element)
	if parent_definite {
		max = parent_width - x_margin(element)
		apply_max = true
	}

	if element.width.max > 0 {
		if apply_max {
			if element.width.max < max {
				max = element.width.max
			}
		} else {
			max = element.width.max
			apply_max = true
		}
	}

	if element._size.x < min {
		element._size.x = min
	}
	if apply_max && element._size.x > max {
		element._size.x = max
	}
}

// MARK: clamp height
@(private)
flex_clamp_height :: proc(ctx: ^Context, element: ^Element) {
	if element.layout != .Flex {
		return
	}

	min := max(element.height.min, y_padding(element) + y_border(element))

	apply_max := false
	max: f32 = 0

	parent_height, parent_definite := parent_inner_height(ctx, element)
	if parent_definite {
		max = parent_height - y_margin(element)
		apply_max = true
	}

	if element.height.max > 0 {
		if apply_max {
			if element.height.max < max {
				max = element.height.max
			}
		} else {
			max = element.height.max
			apply_max = true
		}
	}

	if element._size.y < min {
		element._size.y = min
	}
	if apply_max && element._size.y > max {
		element._size.y = max
	}
}

// MARK: compute position
@(private)
flex_compute_position :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	if element.direction == .LeftToRight {
		if flex_should_wrap(element) {
			flex_compute_position_row_wrapped(ctx, element)
		} else {
			flex_compute_position_row_unwrapped(ctx, element)
		}
	} else {
		if flex_should_wrap(element) {
			flex_compute_position_column_wrapped(ctx, element)
		} else {
			flex_compute_position_column_unwrapped(ctx, element)
		}
	}
}

// MARK: position row unwrapped
@(private)
flex_compute_position_row_unwrapped :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	total_size, child_count := _content_size(ctx, element)
	available_space := inner_width(element) - total_size
	main_axis_offset := main_offset(element.align_main, available_space, child_count)
	child := element.children
	x := element.padding.left + element.border.left + main_axis_offset.initial
	index := 0
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if index > 0 {
			x += main_axis_offset.between
		}

		x += child_element.margin.left
		y :=
			element.padding.top +
			element.border.top +
			cross_offset(
				element.align_cross,
				inner_height(element),
				child_element._size.y + y_margin(child_element),
				child_element.margin.top,
			)
		child_element._position = element._position + {x, y}

		if child_element.position.type == .Relative {
			child_element._position += child_element.position.value
		}

		child_element._position -= get_scroll_offset(element)
		x += child_element._size.x + element.gap + child_element.margin.right
		index += 1
		child = child_element.next
	}
}

// MARK: position column unwrapped
@(private)
flex_compute_position_column_unwrapped :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	total_size, child_count := _content_size(ctx, element)
	available_space := inner_height(element) - total_size
	main_axis_offset := main_offset(element.align_main, available_space, child_count)
	child := element.children
	y := element.padding.top + element.border.top + main_axis_offset.initial
	index := 0
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if index > 0 {
			y += main_axis_offset.between
		}

		x :=
			element.padding.left +
			element.border.left +
			cross_offset(
				element.align_cross,
				inner_width(element),
				child_element._size.x + x_margin(child_element),
				child_element.margin.left,
			)
		y += child_element.margin.top
		child_element._position = element._position + {x, y}

		if child_element.position.type == .Relative {
			child_element._position += child_element.position.value
		}

		child_element._position -= get_scroll_offset(element)
		y += child_element._size.y + element.gap + child_element.margin.bottom
		index += 1
		child = child_element.next
	}
}

// MARK: position row wrapped
@(private)
flex_compute_position_row_wrapped :: proc(ctx: ^Context, element: ^Element) {
	if element._line_count <= 1 {
		flex_compute_position_row_unwrapped(ctx, element)
		return
	}

	elements := &ctx.elements[current_buffer(ctx)]
	element_inner_width := inner_width(element)
	available := inner_height(element) - element._content_size.y
	group_offset := main_offset(element.align_content, available, element._line_count)
	line_y_offset := group_offset.initial

	current_line := 0
	line_first := 0
	line_last := 0
	line_child_count := 0
	line_width: f32 = 0
	line_height: f32 = 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if line_first != 0 && child_element._line != current_line {
			flex_compute_position_row_line(
				ctx,
				element,
				line_first,
				line_last,
				line_width,
				line_height,
				line_child_count,
				line_y_offset,
			)

			// next line
			line_y_offset += line_height + element.gap + group_offset.between
			line_first = 0
			line_last = 0
			line_child_count = 0
			line_width = 0
			line_height = 0
		}

		if line_first == 0 {
			line_first = child
			current_line = child_element._line
		}

		if line_child_count > 0 {
			line_width += element.gap
		}
		line_width += child_element._size.x + x_margin(child_element)
		line_child_count += 1
		height := child_element._size.y + y_margin(child_element)
		if height > line_height {
			line_height = height
		}
		line_last = child
		child = child_element.next
	}

	// flush the final line
	if line_first != 0 {
		flex_compute_position_row_line(
			ctx,
			element,
			line_first,
			line_last,
			line_width,
			line_height,
			line_child_count,
			line_y_offset,
		)
	}
}

// MARK: position row line
@(private)
flex_compute_position_row_line :: proc(
	ctx: ^Context,
	element: ^Element,
	line_first: int,
	line_last: int,
	line_width: f32,
	line_height: f32,
	line_child_count: int,
	line_y_offset: f32,
) {
	elements := &ctx.elements[current_buffer(ctx)]
	main_axis_offset := main_offset(
		element.align_main,
		inner_width(element) - line_width,
		line_child_count,
	)
	x := element.padding.left + element.border.left + main_axis_offset.initial
	y_start := element.padding.top + element.border.top + line_y_offset
	index := 0
	child := line_first
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if index > 0 {
			x += main_axis_offset.between
		}

		x += child_element.margin.left
		y :=
			y_start +
			cross_offset(
				element.align_cross,
				line_height,
				child_element._size.y + y_margin(child_element),
				child_element.margin.top,
			)

		child_element._position = element._position + {x, y}
		if child_element.position.type == .Relative {
			child_element._position += child_element.position.value
		}
		child_element._position -= get_scroll_offset(element)

		x += child_element._size.x + element.gap + child_element.margin.right
		index += 1
		if child == line_last {
			break
		}
		child = child_element.next
	}
}

// MARK: position column wrapped
@(private)
flex_compute_position_column_wrapped :: proc(ctx: ^Context, element: ^Element) {
	if element._line_count <= 1 {
		flex_compute_position_column_unwrapped(ctx, element)
		return
	}

	elements := &ctx.elements[current_buffer(ctx)]
	element_inner_height := inner_height(element)
	available := inner_width(element) - element._content_size.x
	group_offset := main_offset(element.align_content, available, element._line_count)
	line_x_offset: f32 = group_offset.initial

	current_line := 0
	line_first := 0
	line_last := 0
	line_child_count := 0
	line_height: f32 = 0
	line_width: f32 = 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if line_first != 0 && child_element._line != current_line {
			flex_compute_position_column_line(
				ctx,
				element,
				line_first,
				line_last,
				line_height,
				line_width,
				line_child_count,
				line_x_offset,
			)

			// next line
			line_x_offset += line_width + element.gap + group_offset.between
			line_first = 0
			line_last = 0
			line_child_count = 0
			line_height = 0
			line_width = 0
		}

		if line_first == 0 {
			line_first = child
			current_line = child_element._line
		}

		if line_child_count > 0 {
			line_height += element.gap
		}
		line_height += child_element._size.y + y_margin(child_element)
		line_child_count += 1
		width := child_element._size.x + x_margin(child_element)
		if width > line_width {
			line_width = width
		}
		line_last = child
		child = child_element.next
	}

	// flush the final column
	if line_first != 0 {
		flex_compute_position_column_line(
			ctx,
			element,
			line_first,
			line_last,
			line_height,
			line_width,
			line_child_count,
			line_x_offset,
		)
	}
}

// MARK: position column line
@(private)
flex_compute_position_column_line :: proc(
	ctx: ^Context,
	element: ^Element,
	line_first: int,
	line_last: int,
	line_height: f32,
	line_width: f32,
	line_child_count: int,
	line_x_offset: f32,
) {
	elements := &ctx.elements[current_buffer(ctx)]
	main_axis_offset := main_offset(
		element.align_main,
		inner_height(element) - line_height,
		line_child_count,
	)
	y := element.padding.top + element.border.top + main_axis_offset.initial
	x_start := element.padding.left + element.border.left + line_x_offset
	index := 0
	child := line_first
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type == .Absolute || child_element.position.type != .Fixed {
			child = child_element.next
			continue
		}

		if index > 0 {
			y += main_axis_offset.between
		}

		y += child_element.margin.top
		x :=
			x_start +
			cross_offset(
				element.align_cross,
				line_width,
				child_element._size.x + x_margin(child_element),
				child_element.margin.left,
			)

		child_element._position = element._position + {x, y}
		if child_element.position.type == .Relative {
			child_element._position += child_element.position.value
		}
		child_element._position -= get_scroll_offset(element)

		y += child_element._size.y + element.gap + child_element.margin.bottom
		index += 1
		if child == line_last {
			break
		}
		child = child_element.next
	}
}

@(private = "file")
_content_size :: proc(ctx: ^Context, element: ^Element) -> (f32, int) {
	elements := &ctx.elements[current_buffer(ctx)]
	size: f32 = 0
	count := 0
	child := element.children
	for child != 0 {
		child_element := &elements[child]
		if child_element.position.type != .Absolute && child_element.position.type != .Fixed {
			count += 1
			if element.direction == .LeftToRight {
				size += child_element._size.x + x_margin(child_element)
			} else {
				size += child_element._size.y + y_margin(child_element)
			}
		}
		child = child_element.next
	}

	gap := element.gap * f32(count - 1)
	return size + gap, count
}

@(private)
MainAxisOffset :: struct {
	initial: f32,
	between: f32,
}

// MARK: main offset
@(private)
main_offset :: proc(
	alignment: MainAlignment,
	available_space: f32,
	child_count: int,
) -> MainAxisOffset {
	if available_space <= 0 {
		return {}
	}

	switch alignment {
	case .Start:
		return {0, 0}
	case .End:
		return {available_space, 0}
	case .Center:
		return {available_space / 2, 0}
	case .SpaceBetween:
		if child_count <= 1 {
			return {0, 0}
		}
		return {0, available_space / f32(child_count - 1)}
	case .SpaceAround:
		if child_count == 0 {
			return {0, 0}
		}
		space_per_child := available_space / f32(child_count)
		return {space_per_child / 2, space_per_child}
	case .SpaceEvenly:
		if child_count == 0 {
			return {0, 0}
		}
		space_per_gap := available_space / f32(child_count + 1)
		return {space_per_gap, space_per_gap}
	}
	return {}
}

// MARK: cross offset
@(private)
cross_offset :: proc(
	alignment: CrossAlignment,
	available_space: f32,
	child_size: f32,
	child_margin: f32,
) -> f32 {
	switch alignment {
	case .Start:
		return child_margin
	case .End:
		return available_space - child_size + child_margin
	case .Center:
		return (available_space - child_size) / 2 + child_margin
	}
	return 0
}
