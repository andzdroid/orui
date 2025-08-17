package orui

@(private)
x_padding :: proc(e: ^Element) -> f32 {
	return e.padding.left + e.padding.right
}

@(private)
y_padding :: proc(e: ^Element) -> f32 {
	return e.padding.top + e.padding.bottom
}

@(private)
x_margin :: proc(e: ^Element) -> f32 {
	return e.margin.left + e.margin.right
}

@(private)
y_margin :: proc(e: ^Element) -> f32 {
	return e.margin.top + e.margin.bottom
}

@(private)
inner_width :: proc(e: ^Element) -> f32 {
	return max(0, e._size.x - x_padding(e))
}

@(private)
inner_height :: proc(e: ^Element) -> f32 {
	return max(0, e._size.y - y_padding(e))
}

@(private)
inner_main :: proc(e: ^Element) -> f32 {
	if e.direction == .LeftToRight {
		return inner_width(e)
	} else {
		return inner_height(e)
	}
}

@(private)
parent_inner_width :: proc(ctx: ^Context, e: ^Element) -> (w: f32, definite: bool) {
	if e.parent == 0 {
		root := &ctx.elements[0]
		return root._size.x, true
	}

	parent := &ctx.elements[e.parent]
	return inner_width(parent), parent._size.x > 0
}

@(private)
parent_inner_height :: proc(ctx: ^Context, e: ^Element) -> (h: f32, definite: bool) {
	if e.parent == 0 {
		root := &ctx.elements[0]
		return root._size.y, true
	}

	parent := &ctx.elements[e.parent]
	return inner_height(parent), parent._size.y > 0
}
