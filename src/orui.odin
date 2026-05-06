package orui

import "base:intrinsics"
import "base:runtime"
import "core:log"
import "core:mem/virtual"
import rl "vendor:raylib"

MAX_ELEMENTS :: 8192
MAX_COMMANDS :: 8192

when ODIN_OS == .Darwin {
	SCROLL_FACTOR: f32 : 8
} else {
	// TODO: need scroll factor tuned for each OS
	SCROLL_FACTOR: f32 : 40
}

@(thread_local)
current_context: ^Context

IdBuffer :: struct {
	ids:   [MAX_ELEMENTS]Id,
	count: i32,
}

Context :: struct {
	arena:                [2]virtual.Arena,
	allocator:            [2]runtime.Allocator,
	elements:             [2][MAX_ELEMENTS]Element,
	grid_states:          [2][dynamic]GridState,
	element_count:        [2]i32,
	frame:                int,
	time:                 f64,
	default_font:         rl.Font,
	text_cache:           [2]map[TextCacheKey]TextCache,
	text_width_cache:     [2]map[TextWidthKey]f32,
	sorted:               [MAX_ELEMENTS]i32,
	sorted_count:         i32,
	axis_items:           [MAX_ELEMENTS]AxisAllocationItem,
	axis_breakpoints:     [MAX_ELEMENTS]AxisBreakpoint,
	render_commands:      [MAX_COMMANDS]RenderCommand,
	render_command_count: int,

	// current element index - used while building up the UI
	current:              i32,
	current_id:           Id,
	previous:             i32,
	parent:               i32,

	// mouse input
	pointer_capture:      i32,
	pointer_capture_id:   Id,
	hover:                [2]IdBuffer,
	active:               [2]IdBuffer,

	// text input
	focus:                i32,
	focus_id:             Id,
	prev_focus_id:        Id,
	caret_index:          int,
	caret_position:       rl.Vector2,
	caret_time:           f32,
	text_selection:       TextSelection,
	selecting:            bool,
}

init :: proc(ctx: ^Context) {
	for i in 0 ..< 2 {
		err := virtual.arena_init_growing(&ctx.arena[i])
		if err != nil {
			log.panicf("Failed to initialize arena: %v", err)
		}
		ctx.allocator[i] = virtual.arena_allocator(&ctx.arena[i])
	}
}

destroy :: proc(ctx: ^Context) {
	for i in 0 ..< 2 {
		virtual.arena_destroy(&ctx.arena[i])
	}
}

current_buffer :: #force_inline proc(ctx: ^Context) -> int {
	return ctx.frame % 2
}

previous_buffer :: #force_inline proc(ctx: ^Context) -> int {
	return (ctx.frame + 1) % 2
}

// Begin UI declaration.
// Resets UI state and sets the current UI context.
//
// Must be closed with end().
// begin() and end() pairs must not be interleaved or nested.
begin :: proc {
	begin_f32,
	begin_int,
}
@(private)
begin_f32 :: proc(ctx: ^Context, width: f32, height: f32, dt: f32 = 0) {
	_begin(ctx, width, height, dt)
}
@(private)
begin_int :: proc(ctx: ^Context, #any_int width, height: int, dt: f32 = 0) {
	_begin(ctx, f32(width), f32(height), dt)
}

@(private)
_begin :: proc(ctx: ^Context, width: f32, height: f32, dt: f32) {
	current_context = ctx

	ctx.frame += 1

	i := current_buffer(ctx)
	virtual.arena_free_all(&ctx.arena[i])
	ctx.text_cache[i] = make(map[TextCacheKey]TextCache, 1024, ctx.allocator[i])
	ctx.text_width_cache[i] = make(map[TextWidthKey]f32, 1024, ctx.allocator[i])
	ctx.grid_states[i] = make([dynamic]GridState, ctx.allocator[i])

	handle_input_state(ctx)

	elements := &ctx.elements[current_buffer(ctx)]
	element_count := &ctx.element_count[current_buffer(ctx)]
	intrinsics.mem_zero(elements, size_of(Element) * element_count^)

	root_id := to_id("root")
	element_count^ = 0
	elements[0] = {
		id          = root_id,
		width       = fixed(width),
		height      = fixed(height),
		_size       = {width, height},
		layer       = 1,
		disabled    = .False,
		block       = .True,
		capture     = .False,
		_grid_state = -1,
	}
	element_count^ += 1

	ctx.current = 0
	ctx.previous = 0
	ctx.parent = 0

	dt := dt > 0 ? dt : rl.GetFrameTime()
	ctx.caret_time += dt
}

// Ends UI declaration.
// Returns a list of render commands to draw the UI.
end :: proc {
	_end,
	_end_with_context,
}

@(private)
_end :: proc() -> []RenderCommand {
	ctx := current_context
	return _end_with_context(ctx)
}

@(private)
_end_with_context :: proc(ctx: ^Context) -> []RenderCommand {
	fit_widths(ctx, 0)
	distribute_widths(ctx, 0)
	wrap(ctx, 0)
	fit_heights(ctx, 0)
	distribute_heights(ctx, 0)
	compute_layout(ctx, 0)
	render(ctx)
	return ctx.render_commands[:ctx.render_command_count]
}


// Declares an open element with the given ID.
// All elements should be declared with this function.
//
// You should NOT cache the result of this function, always call it inside an element declaration.
// This should not be used outside of element declarations. Use to_id() instead.
id :: proc {
	_id,
	_id_string,
	_id_int,
	_id_string_index,
	_id_id_index,
}

@(private)
_id :: proc(id: Id) -> Id {
	ctx := current_context
	ctx.current_id = id
	return id
}

@(private)
_id_string :: proc(str: string) -> Id {
	id := to_id(str)
	ctx := current_context
	ctx.current_id = id
	return id
}

@(private)
_id_int :: proc(#any_int id: int) -> Id {
	id := to_id(id)
	ctx := current_context
	ctx.current_id = id
	return id
}

@(private)
_id_string_index :: proc(str: string, #any_int index: int) -> Id {
	id := to_id(str, index)
	ctx := current_context
	ctx.current_id = id
	return id
}

@(private)
_id_id_index :: proc(id: Id, #any_int index: int) -> Id {
	indexed_id := to_id(id, index)
	ctx := current_context
	ctx.current_id = indexed_id
	return indexed_id
}

// Begins an element with the given ID.
// Any elements declared after this will be added as children of this element.
//
// Must be closed with end_element().
begin_element :: proc(id: Id, loc := #caller_location) -> (^Element, ^Element) {
	ctx := current_context
	elements := &ctx.elements[current_buffer(ctx)]
	assert(
		ctx.current_id == id,
		"id mismatch. id() must always be called in the element declaration",
		loc = loc,
	)
	parent_index := ctx.current
	parent := &elements[parent_index]

	index := ctx.element_count[current_buffer(ctx)]
	ctx.element_count[current_buffer(ctx)] += 1
	ctx.current = index
	ctx.parent = parent_index

	element := &elements[index]
	element.id = id
	element.parent = parent_index

	if parent.children == 0 {
		parent.children = index
	} else {
		previous := &elements[ctx.previous]
		previous.next = index
	}
	parent.children_count += 1

	return element, parent
}

// Closes the current element.
end_element :: proc() {
	ctx := current_context
	element := ctx.current
	finalize_element(ctx, element)
	elements := &ctx.elements[current_buffer(ctx)]
	elements[ctx.parent]._subtree_flags +=
		elements[element]._flags + elements[element]._subtree_flags
	ctx.previous = element
	ctx.current = ctx.parent
	current := elements[ctx.current]
	ctx.parent = current.parent
}

ElementModifier :: proc(element: ^Element)

// The basic building block of the UI.
// Must have a matching end_element() call.
element :: proc(
	id: Id,
	config: ElementConfig,
	modifiers: ..ElementModifier,
	loc := #caller_location,
) -> bool {
	ctx := current_context
	element, parent := begin_element(id, loc)
	configure_element(ctx, element, parent^, config)
	for modifier in modifiers {
		modifier(element)
	}
	return true
}

element_index_by_id :: proc(ctx: ^Context, buffer: int, id: Id) -> (index: i32, ok: bool) {
	assert(ctx != nil)

	elements := &ctx.elements[buffer]
	count := ctx.element_count[buffer]
	for i in 0 ..< count {
		if elements[i].id == id {
			return i, true
		}
	}
	return 0, false
}

// Get an element from the previous frame.
get_element :: proc(id: Id) -> ^Element {
	ctx := current_context
	buffer := previous_buffer(ctx)
	element_index, ok := element_index_by_id(ctx, buffer, id)
	if ok {
		return &ctx.elements[buffer][element_index]
	}
	return nil
}

@(private)
finalize_element :: proc(ctx: ^Context, index: i32) {
	elements := &ctx.elements[current_buffer(ctx)]
	element := &elements[index]
	measure_text(ctx, element)
	measure_width(element)
	measure_height(element)
	flex_finalize_base_size(ctx, index)
	grid_finalize_base_size(ctx, index)
	set_flags(element)
	if element.parent != 0 {
		flex_update_parent_size(ctx, element.parent, index)
		grid_place_child(ctx, element.parent, index)
	}
}

@(private)
measure_text :: proc(ctx: ^Context, element: ^Element) {
	if !element.has_text {
		return
	}

	element._text_width = measure_text_width(
		ctx,
		element.text,
		element.font,
		element.font_size,
		element.letter_spacing,
	)
	element._line_height = measure_text_height(element.font_size, element.line_height)

	if element.overflow == .Visible {
		if len(element.text) > 0 {
			element._line_count = 1
		}
	}
}
