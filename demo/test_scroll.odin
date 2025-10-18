package demo

import orui "../src"
import "core:strings"
import rl "vendor:raylib"

text_input1: strings.Builder
text_input2: strings.Builder
scroll_initialised := false

LOREM :: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut fringilla molestie turpis, non sollicitudin felis. Integer vehicula, enim ac egestas elementum, orci dolor hendrerit massa, commodo tincidunt velit est sit amet lorem. Cras eget egestas mauris. Phasellus auctor pulvinar suscipit. Mauris ut est rhoncus, dapibus quam porttitor, gravida felis. Maecenas auctor dui augue, non tincidunt sapien commodo eu. Nam lorem urna, suscipit in ultricies sed, rutrum ut quam. Etiam ultricies malesuada efficitur. Vestibulum sit amet nulla justo. Etiam pretium ipsum a fermentum pretium. Maecenas sit amet lorem tellus. Aliquam tincidunt aliquet arcu. Cras sit amet erat dictum nisi auctor elementum. Vivamus vel tempus purus, et lobortis urna.\n\nQuisque gravida tortor sed odio lobortis aliquam sit amet et purus. Nullam nec lorem id ligula porta egestas sit amet in orci. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Nulla nunc risus, dapibus a elit non, aliquam viverra magna. Maecenas et vehicula mauris, non posuere nulla. Nunc erat leo, lacinia sit amet augue et, eleifend sagittis felis. Morbi iaculis est sit amet nunc venenatis, at consectetur lorem aliquam. Vestibulum et finibus arcu. Ut et rutrum nisl. Aliquam molestie rhoncus augue eget hendrerit. Pellentesque sodales sed dui quis fringilla. Morbi tristique viverra pharetra. Aenean condimentum eu tellus sed dapibus. Quisque ut egestas magna. Nunc ante odio, lacinia non scelerisque rutrum, sodales vel augue. Vestibulum at semper quam, suscipit tincidunt sapien.\n\nNam diam libero, facilisis ut ultrices id, tincidunt eget sapien. Praesent interdum magna vitae libero ullamcorper, et blandit enim congue. Integer lobortis neque vitae dapibus sodales. Etiam vel tortor posuere, mattis ante quis, varius neque. Phasellus lorem nisl, dignissim at neque a, accumsan mollis dolor. Aliquam in tempor nibh. Suspendisse a eros faucibus, tincidunt augue nec, tincidunt sem. Maecenas vulputate mattis faucibus. Vivamus a ullamcorper magna. Proin in sem ac nisi dapibus bibendum in vestibulum ante. Morbi volutpat fermentum mollis. In pharetra maximus suscipit. Donec in leo sed eros porttitor porttitor. Suspendisse id fermentum lectus, ut vestibulum dui. Sed at nisi pretium, gravida nisl id, euismod nulla. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.\n\nDonec odio neque, semper in vestibulum maximus, placerat vel turpis. Suspendisse dapibus mollis posuere. Ut tincidunt lobortis erat sit amet venenatis. In et ultricies augue, in lacinia dolor. Suspendisse et molestie metus. In nibh sapien, porta sed dapibus non, suscipit in nisl. Proin scelerisque dolor lorem, vitae pretium leo auctor a. Suspendisse in libero vel nulla pharetra molestie vel vel leo. Nulla facilisi. Aliquam a porttitor ex. In in eros nulla. Mauris ullamcorper tellus in urna sollicitudin, ut aliquet tellus tempor.\n\nPraesent ullamcorper elit sed est eleifend scelerisque. Suspendisse malesuada ullamcorper quam vel congue. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nulla blandit varius tellus, ut venenatis ligula lobortis eget. Nam vestibulum odio placerat, porta nisi in, euismod purus. Fusce nibh lacus, malesuada in felis ac, elementum condimentum odio. Suspendisse in libero iaculis, euismod dolor nec, hendrerit est. Pellentesque leo nunc, eleifend at massa eu, feugiat facilisis orci. Vestibulum semper felis elit. Curabitur ante sem, efficitur eu consequat vel, facilisis nec ex. Duis tincidunt fermentum ligula in hendrerit. Vestibulum magna sapien, aliquam ac pellentesque id, porta non diam. In hac habitasse platea dictumst. Morbi scelerisque condimentum ligula, pulvinar commodo justo blandit at.\n\nClass aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nunc elementum, neque nec lobortis auctor, purus eros condimentum urna, id volutpat velit quam vel turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent imperdiet lorem quis nisi feugiat semper. Donec condimentum nulla a mattis feugiat. In faucibus urna at metus euismod suscipit. Praesent ultricies sed nulla auctor placerat.\n\nSed non dapibus eros. Phasellus ut lectus diam. Sed ornare lacinia nisi eget aliquam. Phasellus egestas arcu sit amet orci pretium tristique. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nunc ante magna, congue semper mi vitae, tempus pellentesque erat. Morbi eleifend turpis condimentum ligula luctus, sed tincidunt tellus tristique. In et consequat orci. Vestibulum sodales nunc ultricies tristique semper. Nunc eget leo libero. Integer rutrum aliquet elit, quis mollis nulla bibendum ut.\n\nInteger maximus erat ante, non aliquet nulla vehicula eget. Aliquam vitae accumsan nulla, id sagittis ipsum. Sed feugiat dictum felis, vitae tristique ante rutrum ut. Vestibulum et iaculis mi. Nam pretium massa et erat volutpat, id lacinia justo sodales. In pharetra turpis ornare enim sollicitudin, ac porta libero tempor. Maecenas at arcu eleifend nunc pellentesque tristique. Cras ornare mi dui, eu luctus ipsum scelerisque sit amet. Morbi a aliquam arcu, quis malesuada nulla. Quisque vehicula sed purus ac vulputate. Fusce sit amet dapibus ex. Nam enim ex, consequat a orci quis, vehicula dictum arcu. Nulla nec sem a nisl pharetra ornare. Sed cursus finibus lectus, dignissim placerat nisl tristique eu. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Aliquam malesuada leo sit amet lectus commodo, id lacinia augue pulvinar.\n\nNullam sed massa enim. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed in ante neque. Quisque vel urna sed lorem finibus sollicitudin. Aenean gravida velit commodo sodales bibendum. Nulla sit amet ex orci. Sed porta aliquet ligula vehicula vehicula. Morbi ultricies ut metus sed mollis. Curabitur eget nunc bibendum, commodo nisi nec, fringilla augue. Quisque porttitor dui nisl, pellentesque placerat ante commodo id. Nunc tincidunt lorem urna, sed aliquam nisi aliquam et. Maecenas ut leo nec ex semper interdum vestibulum ut eros.\n\nPhasellus posuere ante a risus pulvinar, vitae semper nunc tincidunt. In hac habitasse platea dictumst. Nam vitae lacinia metus. Nullam varius bibendum varius. Cras consectetur ultricies blandit. Praesent tempus velit et sem sodales, id mattis metus finibus. Morbi tincidunt nulla ac bibendum suscipit. Sed tincidunt risus quis semper elementum.\n\nNullam id hendrerit odio, a scelerisque dui. Donec sed ornare lorem. Praesent a auctor augue. Pellentesque laoreet porta leo, et venenatis felis eleifend et. Vivamus in enim non ligula congue tincidunt sit amet vitae massa. Quisque at interdum lorem. Nam nisi felis, ultrices nec consequat sit amet, vulputate eget arcu. Vestibulum consequat porttitor orci ut facilisis. Aliquam at rhoncus lectus. Curabitur dapibus libero fermentum justo aliquet, vitae volutpat tortor vehicula. Duis pulvinar mauris quis magna faucibus viverra.\n\nPellentesque viverra auctor libero faucibus pharetra. Vivamus a euismod massa. Pellentesque faucibus ex eget bibendum suscipit. Etiam vel mauris rhoncus, dignissim diam non, bibendum erat. Nulla sapien erat, pellentesque eu elementum sit amet, sodales a nunc. Pellentesque cursus finibus ligula, et imperdiet nibh consequat a. Morbi varius mauris non laoreet cursus. Aenean ante risus, luctus quis arcu non, auctor placerat ex.\n\nDuis sollicitudin neque enim. Curabitur fringilla ullamcorper interdum. Integer mollis tempus viverra. Quisque et hendrerit lacus. Morbi tempus libero dolor, id consectetur libero iaculis ornare. Ut fermentum vehicula enim, ut lobortis purus ultrices eget. Fusce mauris mi, pharetra id libero id, luctus fringilla justo. Aenean ac fringilla neque. Donec sit amet elit mauris. Vivamus id justo orci. Ut sapien lacus, elementum vel feugiat sit amet, dapibus sit amet lacus. Maecenas consequat libero sollicitudin, pellentesque diam et, commodo justo.\n\nNam vestibulum justo sed laoreet efficitur. Sed ornare urna ipsum, vitae viverra dolor euismod eget. Quisque egestas ante eu congue ullamcorper. Aliquam quis sem lacinia neque lobortis auctor. Nulla luctus mi lacus, in interdum tortor iaculis nec. Quisque eleifend placerat mollis. Curabitur vel nulla enim. Praesent felis felis, malesuada non purus non, luctus laoreet nisl. Pellentesque quis magna id est molestie porttitor. Integer vulputate dignissim dolor, sit amet ullamcorper enim. Nulla non dui sapien. Pellentesque aliquam lacus in lorem viverra posuere. Suspendisse imperdiet ante sit amet malesuada feugiat. Nullam a mattis felis. Donec volutpat ligula tortor, ut gravida orci egestas quis. Donec eget leo ligula.\n\nPhasellus nibh dolor, dictum in nibh at, malesuada molestie turpis. In a mi feugiat, luctus justo sit amet, viverra dolor. Nulla vitae felis finibus, ultricies leo vitae, sodales mi. Pellentesque facilisis libero vitae felis semper, vitae tincidunt tellus malesuada. Maecenas convallis eu orci nec lacinia. Etiam commodo felis eget pulvinar rhoncus. Duis eget purus id metus rhoncus ullamcorper. Donec tellus diam, vehicula sit amet aliquam eu, mollis posuere quam. Ut consectetur hendrerit lacus quis varius. Suspendisse eleifend orci vel neque blandit ornare. Maecenas tellus magna, pharetra quis mi eu, mattis fringilla felis. Praesent congue mauris quis varius pulvinar. Etiam semper ex facilisis venenatis tempor. Pellentesque ornare dolor non elit luctus accumsan sed in erat. Ut porttitor eget nisl quis rutrum.\n\nVestibulum vitae mi tristique, egestas est eget, condimentum lectus. Sed sollicitudin turpis et mollis auctor. Praesent eu accumsan nulla, sit amet porta risus. Sed sollicitudin vitae arcu at rutrum. Curabitur dictum velit ipsum, eu pulvinar diam condimentum a. Ut eget urna elementum, euismod diam nec, vehicula nunc. Curabitur gravida ante porttitor diam consequat, faucibus aliquet libero mattis. Nam aliquam turpis leo, et faucibus dolor tempor eget. Nullam bibendum nisl dolor, ac bibendum ex aliquet non. Aliquam vel urna congue, consequat nulla quis, vulputate nibh. Proin id porttitor sapien. Quisque ante ligula, molestie et ornare consectetur, bibendum ac massa. Sed cursus, lacus vitae pellentesque bibendum, ipsum orci dictum turpis, at cursus magna ipsum a felis.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque sed suscipit turpis. Nullam non mi non tellus tempor aliquet quis eget libero. Nunc est tellus, fermentum vel felis ut, faucibus elementum ante. Vestibulum ultrices placerat ipsum. Vestibulum rutrum sem quis elit dictum imperdiet. Maecenas libero ligula, viverra ut vulputate id, pharetra a urna. Nullam sed elit scelerisque, eleifend justo sed, suscipit turpis.\n\nCurabitur euismod mollis velit nec pharetra. Fusce et felis viverra nulla pretium viverra eu nec lectus. Maecenas eu purus a purus volutpat tempor ac vel quam. Vivamus et massa sit amet turpis consequat tempus in ac neque. Sed in aliquet nunc. Vestibulum id laoreet erat. Aenean consectetur enim ac dolor consequat, eget imperdiet velit luctus. Proin a nibh fringilla, porta nunc sit amet, vulputate ligula.\n\nInteger congue mi leo, at sagittis dolor posuere vitae. Nunc placerat risus non tortor porttitor accumsan. Vivamus congue, magna a cursus blandit, arcu erat luctus dui, a laoreet quam leo vel lacus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nulla non lectus metus. Etiam gravida nisi ante, a tincidunt augue aliquam et. Praesent congue arcu urna, in pulvinar neque efficitur nec. Nunc cursus mauris id tempor fermentum. Etiam id tempus magna.\n\nIn pellentesque pulvinar molestie. Cras blandit ullamcorper lacus, quis viverra nisl dictum at. Donec hendrerit nibh in lectus consectetur, eu commodo urna vehicula. Proin porta quam sed luctus pellentesque. Vivamus ante risus, maximus non ipsum eget, aliquam consectetur mauris. Nam pulvinar nisi a metus semper feugiat. Integer vestibulum pretium felis, ac sodales arcu aliquam ut. Nunc purus magna, porttitor sit amet eleifend et, consectetur id nulla. Phasellus at justo non nibh rutrum accumsan. Sed fringilla arcu a ipsum sollicitudin, et vulputate risus ullamcorper. Donec eu pharetra arcu. Ut tincidunt lobortis dolor non feugiat. Suspendisse potenti. Duis fermentum mi a est gravida finibus. "

render_test_scroll :: proc() {
	if !scroll_initialised {
		text_input1 = strings.builder_make()
		strings.write_string(
			&text_input1,
			"Hello world! This is a single line text input. This is a single line text input.",
		)
		text_input2 = strings.builder_make()
		strings.write_string(&text_input2, LOREM)
		scroll_initialised = true
	}

	orui.container(
		orui.id("container"),
		{
			direction = .TopToBottom,
			width = orui.grow(),
			height = orui.grow(),
			padding = {16, 24, 16, 16},
			background_color = rl.BEIGE,
			gap = 16,
			align_cross = .Center,
			scroll = orui.scroll(.Vertical),
		},
	)

	orui.scrollbar(
		orui.to_id("container"),
		{
			position = {.Absolute, {-5, 0}},
			placement = orui.placement(.Right, .Right),
			width = orui.fixed(8),
			height = orui.percent(0.98),
		},
		{
			direction = .TopToBottom,
			width = orui.percent(1),
			background_color = rl.DARKGRAY,
			corner_radius = orui.corner(4),
		},
	)

	orui.label(
		orui.id("title"),
		"Scroll",
		{width = orui.grow(), font_size = 24, color = rl.BLACK, align = {.Center, .Center}},
	)

	orui.text_input(
		orui.id("text input 1"),
		&text_input1,
		{
			width = orui.fixed(300),
			height = orui.fit(),
			padding = orui.padding(8),
			background_color = orui.hovered() || orui.focused() ? rl.WHITE : {240, 240, 240, 255},
			color = rl.BLACK,
			font_size = 16,
			overflow = .Visible,
			clip = {.Self, {}},
			scroll = orui.scroll(.Auto),
			border = orui.border(1),
			border_color = orui.focused() ? rl.BLACK : rl.LIGHTGRAY,
		},
	)

	{orui.container(
			orui.id("text input 2 container"),
			{width = orui.fixed(500), height = orui.fixed(500), position = {.Relative, {}}},
		)

		orui.text_input(
			orui.id("text input 2"),
			&text_input2,
			{
				width = orui.fixed(500),
				height = orui.fixed(500),
				padding = orui.padding(8),
				background_color = orui.hovered() || orui.focused() ? rl.WHITE : {240, 240, 240, 255},
				color = rl.BLACK,
				font_size = 16,
				overflow = .Wrap,
				clip = {.Self, {}},
				scroll = orui.scroll(.Auto),
				border = orui.border(1),
				border_color = orui.focused() ? rl.BLACK : rl.LIGHTGRAY,
			},
		)

		orui.scrollbar(
			orui.to_id("text input 2"),
			{
				position = {.Absolute, {-5, 0}},
				placement = orui.placement(.Right, .Right),
				width = orui.fixed(6),
				height = orui.percent(0.9),
			},
			{direction = .TopToBottom, width = orui.percent(1), background_color = rl.LIGHTGRAY},
		)
	}


	{orui.container(
			orui.id("scroll container"),
			{
				position = {.Relative, {}},
				layout = .Flex,
				direction = .TopToBottom,
				width = orui.fixed(600),
				height = orui.fixed(600),
				padding = orui.padding(0, 0),
				background_color = rl.LIGHTGRAY,
				gap = 8,
				clip = {.Self, {}},
				scroll = orui.scroll(.Auto),
				corner_radius = orui.corner(8),
			},
		)

		for i in 0 ..< 25 {
			background: rl.Color =
				i % 3 == 0 ? {4, 41, 64, 255} : i % 3 == 1 ? {0, 92, 83, 255} : {159, 193, 49, 255}
			orui.label(
				orui.id("element", i),
				"Scroll around",
				{
					width = orui.fixed(800),
					height = orui.fixed(200),
					background_color = background,
					font_size = 16,
					color = rl.WHITE,
					align = {.Center, .Center},
					margin = orui.margin(16),
				},
			)
		}

		orui.scrollbar(
			orui.to_id("scroll container"),
			{
				position = {.Absolute, {5, 0}},
				placement = orui.placement(.Right, .Left),
				width = orui.fixed(10),
				height = orui.percent(1),
				background_color = {214, 213, 142, 255},
				corner_radius = orui.corner(4),
			},
			{
				direction = .TopToBottom,
				width = orui.percent(1),
				background_color = rl.DARKGRAY,
				corner_radius = orui.corner(4),
			},
			0,
		)

		orui.scrollbar(
			orui.to_id("scroll container"),
			{
				position = {.Absolute, {0, 15}},
				placement = orui.placement(.Bottom, .Bottom),
				width = orui.percent(1),
				height = orui.fixed(10),
				background_color = {214, 213, 142, 255},
				corner_radius = orui.corner(4),
			},
			{
				direction = .LeftToRight,
				height = orui.percent(1),
				background_color = rl.DARKGRAY,
				corner_radius = orui.corner(4),
			},
			1,
		)
	}
}
