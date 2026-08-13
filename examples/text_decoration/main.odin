package demo

import orui "../../src"
import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

BODY_TEXT :: "orui is an immediate mode UI library for odin and raylib, with support for flex and grid layouts. You can click here to visit the orui repository on github: Visit the orui repo. Different kinds of text decorations in orui can be added this way."
SEARCH_TEXT :: "orui"
LINK_TEXT :: "Visit the orui repo"
HIGHLIGHT_COLOR :: rl.Color{255, 214, 82, 120}

TextRange :: struct {
	start: int,
	end:   int,
	color: rl.Color,
}

TextRanges :: struct {
	items: [8]TextRange,
	count: int,
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT, .WINDOW_HIGHDPI})
	rl.InitWindow(960, 540, "orui text decoration")
	defer rl.CloseWindow()

	ctx := new(orui.Context)
	defer free(ctx)

	orui.init(ctx)
	defer orui.destroy(ctx)

	font_path, _ := filepath.join(
		{#directory, "..", "..", "assets", "Inter-Regular.ttf"},
		context.temp_allocator,
	)
	ctx.default_font = rl.LoadFontEx(
		strings.clone_to_cstring(font_path, context.temp_allocator),
		80,
		{},
		0,
	)
	defer rl.UnloadFont(ctx.default_font)

	text_id := orui.to_id("highlighted text")
	search_ranges := find_all_ranges(BODY_TEXT, SEARCH_TEXT)
	link_range := find_first_range(BODY_TEXT, LINK_TEXT)
	current_cursor := rl.MouseCursor.DEFAULT

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({245, 242, 235, 255})

		orui.begin(ctx, rl.GetScreenWidth(), rl.GetScreenHeight())
		cursor_hint := orui.cursor(ctx)
		next_cursor :=
			cursor_hint == .Unspecified ? rl.MouseCursor.DEFAULT : rl.MouseCursor(cursor_hint)
		if next_cursor != current_cursor {
			rl.SetMouseCursor(next_cursor)
			current_cursor = next_cursor
		}

		{orui.container(
				orui.id("root"),
				{
					width = orui.grow(),
					height = orui.grow(),
					padding = orui.padding(48),
					align_main = .Center,
					align_cross = .Center,
				},
			)
			{orui.container(
					orui.id("panel"),
					{
						direction = .TopToBottom,
						width = orui.fixed(690),
						height = orui.fit(),
						padding = orui.padding(24),
						gap = 14,
						background_color = rl.WHITE,
						border = orui.border(1),
						border_color = {205, 200, 190, 255},
						corner_radius = orui.corner(6),
					},
				)
				orui.label(
					orui.id("title"),
					"Text decorations",
					{
						font_size = 22,
						color = {40, 45, 50, 255},
						width = orui.grow(),
						height = orui.fit(),
					},
				)

				orui.label(
					orui.id(text_id),
					BODY_TEXT,
					{
						font_size = 18,
						line_height = 1.5,
						color = {32, 34, 38, 255},
						width = orui.grow(),
						height = orui.fit(),
						overflow = .Wrap,
					},
				)
			}
		}

		commands := orui.end()

		link_hovered := text_range_hovered(commands, text_id, link_range)

		for command in commands {
			if command.source.id == text_id {
				draw_search_highlights(command, search_ranges.items[:search_ranges.count])
				if link_hovered {
					draw_link_decoration(command, link_range)
				}
			}

			orui.render_command(command)

			if command.source.id == text_id {
				draw_link_underline(command, link_range)
			}
		}

		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}

find_all_ranges :: proc(text, needle: string) -> TextRanges {
	ranges: TextRanges
	i := 0
	for i <= len(text) - len(needle) && ranges.count < len(ranges.items) {
		if text[i:i + len(needle)] == needle {
			ranges.items[ranges.count] = {i, i + len(needle), HIGHLIGHT_COLOR}
			ranges.count += 1
			i += len(needle)
		} else {
			i += 1
		}
	}
	return ranges
}

find_first_range :: proc(text, needle: string) -> TextRange {
	for i := 0; i <= len(text) - len(needle); i += 1 {
		if text[i:i + len(needle)] == needle {
			return {i, i + len(needle), {}}
		}
	}
	return {}
}

draw_search_highlights :: proc(command: orui.RenderCommand, ranges: []TextRange) {
	for range in ranges {
		rect := orui.measure_text_command_range(command, range.start, range.end) or_continue
		rl.DrawRectangleRec(rect, range.color)
	}
}

draw_link_decoration :: proc(command: orui.RenderCommand, range: TextRange) -> bool {
	rect := orui.measure_text_command_range(command, range.start, range.end) or_return
	rl.DrawRectangleRec(rect, {82, 146, 255, 70})
	return true
}

draw_link_underline :: proc(command: orui.RenderCommand, range: TextRange) -> bool {
	rect := orui.measure_text_command_range(command, range.start, range.end) or_return
	rl.DrawRectangleRec({rect.x, rect.y + rect.height - 2, rect.width, 1}, rl.BLUE)
	return true
}

text_range_hovered :: proc(
	commands: []orui.RenderCommand,
	text_id: orui.Id,
	range: TextRange,
) -> bool {
	mouse := rl.GetMousePosition()
	for command in commands {
		if command.type != .Text || command.source.id != text_id {
			continue
		}

		rect := orui.measure_text_command_range(command, range.start, range.end) or_continue
		if rl.CheckCollisionPointRec(mouse, rect) {
			return true
		}
	}
	return false
}
