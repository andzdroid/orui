package orui_test

import orui "../src"
import "core:testing"
import rl "vendor:raylib"

find_text_command :: proc(
	commands: []orui.RenderCommand,
	id: orui.Id,
) -> (
	orui.RenderCommand,
	bool,
) {
	for command in commands {
		if command.type == .Text && command.source.id == id {
			return command, true
		}
	}
	return {}, false
}

find_image_command :: proc(
	commands: []orui.RenderCommand,
	id: orui.Id,
) -> (
	orui.RenderCommand,
	bool,
) {
	for command in commands {
		if command.type == .Image && command.source.id == id {
			return command, true
		}
	}
	return {}, false
}

@(test)
fit_height_child_is_not_clamped_by_vertical_scroll_parent :: proc(t: ^testing.T) {
	item_count := 10
	row_height := f32(30)
	gap := f32(5)
	viewport_height := f32(120)
	expected_content_height := f32(item_count) * row_height + f32(item_count - 1) * gap

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 200, 120, 0)
	{orui.container(
			orui.id("scroll-parent"),
			{
				layout = .Flex,
				direction = .TopToBottom,
				width = orui.percent(1),
				height = orui.percent(1),
				gap = gap,
				scroll = orui.scroll(.Vertical),
				clip = {.Self, {}},
			},
		)
		{orui.container(
				orui.id("fit-child"),
				{
					layout = .Flex,
					direction = .TopToBottom,
					width = orui.percent(1),
					height = orui.fit(),
					gap = gap,
				},
			)
			for i in 0 ..< item_count {
				orui.container(
					orui.id("row", i),
					{width = orui.percent(1), height = orui.fixed(row_height)},
				)
			}
		}
	}
	orui.end()

	fit_child := find_element(ctx, orui.to_id("fit-child"))
	scroll_parent := find_element(ctx, orui.to_id("scroll-parent"))
	testing.expect(t, fit_child != nil)
	testing.expect(t, scroll_parent != nil)
	testing.expect_value(t, fit_child._size.y, expected_content_height)
	testing.expect_value(t, scroll_parent._content_size.y, expected_content_height)
	testing.expect_value(t, scroll_parent._size.y, viewport_height)
	testing.expect(t, fit_child._size.y > scroll_parent._size.y)
}

@(test)
fit_width_child_is_not_clamped_by_horizontal_scroll_parent :: proc(t: ^testing.T) {
	item_count := 10
	col_width := f32(40)
	gap := f32(6)
	viewport_width := f32(120)
	expected_content_width := f32(item_count) * col_width + f32(item_count - 1) * gap

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 120, 200, 0)
	{orui.container(
			orui.id("scroll-parent"),
			{
				layout = .Flex,
				direction = .LeftToRight,
				width = orui.percent(1),
				height = orui.percent(1),
				gap = gap,
				scroll = orui.scroll(.Horizontal),
				clip = {.Self, {}},
			},
		)
		{orui.container(
				orui.id("fit-child"),
				{
					layout = .Flex,
					direction = .LeftToRight,
					width = orui.fit(),
					height = orui.percent(1),
					gap = gap,
				},
			)
			for i in 0 ..< item_count {
				orui.container(
					orui.id("col", i),
					{width = orui.fixed(col_width), height = orui.percent(1)},
				)
			}
		}
	}
	orui.end()

	fit_child := find_element(ctx, orui.to_id("fit-child"))
	scroll_parent := find_element(ctx, orui.to_id("scroll-parent"))
	testing.expect(t, fit_child != nil)
	testing.expect(t, scroll_parent != nil)
	testing.expect_value(t, fit_child._size.x, expected_content_width)
	testing.expect_value(t, scroll_parent._content_size.x, expected_content_width)
	testing.expect_value(t, scroll_parent._size.x, viewport_width)
	testing.expect(t, fit_child._size.x > scroll_parent._size.x)
}

@(test)
right_aligned_overflowing_text_scrolls_left :: proc(t: ^testing.T) {
	text := "aaaaaaaaaaaaaaaaaaaaa"
	width := f32(10)
	text_width := f32(len(text) - 1)
	overflow := text_width - width
	left_id := orui.to_id("right-aligned-left")
	right_id := orui.to_id("right-aligned-right")

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 40, 20, 0)
	orui.label(
		orui.id(left_id),
		text,
		{
			width = orui.fixed(width),
			height = orui.fixed(10),
			overflow = .Visible,
			scroll = {.Horizontal, {-999, 0}},
			align = {.End, .Start},
			clip = {.Self, {}},
		},
	)
	orui.label(
		orui.id(right_id),
		text,
		{
			width = orui.fixed(width),
			height = orui.fixed(10),
			overflow = .Visible,
			scroll = {.Horizontal, {999, 0}},
			align = {.End, .Start},
			clip = {.Self, {}},
		},
	)
	commands := orui.end()

	left := find_element(ctx, left_id)
	right := find_element(ctx, right_id)
	testing.expect(t, left != nil)
	testing.expect(t, right != nil)
	expect_f32(t, left.scroll.offset.x, -overflow, "right aligned min scroll")
	expect_f32(t, right.scroll.offset.x, 0, "right aligned max scroll")

	left_command, left_ok := find_text_command(commands, left_id)
	testing.expect(t, left_ok)
	left_text := left_command.data.(orui.RenderCommandDataText)
	expect_f32(t, left_text.position.x, left._position.x, "left overflow text position")

	right_command, right_ok := find_text_command(commands, right_id)
	testing.expect(t, right_ok)
	right_text := right_command.data.(orui.RenderCommandDataText)
	expect_f32(t, right_text.position.x, right._position.x - overflow, "right edge text position")
}

@(test)
cross_axis_aligned_flex_overflow_scrolls_to_overflow_side :: proc(t: ^testing.T) {
	width := f32(10)
	child_width := f32(20)
	overflow := child_width - width
	left_id := orui.to_id("flex-left")
	left_child_id := orui.to_id("flex-left-child")
	right_id := orui.to_id("flex-right")
	right_child_id := orui.to_id("flex-right-child")

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 40, 10, 0)
	{orui.container(
			orui.id(left_id),
			{
				layout = .Flex,
				direction = .TopToBottom,
				align_cross = .End,
				width = orui.fixed(width),
				height = orui.fixed(10),
				scroll = {.Horizontal, {-999, 0}},
				clip = {.Self, {}},
			},
		)
		{orui.container(
				orui.id(left_child_id),
				{width = orui.fixed(child_width), height = orui.fixed(10)},
			)
		}
	}
	{orui.container(
			orui.id(right_id),
			{
				layout = .Flex,
				direction = .TopToBottom,
				align_cross = .End,
				width = orui.fixed(width),
				height = orui.fixed(10),
				scroll = {.Horizontal, {999, 0}},
				clip = {.Self, {}},
			},
		)
		{orui.container(
				orui.id(right_child_id),
				{width = orui.fixed(child_width), height = orui.fixed(10)},
			)
		}
	}
	orui.end()

	left := find_element(ctx, left_id)
	left_child := find_element(ctx, left_child_id)
	right := find_element(ctx, right_id)
	right_child := find_element(ctx, right_child_id)
	testing.expect(t, left != nil)
	testing.expect(t, left_child != nil)
	testing.expect(t, right != nil)
	testing.expect(t, right_child != nil)
	expect_f32(t, left.scroll.offset.x, -overflow, "flex cross-axis min scroll")
	expect_f32(t, right.scroll.offset.x, 0, "flex cross-axis max scroll")
	expect_f32(t, left_child._position.x, left._position.x, "left overflow child position")
	expect_f32(
		t,
		right_child._position.x,
		right._position.x - overflow,
		"right edge child position",
	)
}

@(test)
end_aligned_overflowing_image_scrolls_left :: proc(t: ^testing.T) {
	texture := rl.Texture2D {
		width  = 20,
		height = 10,
	}
	width := f32(10)
	overflow := f32(texture.width) - width
	left_id := orui.to_id("image-left")
	right_id := orui.to_id("image-right")

	ctx := new(orui.Context)
	defer free(ctx)
	orui.init(ctx)
	defer orui.destroy(ctx)

	orui.begin(ctx, 40, 10, 0)
	orui.image(
		orui.id(left_id),
		&texture,
		{
			width = orui.fixed(width),
			height = orui.fixed(10),
			texture_fit = .None,
			scroll = {.Horizontal, {-999, 0}},
			align = {.End, .Start},
			clip = {.Self, {}},
		},
	)
	orui.image(
		orui.id(right_id),
		&texture,
		{
			width = orui.fixed(width),
			height = orui.fixed(10),
			texture_fit = .None,
			scroll = {.Horizontal, {999, 0}},
			align = {.End, .Start},
			clip = {.Self, {}},
		},
	)
	commands := orui.end()

	left := find_element(ctx, left_id)
	right := find_element(ctx, right_id)
	testing.expect(t, left != nil)
	testing.expect(t, right != nil)
	expect_f32(t, left.scroll.offset.x, -overflow, "end aligned image min scroll")
	expect_f32(t, right.scroll.offset.x, 0, "end aligned image max scroll")

	left_command, left_ok := find_image_command(commands, left_id)
	testing.expect(t, left_ok)
	left_image := left_command.data.(orui.RenderCommandDataImage)
	expect_f32(t, left_image.src.x, 0, "left overflow image source")
	expect_f32(t, left_image.dst.x, left._position.x, "left overflow image position")

	right_command, right_ok := find_image_command(commands, right_id)
	testing.expect(t, right_ok)
	right_image := right_command.data.(orui.RenderCommandDataImage)
	expect_f32(t, right_image.src.x, overflow, "right edge image source")
	expect_f32(t, right_image.dst.x, right._position.x, "right edge image position")
}
