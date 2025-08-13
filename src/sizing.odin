package orui

/*
Border/padding box: size of element (_size)
Content box: border box - padding
Margin box: border box + margin
*/

set_element_size :: proc(element: ^Element) {
	if element.width.type == .Fixed {
		element._size.x = element.width.value
	}

	if element.height.type == .Fixed {
		element._size.y = element.height.value
	}
}


size_pass_x :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	// Set fixed and percent widths
	if element.width.type == .Fixed {
		element._size.x = element.width.value
	} else if element.width.type == .Percent {
		parent_width, definite := parent_inner_width(ctx, element)
		if definite {
			element._size.x = parent_width * element.width.value
		}
	}

	child := element.children
	for child != 0 {
		size_pass_x(ctx, child)
		child = ctx.elements[child].next
	}

	if element.layout != .Flex {
		return
	}

	// Set flex widths
	if element.direction == .LeftToRight {
		element_inner_width := inner_width(element)
		is_width_explicit := size_is_explicit(element.width)
		gaps := element.gap * f32(max(element.children_count - 1, 0))

		sum: f32 = 0
		sum_with_margins: f32 = 0
		total_weight: f32 = 0

		child = element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			base: f32 = 0

			switch child_element.width.type {
			case .Fixed:
				base = child_element.width.value
			case .Percent:
				if is_width_explicit {
					base = element_inner_width * child_element.width.value
				} else {
					base = 0
				}
			case .Fit:
				base = child_element._size.x
			case .Grow:
				base = child_element._size.x
				width := child_element.width.value
				if width <= 0 {width = 1}
				total_weight += width
			}

			child_element._size.x = base
			sum += base
			sum_with_margins += base + x_margin(child_element)
			child = child_element.next
		}

		remaining := element_inner_width - sum_with_margins - gaps
		if is_width_explicit && remaining > 0 && total_weight > 0 {
			child = element.children
			for child != 0 {
				child_element := &ctx.elements[child]
				if child_element.width.type == .Grow {
					weight := child_element.width.value
					if weight <= 0 {weight = 1}
					add := remaining * (weight / total_weight)
					child_element._size.x += add
				}
				child = child_element.next
			}
		}

		if !is_width_explicit {
			element._size.x = sum + gaps + x_padding(element)
		}
	} else {
		inner_width := inner_width(element)
		is_width_explicit := size_is_explicit(element.width)

		max_child_width: f32 = 0

		child = element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			width: f32 = 0
			switch child_element.width.type {
			case .Fixed:
				width = child_element.width.value
			case .Percent:
				if is_width_explicit {
					width = inner_width * child_element.width.value
				} else {
					width = 0
				}
			case .Fit:
				width = child_element._size.x
			case .Grow:
				width = inner_width
			}

			child_element._size.x = width
			if width > max_child_width {
				max_child_width = width
			}
			child = child_element.next
		}

		if !is_width_explicit {
			element._size.x = max_child_width + x_padding(element)
		}
	}
}

text_wrap_pass :: proc(ctx: ^Context) {}
propagate_heights :: proc(ctx: ^Context) {}

size_pass_y :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	// Set fixed and percent heights
	if element.height.type == .Fixed {
		element._size.y = element.height.value
	} else if element.height.type == .Percent {
		parent_height, definite := parent_inner_height(ctx, element)
		if definite {
			element._size.y = parent_height * element.height.value
		}
	}

	child := element.children
	for child != 0 {
		size_pass_y(ctx, child)
		child = ctx.elements[child].next
	}

	if element.layout != .Flex {
		return
	}

	// Set flex heights
	if element.direction == .TopToBottom {
		inner_height := inner_height(element)
		is_height_explicit := size_is_explicit(element.height)
		total_gaps := element.gap * f32(max(element.children_count - 1, 0))

		sum: f32 = 0
		sum_with_margins: f32 = 0
		total_weight: f32 = 0

		child = element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			base: f32 = 0

			switch child_element.height.type {
			case .Fixed:
				base = child_element.height.value
			case .Percent:
				if is_height_explicit {
					base = inner_height * child_element.height.value
				} else {
					base = 0
				}
			case .Fit:
				base = child_element._size.y
			case .Grow:
				base = child_element._size.y
				height := child_element.height.value
				if height <= 0 {height = 1}
				total_weight += height
			}

			child_element._size.y = base
			sum += base
			sum_with_margins += base + y_margin(child_element)
			child = child_element.next
		}

		remaining := inner_height - sum_with_margins - total_gaps
		if is_height_explicit && remaining > 0 && total_weight > 0 {
			child = element.children
			for child != 0 {
				child_element := &ctx.elements[child]
				if child_element.height.type == .Grow {
					weight := child_element.height.value
					if weight <= 0 {weight = 1}
					add := remaining * (weight / total_weight)
					child_element._size.y += add
				}
				child = child_element.next
			}
		}

		if !is_height_explicit {
			element._size.y = sum + total_gaps + y_padding(element)
		}
	} else {
		element_inner_height := inner_height(element)
		is_height_explicit := size_is_explicit(element.height)

		max_child_height: f32 = 0

		child = element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			height: f32 = 0
			switch child_element.height.type {
			case .Fixed:
				height = child_element.height.value
			case .Percent:
				if is_height_explicit {
					height = element_inner_height * child_element.height.value
				} else {
					height = 0
				}
			case .Fit:
				height = child_element._size.y
			case .Grow:
				height = element_inner_height
			}

			child_element._size.y = height
			if height > max_child_height {
				max_child_height = height
			}
			child = child_element.next
		}

		if !is_height_explicit {
			element._size.y = max_child_height + y_padding(element)
		}
	}
}

cross_axis_finalize :: proc(ctx: ^Context) {}
