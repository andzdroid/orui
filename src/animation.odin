package orui

import "core:hash"
import "core:math"
import "core:math/ease"
import rl "vendor:raylib"

AnimationId :: distinct u32

DEFAULT_ANIMATION_TIME: f32 : 0.12
DEFAULT_ANIMATION_EASING: ease.Ease : .Quadratic_Out

AnimationFactorData :: struct {
	value:   f32,
	start:   f32,
	target:  f32,
	trigger: bool,
}

AnimationValueData :: struct($T: typeid) {
	value:  T,
	start:  T,
	target: T,
}

AnimationData :: union {
	AnimationFactorData,
	AnimationValueData(f32),
	AnimationValueData(rl.Vector2),
	AnimationValueData(rl.Color),
	AnimationValueData(Edges),
	AnimationValueData(Corners),
	AnimationValueData(Size),
}

AnimationState :: struct {
	elapsed:  f32,
	duration: f32,
	easing:   ease.Ease,
	active:   bool,
	data:     AnimationData,
}

transition :: proc {
	transition_factor_string,
	transition_factor_string_index,
	transition_string,
	transition_string_index,
}

animate :: proc {
	animate_string,
	animate_string_index,
}

lerp :: proc {
	lerp_float,
	lerp_vector2,
	lerp_color,
	lerp_edges,
	lerp_corners,
	lerp_size,
}

lerp_float :: proc(a, b, t: f32) -> f32 {
	return math.lerp(a, b, t)
}

lerp_vector2 :: proc(a, b: rl.Vector2, t: f32) -> rl.Vector2 {
	return math.lerp(a, b, t)
}

lerp_color :: proc(a, b: rl.Color, t: f32) -> rl.Color {
	return {
		lerp_color_channel(a[0], b[0], t),
		lerp_color_channel(a[1], b[1], t),
		lerp_color_channel(a[2], b[2], t),
		lerp_color_channel(a[3], b[3], t),
	}
}

@(private)
lerp_color_channel :: #force_inline proc(a, b: u8, t: f32) -> u8 {
	return u8(clamp(math.lerp(f32(a), f32(b), t), 0, 255))
}

lerp_edges :: proc(a, b: Edges, t: f32) -> Edges {
	return Edges {
		top = lerp_float(a.top, b.top, t),
		right = lerp_float(a.right, b.right, t),
		bottom = lerp_float(a.bottom, b.bottom, t),
		left = lerp_float(a.left, b.left, t),
	}
}

lerp_corners :: proc(a, b: Corners, t: f32) -> Corners {
	return Corners {
		top_left = lerp_float(a.top_left, b.top_left, t),
		top_right = lerp_float(a.top_right, b.top_right, t),
		bottom_right = lerp_float(a.bottom_right, b.bottom_right, t),
		bottom_left = lerp_float(a.bottom_left, b.bottom_left, t),
	}
}

lerp_size :: proc(a, b: Size, t: f32) -> Size {
	if a.type != b.type do return b

	return Size {
		type = a.type,
		value = lerp_float(a.value, b.value, t),
		min = lerp_float(a.min, b.min, t),
		max = lerp_float(a.max, b.max, t),
	}
}

@(private)
transition_factor_string :: proc(
	id: string,
	trigger: bool,
	duration: f32 = DEFAULT_ANIMATION_TIME,
	easing: ease.Ease = DEFAULT_ANIMATION_EASING,
) -> f32 {
	return transition_factor(animation_id(id), trigger, duration, easing)
}

@(private)
transition_factor_string_index :: proc(
	id: string,
	index: int,
	trigger: bool,
	duration: f32 = DEFAULT_ANIMATION_TIME,
	easing: ease.Ease = DEFAULT_ANIMATION_EASING,
) -> f32 {
	return transition_factor(animation_id(id, index), trigger, duration, easing)
}

@(private)
transition_string :: proc(
	id: string,
	trigger: bool,
	from, to: $T,
	duration: f32 = DEFAULT_ANIMATION_TIME,
	easing: ease.Ease = DEFAULT_ANIMATION_EASING,
) -> T {
	return transition_value(animation_id(id), trigger, from, to, duration, easing)
}

@(private)
transition_string_index :: proc(
	id: string,
	index: int,
	trigger: bool,
	from, to: $T,
	duration: f32 = DEFAULT_ANIMATION_TIME,
	easing: ease.Ease = DEFAULT_ANIMATION_EASING,
) -> T {
	return transition_value(animation_id(id, index), trigger, from, to, duration, easing)
}

@(private)
transition_value :: proc(
	local_id: AnimationId,
	trigger: bool,
	from, to: $T,
	duration: f32 = DEFAULT_ANIMATION_TIME,
	easing: ease.Ease = DEFAULT_ANIMATION_EASING,
) -> T {
	when T == Size {
		if from.type != to.type do return trigger ? to : from
	}

	return lerp(from, to, transition_factor(local_id, trigger, duration, easing))
}

@(private)
transition_factor :: proc(
	local_id: AnimationId,
	trigger: bool,
	duration: f32 = DEFAULT_ANIMATION_TIME,
	easing: ease.Ease = DEFAULT_ANIMATION_EASING,
) -> f32 {
	ctx := current_context
	key := animation_key(local_id)
	target: f32 = trigger ? 1 : 0

	if state, ok := animation_current(ctx, key); ok {
		if data, ok2 := state.data.(AnimationFactorData); ok2 {
			assert(
				data.trigger == trigger,
				"same transition id used with conflicting triggers in one frame",
			)
			return data.value
		}

		assert(false, "animation id reused with incompatible animation value type")
		return 0
	}

	if state, ok := animation_previous(ctx, key); ok {
		if data, ok2 := state.data.(AnimationFactorData); ok2 {
			if data.trigger != trigger {
				data.trigger = trigger
				data.start = data.value
				data.target = target
				animation_start(&state, duration, easing, data.start != data.target)
			}

			animation_update(ctx, &state, &data)
			state.data = data
			animation_store(ctx, key, state)
			return data.value
		}
	}

	data := AnimationFactorData {
		value   = target,
		start   = target,
		target  = target,
		trigger = trigger,
	}
	state := AnimationState {
		elapsed  = 0,
		duration = max(duration, 0),
		easing   = easing,
		active   = false,
		data     = data,
	}
	animation_store(ctx, key, state)
	return data.value
}

@(private)
animate_string :: proc(
	id: string,
	target: $T,
	duration: f32 = DEFAULT_ANIMATION_TIME,
	easing: ease.Ease = DEFAULT_ANIMATION_EASING,
) -> T {
	return animate_value(animation_id(id), target, duration, easing)
}

@(private)
animate_string_index :: proc(
	id: string,
	index: int,
	target: $T,
	duration: f32 = DEFAULT_ANIMATION_TIME,
	easing: ease.Ease = DEFAULT_ANIMATION_EASING,
) -> T {
	return animate_value(animation_id(id, index), target, duration, easing)
}

@(private)
animate_value :: proc(
	local_id: AnimationId,
	target: $T,
	duration: f32 = DEFAULT_ANIMATION_TIME,
	easing: ease.Ease = DEFAULT_ANIMATION_EASING,
) -> T {
	ctx := current_context
	key := animation_key(local_id)

	if state, ok := animation_current(ctx, key); ok {
		if data, ok2 := state.data.(AnimationValueData(T)); ok2 {
			assert(
				data.target == target,
				"same animate id used with conflicting targets in one frame",
			)
			return data.value
		}

		assert(false, "animation id reused with incompatible animation value type")
		return {}
	}

	if state, ok := animation_previous(ctx, key); ok {
		if data, ok2 := state.data.(AnimationValueData(T)); ok2 {
			if data.target != target {
				when T == Size {
					if data.target.type != target.type {
						data.value = target
						data.start = target
						data.target = target
						state.active = false
						state.elapsed = 0
						state.duration = max(duration, 0)
						state.easing = easing
					} else {
						data.start = data.value
						data.target = target
						animation_start(&state, duration, easing, data.start != data.target)
					}
				} else {
					data.start = data.value
					data.target = target
					animation_start(&state, duration, easing, data.start != data.target)
				}
			}

			animation_update(ctx, &state, &data)
			state.data = data
			animation_store(ctx, key, state)
			return data.value
		}
	}

	data := AnimationValueData(T) {
		value  = target,
		start  = target,
		target = target,
	}
	state := AnimationState {
		elapsed  = 0,
		duration = max(duration, 0),
		easing   = easing,
		active   = false,
		data     = data,
	}
	animation_store(ctx, key, state)
	return data.value
}

@(private)
animation_start :: #force_inline proc(
	state: ^AnimationState,
	duration: f32,
	easing: ease.Ease,
	changed: bool,
) {
	state.duration = max(duration, 0)
	state.easing = easing
	state.active = changed && state.duration > 0
	state.elapsed = 0
}

@(private)
animation_update :: proc(ctx: ^Context, state: ^AnimationState, data: ^$Data) {
	if state.active {
		state.elapsed += ctx.dt
		raw_t := state.duration <= 0 ? 1 : clamp(state.elapsed / state.duration, 0, 1)
		eased_t := animation_apply_easing(raw_t, state.easing)
		data.value = lerp(data.start, data.target, eased_t)

		if raw_t >= 1 {
			data.value = data.target
			state.active = false
		}
	} else {
		data.value = data.target
	}
}

@(private)
animation_apply_easing :: #force_inline proc(t: f32, easing: ease.Ease) -> f32 {
	return ease.ease(easing, clamp(t, 0, 1))
}

@(private)
animation_current :: #force_inline proc(
	ctx: ^Context,
	key: AnimationId,
) -> (
	AnimationState,
	bool,
) {
	return ctx.animation_states[current_buffer(ctx)][key]
}

@(private)
animation_previous :: #force_inline proc(
	ctx: ^Context,
	key: AnimationId,
) -> (
	AnimationState,
	bool,
) {
	return ctx.animation_states[previous_buffer(ctx)][key]
}

@(private)
animation_store :: #force_inline proc(ctx: ^Context, key: AnimationId, state: AnimationState) {
	ctx.animation_states[current_buffer(ctx)][key] = state
}

animation_id :: proc {
	animation_id_compiled,
	animation_id_compiled_index,
	animation_id_string,
	animation_id_string_index,
}

animation_id_compiled :: proc($S: string) -> AnimationId {
	return AnimationId(#hash(S, "fnv32a"))
}

animation_id_compiled_index :: proc($S: string, #any_int index: int) -> AnimationId {
	return AnimationId(hash.fnv32a(transmute([]u8)S, u32(index)))
}

animation_id_string :: proc(str: string) -> AnimationId {
	return AnimationId(hash.fnv32a(transmute([]u8)str))
}

animation_id_string_index :: proc(str: string, #any_int index: int) -> AnimationId {
	return AnimationId(hash.fnv32a(transmute([]u8)str, u32(index)))
}

animation_key :: #force_inline proc(local_id: AnimationId) -> AnimationId {
	ctx := current_context
	assert(ctx != nil)
	assert(ctx.current_id != 0, "animation functions must be called inside an element declaration")
	local_bytes := transmute([4]u8)local_id
	return AnimationId(hash.fnv32a(local_bytes[:], u32(ctx.current_id)))
}
