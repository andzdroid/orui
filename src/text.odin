package orui

import "core:log"
import "core:math"
import "core:strings"
import "core:unicode/utf8"
import rl "vendor:raylib"

@(private)
TextLine :: struct {
	start:      int,
	end:        int,
	width:      f32,
	hard_break: bool,
}

@(private)
TextWrapIterator :: struct {
	ctx:               ^Context,
	text:              string,
	font:              ^rl.Font,
	font_size:         f32,
	letter_spacing:    f32,
	inner_width:       f32,
	whitespace:        WhitespaceMode,
	index:             int,
	line_start:        int,
	line_width:        f32,
	last_nonspace_end: int,
}

@(private)
measure_text_width :: proc(
	ctx: ^Context,
	text: string,
	font: ^rl.Font,
	font_size: f32,
	letter_spacing: f32,
) -> f32 {
	if len(text) == 0 {
		return 0
	}

	if width, ok := ctx.text_width_cache[previous_buffer(ctx)][text]; ok {
		ctx.text_width_cache[current_buffer(ctx)][text] = width
		return width
	}

	width: f32 = 0
	count := 0
	for codepoint in text {
		count += 1
		if codepoint != '\n' {
			width += glyph_advance(font, codepoint, font_size)
		}
	}

	letter_spacing := letter_spacing > 0 ? letter_spacing : 1
	width = width + letter_spacing * f32(count - 1)
	ctx.text_width_cache[current_buffer(ctx)][text] = width
	return width
}

@(private)
measure_text_height :: proc(font_size: f32, line_height_multiplier: f32) -> f32 {
	line_height := line_height_multiplier > 0 ? line_height_multiplier : 1
	return font_size * line_height
}

@(private)
glyph_advance :: proc(font: ^rl.Font, r: rune, font_size: f32) -> (adv: f32) {
	idx := i32(r) - 32
	if idx < 0 || idx >= font.glyphCount {
		idx = i32('?' - 32)
	}
	if font.glyphs[idx].advanceX > 0 {
		adv = f32(font.glyphs[idx].advanceX)
	} else {
		adv = font.recs[idx].width + f32(font.glyphs[idx].offsetX)
	}
	return adv * (font_size / f32(font.baseSize))
}

@(private)
find_break_index :: proc(
	ctx: ^Context,
	text: string,
	start: int,
	end: int,
	font: ^rl.Font,
	font_size: f32,
	letter_spacing: f32,
	max_width: f32,
) -> (
	split_index: int,
	width: f32,
) {
	if start >= end || max_width <= 0 {
		_, size := utf8.decode_rune(text[start:end])
		sub := text[start:start + size]
		width = measure_text_width(ctx, sub, font, font_size, letter_spacing)
		return start + size, width
	}

	count := 0
	i := start

	for i < end {
		rune, size := utf8.decode_rune(text[i:end])
		adv := glyph_advance(font, rune, font_size)
		spacing := count > 0 ? letter_spacing : 0
		next_width := width + spacing + adv

		if next_width > max_width {
			if count == 0 {
				return i + size, spacing + adv
			}
			return i, width
		}

		width = next_width
		count += 1
		i += size
	}

	return end, width
}

@(private)
find_next_space :: proc(text: string, start_index: int) -> (start: int, end: int) {
	index := start_index
	text_len := len(text)

	if text[index] == ' ' {
		for index < text_len && text[index] == ' ' {
			index += 1
		}
		return start_index, index
	}

	for index < text_len && text[index] != ' ' && text[index] != '\n' {
		index += 1
	}

	return start_index, index
}

@(private)
text_wrap_iterator_next :: proc(it: ^TextWrapIterator) -> (ok: bool, line: TextLine) {
	if it.whitespace == .Collapse {
		return _text_wrap_iterator_next_collapse(it)
	}
	return _text_wrap_iterator_next_preserve(it)
}

@(private)
_text_wrap_iterator_next_preserve :: proc(it: ^TextWrapIterator) -> (ok: bool, line: TextLine) {
	text_len := len(it.text)

	if it.index >= text_len {
		return false, {}
	}

	for it.index < text_len {
		if it.text[it.index] == '\n' {
			start := it.line_start
			end := it.index

			it.index += 1
			it.line_start = it.index
			it.line_width = 0

			return true, TextLine {
				start = start,
				end = end,
				width = measure_text_width(
					it.ctx,
					it.text[start:end],
					it.font,
					it.font_size,
					it.letter_spacing,
				),
				hard_break = true,
			}
		}

		for it.index < text_len && it.text[it.index] != '\n' {
			word_start, word_end := find_next_space(it.text, it.index)
			token := it.text[word_start:word_end]
			is_space := it.text[word_start] == ' '
			token_width := measure_text_width(
				it.ctx,
				token,
				it.font,
				it.font_size,
				it.letter_spacing,
			)

			join := it.line_width > 0 ? it.letter_spacing : 0
			new_width := it.line_width + join + token_width

			if new_width <= it.inner_width + 0.0001 {
				it.line_width = new_width
				it.index = word_end
				continue
			}

			// If whitespace overflows, split the whitespace run mid-sequence
			if is_space && it.line_width > 0 {
				available := it.inner_width - it.line_width - join
				if available <= 0 {
					start := it.line_start
					end := it.index
					width := it.line_width

					it.line_start = word_start
					it.line_width = 0
					it.index = word_start

					return true, TextLine {
						start = start,
						end = end,
						width = width,
						hard_break = false,
					}
				}

				split_index, part_width := find_break_index(
					it.ctx,
					it.text,
					word_start,
					word_end,
					it.font,
					it.font_size,
					it.letter_spacing,
					available,
				)

				start := it.line_start
				end := split_index
				width := it.line_width + join + part_width

				it.line_start = split_index
				it.line_width = 0
				it.index = split_index

				return true, TextLine{start = start, end = end, width = width, hard_break = false}
			}

			// Soft wrap before this non-whitespace token
			if it.line_width > 0 {
				start := it.line_start
				end := it.index
				width := it.line_width

				it.line_start = word_start
				it.line_width = 0
				it.index = word_start

				return true, TextLine{start = start, end = end, width = width, hard_break = false}
			}

			// Token itself doesn't fit on empty line: break mid-token
			split_index, part_width := find_break_index(
				it.ctx,
				it.text,
				word_start,
				word_end,
				it.font,
				it.font_size,
				it.letter_spacing,
				it.inner_width,
			)

			start := it.line_start
			end := split_index
			width := part_width

			it.line_start = split_index
			it.line_width = 0
			it.index = split_index

			return true, TextLine{start = start, end = end, width = width, hard_break = false}
		}
	}

	if it.line_start < it.index {
		start := it.line_start
		end := it.index
		width := measure_text_width(
			it.ctx,
			it.text[start:end],
			it.font,
			it.font_size,
			it.letter_spacing,
		)
		it.line_start = it.index
		return true, TextLine{start = start, end = end, width = width, hard_break = false}
	}

	return false, {}
}

@(private)
_text_wrap_iterator_next_collapse :: proc(it: ^TextWrapIterator) -> (ok: bool, line: TextLine) {
	text_len := len(it.text)

	if it.index >= text_len {
		return false, {}
	}

	for it.index < text_len {
		if it.text[it.index] == '\n' {
			start := it.line_start
			end := it.last_nonspace_end > 0 ? it.last_nonspace_end : it.index

			it.index += 1
			it.line_start = it.index
			it.line_width = 0
			it.last_nonspace_end = it.index

			return true, TextLine {
				start = start,
				end = end,
				width = measure_text_width(
					it.ctx,
					it.text[start:end],
					it.font,
					it.font_size,
					it.letter_spacing,
				),
				hard_break = true,
			}
		}

		for it.index < text_len && it.text[it.index] != '\n' {
			token_start, token_end := find_next_space(it.text, it.index)
			is_space := it.text[token_start] == ' '

			if is_space {
				// Collapse run to a single space if not at line start
				if it.line_width == 0 {
					// drop leading spaces
					it.index = token_end
					it.line_start = it.index
					it.last_nonspace_end = it.index
					continue
				}

				space_width := measure_text_width(
					it.ctx,
					" ",
					it.font,
					it.font_size,
					it.letter_spacing,
				)
				join := it.letter_spacing // there is always at least one previous glyph here
				new_width := it.line_width + join + space_width

				if new_width <= it.inner_width + 0.0001 {
					it.line_width = new_width
					// include only ONE space from the run in the displayed range
					it.last_nonspace_end = token_start + 1
					it.index = token_end
					continue
				}

				// overflow on space: wrap before the space and drop it
				start := it.line_start
				end := it.last_nonspace_end
				width := it.line_width

				it.line_start = token_end // skip the collapsed space on next line
				it.line_width = 0
				it.last_nonspace_end = it.line_start

				return true, TextLine{start = start, end = end, width = width, hard_break = false}
			}

			// non-space token
			token_width := measure_text_width(
				it.ctx,
				it.text[token_start:token_end],
				it.font,
				it.font_size,
				it.letter_spacing,
			)
			join := it.line_width > 0 ? it.letter_spacing : 0
			new_width := it.line_width + join + token_width

			if new_width <= it.inner_width + 0.0001 {
				it.line_width = new_width
				it.last_nonspace_end = token_end
				it.index = token_end
				continue
			}

			if it.line_width > 0 {
				// break before word
				start := it.line_start
				end := it.last_nonspace_end
				width := it.line_width

				it.line_start = token_start
				it.line_width = 0
				// keep last_nonspace_end as new line start initially
				it.last_nonspace_end = token_start
				it.index = token_start

				return true, TextLine{start = start, end = end, width = width, hard_break = false}
			}

			// word too long for empty line: split mid-word
			split_index, part_width := find_break_index(
				it.ctx,
				it.text,
				token_start,
				token_end,
				it.font,
				it.font_size,
				it.letter_spacing,
				it.inner_width,
			)

			start := it.line_start
			end := split_index
			width := part_width

			it.line_start = split_index
			it.line_width = 0
			it.last_nonspace_end = split_index
			it.index = split_index

			return true, TextLine{start = start, end = end, width = width, hard_break = false}
		}
	}

	if it.line_start < it.index {
		start := it.line_start
		end := it.last_nonspace_end
		width := measure_text_width(
			it.ctx,
			it.text[start:end],
			it.font,
			it.font_size,
			it.letter_spacing,
		)

		it.line_start = it.index
		return true, TextLine{start = start, end = end, width = width, hard_break = false}
	}

	return false, {}
}

@(private)
wrap_count_and_max_width :: proc(it: ^TextWrapIterator) -> (count: int, max_width: f32) {
	for {
		ok, line := text_wrap_iterator_next(it)
		if !ok {
			break
		}
		count += 1
		if line.width > max_width {
			max_width = line.width
		}
	}
	if len(it.text) == 0 {
		count = 1
	}
	if len(it.text) > 0 && it.text[it.index - 1] == '\n' {
		count += 1
	}
	return count, max_width
}

@(private)
wrap_text_element :: proc(ctx: ^Context, element: ^Element) {
	text := element.text
	text_len := len(text)

	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	inner_available: f32 = 0
	width_definite := false

	if element._size.x > 0 {
		inner_available = inner_width(element)
		width_definite = true
	} else if element.width.type == .Percent {
		parent_inner, parent_definite := parent_inner_width(ctx, element)
		if parent_definite {
			inner_available =
				parent_inner * element.width.value - x_padding(element) - x_border(element)
			if inner_available < 0 {
				inner_available = 0
			}
			width_definite = true
		}
	}

	it := TextWrapIterator {
		ctx            = ctx,
		text           = text,
		font           = element.font,
		font_size      = element.font_size,
		letter_spacing = letter_spacing > 0 ? letter_spacing : 1,
		inner_width    = width_definite ? inner_available : 1e30,
		whitespace     = element.whitespace,
	}
	line_count, max_line_width := wrap_count_and_max_width(&it)

	element._line_count = line_count

	if element.height.type != .Fixed {
		if element.height.type == .Percent {
			_, parent_definite := parent_inner_height(ctx, element)
			if !parent_definite {
				line_height_px := measure_text_height(element.font_size, element.line_height)
				element._size.y =
					line_height_px * f32(line_count) + y_padding(element) + y_border(element)
			}
		} else {
			line_height_px := measure_text_height(element.font_size, element.line_height)
			element._size.y =
				line_height_px * f32(line_count) + y_padding(element) + y_border(element)
		}
	}

	if element.width.type == .Fit {
		element._size.x = max_line_width + x_padding(element) + x_border(element)
		flex_clamp_width(ctx, element)
	}

	element._content_size.x = max_line_width
}

@(private)
render_text_line :: proc(
	position: rl.Vector2,
	text: string,
	font: ^rl.Font,
	font_size: f32,
	letter_spacing: f32,
	color: rl.Color,
) {
	rl.DrawTextEx(
		font^,
		strings.clone_to_cstring(text, context.temp_allocator),
		position,
		font_size,
		letter_spacing,
		color,
	)
}

@(private)
_render_text_line :: proc(
	ctx: ^Context,
	element: ^Element,
	text: string,
	line_width: f32,
	x_start: f32,
	y: f32,
	letter_spacing: f32,
	inner_width: f32,
) {
	line_height := measure_text_height(element.font_size, element.line_height)
	if element._clip.height > 0 &&
	   (y + line_height < f32(element._clip.y) ||
			   y > f32(element._clip.y + element._clip.height)) {
		return
	}

	line_offset := calculate_line_offset(element, line_width, inner_width)
	x := x_start + line_offset

	ctx.render_commands[ctx.render_command_count] = RenderCommand {
		type = .Text,
		data = RenderCommandDataText {
			position = {x, y},
			text = text,
			font = element.font,
			font_size = element.font_size,
			letter_spacing = letter_spacing,
			color = element.color,
		},
	}
	ctx.render_command_count += 1
}

@(private)
render_text :: proc(ctx: ^Context, element: ^Element) {
	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	line_width := measure_text_width(
		ctx,
		element.text,
		element.font,
		element.font_size,
		letter_spacing,
	)
	inner_width := inner_width(element)

	x := element._position.x + element.padding.left + element.border.left - element.scroll.offset.x
	y :=
		element._position.y +
		element.padding.top +
		element.border.top +
		calculate_text_offset(element) -
		element.scroll.offset.y

	if current_context.focus_id == element.id {
		render_selection(
			ctx,
			element,
			element.text,
			0,
			len(element.text),
			line_width,
			x,
			y,
			letter_spacing,
			inner_width,
			current_context.text_selection,
		)
	}

	_render_text_line(ctx, element, element.text, line_width, x, y, letter_spacing, inner_width)

	render_caret(
		ctx,
		element,
		element.text,
		0,
		len(element.text),
		line_width,
		x,
		y,
		letter_spacing,
		inner_width,
	)
}

@(private)
render_wrapped_text :: proc(ctx: ^Context, element: ^Element) {
	text := element.text
	text_len := len(element.text)
	x_start :=
		element._position.x + element.padding.left + element.border.left - element.scroll.offset.x
	y_start :=
		element._position.y +
		element.padding.top +
		element.border.top +
		calculate_text_offset(element) -
		element.scroll.offset.y
	letter_spacing := element.letter_spacing > 0 ? element.letter_spacing : 1
	inner_width := inner_width(element)

	if text_len == 0 {
		render_caret(ctx, element, "", 0, 0, 0, x_start, y_start, letter_spacing, inner_width)
		return
	}

	line_height := measure_text_height(element.font_size, element.line_height)
	active := current_context.focus_id == element.id

	it := TextWrapIterator {
		ctx            = ctx,
		text           = text,
		font           = element.font,
		font_size      = element.font_size,
		letter_spacing = letter_spacing > 0 ? letter_spacing : 1,
		inner_width    = inner_width,
		whitespace     = element.whitespace,
	}

	y := y_start
	for {
		ok, line := text_wrap_iterator_next(&it)
		if !ok {
			break
		}

		if active {
			render_selection(
				ctx,
				element,
				text,
				line.start,
				line.end,
				line.width,
				x_start,
				y,
				letter_spacing,
				inner_width,
				current_context.text_selection,
			)
		}

		_render_text_line(
			ctx,
			element,
			text[line.start:line.end],
			line.width,
			x_start,
			y,
			letter_spacing,
			inner_width,
		)

		render_caret(
			ctx,
			element,
			text,
			line.start,
			line.end,
			line.width,
			x_start,
			y,
			letter_spacing,
			inner_width,
		)

		y += line_height
	}

	if text[text_len - 1] == '\n' {
		render_caret(
			ctx,
			element,
			text,
			text_len,
			text_len,
			0,
			x_start,
			y,
			letter_spacing,
			inner_width,
		)
	}
}

@(private)
// Vertical offset
calculate_text_offset :: proc(element: ^Element) -> f32 {
	content_height := inner_height(element)
	line_height := measure_text_height(element.font_size, element.line_height)
	line_count := element._line_count > 0 ? element._line_count : 1
	text_height := line_height * f32(line_count)
	return calculate_alignment_offset(element.align.y, content_height, text_height)
}

@(private)
// Horizontal offset
calculate_line_offset :: proc(element: ^Element, line_width: f32, available_width: f32) -> f32 {
	return calculate_alignment_offset(element.align.x, available_width, line_width)
}

@(private)
render_caret :: proc(
	ctx: ^Context,
	element: ^Element,
	text: string,
	line_start: int,
	line_end: int,
	line_width: f32,
	x_start: f32,
	y: f32,
	letter_spacing: f32,
	inner_width: f32,
) {
	if current_context.focus_id != element.id || current_context.caret_index == -1 {
		return
	}

	blink_cycle := math.mod(current_context.caret_time, 1.0)
	if blink_cycle >= 0.5 {
		return
	}

	caret := current_context.caret_index
	if caret < line_start || caret > line_end {
		return
	}

	// caret at end of soft-wrapped line is rendered on the next line
	if caret == line_end && line_end < len(text) && text[line_end] != '\n' {
		return
	}

	line_height := measure_text_height(element.font_size, element.line_height)
	if element._clip.height > 0 &&
	   (y + line_height < f32(element._clip.y) ||
			   y > f32(element._clip.y + element._clip.height)) {
		return
	}

	prefix_width := measure_text_width(
		ctx,
		text[line_start:caret],
		element.font,
		element.font_size,
		letter_spacing,
	)
	line_offset := calculate_line_offset(element, line_width, inner_width)

	current_context.caret_position = {x_start + line_offset + prefix_width, y}
	current_context.render_commands[current_context.render_command_count] = RenderCommand {
		type = .Rectangle,
		data = RenderCommandDataRectangle {
			position = current_context.caret_position,
			size = {1, line_height},
			color = element.color,
		},
	}
	current_context.render_command_count += 1
}

@(private)
render_selection :: proc(
	ctx: ^Context,
	element: ^Element,
	text: string,
	line_start: int,
	line_end: int,
	line_width: f32,
	x_start: f32,
	y: f32,
	letter_spacing: f32,
	inner_width: f32,
	selection: TextSelection,
) {
	if current_context.focus_id != element.id {
		return
	}

	if selection.start == selection.end {
		return
	}

	line_height := measure_text_height(element.font_size, element.line_height)
	if element._clip.height > 0 &&
	   (y + line_height < f32(element._clip.y) ||
			   y > f32(element._clip.y + element._clip.height)) {
		return
	}

	start := clamp(selection.start, line_start, line_end)
	end := clamp(selection.end, line_start, line_end)
	if start > end {
		start, end = end, start
	}

	prefix_width := measure_text_width(
		ctx,
		text[line_start:start],
		element.font,
		element.font_size,
		letter_spacing,
	)
	selection_width := measure_text_width(
		ctx,
		text[start:end],
		element.font,
		element.font_size,
		letter_spacing,
	)
	line_offset := calculate_line_offset(element, line_width, inner_width)

	x := x_start + line_offset + prefix_width
	current_context.render_commands[current_context.render_command_count] = RenderCommand {
		type = .Rectangle,
		data = RenderCommandDataRectangle {
			position = {x, y},
			size = {selection_width, line_height},
			color = {31, 104, 217, 120},
		},
	}
	current_context.render_command_count += 1
}
