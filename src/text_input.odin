package orui

import "core:math"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"
import rl "vendor:raylib"

TextSelection :: struct {
	start: int,
	end:   int,
}

TextSelectionMode :: enum u8 {
	Character,
	Word,
	Line,
}

@(private)
TextSelectionClass :: enum u8 {
	Word,
	Whitespace,
	Newline,
	Other,
}

@(private = "file")
is_continuation_byte :: #force_inline proc(b: u8) -> bool {
	return b >= 0x80 && b < 0xc0
}

@(private = "file")
is_space :: #force_inline proc(b: u8) -> bool {
	return b == ' ' || b == '\t' || b == '\n'
}

@(private)
utf8_prev :: proc {
	utf8_prev_builder,
	utf8_prev_string,
}

@(private)
utf8_prev_builder :: proc(text: ^strings.Builder, index: int) -> int {
	if index <= 0 {
		return 0
	}

	index := index
	index -= 1
	for index > 0 && is_continuation_byte(text.buf[index]) {
		index -= 1
	}
	return index
}

@(private)
utf8_next :: proc {
	utf8_next_builder,
	utf8_next_string,
}

@(private)
utf8_next_builder :: proc(text: ^strings.Builder, index: int) -> int {
	if index >= len(text.buf) {
		return len(text.buf)
	}

	index := index
	index += 1
	for index < len(text.buf) && is_continuation_byte(text.buf[index]) {
		index += 1
	}
	return index
}

@(private)
utf8_prev_word :: proc(text: ^strings.Builder, index: int) -> int {
	if index <= 0 {
		return 0
	}

	index := index
	for index > 0 && is_space(text.buf[index - 1]) {
		index -= 1
	}
	for index > 0 && !is_space(text.buf[index - 1]) {
		index -= 1
	}
	return index
}

@(private)
utf8_next_word :: proc(text: ^strings.Builder, index: int) -> int {
	if index >= len(text.buf) {
		return len(text.buf)
	}

	index := index
	for index < len(text.buf) && is_space(text.buf[index]) {
		index += 1
	}
	for index < len(text.buf) && !is_space(text.buf[index]) {
		index += 1
	}
	return index
}

@(private)
utf8_prev_string :: proc(text: string, idx: int) -> int {
	if idx <= 0 {
		return 0
	}

	index := min(idx, len(text))
	index -= 1
	for index > 0 && is_continuation_byte(text[index]) {
		index -= 1
	}
	return index
}

@(private)
utf8_next_string :: proc(text: string, idx: int) -> int {
	if idx >= len(text) {
		return len(text)
	}

	index := max(idx, 0)
	index += 1
	for index < len(text) && is_continuation_byte(text[index]) {
		index += 1
	}
	return index
}

@(private)
rune_start :: proc(text: string, idx: int) -> int {
	if len(text) == 0 {
		return 0
	}

	index := clamp(idx, 0, len(text))
	if index == len(text) {
		return utf8_prev(text, index)
	}
	for index > 0 && is_continuation_byte(text[index]) {
		index -= 1
	}
	return index
}

@(private)
text_selection_class :: proc(text: string, idx: int) -> TextSelectionClass {
	if len(text) == 0 {
		return .Other
	}

	index := rune_start(text, idx)
	r, _ := utf8.decode_rune(text[index:])
	if r == '\n' {
		return .Newline
	}
	if r == '_' || unicode.is_letter(r) || unicode.is_digit(r) {
		return .Word
	}
	if unicode.is_space(r) {
		return .Whitespace
	}
	return .Other
}

@(private)
previous_selection_index :: proc(text: string, idx: int) -> int {
	index := clamp(idx, 0, len(text))
	for index > 0 {
		prev := utf8_prev(text, index)
		class := text_selection_class(text, prev)
		if class != .Whitespace && class != .Newline {
			return prev
		}
		index = prev
	}
	return 0
}

@(private)
text_word_range :: proc(text: string, index: int) -> TextSelection {
	if len(text) == 0 {
		return {}
	}

	index := index
	if index >= len(text) {
		// handle edge case of double-clicking the end of the text
		index = previous_selection_index(text, index)
	} else {
		index = rune_start(text, index)
	}
	selection_class := text_selection_class(text, index)

	start := index
	for start > 0 {
		prev := utf8_prev(text, start)
		if text_selection_class(text, prev) != selection_class {
			break
		}
		start = prev
	}

	end := utf8_next(text, index)
	for end < len(text) {
		if text_selection_class(text, end) != selection_class {
			break
		}
		end = utf8_next(text, end)
	}

	return {start, end}
}

@(private)
text_line_range :: proc(text: string, idx: int) -> TextSelection {
	if len(text) == 0 {
		return {}
	}

	index := clamp(idx, 0, len(text))
	if index == len(text) {
		index = utf8_prev(text, index)
	}
	start := index
	for start > 0 && text[start - 1] != '\n' {
		start -= 1
	}

	end := index
	for end < len(text) && text[end] != '\n' {
		end += 1
	}
	if end < len(text) && text[end] == '\n' {
		end += 1
	}

	return {start, end}
}

@(private)
extend_text_selection :: proc(
	anchor, target: TextSelection,
) -> (
	selection: TextSelection,
	caret: int,
) {
	if target.start < anchor.start {
		return {anchor.end, target.start}, target.start
	}
	return {anchor.start, target.end}, target.end
}

@(private)
insert_bytes :: proc(builder: ^strings.Builder, position: int, text: string) -> int {
	if position < 0 || position > len(builder.buf) {
		return 0
	}

	if ok, _ := inject_at(&builder.buf, position, text); !ok {
		n := cap(builder.buf) - len(builder.buf)
		for is_continuation_byte(text[n]) {
			n -= 1
		}
		if ok2, _ := inject_at(&builder.buf, position, text[:n]); !ok2 {
			n = 0
		}
		return n
	}

	return len(text)
}

@(private)
delete_range :: proc(builder: ^strings.Builder, start: int, end: int) -> bool {
	safe_start := max(0, start)
	safe_end := min(end, len(builder.buf))
	if safe_end <= safe_start {
		return true
	}
	remove_range(&builder.buf, safe_start, safe_end)
	return true
}

@(private)
text_index_from_point :: proc(ctx: ^Context, element: ^Element, point: rl.Vector2) -> int {
	text := element.text
	if len(text) == 0 {
		return 0
	}

	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
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
		line_offset := calculate_line_offset(element, element._text_width, inner_width)
		local_x := point.x - (x_start + line_offset)
		if local_x >= element._text_width {
			return len(text)
		}
		return text_index_in_line(element, text, 0, len(text), local_x, letter_spacing)
	} else if element.overflow == .Wrap {
		total_lines := element._line_count > 0 ? element._line_count : 1
		target_line := int(math.floor((point.y - y_start) / element._line_height))
		target_line = clamp(target_line, 0, int(total_lines - 1))

		cache := get_text_cache(ctx, element, inner_width, letter_spacing)
		line := cache.lines[target_line]
		line_offset := calculate_line_offset(element, line.width, inner_width)
		x := point.x - (x_start + line_offset)
		if x >= line.width && line.end == len(text) {
			return len(text)
		}
		return text_index_in_line(element, text, line.start, line.end, x, letter_spacing)
	}

	return 0
}

@(private)
text_caret_from_point :: proc(ctx: ^Context, element: ^Element, point: rl.Vector2) -> int {
	text := element.text
	if len(text) == 0 {
		return 0
	}

	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
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
		line_offset := calculate_line_offset(element, element._text_width, inner_width)
		local_x := point.x - (x_start + line_offset)

		if local_x <= 0 {
			return 0
		}

		if local_x >= element._text_width {
			return len(text)
		}

		return caret_index_in_line(element, text, 0, len(text), local_x, letter_spacing)
	} else if element.overflow == .Wrap {
		total_lines := element._line_count > 0 ? element._line_count : 1
		target_line := int(math.floor((point.y - y_start) / element._line_height))
		target_line = clamp(target_line, 0, int(total_lines - 1))

		cache := get_text_cache(ctx, element, inner_width, letter_spacing)
		line := cache.lines[target_line]
		line_start := line.start
		line_end := line.end
		width := line.width
		line_offset := calculate_line_offset(element, width, inner_width)
		x := point.x - (x_start + line_offset)
		if x <= 0 {
			return line_start
		}
		if x >= width {
			// step back one rune at the end of a soft-wrapped line
			if line_end < len(text) && text[line_end] != '\n' {
				if line_end == 0 {
					return 0
				}
				prev := line_end - 1
				for prev > 0 && is_continuation_byte(text[prev]) {
					prev -= 1
				}
				if prev < line_start {
					return line_start
				}
				return prev
			}
			return line_end
		}
		idx := caret_index_in_line(element, text, line_start, line_end, x, letter_spacing)
		// step back one rune at the end of a soft-wrapped line
		if idx == line_end && line_end < len(text) && text[line_end] != '\n' {
			if line_end == 0 {
				return 0
			}
			prev := line_end - 1
			for prev > 0 && is_continuation_byte(text[prev]) {
				prev -= 1
			}
			if prev < line_start {
				return line_start
			}
			return prev
		}
		return idx
	}

	return 0
}

@(private)
// Get a specific line from wrapped text.
// Returns the start index, end index, and width of the line.
wrapped_line_at :: proc(
	ctx: ^Context,
	element: ^Element,
	target_line: int,
	inner_width: f32,
	letter_spacing: f32,
) -> (
	start: int,
	end: int,
	width: f32,
) {
	cache := get_text_cache(ctx, element, inner_width, letter_spacing)
	if target_line >= 0 && target_line < len(cache.lines) {
		l := cache.lines[target_line]
		return l.start, l.end, l.width
	}
	text_len := len(element.text)
	return text_len, text_len, 0
}

@(private)
// Get the text index under a point in a line of text.
text_index_in_line :: proc(
	element: ^Element,
	text: string,
	start: int,
	end: int,
	x: f32,
	letter_spacing: f32,
) -> int {
	acc: f32 = 0
	count := 0
	i := start
	prev := start

	for i < end {
		prev = i
		r, size := utf8.decode_rune(text[i:end])
		adv := glyph_advance(element.font, r, element.font_size)
		spacing := count > 0 ? letter_spacing : 0
		step := spacing + adv

		if x <= acc + step {
			return i
		}

		acc += step
		count += 1
		i += size
	}

	return prev
}

@(private)
// Get the caret index in a line of text, given an x position.
// This rounds to the nearest caret position:
// left half of a glyph returns caret index to the left of the character
// right half of a glyph returns caret index to the right of the character
caret_index_in_line :: proc(
	element: ^Element,
	text: string,
	start: int,
	end: int,
	x: f32,
	letter_spacing: f32,
) -> int {
	acc: f32 = 0
	count := 0
	i := start

	for i < end {
		r, size := utf8.decode_rune(text[i:end])
		adv := glyph_advance(element.font, r, element.font_size)
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
caret_index_up :: proc(ctx: ^Context, element: ^Element, from: rl.Vector2, lines := 1) -> int {
	target := from - {0, element._line_height * f32(lines)}
	return text_caret_from_point(ctx, element, target)
}

@(private)
caret_index_down :: proc(ctx: ^Context, element: ^Element, from: rl.Vector2, lines := 1) -> int {
	target := from + {0, element._line_height * f32(lines)}
	return text_caret_from_point(ctx, element, target)
}

@(private)
caret_index_start_of_line :: proc(ctx: ^Context, element: ^Element, caret_index: int) -> int {
	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	inner_width := inner_width(element)
	current_line_index := find_caret_line(ctx, element, caret_index, inner_width, letter_spacing)
	line_start, _, _ := wrapped_line_at(
		ctx,
		element,
		current_line_index,
		inner_width,
		letter_spacing,
	)
	return line_start
}

@(private)
caret_index_end_of_line :: proc(ctx: ^Context, element: ^Element, caret_index: int) -> int {
	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	inner_width := inner_width(element)
	current_line_index := find_caret_line(ctx, element, caret_index, inner_width, letter_spacing)
	_, line_end, _ := wrapped_line_at(
		ctx,
		element,
		current_line_index,
		inner_width,
		letter_spacing,
	)

	// step back one rune at the end of a soft-wrapped line
	if line_end < len(element.text) && element.text[line_end] != '\n' {
		if line_end == 0 {
			return 0
		}
		prev := line_end - 1
		for prev > 0 && is_continuation_byte(element.text[prev]) {
			prev -= 1
		}
		return prev
	}

	return line_end
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

	clamped_caret_index := clamp(caret_index, 0, len(element.text))
	text_before_caret := element.text[:clamped_caret_index]
	caret_x := measure_text_width(
		ctx,
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
	element.scroll.offset = scroll_offset
}

@(private)
ensure_caret_visible_vertical :: proc(ctx: ^Context, element: ^Element, caret_index: int) {
	if len(element.text) == 0 {
		return
	}

	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	line_height := element._line_height
	inner_width := inner_width(element)
	inner_height := inner_height(element)

	caret_line := find_caret_line(ctx, element, caret_index, inner_width, letter_spacing)
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
	element.scroll.offset = scroll_offset
}

@(private)
find_caret_line :: proc(
	ctx: ^Context,
	element: ^Element,
	caret_index: int,
	inner_width: f32,
	letter_spacing: f32,
) -> int {
	text := element.text
	text_len := len(text)
	cache := get_text_cache(ctx, element, inner_width, letter_spacing)
	for i := 0; i < len(cache.lines); i += 1 {
		line := cache.lines[i]
		if caret_index < line.end {
			return i
		}
		if caret_index == line.end {
			if line.hard_break {
				return i
			}
			// soft wrap: continue to next line
		}
	}
	if text_len > 0 && text[text_len - 1] == '\n' && caret_index == text_len {
		return len(cache.lines)
	}
	return max(len(cache.lines) - 1, 0)
}
