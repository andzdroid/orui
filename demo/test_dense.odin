package demo

import orui "../src"
import rl "vendor:raylib"

render_dense :: proc() {
	orui.container(
		orui.id("dense"),
		{
			direction = .LeftToRight,
			width = orui.grow(),
			height = orui.grow(),
			gap = 4,
			padding = orui.padding(4),
			background_color = rl.BEIGE,
			scroll = orui.scroll(.Vertical),
			align_main = .Center,
			align_cross = .Center,
			align_content = .Center,
			flex_wrap = .Wrap,
		},
	)

	for i in 0 ..< 6400 {
		{orui.container(
				orui.id("cell", i),
				{
					layout = .None,
					width = orui.fixed(8),
					height = orui.fixed(8),
					background_color = rl.BLUE,
				},
			)}
	}
}
