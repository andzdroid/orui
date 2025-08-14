package orui

import rl "vendor:raylib"

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
	_size:            rl.Vector2, // border box size
	parent:           int,
	children:         int,
	next:             int,
	children_count:   int,
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

id :: proc(str: string) -> Id {
	return hash_string(str, 0)
}

@(private)
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
