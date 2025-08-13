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

	// TODO: remove this, should be handled in compute_sizes pass
	// if element.layout == .Flex {
	// 	// size has already been computed by the children
	// 	children := element.children_count
	// 	gap := element.gap * f32(children - 1)

	// 	if element.direction == .LeftToRight {
	// 		element._size.x += gap
	// 	} else {
	// 		element._size.y += gap
	// 	}
	// }
}

// compute_sizes :: proc(ctx: ^Context, index: int) {
// 	elem := &ctx.elements[index]
// 	child := elem.children
// 	for child != 0 {
// 		compute_sizes(ctx, child)
// 		child = ctx.elements[child].next
// 	}

// 	if index == 0 || elem.layout != .Flex {
// 		return
// 	}

// 	dir := elem.direction
// 	// TODO
// }

size_pass_x :: proc(ctx: ^Context) {
	x_top_down_width(ctx, 0)
	x_bottom_up_flex(ctx, 0)
}

x_top_down_width :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]
	if element.layout != .Flex {
		return
	}

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
		x_top_down_width(ctx, child)
		child = ctx.elements[child].next
	}
}

x_bottom_up_flex :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	child := element.children
	for child != 0 {
		x_bottom_up_flex(ctx, child)
		child = ctx.elements[child].next
	}

	if element.layout != .Flex {
		return
	}

	if element.direction == .LeftToRight {
		inner_width := inner_width(element)
		gaps := element.gap * f32(max(element.children_count - 1, 0))

		sum_base_no_margins: f32 = 0
		sum_with_margins: f32 = 0
		total_weight: f32 = 0

		child = element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			width_size := child_element.width
			base: f32 = 0

			switch width_size.type {
			case .Fixed:
				base = width_size.value
			case .Percent:
				definite := element.width.type == .Fixed || element.width.type == .Percent
				if definite {
					base = inner_width * width_size.value
				} else {
					base = 0
				}
			case .Fit:
				base = child_element._size.x
			case .Grow:
				base = child_element._size.x
				w := width_size.value
				if w <= 0 {w = 1}
				total_weight += w
			}

			child_element._size.x = base
			sum_base_no_margins += base
			sum_with_margins += base + x_margin(child_element)
			child = child_element.next
		}

		parent_explicit := element.width.type == .Fixed || element.width.type == .Percent

		remaining := inner_width - sum_with_margins - gaps
		if parent_explicit && remaining > 0 && total_weight > 0 {
			child = element.children
			for child != 0 {
				child_element := &ctx.elements[child]
				width_size := child_element.width
				if width_size.type == .Grow {
					width := width_size.value
					add := remaining * (width / total_weight)
					child_element._size.x += add
				}
				child = child_element.next
			}
		}

		if !parent_explicit {
			element._size.x = sum_base_no_margins + gaps + x_padding(element)
		}
	} else {
		inner_width := inner_width(element)

		max_child_w_no_margins: f32 = 0

		child = element.children
		for child != 0 {
			child_element := &ctx.elements[child]
			width_size := child_element.width
			width: f32 = 0
			switch width_size.type {
			case .Fixed:
				width = width_size.value
			case .Percent:
				definite := element.width.type == .Fixed || element.width.type == .Percent
				if definite {
					width = inner_width * width_size.value
				} else {
					width = 0
				}
			case .Grow:
				width = inner_width
			case .Fit:
				width = child_element._size.x
			}

			child_element._size.x = width
			child = child_element.next
		}

		if !(element.width.type == .Fixed || element.width.type == .Percent) {
			element._size.x = max_child_w_no_margins + x_padding(element)
		}
	}
}

text_wrap_pass :: proc(ctx: ^Context) {}
propagate_heights :: proc(ctx: ^Context) {}
size_pass_y :: proc(ctx: ^Context) {}
cross_axis_finalize :: proc(ctx: ^Context) {}
