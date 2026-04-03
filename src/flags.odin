package orui

Element_Flag :: enum {
	Needs_Width,
	Needs_Height,
	Needs_Wrap,
	Needs_Layout,
	Width_Blocked,
	Height_Blocked,
	Grid_Width_Resolved,
	Grid_Height_Resolved,
}

Element_Flags :: bit_set[Element_Flag;u16]

@(private)
set_flags :: proc(element: ^Element) {
	if element.width.type == .Percent {
		element._flags += {.Needs_Width}
	}

	if element.height.type == .Percent {
		element._flags += {.Needs_Height}
	}

	if element.has_text && element.overflow == .Wrap {
		element._flags += {.Needs_Wrap}
	}

	if element.position.type != .Auto {
		element._flags += {.Needs_Layout}
	}

	if element.scroll.direction != .None {
		element._flags += {.Needs_Layout}
	}

	switch element.layout {
	case .Flex:
		element._flags += {.Needs_Width, .Needs_Height, .Needs_Layout}
	case .Grid:
		element._flags += {.Needs_Width, .Needs_Height, .Needs_Layout}
	case .None:
	}
}

@(private)
element_flags :: #force_inline proc(element: ^Element) -> Element_Flags {
	return element._flags + element._subtree_flags
}

@(private)
has_flags :: #force_inline proc(element: ^Element, mask: Element_Flags) -> bool {
	return (element_flags(element) & mask) != {}
}
