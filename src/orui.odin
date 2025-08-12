package orui

import "core:log"
import rl "vendor:raylib"

MAX_ELEMENTS :: 8192

Id :: distinct int

Edges :: struct {
	left:   f32,
	right:  f32,
	top:    f32,
	bottom: f32,
}

SizeType :: enum {
	Fit,
	Grow,
	Percent,
	Fixed,
}

Size :: struct {
	type:  SizeType,
	value: f32,
	min:   f32,
	max:   f32,
}

PositionType :: enum {
	Auto,
	Absolute,
	Relative,
}

Position :: struct {
	type:  PositionType,
	value: rl.Vector2,
}

Layout :: enum {
	None,
	Flex,
}

LayoutDirection :: enum {
	LeftToRight,
	TopToBottom,
}

ElementConfig :: struct {
	user_data:        rawptr,

	// layout
	layout:           Layout,
	direction:        LayoutDirection,
	position:         Position,
	width:            Size,
	height:           Size,
	padding:          Edges,
	margin:           Edges,
	gap:              f32,

	// style
	background_color: rl.Color,
}

Element :: struct {
	id:               Id,
	user_data:        rawptr,

	// layout
	layout:           Layout,
	direction:        LayoutDirection,
	position:         Position,
	width:            Size,
	height:           Size,
	padding:          Edges,
	margin:           Edges,
	gap:              f32,

	// style
	background_color: rl.Color,

	// internal
	_position:        rl.Vector2,
	_size:            rl.Vector2,
	parent:           int,
	children:         int,
	next:             int,
	children_count:   int,
}

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
	}
	ctx.element_count += 1

	ctx.current = 0
	ctx.previous = 0
	ctx.parent = 0
	ctx.hover = 0
	ctx.active = 0
}

end :: proc(ctx: ^Context) {
	compute_layout(ctx, ctx.elements[0].children)
	render_element(ctx, ctx.elements[0].children)
}

begin_element :: proc(ctx: ^Context, id: string) -> ^Element {
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

end_element :: proc(ctx: ^Context, _: string, _: ElementConfig) {
	element := &ctx.elements[ctx.current]

	compute_element_size(element)

	parent := &ctx.elements[element.parent]
	if parent.layout == .Flex {
		if parent.direction == .LeftToRight {
			parent._size.x += element._size.x
			parent._size.y = max(parent._size.y, element._size.y)

			if parent.children != ctx.current {
				parent._size.x += parent.gap
			}
		} else {
			parent._size.y += element._size.y
			parent._size.x = max(parent._size.x, element._size.x)

			if parent.children != ctx.current {
				parent._size.y += parent.gap
			}
		}
	}

	ctx.previous = ctx.current
	ctx.current = ctx.parent
	current := ctx.elements[ctx.current]
	ctx.parent = current.parent
}

configure_element :: proc(element: ^Element, config: ElementConfig) {
	element.layout = config.layout
	element.direction = config.direction
	element.position = config.position
	element.width = config.width
	element.height = config.height
	element.padding = config.padding
	element.margin = config.margin
	element.gap = config.gap
	element.background_color = config.background_color
	element.user_data = config.user_data
}

compute_layout :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]
	compute_layout_element(ctx, element)

	child := element.children
	for child != 0 {
		compute_layout(ctx, child)
		child = ctx.elements[child].next
	}
}

compute_layout_element :: proc(ctx: ^Context, element: ^Element) {
	compute_element_position(ctx, element)
}

compute_element_size :: proc(element: ^Element) {
	if element.width.type == .Fixed {
		width := element.width.value
		element._size.x = width + element.margin.left + element.margin.right
		// log.infof("set element fixed width: %v", element)
	}

	if element.height.type == .Fixed {
		height := element.height.type == .Fixed ? element.height.value : 0
		element._size.y = height + element.margin.top + element.margin.bottom
		// log.infof("set element fixed height: %v", element)
	}

	if element.layout == .Flex {
		// size has already been computed by the children
		children := element.children_count
		gap := element.gap * f32(children - 1)

		if element.direction == .LeftToRight {
			element._size.x += gap
		} else {
			element._size.y += gap
		}
	}
}

compute_element_position :: proc(ctx: ^Context, element: ^Element) {
	parent := &ctx.elements[element.parent]

	if element.position.type == .Absolute {
		element._position = element.position.value
	} else if element.position.type == .Relative {
		element._position = parent._position + element.position.value
	}

	if element.layout == .Flex {
		// log.infof("layout flex children of %v", element)
		child := element.children
		x := element.padding.left
		y := element.padding.top
		for child != 0 {
			child_element := &ctx.elements[child]

			if child_element.position.type != .Auto {
				child = child_element.next
				continue
			}

			if element.direction == .LeftToRight {
				x += child_element.margin.left
				y = element.padding.top + child_element.margin.top
			} else {
				x = element.padding.left + child_element.margin.left
				y += child_element.margin.top
			}

			child_element._position = element._position + {x, y}
			// log.infof("set child element position: %v", child_element)

			if element.direction == .LeftToRight {
				x += child_element._size.x + element.gap + child_element.margin.right
			} else {
				y += child_element._size.y + element.gap + child_element.margin.bottom
			}

			child = child_element.next
		}
	}
}

render_element :: proc(ctx: ^Context, index: int) {
	element := &ctx.elements[index]

	if element.background_color.a > 0 {
		rl.DrawRectangle(
			i32(element._position.x),
			i32(element._position.y),
			i32(element._size.x),
			i32(element._size.y),
			element.background_color,
		)
	}

	child := element.children
	for child != 0 {
		render_element(ctx, child)
		child = ctx.elements[child].next
	}
}

@(deferred_in = end_element)
container :: proc(ctx: ^Context, id: string, config: ElementConfig) -> bool {
	element := begin_element(ctx, id)
	configure_element(element, config)
	return true
}

id :: proc(str: string) -> Id {
	return hash_string(str, 0)
}

hash_string :: proc(str: string, seed: int) -> Id {
	hash := seed

	for c in str {
		hash += int(c)
		hash += (hash << 10)
		hash ~= (hash >> 6)
	}

	hash += (hash << 3)
	hash ~= (hash >> 11)
	hash += (hash << 15)

	return Id(hash)
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

primary_axis_size :: proc(e: ^Element) -> f32 {
	return e.direction == .LeftToRight ? e._size.x : e._size.y
}

set_primary_axis_size :: proc(e: ^Element, size: f32) {
	if e.direction == .LeftToRight {
		e._size.x = size
	} else {
		e._size.y = size
	}
}

cross_axis_size :: proc(e: ^Element) -> f32 {
	return e.direction == .LeftToRight ? e._size.y : e._size.x
}

set_cross_axis_size :: proc(e: ^Element, size: f32) {
	if e.direction == .LeftToRight {
		e._size.y = size
	} else {
		e._size.x = size
	}
}

padding_primary :: proc(p: ^Edges, dir: LayoutDirection) -> f32 {
	return dir == .LeftToRight ? p.left + p.right : p.top + p.bottom
}

padding_cross :: proc(p: ^Edges, dir: LayoutDirection) -> f32 {
	return dir == .LeftToRight ? p.top + p.bottom : p.left + p.right
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

percent :: proc {
	percent_f32,
	percent_i32,
}
percent_f32 :: proc(value: f32) -> Size {
	return {.Percent, value, 0, 0}
}
percent_i32 :: proc(value: i32) -> Size {
	return {.Percent, f32(value), 0, 0}
}

fit :: proc() -> Size {
	return {.Fit, 0, 0, 0}
}

grow :: proc() -> Size {
	return {.Grow, 0, 0, 0}
}
