package orui

import "core:math"
import "core:unicode/utf8"
import rl "vendor:raylib"

TextView :: struct {
	data:   []u8,
	length: int,
}

TextEdit :: struct {
	id:         Id,
	last_frame: int,
	caret:      int,
	selection:  TextSelection,
	blink_t:    f32,
	scrolL_x:   f32,
}

TextSelection :: struct {
	start: int,
	end:   int,
}

@(private = "file")
utf8_is_cont :: #force_inline proc(b: u8) -> bool {
	return (b & 0xC0) == 0x80
}

@(private)
utf8_prev :: proc(text: ^TextView, index: int) -> int {
	if index <= 0 {
		return 0
	}

	index := index
	index -= 1
	for index > 0 && utf8_is_cont(text.data[index]) {
		index -= 1
	}
	return index
}

@(private)
utf8_next :: proc(text: ^TextView, index: int) -> int {
	if index >= text.length {
		return text.length
	}

	index := index
	index += 1
	for index < text.length && utf8_is_cont(text.data[index]) {
		index += 1
	}
	return index
}

@(private)
insert_bytes :: proc(text_view: ^TextView, position: int, bytes: []u8) -> (bool, int) {
	if position < 0 || position > text_view.length {
		return false, position
	}

	available_space := len(text_view.data) - text_view.length
	if len(bytes) > available_space {
		return false, position
	}

	bytes_to_move := text_view.length - position
	if bytes_to_move > 0 {
		src_start := position
		src_end := position + bytes_to_move
		dst_start := position + len(bytes)
		dst_end := dst_start + bytes_to_move
		copy(text_view.data[dst_start:dst_end], text_view.data[src_start:src_end])
	}

	copy(text_view.data[position:position + len(bytes)], bytes)
	text_view.length += len(bytes)
	return true, position + len(bytes)
}

@(private)
delete_range :: proc(text_view: ^TextView, start: int, end: int) -> bool {
	start := max(0, start)
	end := min(end, text_view.length)
	if end <= start {
		return true
	}

	bytes_after_deletion := text_view.length - end
	if bytes_after_deletion > 0 {
		source_start := end
		source_end := end + bytes_after_deletion
		destination_start := start
		destination_end := destination_start + bytes_after_deletion
		copy(
			text_view.data[destination_start:destination_end],
			text_view.data[source_start:source_end],
		)
	}
	text_view.length -= (end - start)
	return true
}

text_caret_from_point :: proc(element: ^Element, point: rl.Vector2) -> int {
	text := element.text
	if len(text) == 0 {
		return 0
	}

	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	line_height := measure_text_height(element.font_size, element.line_height)
	inner_width := inner_width(element)

	x_start :=
		element._position.x + element.padding.left + element.border.left - element.scroll.offset.x
	y_start :=
		element._position.y +
		element.padding.top +
		element.border.top +
		calculate_text_offset(element) -
		element.scroll.offset.y

	if element.overflow == .Visible {
		line_width := measure_text_width(text, element.font, element.font_size, letter_spacing)
		line_offset := calculate_line_offset(element, line_width, inner_width)
		local_x := point.x - (x_start + line_offset)

		if local_x <= 0 {
			return 0
		}

		if local_x >= line_width {
			return len(text)
		}

		return caret_index_in_line(element, text, 0, len(text), local_x, letter_spacing)
	} else if element.overflow == .Wrap {
		total_lines := element._line_count > 0 ? element._line_count : 1
		target_line := int(math.floor((point.y - y_start) / line_height))
		target_line = clamp(target_line, 0, total_lines - 1)

		line_start, line_end, width := wrapped_line_at(
			element,
			target_line,
			inner_width,
			letter_spacing,
		)
		line_offset := calculate_line_offset(element, width, inner_width)
		x := point.x - (x_start + line_offset)
		if x <= 0 {
			return line_start
		}
		if x >= width {
			return line_end
		}
		return caret_index_in_line(element, text, line_start, line_end, x, letter_spacing)
	}

	return 0
}

@(private)
// Get a specific line from wrapped text.
// Returns the start index, end index, and width of the line.
wrapped_line_at :: proc(
	element: ^Element,
	target_line: int,
	inner_width: f32,
	letter_spacing: f32,
) -> (
	start: int,
	end: int,
	width: f32,
) {
	text := element.text
	text_len := len(text)

	index := 0
	line := 0

	line_start := 0
	line_width: f32 = 0
	pending_space: f32 = 0
	line_started_by_newline := true
	last_nonspace_end := 0

	for index < text_len {
		if text[index] == '\n' {
			// include trailing spaces on hard wrapped lines
			joining_space := (line_width > 0 && pending_space > 0) ? letter_spacing : 0
			actual_width := line_width + pending_space + joining_space
			if line == target_line {
				return line_start, index, actual_width
			}

			// advance to next line
			index += 1
			line += 1
			line_start = index
			line_width = 0
			pending_space = 0
			last_nonspace_end = index
			line_started_by_newline = true
			continue
		}

		// build line until soft wrap or new line
		for index < text_len && text[index] != '\n' {
			word_start, word_end := find_next_space(text, index)
			token := text[word_start:word_end]
			is_space := text[word_start] == ' '
			token_width := measure_text_width(
				token,
				element.font,
				element.font_size,
				letter_spacing,
			)

			if is_space {
				// drop leading spaces on soft wrapped lines
				if line_width == 0 && !line_started_by_newline {
					index = word_end
					line_start = index
					last_nonspace_end = index
					continue
				}
				if line_width > 0 {
					line_width += letter_spacing
				}
				pending_space = token_width
				index = word_end
				continue
			}

			joining_space := pending_space > 0 ? letter_spacing : 0
			next_width := line_width + pending_space + token_width + joining_space

			if next_width <= inner_width + 0.0001 {
				line_width = next_width
				last_nonspace_end = word_end
				pending_space = 0
				index = word_end
				line_started_by_newline = false
				continue
			}

			// soft wrap before this token
			if line == target_line {
				return line_start, last_nonspace_end, line_width
			}

			// start new line
			line += 1
			line_start = word_start
			line_width = 0
			pending_space = 0
			last_nonspace_end = word_start
			line_started_by_newline = false
			index = word_start
			break
		}
	}

	if line_start < index {
		joining_space := (line_width > 0 && pending_space > 0) ? letter_spacing : 0
		actual_width := line_width + pending_space + joining_space
		if line == target_line {
			return line_start, index, actual_width
		}
		line += 1
	}

	return text_len, text_len, 0
}

@(private)
// Get the caret index in a line of text, given an x position.
caret_index_in_line :: proc(
	element: ^Element,
	text: string,
	start: int,
	end: int,
	x: f32,
	letter_spacing: f32,
) -> int {
	font := element.font^
	scale := element.font_size / f32(font.baseSize)

	acc: f32 = 0
	count := 0
	i := start

	for i < end {
		r, size := utf8.decode_rune(text[i:end])

		idx := int(r) - 32
		adv: f32 = 0
		if idx >= 0 && idx < int(font.glyphCount) {
			if font.glyphs[idx].advanceX > 0 {
				adv = f32(font.glyphs[idx].advanceX)
			} else {
				adv = font.recs[idx].width + f32(font.glyphs[idx].offsetX)
			}
		} else {
			q := int('?' - 32)
			if q >= 0 && q < int(font.glyphCount) {
				if font.glyphs[q].advanceX > 0 {
					adv = f32(font.glyphs[q].advanceX)
				} else {
					adv = font.recs[q].width + f32(font.glyphs[q].offsetX)
				}
			}
		}

		adv = adv * scale
		spacing := count > 0 ? letter_spacing : 0
		step := spacing + adv

		if x <= acc + step * 0.5 {
			return i
		}

		acc += step
		count += 1
		i += size
	}

	return end
}

@(private)
caret_index_up :: proc(element: ^Element, from: rl.Vector2) -> int {
	line_height := measure_text_height(element.font_size, element.line_height)
	target := from - {0, line_height}
	return text_caret_from_point(element, target)
}

@(private)
caret_index_down :: proc(element: ^Element, from: rl.Vector2) -> int {
	line_height := measure_text_height(element.font_size, element.line_height)
	target := from + {0, line_height}
	return text_caret_from_point(element, target)
}

@(private)
ensure_caret_visible :: proc(ctx: ^Context, element: ^Element, caret_index: int) {
	if element.overflow == .Visible {
		ensure_caret_visible_horizontal(ctx, element, caret_index)
	} else if element.overflow == .Wrap {
		ensure_caret_visible_vertical(ctx, element, caret_index)
	}
}

@(private)
ensure_caret_visible_horizontal :: proc(ctx: ^Context, element: ^Element, caret_index: int) {
	if len(element.text) == 0 {
		return
	}

	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	inner_width := inner_width(element)

	caret_index := clamp(caret_index, 0, len(element.text))
	text_before_caret := element.text[:caret_index]
	caret_x := measure_text_width(
		text_before_caret,
		element.font,
		element.font_size,
		letter_spacing,
	)
	scroll_offset := get_scroll_offset(element)

	if caret_x < scroll_offset.x {
		scroll_offset.x = caret_x
	}

	if caret_x > scroll_offset.x + inner_width {
		scroll_offset.x = caret_x - inner_width
	}

	max_scroll := max(0, element._content_size.x - inner_width)
	scroll_offset.x = clamp(scroll_offset.x, 0, max_scroll)
	set_scroll_offset(element.id, scroll_offset)
}

@(private)
ensure_caret_visible_vertical :: proc(ctx: ^Context, element: ^Element, caret_index: int) {
	if len(element.text) == 0 {
		return
	}

	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	line_height := measure_text_height(element.font_size, element.line_height)
	inner_width := inner_width(element)
	inner_height := inner_height(element)

	caret_line := find_caret_line(element, caret_index, inner_width, letter_spacing)
	caret_y := f32(caret_line) * line_height

	scroll_offset := get_scroll_offset(element)

	if caret_y < scroll_offset.y {
		scroll_offset.y = caret_y
	}

	if caret_y + line_height > scroll_offset.y + inner_height {
		scroll_offset.y = caret_y + line_height - inner_height
	}

	prev_max := max(0, element._content_size.y - inner_height)
	needed_max := max(0, caret_y + line_height - inner_height)
	max_scroll := max(prev_max, needed_max)
	scroll_offset.y = clamp(scroll_offset.y, 0, max_scroll)
	set_scroll_offset(element.id, scroll_offset)
}

@(private)
find_caret_line :: proc(
	element: ^Element,
	caret_index: int,
	inner_width: f32,
	letter_spacing: f32,
) -> int {
	text := element.text
	text_len := len(text)
	index := 0
	line := 0
	line_width: f32 = 0
	pending_space: f32 = 0
	line_started_by_newline := true
	last_nonspace_end := 0

	for index < text_len {
		if text[index] == '\n' {
			if caret_index <= index {
				return line
			}
			index += 1
			line += 1
			line_width = 0
			pending_space = 0
			last_nonspace_end = index
			line_started_by_newline = true
			continue
		}

		for index < text_len && text[index] != '\n' {
			if caret_index <= index {
				return line
			}

			word_start, word_end := find_next_space(text, index)
			token := text[word_start:word_end]
			is_space := text[word_start] == ' '
			token_width := measure_text_width(
				token,
				element.font,
				element.font_size,
				letter_spacing,
			)

			if is_space {
				if line_width == 0 && !line_started_by_newline {
					index = word_end
					continue
				}
				if line_width > 0 {
					line_width += letter_spacing
				}
				pending_space = token_width
				index = word_end
				continue
			}

			joining_space := pending_space > 0 ? letter_spacing : 0
			next_width := line_width + pending_space + token_width + joining_space

			if next_width <= inner_width + 0.0001 {
				line_width = next_width
				last_nonspace_end = word_end
				pending_space = 0
				index = word_end
				line_started_by_newline = false
				continue
			}

			if caret_index <= last_nonspace_end {
				return line
			}

			line += 1
			line_width = 0
			pending_space = 0
			line_started_by_newline = false
			index = word_start
			break
		}

		if index >= text_len {
			return line
		}
	}

	return line
}
