package demo

import orui "../../src"
import rl "vendor:raylib"

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 900, "orui")
	defer rl.CloseWindow()

	ctx := new(orui.Context)
	defer free(ctx)

	orui.init(ctx)
	defer orui.destroy(ctx)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BEIGE)

		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()
		orui.begin(ctx, width, height)

		{orui.container(
				orui.id("container"),
				{
					direction = .TopToBottom,
					width = orui.percent(1),
					height = orui.percent(1),
					gap = 4,
					padding = orui.padding(20),
				},
			)

			{orui.container(
					orui.id("top"),
					{
						width = orui.percent(1),
						height = orui.fixed(30),
						background_color = {100, 0, 0, 255},
					},
				)}

			{orui.container(
					orui.id("center"),
					{
						width = orui.percent(1),
						height = orui.grow(),
						background_color = {0, 0, 100, 255},
						direction = .LeftToRight,
						padding = orui.padding(10),
					},
				)

				{orui.container(
						orui.id("sidebar"),
						{
							layout = .Flex,
							direction = .TopToBottom,
							width = orui.fixed(300),
							height = orui.percent(1),
							padding = orui.padding(8),
							background_color = {100, 100, 255, 255},
						},
					)

					{orui.container(
							orui.id("header"),
							{
								width = orui.grow(),
								height = orui.fixed(30),
								background_color = {100, 255, 100, 255},
							},
						)}

					// PROBLEM: scroll container's height is EXCEEDING the bounds of sidebar
					{orui.container(
							orui.id("scroll container"),
							{
								position = {.Relative, {}},
								layout = .Flex,
								direction = .TopToBottom,
								width = orui.grow(),
								height = orui.grow(),
								padding = orui.padding(8),
								background_color = {255, 255, 60, 255},
							},
						)

						{orui.container(
								orui.id("content"),
								{
									width = orui.grow(),
									height = orui.grow(),
									direction = .TopToBottom,
									gap = 4,
									scroll = orui.scroll(.Vertical),
									clip = {.Self, {}},
								},
							)
							for i in 0 ..< 50 {
								{orui.container(
										orui.id("row", i),
										{
											width = orui.grow(),
											height = orui.fixed(30),
											background_color = {255, 100, 100, 255},
										},
									)}
							}
						}
					}
				}
			}

			{orui.container(
					orui.id("bottom"),
					{
						width = orui.percent(1),
						height = orui.fixed(30),
						background_color = {0, 100, 0, 255},
					},
				)}
		}

		render_commands := orui.end()
		for command in render_commands {
			orui.render_command(command)
		}

		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
}
