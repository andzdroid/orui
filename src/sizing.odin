package orui

import "core:log"

/*
Border/padding box: size of element (_size)
Content box: border box - padding
Margin box: border box + margin
*/

// Set fixed widths and fit widths.
fit_widths :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.width.type == .Fixed {
		element._size.x = element.width.value
	}

	child := element.children
	for child != 0 {
		fit_widths(ctx, child)
		child = ctx.elements[child].next
	}

	if element.layout != .Flex {
		return
	}

	if element._size.x > 0 || element.width.type == .Percent {
		return
	}

	if element.direction == .LeftToRight {
		// sum of child widths
		sum: f32 = 0
		gaps := element.gap * f32(max(element.children_count - 1, 0))
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			if child_element.position.type == .Absolute {
				child = child_element.next
				continue
			}

			if child_element.width.type == .Percent {
				child = child_element.next
				continue
			}

			sum += child_element._size.x + x_margin(child_element)
			child = child_element.next
		}
		element._size.x = sum + gaps + x_padding(element)
	} else {
		// max of child widths
		max_child: f32 = 0
		child = element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			if child_element.position.type == .Absolute {
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
		element._size.x = max_child + x_padding(element)
	}
}

// Set percent widths and grow widths.
distribute_widths :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.width.type == .Percent {
		percent_width, definite := parent_inner_width(ctx, element)
		if definite {
			element._size.x = percent_width * element.width.value
		}
	}

	if element.layout == .Flex {
		if element.direction == .LeftToRight {
			element_inner_width := inner_width(element)
			has_definite := element._size.x > 0

			sum_with_margins: f32 = 0
			total_weight: f32 = 0

			child := element.children
			for child != 0 {
				child_element := &ctx.elements[child]
				if child_element.position.type == .Absolute {
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
				sum_with_margins += base + x_margin(child_element)
				child = child_element.next
			}

			gaps := element.gap * f32(max(element.children_count - 1, 0))
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
					}
					child = child_element.next
				}
			}
		} else {
			element_inner_width := inner_width(element)
			has_definite := element._size.x > 0

			child := element.children
			for child != 0 {
				child_element := &ctx.elements[child]

				if child_element.position.type == .Absolute {
					child = child_element.next
					continue
				}

				if child_element.width.type == .Percent {
					available_width := element_inner_width - x_margin(child_element)
					child_element._size.x = available_width * child_element.width.value
				} else if child_element.width.type == .Grow {
					child_element._size.x = element_inner_width - x_margin(child_element)
				}

				child = child_element.next
			}
		}
	}

	child := element.children
	for child != 0 {
		distribute_widths(ctx, child)
		child = ctx.elements[child].next
	}
}

text_wrap_pass :: proc(ctx: ^Context) {}
propagate_heights :: proc(ctx: ^Context) {}

// Set fixed heights and fit heights.
fit_heights :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.height.type == .Fixed {
		element._size.y = element.height.value
	}

	child := element.children
	for child != 0 {
		fit_heights(ctx, child)
		child = ctx.elements[child].next
	}

	if element.layout != .Flex {
		return
	}

	if element._size.y > 0 || element.height.type == .Percent {
		return
	}

	if element.direction == .TopToBottom {
		// sum of child heights
		sum: f32 = 0
		gaps := element.gap * f32(max(element.children_count - 1, 0))
		child := element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			if child_element.position.type == .Absolute {
				child = child_element.next
				continue
			}

			if child_element.height.type == .Percent {
				child = child_element.next
				continue
			}

			sum += child_element._size.y + y_margin(child_element)
			child = child_element.next
		}
		element._size.y = sum + gaps + y_padding(element)
	} else {
		// max of child heights
		max_child: f32 = 0
		child = element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			if child_element.position.type == .Absolute {
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
		element._size.y = max_child + y_padding(element)
	}
}

// Set percent heights and grow heights.
distribute_heights :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.height.type == .Percent {
		percent_height, definite := parent_inner_height(ctx, element)
		if definite {
			element._size.y = percent_height * element.height.value
		}
	}

	if element.layout == .Flex {
		if element.direction == .TopToBottom {
			element_inner_height := inner_height(element)
			has_definite := element._size.y > 0

			sum_with_margins: f32 = 0
			total_weight: f32 = 0

			child := element.children
			for child != 0 {
				child_element := &ctx.elements[child]
				if child_element.position.type == .Absolute {
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
				sum_with_margins += base + y_margin(child_element)
				child = child_element.next
			}

			gaps := element.gap * f32(max(element.children_count - 1, 0))
			remaining := element_inner_height - sum_with_margins - gaps
			if remaining > 0 && total_weight > 0 {
				child = element.children
			}
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
		} else {
			element_inner_height := inner_height(element)
			has_definite := element._size.y > 0

			child := element.children
			for child != 0 {
				child_element := &ctx.elements[child]

				if child_element.position.type == .Absolute {
					child = child_element.next
					continue
				}

				if child_element.height.type == .Percent {
					available_height := element_inner_height - y_margin(child_element)
					child_element._size.y = available_height * child_element.height.value
				} else if child_element.height.type == .Grow {
					child_element._size.y = element_inner_height - y_margin(child_element)
				}

				child = child_element.next
			}
		}
	}

	child := element.children
	for child != 0 {
		distribute_heights(ctx, child)
		child = ctx.elements[child].next
	}
}

cross_axis_finalize :: proc(ctx: ^Context) {}
