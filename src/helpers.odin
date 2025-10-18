package orui

import rl "vendor:raylib"

hovered :: proc {
	_hovered,
	_hovered_string,
	_hovered_id,
}

@(private)
// Whether the mouse is over the current element.
// Should only be used inside an element declaration.
_hovered :: proc() -> bool {
	ctx := current_context
	if ctx.current == 0 {
		return false
	}

	buffer := current_buffer(ctx)
	count := ctx.hover[buffer].count
	for i := 0; i < count; i += 1 {
		if ctx.hover[buffer].ids[i] == ctx.current_id {
			return true
		}
	}

	return false
}

@(private)
// Whether the mouse is over the element with the given ID.
_hovered_string :: proc(id: string) -> bool {
	ctx := current_context
	id := to_id(id)
	buffer := current_buffer(ctx)
	count := ctx.hover[buffer].count
	for i := 0; i < count; i += 1 {
		if ctx.hover[buffer].ids[i] == id {
			return true
		}
	}

	return false
}

@(private)
_hovered_id :: proc(id: Id) -> bool {
	ctx := current_context
	buffer := current_buffer(ctx)
	count := ctx.hover[buffer].count
	for i := 0; i < count; i += 1 {
		if ctx.hover[buffer].ids[i] == id {
			return true
		}
	}
	return false
}

// Whether an element is active (mouse down).
active :: proc {
	_active,
	_active_string,
	_active_id,
}

@(private)
// Whether the current element is active (mouse down).
_active :: proc() -> bool {
	ctx := current_context
	if ctx.current == 0 {
		return false
	}

	buffer := previous_buffer(ctx)
	count := ctx.active[buffer].count
	for i := 0; i < count; i += 1 {
		if ctx.active[buffer].ids[i] == ctx.current_id {
			return true
		}
	}

	return false
}

@(private)
// Whether the specified element is active (mouse down).
_active_string :: proc(id: string) -> bool {
	ctx := current_context
	id := to_id(id)
	buffer := previous_buffer(ctx)
	count := ctx.active[buffer].count
	for i := 0; i < count; i += 1 {
		if ctx.active[buffer].ids[i] == id {
			return true
		}
	}

	return false
}

@(private)
_active_id :: proc(id: Id) -> bool {
	ctx := current_context
	buffer := previous_buffer(ctx)
	count := ctx.active[buffer].count
	for i := 0; i < count; i += 1 {
		if ctx.active[buffer].ids[i] == id {
			return true
		}
	}
	return false
}

clicked :: proc {
	_clicked,
	_clicked_string,
	_clicked_id,
}

@(private)
// Whether the current element has been clicked this frame.
_clicked :: proc() -> bool {
	return rl.IsMouseButtonReleased(.LEFT) && active()
}

@(private)
_clicked_string :: proc(id: string) -> bool {
	return rl.IsMouseButtonReleased(.LEFT) && active(id)
}

@(private)
_clicked_id :: proc(id: Id) -> bool {
	return rl.IsMouseButtonReleased(.LEFT) && active(id)
}

focused :: proc {
	_focused,
	_focused_string,
	_focused_id,
}

@(private)
// Whether the current text input element is focused (receiving keyboard input).
// Only one element can be focused at a time.
_focused :: proc() -> bool {
	ctx := current_context
	return ctx.focus_id == ctx.current_id
}

@(private)
// Whether the specified text input element is focused (receiving keyboard input).
// Only one element can be focused at a time.
_focused_string :: proc(id: string) -> bool {
	ctx := current_context
	id := to_id(id)
	return ctx.focus_id == id
}

@(private)
_focused_id :: proc(id: Id) -> bool {
	ctx := current_context
	return ctx.focus_id == id
}

captured :: proc {
	_captured,
	_captured_string,
	_captured_id,
}

@(private)
_captured :: proc() -> bool {
	ctx := current_context
	return ctx.pointer_capture_id == ctx.current_id
}

@(private)
_captured_string :: proc(id: string) -> bool {
	ctx := current_context
	id := to_id(id)
	return ctx.pointer_capture_id == id
}

@(private)
_captured_id :: proc(id: Id) -> bool {
	ctx := current_context
	return ctx.pointer_capture_id == id
}

padding :: proc {
	padding_all,
	padding_axis,
}

@(private)
// Equal padding on all sides.
padding_all :: proc(p: f32) -> Edges {
	return {p, p, p, p}
}

@(private)
// Padding on the x and y axis.
padding_axis :: proc(x: f32, y: f32) -> Edges {
	return {y, x, y, x}
}

margin :: proc {
	margin_all,
	margin_axis,
}

@(private)
// Equal margin on all sides.
margin_all :: proc(m: f32) -> Edges {
	return {m, m, m, m}
}

@(private)
// Margin on the x and y axis.
margin_axis :: proc(x: f32, y: f32) -> Edges {
	return {y, x, y, x}
}

// Equal border width on all sides.
border :: proc(b: f32) -> Edges {
	return {b, b, b, b}
}

// Equal corner radius on all sides.
corner :: proc(r: f32) -> Corners {
	return {r, r, r, r}
}

fixed :: proc {
	fixed_f32,
	fixed_i32,
}
@(private)
fixed_f32 :: proc(value: f32) -> Size {
	return {.Fixed, value, 0, 0}
}
@(private)
fixed_i32 :: proc(value: i32) -> Size {
	return {.Fixed, f32(value), 0, 0}
}

percent :: proc(value: f32) -> Size {
	return {.Percent, value, 0, 0}
}

fit :: proc() -> Size {
	return {.Fit, 0, 0, 0}
}

grow :: proc(base: f32 = 0) -> Size {
	return {.Grow, base, 0, 0}
}

AnchorPoint :: enum {
	TopLeft,
	TopRight,
	Top,
	Left,
	Right,
	Center,
	BottomLeft,
	BottomRight,
	Bottom,
}

anchor_point :: proc(point: AnchorPoint) -> rl.Vector2 {
	switch point {
	case .TopLeft:
		return {0, 0}
	case .TopRight:
		return {1, 0}
	case .Top:
		return {0.5, 0}
	case .Left:
		return {0, 0.5}
	case .Right:
		return {1, 0.5}
	case .BottomLeft:
		return {0, 1}
	case .BottomRight:
		return {1, 1}
	case .Bottom:
		return {0.5, 1}
	case .Center:
		return {0.5, 0.5}
	}
	return {0, 0}
}

placement :: proc(anchor: AnchorPoint, origin: AnchorPoint) -> Placement {
	return {anchor_point(anchor), anchor_point(origin)}
}

scroll :: proc(direction: ScrollDirection) -> ScrollConfig {
	return {direction, scroll_offset()}
}

scroll_offset :: proc {
	_scroll_offset,
	_scroll_offset_id,
}

@(private)
_scroll_offset :: proc() -> rl.Vector2 {
	return _scroll_offset_id(current_context.current_id)
}

@(private)
_scroll_offset_id :: proc(id: Id) -> rl.Vector2 {
	element := get_element(id)
	if element != nil {
		return element.scroll.offset
	}
	return {}
}

set_scroll_offset :: proc {
	_set_scroll_offset,
	_set_scroll_offset_id,
}

@(private)
_set_scroll_offset :: proc(offset: rl.Vector2) {
	_set_scroll_offset_id(current_context.current_id, offset)
}

@(private)
_set_scroll_offset_id :: proc(id: Id, offset: rl.Vector2) {
	ctx := current_context
	elements := &ctx.elements[current_buffer(ctx)]
	count := ctx.element_count[current_buffer(ctx)]
	for i in 0 ..< count {
		if elements[i].id == id {
			elements[i].scroll.offset = offset
			return
		}
	}
}

scrollbar_handle_params :: proc(id: Id) -> (percent: [2]f32, size: [2]f32) {
	element := get_element(id)
	if element != nil {
		percent := element.scroll.offset / (element._content_size - element._size)

		size: rl.Vector2 = {}
		if element._content_size.x > element._size.x {
			size.x = element._size.x / element._content_size.x
		} else {
			size.x = 1
		}
		if element._content_size.y > element._size.y {
			size.y = element._size.y / element._content_size.y
		} else {
			size.y = 1
		}

		return percent, size
	}
	return {}, {}
}

size :: proc(id: Id) -> rl.Vector2 {
	element := get_element(id)
	if element != nil {
		return element._size
	}
	return {}
}


@(private)
x_padding :: #force_inline proc(e: ^Element) -> f32 {
	return e.padding.left + e.padding.right
}

@(private)
y_padding :: #force_inline proc(e: ^Element) -> f32 {
	return e.padding.top + e.padding.bottom
}

@(private)
x_margin :: #force_inline proc(e: ^Element) -> f32 {
	return e.margin.left + e.margin.right
}

@(private)
y_margin :: #force_inline proc(e: ^Element) -> f32 {
	return e.margin.top + e.margin.bottom
}

@(private)
x_border :: #force_inline proc(e: ^Element) -> f32 {
	return e.border.left + e.border.right
}

@(private)
y_border :: #force_inline proc(e: ^Element) -> f32 {
	return e.border.top + e.border.bottom
}

@(private)
inner_width :: #force_inline proc(e: ^Element) -> f32 {
	return max(0, e._size.x - x_padding(e) - x_border(e))
}

@(private)
inner_height :: #force_inline proc(e: ^Element) -> f32 {
	return max(0, e._size.y - y_padding(e) - y_border(e))
}

@(private)
parent_inner_width :: proc(ctx: ^Context, e: ^Element) -> (w: f32, definite: bool) {
	elements := &ctx.elements[current_buffer(ctx)]
	if e.parent == 0 {
		root := &elements[0]
		return root._size.x, true
	}

	parent := &elements[e.parent]
	if parent.layout == .Grid {
		width: f32 = 0
		col_span := max(e.col_span, 1)
		for i := e._grid_col_index; i < e._grid_col_index + col_span; i += 1 {
			width += parent._grid_col_sizes[i]
		}
		gap := parent.col_gap > 0 ? parent.col_gap : parent.gap
		gap_count := max(col_span - 1, 0)
		width += gap * f32(gap_count)
		return width, !scrolls_x(e)
	} else {
		return inner_width(parent), parent._size.x > 0 && !scrolls_x(e)
	}
}

@(private)
parent_inner_height :: proc(ctx: ^Context, e: ^Element) -> (h: f32, definite: bool) {
	elements := &ctx.elements[current_buffer(ctx)]
	if e.parent == 0 {
		root := &elements[0]
		return root._size.y, true
	}

	parent := &elements[e.parent]
	if parent.layout == .Grid {
		height: f32 = 0
		row_span := max(e.row_span, 1)
		for i := e._grid_row_index; i < e._grid_row_index + row_span; i += 1 {
			height += parent._grid_row_sizes[i]
		}
		gap := parent.row_gap > 0 ? parent.row_gap : parent.gap
		gap_count := max(row_span - 1, 0)
		height += gap * f32(gap_count)
		return height, !scrolls_y(e)
	} else {
		return inner_height(parent), parent._size.y > 0 && !scrolls_y(e)
	}
}

@(private)
has_round_corners :: proc(corners: Corners) -> bool {
	return(
		corners.top_left > 0 ||
		corners.top_right > 0 ||
		corners.bottom_right > 0 ||
		corners.bottom_left > 0 \
	)
}

@(private)
scrolls_x :: proc(element: ^Element) -> bool {
	return(
		(element.scroll.direction == .Auto || element.scroll.direction == .Horizontal) &&
		element._content_size.x > inner_width(element) \
	)
}

@(private)
scrolls_y :: proc(element: ^Element) -> bool {
	return(
		(element.scroll.direction == .Auto || element.scroll.direction == .Vertical) &&
		element._content_size.y > inner_height(element) \
	)
}

@(private)
clamp_scroll_offset :: proc(element: ^Element) {
	// TODO: remove this, replace with scroll velocity/gravity/something
	// animate towards the nearest scrollable position instead of snapping
	max_x := max(0, element._content_size.x - inner_width(element))
	max_y := max(0, element._content_size.y - inner_height(element))
	scroll := element.scroll.offset

	switch element.scroll.direction {
	case .None:
		scroll = {}
	case .Auto:
		scroll = {clamp(scroll.x, 0, max_x), clamp(scroll.y, 0, max_y)}
	case .Vertical:
		scroll.y = clamp(scroll.y, 0, max_y)
	case .Horizontal:
		scroll.x = clamp(scroll.x, 0, max_x)
	case .Manual:
	}
	element.scroll.offset = scroll
}

@(private)
get_scroll_offset :: proc(element: ^Element) -> rl.Vector2 {
	scroll := element.scroll.offset
	switch element.scroll.direction {
	case .None:
		return {}
	case .Auto:
		return scroll
	case .Vertical:
		return {0, scroll.y}
	case .Horizontal:
		return {scroll.x, 0}
	case .Manual:
		return scroll
	}
	return {}
}
