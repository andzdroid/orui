package orui_test

import orui "../src"
import "core:strings"
import "core:testing"

@(test)
rebind_focus_to_element :: proc(t: ^testing.T) {
	ctx := new(orui.Context)
	defer free(ctx)
	ctx.frame = 1

	focused_id := orui.to_id("id")
	ctx.focus = 7
	ctx.focus_id = focused_id
	ctx.element_count[orui.previous_buffer(ctx)] = 4
	ctx.elements[orui.previous_buffer(ctx)][3].id = focused_id
	ctx.elements[orui.previous_buffer(ctx)][3].editable = true

	orui.sync_focus_element(ctx)

	testing.expect_value(t, ctx.focus, 3)
	testing.expect_value(t, ctx.focus_id, focused_id)
}

@(test)
clear_focus_when_element_is_missing :: proc(t: ^testing.T) {
	ctx := new(orui.Context)
	defer free(ctx)
	ctx.frame = 1

	ctx.focus = 7
	ctx.focus_id = orui.to_id("id")

	orui.sync_focus_element(ctx)

	testing.expect_value(t, ctx.focus, 0)
	testing.expect_value(t, ctx.focus_id, orui.Id(0))
}

@(test)
clamp_caret_position :: proc(t: ^testing.T) {
	ctx := new(orui.Context)
	defer free(ctx)

	builder: strings.Builder
	strings.builder_init(&builder, context.allocator)
	defer strings.builder_destroy(&builder)
	strings.write_string(&builder, "1")

	focused_id := orui.to_id("id")
	ctx.frame = 1
	ctx.focus_id = focused_id
	ctx.caret_index = 2
	ctx.text_selection = {2, 2}
	ctx.element_count[orui.previous_buffer(ctx)] = 4
	ctx.elements[orui.previous_buffer(ctx)][3].id = focused_id
	ctx.elements[orui.previous_buffer(ctx)][3].editable = true
	ctx.elements[orui.previous_buffer(ctx)][3].text_input = &builder

	orui.sync_focus_element(ctx)

	testing.expect_value(t, ctx.focus, 3)
	testing.expect_value(t, ctx.caret_index, 1)
	testing.expect_value(t, ctx.text_selection.start, 1)
	testing.expect_value(t, ctx.text_selection.end, 1)
}
