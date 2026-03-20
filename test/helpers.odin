package orui_test

import orui "../src"
import "core:testing"

EPSILON: f32 : 0.001

expect_f32 :: proc(t: ^testing.T, value: f32, expected: f32, label: string) {
	diff := value - expected
	if diff < 0 {
		diff = -diff
	}
	testing.expectf(t, diff <= EPSILON, "%s: expected %v, got %v", label, expected, value)
}

find_element :: proc(ctx: ^orui.Context, id: orui.Id) -> ^orui.Element {
	buffer := ctx.frame % 2
	count := ctx.element_count[buffer]
	for i in 0 ..< count {
		if ctx.elements[buffer][i].id == id {
			return &ctx.elements[buffer][i]
		}
	}
	return nil
}
