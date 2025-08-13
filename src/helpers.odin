package orui

main_size :: proc(e: ^Element) -> f32 {
	return e.direction == .LeftToRight ? e._size.x : e._size.y
}

cross_size :: proc(e: ^Element) -> f32 {
	return e.direction == .LeftToRight ? e._size.y : e._size.x
}

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
	return inner_width(parent), size_is_explicit(parent.width)
}

parent_inner_height :: proc(ctx: ^Context, e: ^Element) -> (h: f32, definite: bool) {
	if e.parent == 0 {
		root := &ctx.elements[0]
		return root._size.y, true
	}

	parent := &ctx.elements[e.parent]
	return inner_height(parent), size_is_explicit(parent.height)
}

size_is_explicit :: proc(size: Size) -> bool {
	return size.type == .Fixed || size.type == .Percent
}
