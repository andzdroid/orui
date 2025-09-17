package orui

@(private)
// Set width of element to fit its children
flex_fit_width :: proc(ctx: ^Context, element: ^Element) {
	if element._size.x > 0 || element.width.type == .Percent {
		return
	}

	if element.direction == .LeftToRight {
		// sum of child widths
		sum: f32 = 0
		child_count := 0
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]
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
	} else {
		// max of child widths
		max_child: f32 = 0
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]
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

	flex_clamp_width(ctx, element)
}

@(private)
// Set widths of children to grow into their parent
flex_distribute_widths :: proc(ctx: ^Context, element: ^Element) {
	if element.direction == .LeftToRight {
		// sum child widths, then distribute remaining space according to weight
		element_inner_width := inner_width(element)

		sum_with_margins: f32 = 0
		total_weight: f32 = 0
		child_count := 0
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]
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
			sum_with_margins += child_element._size.x + x_margin(child_element)
			child_count += 1
			child = child_element.next
		}

		gaps := element.gap * f32(max(child_count - 1, 0))
		remaining := element_inner_width - sum_with_margins - gaps
		if remaining > 0 && total_weight > 0 {
			child = element.children
			for child != 0 {
				child_element := &ctx.elements[child]
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

		element._content_size.x = sum_with_margins + gaps
	} else {
		// set percent and grow widths of children according to parent width
		element_inner_width := inner_width(element)

		max_width: f32 = 0
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]

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
}

@(private)
// Set height of element to fit its children
flex_fit_height :: proc(ctx: ^Context, element: ^Element) {
	if element._size.y > 0 || element.height.type == .Percent {
		return
	}

	if element.direction == .TopToBottom {
		// sum of child heights
		sum: f32 = 0
		child_count := 0
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]
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
	} else {
		// max of child heights
		max_child: f32 = 0
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]
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

	flex_clamp_height(ctx, element)
}

@(private)
// Set heights of children to grow into their parent
flex_distribute_heights :: proc(ctx: ^Context, element: ^Element) {
	if element.direction == .TopToBottom {
		// sum child heights, then distribute remaining space according to weight
		element_inner_height := inner_height(element)

		sum_with_margins: f32 = 0
		total_weight: f32 = 0
		child_count := 0
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]
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
			sum_with_margins += child_element._size.y + y_margin(child_element)
			child_count += 1
			child = child_element.next
		}

		gaps := element.gap * f32(max(child_count - 1, 0))
		remaining := element_inner_height - sum_with_margins - gaps
		if remaining > 0 && total_weight > 0 {
			child = element.children
			for child != 0 {
				child_element := &ctx.elements[child]
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

		element._content_size.y = sum_with_margins + gaps
	} else {
		// set percent and grow heights of children according to parent height
		element_inner_height := inner_height(element)

		max_height: f32 = 0
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]

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
}

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

@(private)
flex_compute_position :: proc(ctx: ^Context, element: ^Element) {
	total_size, child_count := content_size(ctx, element)
	available_space := inner_main(element) - total_size

	main_axis_offset := main_offset(element.align_main, available_space, child_count)

	child := element.children
	x := element.padding.left + element.border.left + main_axis_offset.initial
	y := element.padding.top + element.border.top + main_axis_offset.initial
	index := 0
	for child != 0 {
		child_element := &ctx.elements[child]

		if child_element.position.type == .Absolute || child_element.position.type == .Fixed {
			child = child_element.next
			continue
		}

		if index > 0 {
			if element.direction == .LeftToRight {
				x += main_axis_offset.between
			} else {
				y += main_axis_offset.between
			}
		}

		if element.direction == .LeftToRight {
			x += child_element.margin.left
			y = cross_offset(element, child_element)
		} else {
			x = cross_offset(element, child_element)
			y += child_element.margin.top
		}

		child_element._position = element._position + {x, y}

		if child_element.position.type == .Relative {
			child_element._position += child_element.position.value
		}

		child_element._position -= get_scroll_offset(element)

		if element.direction == .LeftToRight {
			x += child_element._size.x + element.gap + child_element.margin.right
		} else {
			y += child_element._size.y + element.gap + child_element.margin.bottom
		}

		index += 1
		child = child_element.next
	}
}

@(private)
content_size :: proc(ctx: ^Context, element: ^Element) -> (f32, int) {
	size: f32 = 0
	count := 0
	child := element.children
	for child != 0 {
		child_element := &ctx.elements[child]
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

@(private)
main_offset :: proc(
	alignment: MainAlignment,
	available_space: f32,
	child_count: int,
) -> MainAxisOffset {
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

@(private)
cross_offset :: proc(parent: ^Element, child: ^Element) -> f32 {
	if parent.direction == .LeftToRight {
		available_height := inner_height(parent)
		child_height := child._size.y + y_margin(child)
		parent_offset := parent.padding.top + parent.border.top

		switch parent.align_cross {
		case .Start:
			return parent_offset + child.margin.top
		case .End:
			return parent_offset + available_height - child_height + child.margin.top
		case .Center:
			return parent_offset + (available_height - child_height) / 2 + child.margin.top
		}
	} else {
		available_width := inner_width(parent)
		child_width := child._size.x + x_margin(child)
		parent_offset := parent.padding.left + parent.border.left

		switch parent.align_cross {
		case .Start:
			return parent_offset + child.margin.left
		case .End:
			return parent_offset + available_width - child_width + child.margin.left
		case .Center:
			return parent_offset + (available_width - child_width) / 2 + child.margin.left
		}
	}
	return 0
}
