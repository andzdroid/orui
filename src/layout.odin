package orui

@(private)
sort_roots_by_z :: proc(ctx: ^Context) {}

@(private)
compute_layout :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]
	compute_element_position(ctx, element)

	child := element.children
	for child != 0 {
		compute_layout(ctx, child)
		child = ctx.elements[child].next
	}
}

@(private)
compute_element_position :: proc(ctx: ^Context, element: ^Element) {
	parent := &ctx.elements[element.parent]

	if element.position.type == .Absolute {
		element._position = element.position.value
	}

	if element.layout == .Flex {
		total_size, child_count := content_size(ctx, element)
		available_space := inner_main(element) - total_size

		main_axis_offset := main_offset(element.align_main, available_space, child_count)

		child := element.children
		x := element.padding.left + main_axis_offset.initial
		y := element.padding.top + main_axis_offset.initial
		index := 0
		for child != 0 {
			child_element := &ctx.elements[child]

			if child_element.position.type == .Absolute {
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

			if element.direction == .LeftToRight {
				x += child_element._size.x + element.gap + child_element.margin.right
			} else {
				y += child_element._size.y + element.gap + child_element.margin.bottom
			}

			index += 1
			child = child_element.next
		}
	}
}

@(private)
content_size :: proc(ctx: ^Context, element: ^Element) -> (f32, int) {
	size: f32 = 0
	count := 0
	child := element.children
	for child != 0 {
		child_element := &ctx.elements[child]
		if child_element.position.type != .Absolute {
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

		switch parent.align_cross {
		case .Start:
			return parent.padding.top + child.margin.top
		case .End:
			return parent.padding.top + available_height - child_height + child.margin.top
		case .Center:
			return parent.padding.top + (available_height - child_height) / 2 + child.margin.top
		}
	} else {
		available_width := inner_width(parent)
		child_width := child._size.x + x_margin(child)

		switch parent.align_cross {
		case .Start:
			return parent.padding.left + child.margin.left
		case .End:
			return parent.padding.left + available_width - child_width + child.margin.left
		case .Center:
			return parent.padding.left + (available_width - child_width) / 2 + child.margin.left
		}
	}
	return 0
}
