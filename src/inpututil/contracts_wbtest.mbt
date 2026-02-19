///|
fn snapshot_with_pressed_keys(keys : Array[Int]) -> @core.InputSnapshot {
  @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, keys)
}

///|
fn snapshot_with_pressed_mouse_buttons(
  buttons : Array[Int],
) -> @core.InputSnapshot {
  @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [], buttons, [], [])
}

///|
test "inpututil tracks just pressed released and duration" {
  let state = new_key_input_state()

  update_key_input_state(state, snapshot_with_pressed_keys([10]))
  assert_true(is_key_pressed(state, 10))
  assert_true(is_key_just_pressed(state, 10))
  assert_true(!is_key_just_released(state, 10))
  assert_eq(key_press_duration(state, 10), 1)

  update_key_input_state(state, snapshot_with_pressed_keys([10]))
  assert_true(is_key_pressed(state, 10))
  assert_true(!is_key_just_pressed(state, 10))
  assert_true(!is_key_just_released(state, 10))
  assert_eq(key_press_duration(state, 10), 2)

  update_key_input_state(state, snapshot_with_pressed_keys([]))
  assert_true(!is_key_pressed(state, 10))
  assert_true(!is_key_just_pressed(state, 10))
  assert_true(is_key_just_released(state, 10))
  assert_eq(key_press_duration(state, 10), 0)
}

///|
test "inpututil append APIs return deduplicated key sets" {
  let state = new_key_input_state()

  update_key_input_state(state, snapshot_with_pressed_keys([1, 1, 2]))
  let pressed = append_pressed_keys(state, [99])
  let just_pressed = append_just_pressed_keys(state, [])
  let just_released = append_just_released_keys(state, [])

  assert_eq(pressed.length(), 3)
  assert_eq(pressed[0], 99)
  assert_eq(pressed[1], 1)
  assert_eq(pressed[2], 2)
  assert_eq(just_pressed.length(), 2)
  assert_eq(just_pressed[0], 1)
  assert_eq(just_pressed[1], 2)
  assert_eq(just_released.length(), 0)

  update_key_input_state(state, snapshot_with_pressed_keys([2, 3]))
  let just_pressed2 = append_just_pressed_keys(state, [])
  let just_released2 = append_just_released_keys(state, [])
  assert_eq(just_pressed2.length(), 1)
  assert_eq(just_pressed2[0], 3)
  assert_eq(just_released2.length(), 1)
  assert_eq(just_released2[0], 1)
}

///|
test "inpututil tracks mouse button pressed released and duration" {
  let state = new_mouse_input_state()

  update_mouse_input_state(state, snapshot_with_pressed_mouse_buttons([1]))
  assert_true(is_mouse_button_pressed(state, 1))
  assert_true(is_mouse_button_just_pressed(state, 1))
  assert_true(!is_mouse_button_just_released(state, 1))
  assert_eq(mouse_button_press_duration(state, 1), 1)

  update_mouse_input_state(state, snapshot_with_pressed_mouse_buttons([1]))
  assert_true(is_mouse_button_pressed(state, 1))
  assert_true(!is_mouse_button_just_pressed(state, 1))
  assert_true(!is_mouse_button_just_released(state, 1))
  assert_eq(mouse_button_press_duration(state, 1), 2)

  update_mouse_input_state(state, snapshot_with_pressed_mouse_buttons([]))
  assert_true(!is_mouse_button_pressed(state, 1))
  assert_true(!is_mouse_button_just_pressed(state, 1))
  assert_true(is_mouse_button_just_released(state, 1))
  assert_eq(mouse_button_press_duration(state, 1), 0)
}

///|
test "inpututil append mouse button APIs return deduplicated sets" {
  let state = new_mouse_input_state()

  update_mouse_input_state(
    state,
    snapshot_with_pressed_mouse_buttons([0, 0, 2]),
  )
  let pressed = append_pressed_mouse_buttons(state, [9])
  let just_pressed = append_just_pressed_mouse_buttons(state, [])
  let just_released = append_just_released_mouse_buttons(state, [])

  assert_eq(pressed.length(), 3)
  assert_eq(pressed[0], 9)
  assert_eq(pressed[1], 0)
  assert_eq(pressed[2], 2)
  assert_eq(just_pressed.length(), 2)
  assert_eq(just_pressed[0], 0)
  assert_eq(just_pressed[1], 2)
  assert_eq(just_released.length(), 0)

  update_mouse_input_state(state, snapshot_with_pressed_mouse_buttons([2, 1]))
  let just_pressed2 = append_just_pressed_mouse_buttons(state, [])
  let just_released2 = append_just_released_mouse_buttons(state, [])
  assert_eq(just_pressed2.length(), 1)
  assert_eq(just_pressed2[0], 1)
  assert_eq(just_released2.length(), 1)
  assert_eq(just_released2[0], 0)
}
