package orui

@(private)
compute_layout :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]
	compute_position(ctx, element)

	child := element.children
	for child != 0 {
		compute_layout(ctx, child)
		child = ctx.elements[child].next
	}
}

@(private)
compute_position :: proc(ctx: ^Context, element: ^Element) {
	parent := &ctx.elements[element.parent]

	if element.position.type == .Fixed {
		element._position = element.position.value
		apply_placement(element, &ctx.elements[0])
	}

	if element.position.type == .Absolute {
		// absolute position is relative to the nearest parent with a non-auto position
		parent := element.parent
		nearest := &ctx.elements[parent]
		for parent != 0 {
			parent_element := &ctx.elements[parent]
			if parent_element.position.type != .Auto {
				nearest = parent_element
				break
			}
			parent = parent_element.parent
		}

		if parent == 0 {
			element._position = element.position.value
			apply_placement(element, &ctx.elements[0])
		} else {
			element._position = nearest._position + element.position.value
			apply_placement(element, nearest)
		}
	}

	if element.layout == .Flex {
		flex_compute_position(ctx, element)
	} else if element.layout == .Grid {
		grid_compute_position(ctx, element)
	}

	if element.position.type == .Relative {
		element._position += element.position.value
		apply_placement(element, parent)
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
