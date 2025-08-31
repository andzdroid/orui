package orui

import rl "vendor:raylib"

Id :: distinct int

Edges :: struct {
	top:    f32,
	right:  f32,
	bottom: f32,
	left:   f32,
}

Corners :: struct {
	top_left:     f32,
	top_right:    f32,
	bottom_right: f32,
	bottom_left:  f32,
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
	// Layout children in columns and rows
	Grid,
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

InheritedBool :: enum {
	Inherit,
	False,
	True,
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

	// grid
	cols:             int,
	col_sizes:        []Size,
	rows:             int,
	row_sizes:        []Size,
	col_gap:          f32,
	row_gap:          f32,
	col_span:         int,
	row_span:         int,

	// style
	color:            rl.Color,
	background_color: rl.Color,
	border_color:     rl.Color,
	corner_radius:    Corners,

	// text
	has_text:         bool,
	text:             string,
	font:             ^rl.Font,
	font_size:        f32,
	letter_spacing:   f32,
	line_height:      f32,

	// texture
	has_texture:      bool,
	texture:          ^rl.Texture2D,
	texture_source:   rl.Rectangle,

	// content layout
	align:            [2]ContentAlignment,

	// input
	disabled:         InheritedBool,
	block:            InheritedBool,
	capture:          InheritedBool,
}

Element :: struct {
	id:                Id,
	parent:            int,
	children:          int,
	next:              int,
	children_count:    int,
	user_data:         rawptr,

	// layout
	layout:            Layout,
	direction:         LayoutDirection,
	position:          Position,
	width:             Size,
	height:            Size,
	padding:           Edges,
	margin:            Edges,
	border:            Edges,
	gap:               f32,
	align_main:        MainAlignment,
	align_cross:       CrossAlignment,

	// grid
	cols:              int,
	col_sizes:         [MAX_GRID_TRACKS]Size,
	rows:              int,
	row_sizes:         [MAX_GRID_TRACKS]Size,
	col_gap:           f32,
	row_gap:           f32,
	col_span:          int,
	row_span:          int,

	// style
	color:             rl.Color,
	background_color:  rl.Color,
	border_color:      rl.Color,
	corner_radius:     Corners,

	// text
	has_text:          bool,
	text:              string,
	font:              ^rl.Font,
	font_size:         f32,
	letter_spacing:    f32,
	line_height:       f32,

	// texture
	has_texture:       bool,
	texture:           ^rl.Texture2D,
	texture_source:    rl.Rectangle,

	// content layout
	align:             [2]ContentAlignment,

	// input
	disabled:          InheritedBool,
	block:             InheritedBool,
	capture:           InheritedBool,

	// internal
	_position:         rl.Vector2,
	_size:             rl.Vector2, // border box size
	_line_count:       int,
	_grid_col_index:   int,
	_grid_row_index:   int,
	_grid_row_sizes:   [MAX_GRID_TRACKS]f32,
	_grid_col_sizes:   [MAX_GRID_TRACKS]f32,
	_grid_row_offsets: [MAX_GRID_TRACKS]f32,
	_grid_col_offsets: [MAX_GRID_TRACKS]f32,
}

@(private)
configure_element :: proc(element: ^Element, parent: Element, config: ElementConfig) {
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

	// grid
	element.cols = config.cols
	{
		provided := len(config.col_sizes)
		copy_count := provided
		if copy_count > MAX_GRID_TRACKS {copy_count = MAX_GRID_TRACKS}
		for i in 0 ..< copy_count {
			element.col_sizes[i] = config.col_sizes[i]
		}
		last := Size{}
		if provided > 0 {
			last = config.col_sizes[provided - 1]
		}
		for i in copy_count ..< MAX_GRID_TRACKS {
			element.col_sizes[i] = last
		}
	}
	element.rows = config.rows
	{
		provided := len(config.row_sizes)
		copy_count := provided
		if copy_count > MAX_GRID_TRACKS {copy_count = MAX_GRID_TRACKS}
		for i in 0 ..< copy_count {
			element.row_sizes[i] = config.row_sizes[i]
		}
		last := Size{}
		if provided > 0 {
			last = config.row_sizes[provided - 1]
		}
		for i in copy_count ..< MAX_GRID_TRACKS {
			element.row_sizes[i] = last
		}
	}
	element.col_gap = config.col_gap
	element.row_gap = config.row_gap
	element.col_span = config.col_span
	element.row_span = config.row_span

	// style
	element.color = config.color
	element.background_color = config.background_color
	element.border_color = config.border_color
	element.corner_radius = config.corner_radius

	// text
	element.has_text = config.has_text
	element.text = config.text
	element.font = config.font
	element.font_size = config.font_size
	element.letter_spacing = config.letter_spacing
	element.line_height = config.line_height

	// texture
	element.has_texture = config.has_texture
	element.texture = config.texture
	element.texture_source = config.texture_source

	// content layout
	element.align = config.align

	// input
	element.disabled = config.disabled == .Inherit ? parent.disabled : config.disabled
	element.block = config.block == .Inherit ? parent.block : config.block
	element.capture = config.capture == .Inherit ? parent.capture : config.capture
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
