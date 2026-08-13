package orui

import "core:strings"
import rl "vendor:raylib"

@(deferred_none = end_element)
// An element that can contain children.
// Must have its own scope.
container :: proc(
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

// A text element that can be use to display text.
// This element cannot have children.
label :: proc(
	id: Id,
	text: string,
	config: ElementConfig,
	modifiers: ..ElementModifier,
	loc := #caller_location,
) -> bool {
	ctx := current_context
	element, parent := begin_element(id, loc)
	configure_element(ctx, element, parent^, config)
	element.layout = .None
	element.has_text = true
	element.text = text

	for modifier in modifiers {
		modifier(element)
	}

	if element.font == nil && current_context.default_font != {} {
		element.font = &current_context.default_font
	}

	end_element()

	return clicked()
}

// A text element that displays text and allows the user to edit it.
// This element cannot have children.
text_input :: proc(
	id: Id,
	text: ^strings.Builder,
	config: ElementConfig,
	modifiers: ..ElementModifier,
	loc := #caller_location,
) -> bool {
	ctx := current_context
	element, parent := begin_element(id, loc)
	configure_element(ctx, element, parent^, config)
	element.layout = .None
	element.has_text = true
	element.text_input = text
	element.text = string(text.buf[:])
	element.editable = true
	element.whitespace = .Preserve
	element.cursor = .IBeam

	for modifier in modifiers {
		modifier(element)
	}

	if element.font == nil && current_context.default_font != {} {
		element.font = &current_context.default_font
	}

	end_element()

	return current_context.prev_focus_id == id && current_context.focus_id != id
}

// An element that displays a texture.
// This element cannot have children.
image :: proc(
	id: Id,
	texture: ^rl.Texture2D,
	config: ElementConfig,
	modifiers: ..ElementModifier,
	loc := #caller_location,
) -> bool {
	ctx := current_context
	element, parent := begin_element(id, loc)
	configure_element(ctx, element, parent^, config)
	element.layout = .None
	element.texture = texture

	for modifier in modifiers {
		modifier(element)
	}

	end_element()

	return clicked()
}

scrollbar :: proc(
	parent: Id,
	config: ElementConfig,
	handle_config: ElementConfig,
	index := 0,
	loc := #caller_location,
) {
	ctx := current_context
	background_id := to_id(parent, (index * 2) + 1)
	handle_id := to_id(parent, (index * 2) + 2)

	// scrollbar background
	background_element, background_parent := begin_element(id(background_id), loc)
	configure_element(ctx, background_element, background_parent^, config)
	background_element.clip = {.None, {}}
	background_element.capture = .True
	background_element.cursor = .Pointing_Hand

	scroll_percent, handle_percent := scrollbar_handle_params(parent)
	background_size := size(background_id)
	handle_size := handle_percent * background_size

	// scrollbar handle
	handle_element, handle_parent := begin_element(id(handle_id), loc)
	configure_element(ctx, handle_element, handle_parent^, handle_config)
	handle_element.layout = .None
	if handle_config.direction == .TopToBottom {
		handle_element.height = fixed(handle_size.y)
		y := scroll_percent.y * (background_size.y - handle_size.y)
		handle_element.position = {.Relative, {0, y}}
	} else {
		handle_element.width = fixed(handle_size.x)
		x := scroll_percent.x * (background_size.x - handle_size.x)
		handle_element.position = {.Relative, {x, 0}}
	}
	handle_element.block = .False
	handle_element.capture = .False
	end_element()

	// handle mouse events
	if captured(background_id) {
		scrollbar_background := get_element(background_id)
		scroll_container := get_element(parent)
		scroll_offset := scroll_container.scroll.offset

		if handle_config.direction == .TopToBottom {
			mouse_position := rl.GetMousePosition().y
			relative_position :=
				mouse_position - scrollbar_background._position.y - handle_size.y / 2
			track_range := background_size.y - handle_size.y
			percent := track_range > 0 ? clamp(relative_position / track_range, 0, 1) : 0
			min_y, max_y := scroll_bounds_y(scroll_container)
			scroll_offset.y = min_y + percent * (max_y - min_y)
			set_scroll_offset(parent, scroll_offset)
		} else {
			mouse_position := rl.GetMousePosition().x
			relative_position :=
				mouse_position - scrollbar_background._position.x - handle_size.x / 2
			track_range := background_size.x - handle_size.x
			percent := track_range > 0 ? clamp(relative_position / track_range, 0, 1) : 0
			min_x, max_x := scroll_bounds_x(scroll_container)
			scroll_offset.x = min_x + percent * (max_x - min_x)
			set_scroll_offset(parent, scroll_offset)
		}
	}

	end_element()
}
