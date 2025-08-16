package orui

x_padding :: proc(e: ^Element) -> f32 {
	return e.padding.left + e.padding.right
}

y_padding :: proc(e: ^Element) -> f32 {
	return e.padding.top + e.padding.bottom
}

x_margin :: proc(e: ^Element) -> f32 {
	return e.margin.left + e.margin.right
}

y_margin :: proc(e: ^Element) -> f32 {
	return e.margin.top + e.margin.bottom
}

inner_width :: proc(e: ^Element) -> f32 {
	return max(0, e._size.x - x_padding(e))
}

inner_height :: proc(e: ^Element) -> f32 {
	return max(0, e._size.y - y_padding(e))
}

parent_inner_width :: proc(ctx: ^Context, e: ^Element) -> (w: f32, definite: bool) {
	if e.parent == 0 {
		root := &ctx.elements[0]
		return root._size.x, true
	}

	parent := &ctx.elements[e.parent]
	return inner_width(parent), parent._size.x > 0
}

parent_inner_height :: proc(ctx: ^Context, e: ^Element) -> (h: f32, definite: bool) {
	if e.parent == 0 {
		root := &ctx.elements[0]
		return root._size.y, true
	}

	parent := &ctx.elements[e.parent]
	return inner_height(parent), parent._size.y > 0
}
