package orui

import "core:fmt"
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

// Begin UI declaration.
// Resets UI state and sets the current UI context.
//
// Must be closed with end().
// begin() and end() pairs must not be interleaved or nested.
begin :: proc {
	begin_f32,
	begin_i32,
}
@(private)
begin_f32 :: proc(ctx: ^Context, width: f32, height: f32) {
	_begin(ctx, width, height)
}
@(private)
begin_i32 :: proc(ctx: ^Context, width: i32, height: i32) {
	_begin(ctx, f32(width), f32(height))
}

@(private)
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

// Ends UI declaration.
// Renders the declared UI.
end :: proc {
	_end,
	_end_with_context,
}

@(private)
_end :: proc() {
	ctx := current_context
	_end_with_context(ctx)
}

@(private)
_end_with_context :: proc(ctx: ^Context) {
	fit_widths(ctx, 0)
	distribute_widths(ctx, 0)

	wrap_text(ctx)

	fit_heights(ctx, 0)
	distribute_heights(ctx, 0)

	sort_roots_by_z(ctx)
	compute_layout(ctx, 0)
	render(ctx)

	handle_input_state(ctx)
}


// Declares an open element with the given ID.
// All elements should be declared with this function.
//
// You should NOT cache the result of this function, always call it inside an element declaration.
// This should not be used outside of element declarations. Use to_id() instead.
id :: proc(str: string) -> Id {
	id := to_id(str)
	ctx := current_context
	ctx.current_id = id
	return id
}

// Begins an element with the given ID.
// Any elements declared after this will be added as children of this element.
//
// Must be closed with end_element().
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

// Closes the current element.
end_element :: proc() {
	ctx := current_context
	element := &ctx.elements[ctx.current]
	ctx.previous = ctx.current
	ctx.current = ctx.parent
	current := ctx.elements[ctx.current]
	ctx.parent = current.parent
}

ElementModifier :: proc(element: ^Element)

element :: proc(id: Id, config: ElementConfig, modifiers: ..ElementModifier) -> bool {
	element := begin_element(id)
	configure_element(element, config)
	for modifier in modifiers {
		modifier(element)
	}
	return true
}

@(deferred_none = end_element)
// The basic building block of the UI.
container :: proc(id: Id, config: ElementConfig, modifiers: ..ElementModifier) -> bool {
	element := begin_element(id)
	configure_element(element, config)
	for modifier in modifiers {
		modifier(element)
	}
	return true
}

// A label is a text element that can be use to display text.
// This element cannot have children.
label :: proc(id: Id, text: string, config: ElementConfig, modifiers: ..ElementModifier) -> bool {
	element := begin_element(id)
	configure_element(element, config)
	element.has_text = true
	element.text = text

	for modifier in modifiers {
		modifier(element)
	}

	assert(element.font != nil, fmt.tprintf("element with id %s is missing a font", id))

	end_element()

	return rl.IsMouseButtonReleased(.LEFT) && active()
}

// An image is an element that displays a texture.
// This element cannot have children.
image :: proc(
	id: Id,
	texture: ^rl.Texture2D,
	config: ElementConfig,
	modifiers: ..ElementModifier,
) -> bool {
	element := begin_element(id)
	configure_element(element, config)
	element.has_texture = true
	element.texture = texture

	for modifier in modifiers {
		modifier(element)
	}

	end_element()

	return rl.IsMouseButtonReleased(.LEFT) && active()
}

hovered :: proc {
	_hovered,
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

	for i := 0; i < ctx.hover_prev_count; i += 1 {
		if ctx.hover_prev[i] == ctx.current_id {
			return true
		}
	}

	return false
}

@(private)
// Whether the mouse is over the element with the given ID.
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

// Whether an element is active (mouse down).
active :: proc {
	_active,
	_active_id,
}

@(private)
// Whether the current declared element is active (mouse down).
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

@(private)
// Whether the specified element is active (mouse down).
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

clicked :: proc {
	_clicked,
	_clicked_id,
}

@(private)
_clicked :: proc() -> bool {
	return rl.IsMouseButtonReleased(.LEFT) && active()
}

@(private)
_clicked_id :: proc(id: string) -> bool {
	return rl.IsMouseButtonReleased(.LEFT) && active(id)
}

padding :: proc {
	padding_all,
	padding_axis,
}

@(private)
padding_all :: proc(p: f32) -> Edges {
	return {p, p, p, p}
}

@(private)
padding_axis :: proc(x: f32, y: f32) -> Edges {
	return {y, x, y, x}
}

margin :: proc {
	margin_all,
	margin_axis,
}

@(private)
margin_all :: proc(m: f32) -> Edges {
	return {m, m, m, m}
}

@(private)
margin_axis :: proc(x: f32, y: f32) -> Edges {
	return {y, x, y, x}
}

border :: proc(b: f32) -> Edges {
	return {b, b, b, b}
}

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
