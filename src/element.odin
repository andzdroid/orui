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
	None,
	Flex,
}

LayoutDirection :: enum {
	LeftToRight,
	TopToBottom,
}

HorizontalAlignment :: enum {
	Left,
	Center,
	Right,
}

VerticalAlignment :: enum {
	Top,
	Center,
	Bottom,
}

ElementConfig :: struct {
	user_data:            rawptr,

	// layout
	layout:               Layout,
	direction:            LayoutDirection,
	position:             Position,
	width:                Size,
	height:               Size,
	padding:              Edges,
	margin:               Edges,
	gap:                  f32,

	// style
	background_color:     rl.Color,

	// text
	has_text:             bool,
	text:                 string,
	font:                 ^rl.Font,
	font_size:            f32,
	color:                rl.Color,
	letter_spacing:       f32,
	line_height:          f32,

	// text layout
	wrap:                 bool,
	horizontal_alignment: HorizontalAlignment,
	vertical_alignment:   VerticalAlignment,
	// TODO: overflow?
}

Element :: struct {
	id:                   Id,
	user_data:            rawptr,

	// layout
	layout:               Layout,
	direction:            LayoutDirection,
	position:             Position,
	width:                Size,
	height:               Size,
	padding:              Edges,
	margin:               Edges,
	gap:                  f32,

	// style
	background_color:     rl.Color,

	// text
	has_text:             bool,
	text:                 string,
	font:                 ^rl.Font,
	font_size:            f32,
	color:                rl.Color,
	letter_spacing:       f32,
	line_height:          f32,

	// text layout
	wrap:                 bool,
	horizontal_alignment: HorizontalAlignment,
	vertical_alignment:   VerticalAlignment,

	// internal
	_position:            rl.Vector2,
	_size:                rl.Vector2, // border box size
	_measured_size:       rl.Vector2,
	_line_count:          int,
	parent:               int,
	children:             int,
	next:                 int,
	children_count:       int,
}

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
	element.gap = config.gap

	// style
	element.background_color = config.background_color

	// text
	element.has_text = config.has_text
	element.text = config.text
	element.font = config.font
	element.font_size = config.font_size
	element.color = config.color
	element.letter_spacing = config.letter_spacing
	element.line_height = config.line_height

	// text layout
	element.wrap = config.wrap
	element.horizontal_alignment = config.horizontal_alignment
	element.vertical_alignment = config.vertical_alignment
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
