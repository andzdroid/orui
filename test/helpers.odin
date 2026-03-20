package orui_test

import orui "../src"

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
