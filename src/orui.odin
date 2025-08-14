package orui

import "core:log"
import rl "vendor:raylib"

MAX_ELEMENTS :: 8192

current_context: ^Context = nil

Context :: struct {
	elements:      [MAX_ELEMENTS]Element,
	element_count: int,
	// TODO: lookup table of Id => index
	current:       int,
	previous:      int,
	parent:        int,
	hover:         int,
	active:        int,
}

init :: proc(ctx: ^Context) {
}

begin :: proc {
	begin_f32,
	begin_i32,
}
begin_f32 :: proc(ctx: ^Context, width: f32, height: f32) {
	_begin(ctx, width, height)
}
begin_i32 :: proc(ctx: ^Context, width: i32, height: i32) {
	_begin(ctx, f32(width), f32(height))
}

_begin :: proc(ctx: ^Context, width: f32, height: f32) {
	ctx.element_count = 0

	ctx.elements[0] = {
		id     = id("root"),
		width  = fixed(width),
		height = fixed(height),
		_size  = {width, height},
	}
	ctx.element_count += 1

	ctx.current = 0
	ctx.previous = 0
	ctx.parent = 0
	ctx.hover = 0
	ctx.active = 0
}

end :: proc(ctx: ^Context) {
	fit_widths(ctx, 0)
	distribute_widths(ctx, 0)

	text_wrap_pass(ctx)
	propagate_heights(ctx)

	fit_heights(ctx, 0)
	distribute_heights(ctx, 0)

	cross_axis_finalize(ctx)
	sort_roots_by_z(ctx)
	position_pass(ctx)
	render(ctx)
}

begin_element :: proc(ctx: ^Context, id: string) -> ^Element {
	current_context = ctx

	parent_index := ctx.current
	parent := &ctx.elements[parent_index]

	index := ctx.element_count
	ctx.element_count += 1
	element := &ctx.elements[index]
	element^ = Element{}

	ctx.current = index
	ctx.parent = parent_index

	element.id = hash_string(id, 0)
	element.parent = parent_index

	if parent.children == 0 {
		parent.children = index
	} else {
		previous := &ctx.elements[ctx.previous]
		previous.next = index
	}
	parent.children_count += 1

	return element
}

end_element :: proc() {
	ctx := current_context

	element := &ctx.elements[ctx.current]
	ctx.previous = ctx.current
	ctx.current = ctx.parent
	current := ctx.elements[ctx.current]
	ctx.parent = current.parent
}

@(deferred_none = end_element)
container :: proc(ctx: ^Context, id: string, config: ElementConfig) -> bool {
	element := begin_element(ctx, id)
	configure_element(element, config)
	return true
}

print :: proc(ctx: ^Context) {
	print_element(ctx, 0)
}

print_element :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]
	log.infof("element %d: %v", index, element)

	child := element.children
	for child != 0 {
		print_element(ctx, child)
		child = ctx.elements[child].next
	}
}

padding :: proc(p: f32) -> Edges {
	return {p, p, p, p}
}

margin :: proc(m: f32) -> Edges {
	return {m, m, m, m}
}

fixed :: proc {
	fixed_f32,
	fixed_i32,
}
fixed_f32 :: proc(value: f32) -> Size {
	return {.Fixed, value, 0, 0}
}
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
