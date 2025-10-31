package orui

import "base:intrinsics"
import "base:runtime"
import "core:log"
import "core:mem/virtual"
import rl "vendor:raylib"

MAX_ELEMENTS :: 8192
MAX_COMMANDS :: 8192

KEY_REPEAT_DELAY: f64 : 0.45
KEY_REPEAT_INTERVAL: f64 : 0.1
SCROLL_FACTOR: f32 : 8

@(thread_local)
current_context: ^Context

IdBuffer :: struct {
	ids:   [MAX_ELEMENTS]Id,
	count: int,
}

Context :: struct {
	arena:                [2]virtual.Arena,
	allocator:            [2]runtime.Allocator,
	elements:             [2][MAX_ELEMENTS]Element,
	element_count:        [2]int,
	frame:                int,
	time:                 f64,
	default_font:         rl.Font,
	text_cache:           [2]map[TextCacheKey]TextCache,
	text_width_cache:     [2]map[TextWidthKey]f32,
	sorted:               [MAX_ELEMENTS]int,
	sorted_count:         int,
	render_commands:      [MAX_COMMANDS]RenderCommand,
	render_command_count: int,

	// current element index - used while building up the UI
	current:              int,
	current_id:           Id,
	previous:             int,
	parent:               int,

	// mouse input
	pointer_capture:      int,
	pointer_capture_id:   Id,
	hover:                [2]IdBuffer,
	active:               [2]IdBuffer,

	// text input
	focus:                int,
	focus_id:             Id,
	prev_focus_id:        Id,
	caret_index:          int,
	caret_position:       rl.Vector2,
	caret_time:           f32,
	repeat_key:           rl.KeyboardKey,
	repeat_time:          f64,
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
	begin_i32,
}
@(private)
begin_f32 :: proc(ctx: ^Context, width: f32, height: f32, dt: f32 = 0) {
	_begin(ctx, width, height, dt)
}
@(private)
begin_i32 :: proc(ctx: ^Context, width: i32, height: i32, dt: f32 = 0) {
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

	handle_input_state(ctx)

	elements := &ctx.elements[current_buffer(ctx)]
	element_count := &ctx.element_count[current_buffer(ctx)]
	intrinsics.mem_zero(elements, size_of(Element) * element_count^)

	root_id := to_id("root")
	element_count^ = 0
	elements[0] = {
		id       = root_id,
		width    = fixed(width),
		height   = fixed(height),
		_size    = {width, height},
		layer    = 1,
		disabled = .False,
		block    = .True,
		capture  = .False,
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
	wrap(ctx)
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
_id_int :: proc(id: int) -> Id {
	id := to_id(id)
	ctx := current_context
	ctx.current_id = id
	return id
}

@(private)
_id_string_index :: proc(str: string, index: int) -> Id {
	id := to_id(str, index)
	ctx := current_context
	ctx.current_id = id
	return id
}

@(private)
_id_id_index :: proc(id: Id, index: int) -> Id {
	id := to_id(id, index)
	ctx := current_context
	ctx.current_id = id
	return id
}

// Begins an element with the given ID.
// Any elements declared after this will be added as children of this element.
//
// Must be closed with end_element().
begin_element :: proc(id: Id) -> (^Element, ^Element) {
	ctx := current_context
	elements := &ctx.elements[current_buffer(ctx)]
	assert(
		ctx.current_id == id,
		"id mismatch. id() must always be called in the element declaration",
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
	elements := &ctx.elements[current_buffer(ctx)]
	element := &elements[ctx.current]
	ctx.previous = ctx.current
	ctx.current = ctx.parent
	current := elements[ctx.current]
	ctx.parent = current.parent
}

ElementModifier :: proc(element: ^Element)

// The basic building block of the UI.
// Must have a matching end_element() call.
element :: proc(id: Id, config: ElementConfig, modifiers: ..ElementModifier) -> bool {
	ctx := current_context
	element, parent := begin_element(id)
	configure_element(ctx, element, parent^, config)
	for modifier in modifiers {
		modifier(element)
	}
	return true
}

// Get an element from the previous frame.
get_element :: proc(id: Id) -> ^Element {
	ctx := current_context
	elements := &ctx.elements[previous_buffer(ctx)]
	count := ctx.element_count[previous_buffer(ctx)]
	for i in 0 ..< count {
		if elements[i].id == id {
			return &elements[i]
		}
	}
	return nil
}
