package orui

/*
Border/padding box: size of element (_size)
Content box: border box - padding
Margin box: border box + margin
*/

@(private)
// Set fixed widths and fit widths
fit_widths :: proc(ctx: ^Context, index: int) {
	elements := &ctx.elements[current_buffer(ctx)]
	element := &elements[index]

	if element.width.type == .Fixed {
		element._size.x = element.width.value
	}

	if element.has_text &&
	   (element.overflow != .Wrap || element.width.type == .Fit || element.width.type == .Grow) {
		text_width := measure_text_width(
			ctx,
			element.text,
			element.font,
			element.font_size,
			element.letter_spacing,
		)

		if element.overflow != .Wrap {
			element._content_size.x = text_width
		}

		if element.width.type == .Fit || element.width.type == .Grow {
			element._size.x = text_width + x_padding(element) + x_border(element)
		}
	}

	if element.layout == .Grid {
		grid_auto_place(ctx, element)
	}

	child := element.children
	for child != 0 {
		fit_widths(ctx, child)
		child = elements[child].next
	}

	if element.layout == .Flex {
		flex_fit_width(ctx, element)
	} else if element.layout == .Grid {
		grid_fit_columns(ctx, element)
		grid_fit_width(ctx, element)
	}
}

@(private)
// Set widths that depend on parent width (percent, grow)
distribute_widths :: proc(ctx: ^Context, index: int) {
	elements := &ctx.elements[current_buffer(ctx)]
	element := &elements[index]

	if element.width.type == .Percent {
		percent_width, definite := parent_inner_width(ctx, element)
		if definite {
			element._size.x = percent_width * element.width.value
		}
		flex_clamp_width(ctx, element)
	}

	if element.layout == .Flex {
		flex_distribute_widths(ctx, element)
	} else if element.layout == .Grid {
		grid_distribute_columns(ctx, element)
		grid_distribute_widths(ctx, element)
	}

	child := element.children
	for child != 0 {
		distribute_widths(ctx, child)
		child = elements[child].next
	}
}

@(private)
wrap :: proc(ctx: ^Context) {
	elements := &ctx.elements[current_buffer(ctx)]
	for i in 0 ..< ctx.element_count[current_buffer(ctx)] {
		element := &elements[i]
		if element.overflow != .Wrap {
			continue
		}

		if element.has_text {
			wrap_text_element(ctx, element)
		}

		// TODO: wrap flex containers
		// should not happen here, should be part of flex sizing
	}
}

@(private)
// Set fixed heights and fit heights.
fit_heights :: proc(ctx: ^Context, index: int) {
	elements := &ctx.elements[current_buffer(ctx)]
	element := &elements[index]

	if element.height.type == .Fixed {
		element._size.y = element.height.value
	}

	if element.has_text {
		lines := element._line_count > 0 ? element._line_count : 1
		line_height_px := measure_text_height(element.font_size, element.line_height)
		text_height := line_height_px * f32(lines)
		element._content_size.y = text_height

		if element.height.type == .Fit || element.height.type == .Grow {
			element._size.y = text_height + y_padding(element) + y_border(element)
		}
	}

	child := element.children
	for child != 0 {
		fit_heights(ctx, child)
		child = elements[child].next
	}

	if element.layout == .Flex {
		flex_fit_height(ctx, element)
	} else if element.layout == .Grid {
		grid_fit_rows(ctx, element)
		grid_fit_height(ctx, element)
	}
}

@(private)
// Set heights that depend on parent height (percent, grow)
distribute_heights :: proc(ctx: ^Context, index: int) {
	elements := &ctx.elements[current_buffer(ctx)]
	element := &elements[index]

	if element.height.type == .Percent {
		percent_height, definite := parent_inner_height(ctx, element)
		if definite {
			element._size.y = percent_height * element.height.value
		}
		flex_clamp_height(ctx, element)
	}

	if element.layout == .Flex {
		flex_distribute_heights(ctx, element)
	} else if element.layout == .Grid {
		grid_distribute_rows(ctx, element)
		grid_distribute_heights(ctx, element)
	}

	child := element.children
	for child != 0 {
		distribute_heights(ctx, child)
		child = elements[child].next
	}
}
