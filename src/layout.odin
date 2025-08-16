package orui

sort_roots_by_z :: proc(ctx: ^Context) {}

compute_layout :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]
	compute_element_position(ctx, element)

	child := element.children
	for child != 0 {
		compute_layout(ctx, child)
		child = ctx.elements[child].next
	}
}

compute_element_position :: proc(ctx: ^Context, element: ^Element) {
	parent := &ctx.elements[element.parent]

	if element.position.type == .Absolute {
		element._position = element.position.value
	}

	if element.layout == .Flex {
		// log.infof("layout flex children of %v", element)
		child := element.children
		x := element.padding.left
		y := element.padding.top
		for child != 0 {
			child_element := &ctx.elements[child]

			if child_element.position.type == .Absolute {
				child = child_element.next
				continue
			}

			if element.direction == .LeftToRight {
				x += child_element.margin.left
				y = element.padding.top + child_element.margin.top
			} else {
				x = element.padding.left + child_element.margin.left
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

			child = child_element.next
		}
	}
}
