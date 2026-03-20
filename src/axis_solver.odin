package orui

/*
1. Start each item at `size`, clamped to its fixed bounds
2. Compute how much space is left:
       remaining = target_content_size - gap_total - sum(size)
3. If remaining > 0, flexible items grow
   - each item's grow cap is max - size
   - if there is no max, that item can keep growing
4. If remaining < 0, flexible items shrink
   - each item's shrink cap is size - min
5. Split that adjustment by factor until items hit their caps
   - once an item hits its cap, it stops participating
   - the remaining amount is redistributed to the still-active items

Example without caps:
- target item space after gaps: 300
- current item sizes: A = 80, B = 120, C = 60
- current total: 260, so 40 pixels must be added
- weights: A = 1, B = 2, C = 1

Total weight is 4, so the extra 40 splits as:
- A gets `10`
- B gets `20`
- C gets `10`

Final sizes:
- A = 90
- B = 140
- C = 70

Example with cap:
- same setup, but C may grow by at most 5
- the first weighted split still wants to give C 10
- C clamps at +5, leaving 5 pixels still undistributed
- that leftover 5 is redistributed to A and B with weights 1:2

Final deltas become:
- A = +11.666...
- B = +23.333...
- C = +5
*/

EPSILON: f32 : 0.001

AxisAllocationItem :: struct {
	size:   f32,
	min:    f32,
	max:    f32,
	factor: f32,
}

AxisBreakpoint :: struct {
	ratio: f32,
	index: int,
}

resolve_axis_allocation :: proc(
	items: []AxisAllocationItem,
	target_content_size: f32,
	gap_total: f32,
	scratch: []AxisBreakpoint,
) -> (
	resolved_content_size: f32,
) {
	for &item in items {
		item.size = axis_clamp_size(item)
	}

	size_total: f32 = 0
	for item in items {
		size_total += item.size
	}

	remaining := target_content_size - size_total - gap_total
	if remaining > EPSILON {
		capped_weighted_allocate(remaining, items, scratch, false)
	} else if remaining < -EPSILON {
		capped_weighted_allocate(-remaining, items, scratch, true)
	}

	resolved_content_size = gap_total
	for item in items {
		resolved_content_size += item.size
	}
	return
}

@(private = "file")
axis_clamp_size :: proc(item: AxisAllocationItem) -> f32 {
	size := max(item.size, item.min)
	if item.max > 0 {
		max_size := max(item.max, item.min)
		if size > max_size {
			size = max_size
		}
	}
	return size
}

@(private = "file")
axis_item_cap :: proc(item: AxisAllocationItem, shrink: bool) -> (cap: f32, finite: bool) {
	if shrink {
		cap = max(item.size - item.min, 0)
		finite = true
		return
	}

	if item.max <= 0 {
		return
	}

	max_size := max(item.max, item.min)
	cap = max(max_size - item.size, 0)
	finite = true
	return
}

@(private = "file")
capped_weighted_allocate :: proc(
	amount: f32,
	items: []AxisAllocationItem,
	scratch: []AxisBreakpoint,
	shrink: bool,
) -> (
	allocated: f32,
) {
	if amount <= EPSILON || len(items) == 0 {
		return
	}

	assert(len(scratch) >= len(items), "axis solver scratch slice is too small")

	breakpoint_count := 0
	active_factor_sum: f32 = 0

	for item, i in items {
		if item.factor <= 0 {
			continue
		}

		cap, finite := axis_item_cap(item, shrink)
		if finite && cap <= EPSILON {
			continue
		}

		active_factor_sum += item.factor
		if finite {
			scratch[breakpoint_count] = {cap / item.factor, i}
			breakpoint_count += 1
		}
	}

	if active_factor_sum <= 0 {
		return
	}

	sort_breakpoints(scratch[:breakpoint_count])

	current_ratio: f32 = 0
	consumed: f32 = 0
	k := 0
	for k < breakpoint_count {
		next_ratio := scratch[k].ratio
		segment := (next_ratio - current_ratio) * active_factor_sum
		if consumed + segment >= amount - EPSILON {
			break
		}

		consumed += segment
		current_ratio = next_ratio

		for k < breakpoint_count && scratch[k].ratio <= next_ratio + EPSILON {
			active_factor_sum -= items[scratch[k].index].factor
			k += 1
		}

		if active_factor_sum <= 0 {
			break
		}
	}

	scale := current_ratio
	if active_factor_sum > 0 && consumed < amount {
		scale += (amount - consumed) / active_factor_sum
	}

	for &item in items {
		if item.factor <= 0 {
			continue
		}

		cap, finite := axis_item_cap(item, shrink)
		if finite && cap <= EPSILON {
			continue
		}

		delta := scale * item.factor
		if finite && delta > cap {
			delta = cap
		}

		if shrink {
			item.size -= delta
		} else {
			item.size += delta
		}
		allocated += delta
	}

	return
}

@(private = "file")
sort_breakpoints :: proc(scratch: []AxisBreakpoint) {
	for i := 1; i < len(scratch); i += 1 {
		key := scratch[i]
		j := i - 1
		for j >= 0 && scratch[j].ratio > key.ratio {
			scratch[j + 1] = scratch[j]
			j -= 1
		}
		scratch[j + 1] = key
	}
}
