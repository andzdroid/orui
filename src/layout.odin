package orui

@(private)
compute_layout :: proc(ctx: ^Context, index: int) {
	elements := &ctx.elements[current_buffer(ctx)]
	element := &elements[index]
	compute_position(ctx, element)

	child := element.children
	for child != 0 {
		compute_layout(ctx, child)
		child = elements[child].next
	}
}

@(private)
compute_position :: proc(ctx: ^Context, element: ^Element) {
	elements := &ctx.elements[current_buffer(ctx)]
	parent := &elements[element.parent]
	placement_parent := parent
	base_position := element._position

	if element.position.type == .Fixed {
		placement_parent = &elements[0]
		element._position = element.position.value
		base_position = element._position
		apply_placement(element, placement_parent)
	}

	if element.position.type == .Absolute {
		// absolute position is relative to the nearest parent with a non-auto position
		ancestor := element.parent
		nearest := &elements[ancestor]
		for ancestor != 0 {
			parent_element := &elements[ancestor]
			if parent_element.position.type != .Auto {
				nearest = parent_element
				break
			}
			ancestor = parent_element.parent
		}

		if ancestor == 0 {
			placement_parent = &elements[0]
			element._position = element.position.value
			base_position = element._position
			apply_placement(element, placement_parent)
		} else {
			placement_parent = nearest
			element._position = nearest._position + element.position.value
			base_position = element._position
			apply_placement(element, placement_parent)
		}
	}

	if element.position.type == .Relative {
		base_position = element._position
		apply_placement(element, placement_parent)
	}

	if element.position.type != .Auto && element.bounds.target == .Window {
		apply_bounds(element, &elements[0], placement_parent, base_position.x, base_position.y)
	}

	if element.scroll.direction != .None {
		clamp_scroll_offset(element)
	}

	if element.layout == .Flex {
		flex_compute_position(ctx, element)
	} else if element.layout == .Grid {
		grid_compute_position(ctx, element)
	}
}

@(private)
calculate_alignment_offset :: proc(
	alignment: ContentAlignment,
	container_size: f32,
	content_size: f32,
) -> f32 {
	switch alignment {
	case .Start:
		return 0
	case .Center:
		return (container_size - content_size) / 2
	case .End:
		return container_size - content_size
	}
	return 0
}

@(private)
apply_placement :: proc(element: ^Element, parent: ^Element) {
	origin_offset := element.placement.origin * element._size
	anchor_offset := element.placement.anchor * parent._size
	element._position += anchor_offset - origin_offset
}

@(private)
apply_bounds :: proc(
	element: ^Element,
	window: ^Element,
	parent: ^Element,
	base_x: f32,
	base_y: f32,
) {
	left := window._position.x + element.bounds.padding
	top := window._position.y + element.bounds.padding
	right := window._position.x + window._size.x - element.bounds.padding
	bottom := window._position.y + window._size.y - element.bounds.padding

	if element.bounds.mode == .Flip {
		overflow_x := element._position.x < left || element._position.x + element._size.x > right
		overflow_y := element._position.y < top || element._position.y + element._size.y > bottom

		if overflow_x {
			element._position.x =
				base_x -
				2 * element.position.value.x +
				(1 - element.placement.anchor.x) * parent._size.x -
				(1 - element.placement.origin.x) * element._size.x
		}

		if overflow_y {
			element._position.y =
				base_y -
				2 * element.position.value.y +
				(1 - element.placement.anchor.y) * parent._size.y -
				(1 - element.placement.origin.y) * element._size.y
		}
	}

	if element.bounds.mode == .Shift || element.bounds.mode == .Flip {
		max_x := max(left, right - element._size.x)
		max_y := max(top, bottom - element._size.y)
		element._position.x = clamp(element._position.x, left, max_x)
		element._position.y = clamp(element._position.y, top, max_y)
	}
}
