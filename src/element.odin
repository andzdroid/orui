package orui

import "core:hash"
import "core:strings"
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
	// Element shrinks to fit its content.
	// Only used by children of Flex and Grid layouts.
	Fit,
	// Element grows to fill available space.
	// Only used by children of Flex and Grid layouts.
	Grow,
	// Element is a percentage of its parent's size.
	Percent,
	// Element is a fixed pixel size.
	Fixed,
}

Size :: struct {
	type:  SizeType,
	value: f32,
	min:   f32,
	max:   f32,
}

PositionType :: enum {
	// Default. Positioned by flex/grid parent. Don't use this if parent is not flex or grid.
	Auto,
	// Positioned relative to the closest ancestor with a non-auto position.
	Absolute,
	// Positioned relative to its parent's position.
	// When used in a flex/grid container, it will be relative to its Auto position.
	Relative,
	// Positioned relative to the root element (the screen).
	Fixed,
}

Position :: struct {
	type:  PositionType,
	value: rl.Vector2,
}

Placement :: struct {
	// The anchor is the point on the parent that the element will be placed relative to.
	anchor: rl.Vector2,
	// The origin is the point on the element that will be placed at the specified position.
	origin: rl.Vector2,
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
	// Align children to beginning of element
	Start,
	// Align children to end of element
	End,
	// Center the children
	Center,
	// Distribute children with equal space between them, no space at edges
	SpaceBetween,
	// Distribute children with equal space around each item
	SpaceAround,
	// Distribute children with equal space between them and edges
	SpaceEvenly,
}

CrossAlignment :: enum {
	// Align children to beginning of element
	Start,
	// Align children to end of element
	End,
	// Center the children
	Center,
}

ContentAlignment :: enum {
	Start,
	Center,
	End,
}

FlexWrap :: enum {
	NoWrap,
	Wrap,
}

InheritedBool :: enum {
	Inherit,
	False,
	True,
}

Overflow :: enum {
	// Content will be wrapped to fit in the element.
	Wrap,
	// Content will be visible outside of the element.
	// You might want to combine this with clip and/or scroll.
	Visible,
}

WhitespaceMode :: enum {
	// Collapse sequences of spaces; typical for display text.
	Collapse,
	// Preserve all whitespace; typical for text input.
	Preserve,
}

TextureFit :: enum {
	// Image will be stretched or squashed to fill the container.
	Fill,
	// Keeps its aspect ratio, and resizes to fit the container.
	Contain,
	// Keeps its aspect ratio, and resizes to fill the container. Image may be clipped.
	Cover,
	// Image is not resized.
	None,
	// Same as contain but only scale down, never up.
	ScaleDown,
}

ClipType :: enum {
	// Use parent clip
	Inherit,
	// Set clip to element position and size
	Self,
	// Set clip to element position and size, and intersect with parent clip
	Intersect,
	// Set clip to the provided rectangle
	Manual,
	// Do not clip the element
	None,
}

ClipRectangle :: struct {
	x:      i32,
	y:      i32,
	width:  i32,
	height: i32,
}

Clip :: struct {
	type:      ClipType,
	rectangle: ClipRectangle,
}

ScrollDirection :: enum {
	None,
	Auto,
	// Automatically handle mouse scroll events for vertical scrolling.
	Vertical,
	// Automatically handle mouse scroll events for horizontal scrolling.
	Horizontal,
	// Manually set scroll offset
	Manual,
}

ScrollConfig :: struct {
	direction: ScrollDirection,
	offset:    rl.Vector2,
}

ElementConfig :: struct {
	// Determines how child elements are sized and positioned.
	layout:           Layout,
	// Determines the direction of child elements for Grid and Flex layouts.
	direction:        LayoutDirection,
	// Position type of the element.
	position:         Position,
	// How the element is positioned relative to its parent or anchor element.
	// Used for non-auto position types.
	placement:        Placement,
	// How the element width is sized.
	width:            Size,
	// How the element height is sized.
	height:           Size,
	// Padding in pixels.
	// Padding is the space inside the element's border.
	padding:          Edges,
	// Margin in pixels.
	// Margin is the space outside the element's border.
	margin:           Edges,
	// Border width in pixels.
	border:           Edges,
	// Gap between child elements in pixels.
	// Only used for Flex and Grid layouts.
	gap:              f32,
	// How child elements are aligned along the main axis.
	// Equivalent to justify-content in css.
	align_main:       MainAlignment,
	// How child elements are aligned along the cross axis.
	// Equivalent to align-items in css.
	align_cross:      CrossAlignment,
	// How wrapped lines/columns are distributed along the cross axis.
	// Equivalent to align-content in css. Used when flex_wrap = .Wrap.
	align_content:    MainAlignment,
	// How child elements are wrapped along the main axis.
	flex_wrap:        FlexWrap,
	// How the element handles overflowing text content.
	overflow:         Overflow,
	// Control the render order of the element.
	// Inherited from parent by default.
	layer:            int,
	// How the element is clipped.
	// Inherited from parent by default.
	clip:             Clip,

	// Number of columns.
	// Only used for Grid layout.
	cols:             int,
	// Size of each column.
	// If the size of a column is not provided, the last provided size is used.
	col_sizes:        []Size,
	// Number of rows.
	// Only used for Grid layout.
	rows:             int,
	// Size of each row.
	// If the size of a row is not provided, the last provided size is used.
	row_sizes:        []Size,
	// Gap between columns in pixels.
	// If not provided, falls back to `gap`.
	col_gap:          f32,
	// Gap between rows in pixels.
	// If not provided, falls back to `gap`.
	row_gap:          f32,
	// How many columns this element should span.
	// Only used for Grid layout children.
	col_span:         int,
	// How many rows this element should span.
	// Only used for Grid layout children.
	row_span:         int,

	// Foreground color.
	// Used for text color if there is text, and texture tint if there is a texture.
	color:            rl.Color,
	// Background color.
	// If the alpha is 0, nothing is drawn.
	// Default background color is invisible.
	background_color: rl.Color,
	// Border color.
	// If the alpha is 0, nothing is drawn.
	// Default border color is invisible.
	border_color:     rl.Color,
	// Corner radius.
	// Will be applied to both backgrounds and borders.
	// Does not apply to content (labels, images).
	corner_radius:    Corners,

	// Must be true if this element has text.
	has_text:         bool,
	// The string to render.
	text:             string,
	// The font family to use for the text.
	font:             ^rl.Font,
	// The font size to use for the text.
	font_size:        f32,
	// The space between letters in pixels.
	letter_spacing:   f32,
	// The line height multiplier. Default is 1.
	line_height:      f32,
	// How whitespace is handled when measuring and wrapping text.
	whitespace:       WhitespaceMode,
	text_input:       ^strings.Builder,

	// Must be true if this element has a texture.
	has_texture:      bool,
	// The texture to use for the element.
	texture:          ^rl.Texture2D,
	// The source rectangle of the texture that you want to draw.
	texture_source:   rl.Rectangle,
	// How the texture should be resized to fit the element size.
	texture_fit:      TextureFit,

	// How the content (text, image) should be aligned within the element.
	align:            [2]ContentAlignment,

	// Whether the element can be interacted with. Inherited from parent by default.
	disabled:         InheritedBool,
	// Whether the element will consume mouse interactions, blocking elements below it from receiving them.
	// Inherited from parent by default.
	block:            InheritedBool,
	// Whether the element will consume interactions once they are activated.
	// Recommended to be set to True for things like sliders and draggable windows.
	// Inherited from parent by default.
	capture:          InheritedBool,
	editable:         bool,

	// Scroll configuration
	scroll:           ScrollConfig,

	// Emit a custom event in the render command array for this element.
	// Can be used to interleave your own rendering with orui's rendering.
	custom_event:     rawptr,
}

Element :: struct {
	id:                Id,
	parent:            int,
	children:          int,
	next:              int,
	children_count:    int,

	// layout
	layout:            Layout,
	direction:         LayoutDirection,
	position:          Position,
	placement:         Placement,
	width:             Size,
	height:            Size,
	padding:           Edges,
	margin:            Edges,
	border:            Edges,
	gap:               f32,
	align_main:        MainAlignment,
	align_cross:       CrossAlignment,
	align_content:     MainAlignment,
	flex_wrap:         FlexWrap,
	overflow:          Overflow,
	layer:             int,
	clip:              Clip,

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
	whitespace:        WhitespaceMode,
	text_input:        ^strings.Builder,

	// texture
	has_texture:       bool,
	texture:           ^rl.Texture2D,
	texture_source:    rl.Rectangle,
	texture_fit:       TextureFit,

	// content layout
	align:             [2]ContentAlignment,

	// input
	disabled:          InheritedBool,
	block:             InheritedBool,
	capture:           InheritedBool,
	editable:          bool,

	// scroll
	scroll:            ScrollConfig,

	// custom event
	custom_event:      rawptr,

	// internal
	_position:         rl.Vector2,
	_size:             rl.Vector2, // border box size
	_content_size:     rl.Vector2,
	_layer:            int,
	_line_count:       int,
	_line:             int,
	_grid_col_index:   int,
	_grid_row_index:   int,
	_grid_row_sizes:   [MAX_GRID_TRACKS]f32,
	_grid_col_sizes:   [MAX_GRID_TRACKS]f32,
	_grid_row_offsets: [MAX_GRID_TRACKS]f32,
	_grid_col_offsets: [MAX_GRID_TRACKS]f32,
	_clip:             ClipRectangle,
}

@(private)
configure_element :: proc(element: ^Element, parent: Element, config: ElementConfig) {
	// layout
	element.layout = config.layout
	element.direction = config.direction
	element.position = config.position
	element.placement = config.placement
	element.width = config.width
	element.height = config.height
	element.padding = config.padding
	element.margin = config.margin
	element.border = config.border
	element.gap = config.gap
	element.align_main = config.align_main
	element.align_cross = config.align_cross
	element.align_content = config.align_content
	element.flex_wrap = config.flex_wrap
	element.overflow = config.overflow
	element.layer = config.layer
	element.clip = config.clip

	// grid
	element.cols = config.cols
	{
		provided := len(config.col_sizes)
		copy_count := min(provided, MAX_GRID_TRACKS)
		for i in 0 ..< copy_count {
			element.col_sizes[i] = config.col_sizes[i]
		}
		last := provided > 0 ? config.col_sizes[provided - 1] : {}
		for i in copy_count ..< element.cols {
			element.col_sizes[i] = last
		}
	}
	element.rows = config.rows
	{
		provided := len(config.row_sizes)
		copy_count := min(provided, MAX_GRID_TRACKS)
		for i in 0 ..< copy_count {
			element.row_sizes[i] = config.row_sizes[i]
		}
		last := provided > 0 ? config.row_sizes[provided - 1] : {}
		for i in copy_count ..< element.rows {
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
	element.whitespace = config.whitespace
	element.text_input = config.text_input

	// texture
	element.has_texture = config.has_texture
	element.texture = config.texture
	element.texture_source = config.texture_source
	element.texture_fit = config.texture_fit

	// content layout
	element.align = config.align

	// input
	element.disabled = config.disabled == .Inherit ? parent.disabled : config.disabled
	element.block = config.block == .Inherit ? parent.block : config.block
	element.capture = config.capture == .Inherit ? parent.capture : config.capture
	element.editable = config.editable

	// scroll
	element.scroll = config.scroll

	element.custom_event = config.custom_event
}

to_id :: proc {
	to_id_compiled,
	to_id_runtime,
	to_id_int,
	to_id_string_index,
	to_id_id_index,
}

to_id_compiled :: proc($S: string) -> Id {
	return Id(#hash(S, "fnv32a"))
}

to_id_runtime :: proc(str: string) -> Id {
	return Id(hash.fnv32a(transmute([]u8)str))
}

to_id_string_index :: proc(str: string, index: int) -> Id {
	return Id(hash.fnv32a(transmute([]u8)str, u32(index)))
}

to_id_int :: proc(id: int) -> Id {
	return Id(id)
}

to_id_id_index :: proc(id: Id, index: int) -> Id {
	id_u32 := u32(id)
	id_bytes := transmute([4]u8)id_u32
	return Id(hash.fnv32a(id_bytes[:], u32(index)))
}
