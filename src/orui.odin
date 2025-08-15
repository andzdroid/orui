package orui

import "core:log"
import rl "vendor:raylib"

MAX_ELEMENTS :: 8192

current_context: ^Context = nil

Context :: struct {
	elements:          [MAX_ELEMENTS]Element,
	element_count:     int,
	// TODO: lookup table of Id => index
	current:           int,
	current_id:        Id,
	previous:          int,
	parent:            int,

	// input state
	hover:             [MAX_ELEMENTS]Id,
	hover_count:       int,
	active:            [MAX_ELEMENTS]Id,
	active_count:      int,
	hover_prev:        [MAX_ELEMENTS]Id,
	hover_prev_count:  int,
	active_prev:       [MAX_ELEMENTS]Id,
	active_prev_count: int,
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
	current_context = ctx

	ctx.element_count = 0

	ctx.elements[0] = {
		id     = to_id("root"),
		width  = fixed(width),
		height = fixed(height),
		_size  = {width, height},
	}
	ctx.element_count += 1

	ctx.current = 0
	ctx.previous = 0
	ctx.parent = 0

	ctx.hover_prev = ctx.hover
	ctx.hover_prev_count = ctx.hover_count
	ctx.hover_count = 0

	ctx.active_prev = ctx.active
	ctx.active_prev_count = ctx.active_count
	ctx.active_count = 0
}

end :: proc {
	_end,
	_end_with_context,
}

_end :: proc() {
	ctx := current_context
	_end_with_context(ctx)
}

_end_with_context :: proc(ctx: ^Context) {
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

	handle_input_state(ctx)
}

id :: proc(str: string) -> Id {
	id := to_id(str)
	ctx := current_context
	ctx.current_id = id
	return id
}

begin_element :: proc(id: Id) -> ^Element {
	ctx := current_context
	assert(ctx.current_id == id, "id mismatch. id() should only be called in element declarations")
	parent_index := ctx.current
	parent := &ctx.elements[parent_index]

	index := ctx.element_count
	ctx.element_count += 1
	element := &ctx.elements[index]
	element^ = Element{}

	ctx.current = index
	ctx.parent = parent_index

	element.id = id
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

ElementModifier :: proc(element: ^Element)

@(deferred_none = end_element)
container :: proc(id: Id, config: ElementConfig, modifiers: ..ElementModifier) -> bool {
	element := begin_element(id)
	configure_element(element, config)

	for modifier in modifiers {
		modifier(element)
	}

	return true
}

label :: proc(id: Id, text: string, config: ElementConfig, modifiers: ..ElementModifier) -> bool {
	element := begin_element(id)
	configure_element(element, config)
	element.has_text = true
	element.text = text

	for modifier in modifiers {
		modifier(element)
	}

	end_element()
	return true
}

hovered :: proc {
	_hovered,
}

_hovered :: proc() -> bool {
	ctx := current_context
	if ctx.current == 0 {
		return false
	}

	for i := 0; i < ctx.hover_prev_count; i += 1 {
		if ctx.hover_prev[i] == ctx.current_id {
			return true
		}
	}

	return false
}

_hovered_id :: proc(id: string) -> bool {
	ctx := current_context
	if ctx.current == 0 {
		return false
	}

	id := to_id(id)
	for i := 0; i < ctx.hover_prev_count; i += 1 {
		if ctx.hover_prev[i] == id {
			return true
		}
	}

	return false
}

active :: proc {
	_active,
	_active_id,
}

_active :: proc() -> bool {
	ctx := current_context
	if ctx.current == 0 {
		return false
	}

	for i := 0; i < ctx.active_prev_count; i += 1 {
		if ctx.active_prev[i] == ctx.current_id {
			return true
		}
	}

	return false
}

_active_id :: proc(id: string) -> bool {
	ctx := current_context
	if ctx.current == 0 {
		return false
	}

	id := to_id(id)
	for i := 0; i < ctx.active_prev_count; i += 1 {
		if ctx.active_prev[i] == id {
			return true
		}
	}

	return false
}

@(private)
handle_input_state :: proc(ctx: ^Context) {
	position := rl.GetMousePosition()
	mouse_down := rl.IsMouseButtonDown(.LEFT)
	ctx.hover_count = 0
	ctx.active_count = 0
	collect_hovered(ctx, 0, position, mouse_down)
	// TODO: active state, click handling
}

@(private)
collect_hovered :: proc(ctx: ^Context, index: int, position: rl.Vector2, mouse_down: bool) {
	element := &ctx.elements[index]
	if point_in_rect(position, element._position, element._size) {
		ctx.hover[ctx.hover_count] = element.id
		ctx.hover_count += 1

		if mouse_down {
			ctx.active[ctx.active_count] = element.id
			ctx.active_count += 1
		}
	}

	child := element.children
	for child != 0 {
		collect_hovered(ctx, child, position, mouse_down)
		child = ctx.elements[child].next
	}
}

@(private)
point_in_rect :: proc(p: rl.Vector2, pos: rl.Vector2, size: rl.Vector2) -> bool {
	return p.x >= pos.x && p.y >= pos.y && p.x < pos.x + size.x && p.y < pos.y + size.y
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

width :: proc(element: ^Element, value: Size) {
	element.width = value
}

height :: proc(element: ^Element, value: Size) {
	element.height = value
}
