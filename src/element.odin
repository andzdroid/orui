package orui

import rl "vendor:raylib"

Id :: distinct int

Edges :: struct {
	top:    f32,
	right:  f32,
	bottom: f32,
	left:   f32,
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
	// Layout children next to each other
	Flex,
	// Does not layout children
	None,
}

// Only used for Flex layout
LayoutDirection :: enum {
	LeftToRight,
	TopToBottom,
}

MainAlignment :: enum {
	Start,
	End,
	Center,
	SpaceBetween,
	SpaceAround,
	SpaceEvenly,
}

CrossAlignment :: enum {
	Start,
	End,
	Center,
}

ContentAlignment :: enum {
	Start,
	Center,
	End,
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
	border:           Edges,
	gap:              f32,
	align_main:       MainAlignment,
	align_cross:      CrossAlignment,
	// overflow?

	// style
	background_color: rl.Color,
	border_color:     rl.Color,
	// TODO: corner radius

	// text
	has_text:         bool,
	text:             string,
	font:             ^rl.Font,
	font_size:        f32,
	color:            rl.Color,
	letter_spacing:   f32,
	line_height:      f32,

	// content layout
	align:            [2]ContentAlignment,
}

Element :: struct {
	id:               Id,
	parent:           int,
	children:         int,
	next:             int,
	children_count:   int,
	user_data:        rawptr,

	// layout
	layout:           Layout,
	direction:        LayoutDirection,
	position:         Position,
	width:            Size,
	height:           Size,
	padding:          Edges,
	margin:           Edges,
	border:           Edges,
	gap:              f32,
	align_main:       MainAlignment,
	align_cross:      CrossAlignment,

	// style
	background_color: rl.Color,
	border_color:     rl.Color,

	// text
	has_text:         bool,
	text:             string,
	font:             ^rl.Font,
	font_size:        f32,
	color:            rl.Color,
	letter_spacing:   f32,
	line_height:      f32,

	// content layout
	align:            [2]ContentAlignment,

	// internal
	_position:        rl.Vector2,
	_size:            rl.Vector2, // border box size
	_measured_size:   rl.Vector2,
	_line_count:      int,
	_text_offset:     rl.Vector2,
}

@(private)
configure_element :: proc(element: ^Element, config: ElementConfig) {
	element.user_data = config.user_data

	// layout
	element.layout = config.layout
	element.direction = config.direction
	element.position = config.position
	element.width = config.width
	element.height = config.height
	element.padding = config.padding
	element.margin = config.margin
	element.border = config.border
	element.gap = config.gap
	element.align_main = config.align_main
	element.align_cross = config.align_cross

	// style
	element.background_color = config.background_color
	element.border_color = config.border_color

	// text
	element.has_text = config.has_text
	element.text = config.text
	element.font = config.font
	element.font_size = config.font_size
	element.color = config.color
	element.letter_spacing = config.letter_spacing
	element.line_height = config.line_height

	// content layout
	element.align = config.align
}

to_id :: proc(str: string) -> Id {
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
