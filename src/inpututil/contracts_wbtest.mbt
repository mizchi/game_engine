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
fn snapshot_with_touches(
  touches : Array[@core.TouchPoint],
) -> @core.InputSnapshot {
  @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [], [], touches, [])
}

///|
fn snapshot_with_gamepads(
  gamepads : Array[@core.GamepadSnapshot],
) -> @core.InputSnapshot {
  @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [], [], [], gamepads)
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

///|
test "inpututil tracks touch ids and durations" {
  let state = new_touch_input_state()

  update_touch_input_state(
    state,
    snapshot_with_touches([
      @core.new_touch_point(10, 1.0, 2.0),
      @core.new_touch_point(10, 3.0, 4.0),
      @core.new_touch_point(11, 5.0, 6.0),
    ]),
  )
  assert_true(is_touch_pressed(state, 10))
  assert_true(is_touch_just_pressed(state, 10))
  assert_true(!is_touch_just_released(state, 10))
  assert_eq(touch_press_duration(state, 10), 1)
  let touch_ids = append_touch_ids(state, [99])
  let just_pressed = append_just_pressed_touch_ids(state, [])
  assert_eq(touch_ids.length(), 3)
  assert_eq(touch_ids[0], 99)
  assert_eq(touch_ids[1], 10)
  assert_eq(touch_ids[2], 11)
  assert_eq(just_pressed.length(), 2)
  assert_eq(just_pressed[0], 10)
  assert_eq(just_pressed[1], 11)

  update_touch_input_state(
    state,
    snapshot_with_touches([@core.new_touch_point(11, 7.0, 8.0)]),
  )
  assert_true(!is_touch_pressed(state, 10))
  assert_true(is_touch_just_released(state, 10))
  assert_true(is_touch_pressed(state, 11))
  assert_eq(touch_press_duration(state, 11), 2)
  let just_released = append_just_released_touch_ids(state, [])
  assert_eq(just_released.length(), 1)
  assert_eq(just_released[0], 10)
}

///|
test "key input state initial is empty" {
  let state = new_key_input_state()
  assert_true(!is_key_pressed(state, 0))
  assert_true(!is_key_just_pressed(state, 0))
  assert_true(!is_key_just_released(state, 0))
  assert_eq(key_press_duration(state, 0), 0)
  assert_eq(append_pressed_keys(state, []).length(), 0)
}

///|
test "mouse input state initial is empty" {
  let state = new_mouse_input_state()
  assert_true(!is_mouse_button_pressed(state, 0))
  assert_true(!is_mouse_button_just_pressed(state, 0))
  assert_true(!is_mouse_button_just_released(state, 0))
  assert_eq(mouse_button_press_duration(state, 0), 0)
  assert_eq(append_pressed_mouse_buttons(state, []).length(), 0)
}

///|
test "key duration resets after release and re-press" {
  let state = new_key_input_state()
  update_key_input_state(state, snapshot_with_pressed_keys([5]))
  update_key_input_state(state, snapshot_with_pressed_keys([5]))
  update_key_input_state(state, snapshot_with_pressed_keys([5]))
  assert_eq(key_press_duration(state, 5), 3)
  update_key_input_state(state, snapshot_with_pressed_keys([]))
  assert_eq(key_press_duration(state, 5), 0)
  update_key_input_state(state, snapshot_with_pressed_keys([5]))
  assert_eq(key_press_duration(state, 5), 1)
  assert_true(is_key_just_pressed(state, 5))
}

///|
test "simultaneous key presses are tracked independently" {
  let state = new_key_input_state()
  update_key_input_state(state, snapshot_with_pressed_keys([1, 2, 3]))
  assert_true(is_key_pressed(state, 1))
  assert_true(is_key_pressed(state, 2))
  assert_true(is_key_pressed(state, 3))
  assert_true(is_key_just_pressed(state, 1))
  assert_true(is_key_just_pressed(state, 2))
  assert_true(is_key_just_pressed(state, 3))
  update_key_input_state(state, snapshot_with_pressed_keys([2]))
  assert_true(!is_key_pressed(state, 1))
  assert_true(is_key_pressed(state, 2))
  assert_true(!is_key_pressed(state, 3))
  assert_true(is_key_just_released(state, 1))
  assert_true(is_key_just_released(state, 3))
  assert_true(!is_key_just_released(state, 2))
}

///|
test "mouse button duration accumulates correctly" {
  let state = new_mouse_input_state()
  update_mouse_input_state(state, snapshot_with_pressed_mouse_buttons([0]))
  assert_eq(mouse_button_press_duration(state, 0), 1)
  update_mouse_input_state(state, snapshot_with_pressed_mouse_buttons([0]))
  assert_eq(mouse_button_press_duration(state, 0), 2)
  update_mouse_input_state(state, snapshot_with_pressed_mouse_buttons([0]))
  assert_eq(mouse_button_press_duration(state, 0), 3)
  update_mouse_input_state(state, snapshot_with_pressed_mouse_buttons([]))
  assert_eq(mouse_button_press_duration(state, 0), 0)
}

///|
test "empty snapshot clears all pressed keys" {
  let state = new_key_input_state()
  update_key_input_state(state, snapshot_with_pressed_keys([10, 20, 30]))
  assert_eq(append_pressed_keys(state, []).length(), 3)
  update_key_input_state(state, snapshot_with_pressed_keys([]))
  assert_eq(append_pressed_keys(state, []).length(), 0)
  let released = append_just_released_keys(state, [])
  assert_eq(released.length(), 3)
}

///|
test "touch input with boundary id zero" {
  let state = new_touch_input_state()
  update_touch_input_state(
    state,
    snapshot_with_touches([@core.new_touch_point(0, 0.0, 0.0)]),
  )
  assert_true(is_touch_pressed(state, 0))
  assert_true(is_touch_just_pressed(state, 0))
  assert_eq(touch_press_duration(state, 0), 1)
  update_touch_input_state(state, snapshot_with_touches([]))
  assert_true(is_touch_just_released(state, 0))
  assert_eq(touch_press_duration(state, 0), 0)
}

///|
test "touch input with many duplicate ids deduplicates" {
  let state = new_touch_input_state()
  let touches : Array[@core.TouchPoint] = []
  for i in 0..<8 {
    touches.push(@core.new_touch_point(42, i.to_double(), 0.0))
  }
  update_touch_input_state(state, snapshot_with_touches(touches))
  let ids = append_touch_ids(state, [])
  assert_eq(ids.length(), 1)
  assert_eq(ids[0], 42)
  assert_eq(touch_press_duration(state, 42), 1)
}

///|
test "touch rapid press release repress tracks correctly" {
  let state = new_touch_input_state()
  update_touch_input_state(
    state,
    snapshot_with_touches([@core.new_touch_point(5, 0.0, 0.0)]),
  )
  assert_eq(touch_press_duration(state, 5), 1)
  update_touch_input_state(state, snapshot_with_touches([]))
  assert_true(is_touch_just_released(state, 5))
  assert_eq(touch_press_duration(state, 5), 0)
  update_touch_input_state(
    state,
    snapshot_with_touches([@core.new_touch_point(5, 1.0, 1.0)]),
  )
  assert_true(is_touch_just_pressed(state, 5))
  assert_eq(touch_press_duration(state, 5), 1)
}

///|
test "InputHelper initial state" {
  let helper = new_input_helper()
  let empty = @core.empty_input_snapshot()
  assert_true(!is_any_action_just_pressed(helper, empty))
}

///|
test "InputHelper key press detected" {
  let helper = new_input_helper()
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  update_input_helper(helper, input)
  assert_true(is_any_action_just_pressed(helper, input))
  // Second frame: same key held → not just pressed
  update_input_helper(helper, input)
  assert_true(!is_any_action_just_pressed(helper, input))
}

///|
test "InputHelper mouse click detected" {
  let helper = new_input_helper()
  let input = @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [], [0], [], [])
  update_input_helper(helper, input)
  assert_true(is_any_action_just_pressed(helper, input))
}

///|
test "InputHelper touch detected" {
  let helper = new_input_helper()
  let empty = @core.empty_input_snapshot()
  update_input_helper(helper, empty)
  let input_with_touch = @core.new_input_snapshot_full(
    0.0, 0.0, 0.0, 0.0, [], [], [@core.new_touch_point(1, 10.0, 20.0)], [],
  )
  update_input_helper(helper, input_with_touch)
  assert_true(is_any_action_just_pressed(helper, input_with_touch))
}

///|
test "InputHelper touch held not just pressed on second frame" {
  let helper = new_input_helper()
  let empty = @core.empty_input_snapshot()
  update_input_helper(helper, empty)
  let input_with_touch = @core.new_input_snapshot_full(
    0.0, 0.0, 0.0, 0.0, [], [], [@core.new_touch_point(1, 10.0, 20.0)], [],
  )
  // Frame 1: just pressed
  update_input_helper(helper, input_with_touch)
  assert_true(is_any_action_just_pressed(helper, input_with_touch))
  // Frame 2: same touch held → NOT just pressed
  update_input_helper(helper, input_with_touch)
  assert_true(!is_any_action_just_pressed(helper, input_with_touch))
}

///|
test "multiple gamepads tracked independently" {
  let state = new_gamepad_input_state()
  update_gamepad_input_state(
    state,
    snapshot_with_gamepads([
      @core.new_gamepad_snapshot(0, [0.5], [1]),
      @core.new_gamepad_snapshot(1, [-0.5], [2]),
      @core.new_gamepad_snapshot(2, [], [3]),
    ]),
  )
  assert_true(is_gamepad_connected(state, 0))
  assert_true(is_gamepad_connected(state, 1))
  assert_true(is_gamepad_connected(state, 2))
  assert_true(is_gamepad_button_pressed(state, 0, 1))
  assert_true(is_gamepad_button_pressed(state, 1, 2))
  assert_true(is_gamepad_button_pressed(state, 2, 3))
  assert_true(!is_gamepad_button_pressed(state, 0, 2))
  assert_true(!is_gamepad_button_pressed(state, 1, 1))
  // Disconnect gamepad 1, keep 0 and 2
  update_gamepad_input_state(
    state,
    snapshot_with_gamepads([
      @core.new_gamepad_snapshot(0, [0.5], [1]),
      @core.new_gamepad_snapshot(2, [], [3]),
    ]),
  )
  assert_true(is_gamepad_connected(state, 0))
  assert_true(!is_gamepad_connected(state, 1))
  assert_true(is_gamepad_connected(state, 2))
  assert_true(is_gamepad_just_disconnected(state, 1))
  assert_true(is_gamepad_button_just_released(state, 1, 2))
  assert_eq(gamepad_connection_duration(state, 0), 2)
  assert_eq(gamepad_connection_duration(state, 1), 0)
}

///|
test "gamepad button count APIs" {
  let state = new_gamepad_input_state()
  update_gamepad_input_state(
    state,
    snapshot_with_gamepads([@core.new_gamepad_snapshot(0, [], [1, 2, 3, 4, 5])]),
  )
  assert_eq(gamepad_pressed_button_count(state), 5)
  assert_eq(gamepad_just_pressed_button_count(state), 5)
  assert_eq(gamepad_just_released_button_count(state), 0)
  update_gamepad_input_state(
    state,
    snapshot_with_gamepads([@core.new_gamepad_snapshot(0, [], [1, 3])]),
  )
  assert_eq(gamepad_pressed_button_count(state), 2)
  assert_eq(gamepad_just_released_button_count(state), 3)
}

///|
test "gamepad with id zero works" {
  let state = new_gamepad_input_state()
  update_gamepad_input_state(
    state,
    snapshot_with_gamepads([@core.new_gamepad_snapshot(0, [1.0, -1.0], [0])]),
  )
  assert_true(is_gamepad_connected(state, 0))
  assert_true(is_gamepad_button_pressed(state, 0, 0))
  assert_eq(gamepad_connection_duration(state, 0), 1)
  assert_eq(gamepad_button_press_duration(state, 0, 0), 1)
}

// ============================================================
// Direction helper tests
// ============================================================

///|
test "is_move_up detects W key" {
  let state = new_key_input_state()
  update_key_input_state(state, snapshot_with_pressed_keys([87]))
  assert_true!(is_move_up(state))
}

///|
test "is_move_up detects arrow up web" {
  let state = new_key_input_state()
  update_key_input_state(state, snapshot_with_pressed_keys([38]))
  assert_true!(is_move_up(state))
}

///|
test "is_move_up detects arrow up glfw" {
  let state = new_key_input_state()
  update_key_input_state(state, snapshot_with_pressed_keys([265]))
  assert_true!(is_move_up(state))
}

///|
test "is_move_down detects S key" {
  let state = new_key_input_state()
  update_key_input_state(state, snapshot_with_pressed_keys([83]))
  assert_true!(is_move_down(state))
}

///|
test "is_move_left detects A key" {
  let state = new_key_input_state()
  update_key_input_state(state, snapshot_with_pressed_keys([65]))
  assert_true!(is_move_left(state))
}

///|
test "is_move_right detects D key" {
  let state = new_key_input_state()
  update_key_input_state(state, snapshot_with_pressed_keys([68]))
  assert_true!(is_move_right(state))
}

///|
test "is_confirm_just_pressed detects space" {
  let helper = new_input_helper()
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  update_input_helper(helper, input)
  assert_true!(is_confirm_just_pressed(helper))
}

///|
test "is_confirm_just_pressed detects enter web" {
  let helper = new_input_helper()
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [13])
  update_input_helper(helper, input)
  assert_true!(is_confirm_just_pressed(helper))
}

///|
test "is_confirm_just_pressed detects enter glfw" {
  let helper = new_input_helper()
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [257])
  update_input_helper(helper, input)
  assert_true!(is_confirm_just_pressed(helper))
}

///|
test "is_up_just_pressed detects W" {
  let helper = new_input_helper()
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [87])
  update_input_helper(helper, input)
  assert_true!(is_up_just_pressed(helper))
}

///|
test "is_down_just_pressed detects S" {
  let helper = new_input_helper()
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [83])
  update_input_helper(helper, input)
  assert_true!(is_down_just_pressed(helper))
}

///|
test "direction not detected without matching key" {
  let state = new_key_input_state()
  update_key_input_state(state, snapshot_with_pressed_keys([99]))
  assert_true!(!is_move_up(state))
  assert_true!(!is_move_down(state))
  assert_true!(!is_move_left(state))
  assert_true!(!is_move_right(state))
}

///|
test "inpututil tracks gamepad connection and button edges" {
  let state = new_gamepad_input_state()

  update_gamepad_input_state(
    state,
    snapshot_with_gamepads([@core.new_gamepad_snapshot(7, [], [1, 1, 3])]),
  )
  assert_true(is_gamepad_connected(state, 7))
  assert_true(is_gamepad_just_connected(state, 7))
  assert_true(!is_gamepad_just_disconnected(state, 7))
  assert_eq(gamepad_connection_duration(state, 7), 1)
  assert_true(is_gamepad_button_pressed(state, 7, 1))
  assert_true(is_gamepad_button_just_pressed(state, 7, 1))
  assert_true(!is_gamepad_button_just_released(state, 7, 1))
  assert_eq(gamepad_button_press_duration(state, 7, 1), 1)
  let connected = append_connected_gamepad_ids(state, [99])
  let just_connected = append_just_connected_gamepad_ids(state, [])
  assert_eq(connected.length(), 2)
  assert_eq(connected[0], 99)
  assert_eq(connected[1], 7)
  assert_eq(just_connected.length(), 1)
  assert_eq(just_connected[0], 7)

  update_gamepad_input_state(
    state,
    snapshot_with_gamepads([@core.new_gamepad_snapshot(7, [], [3])]),
  )
  assert_true(is_gamepad_connected(state, 7))
  assert_true(!is_gamepad_just_connected(state, 7))
  assert_true(!is_gamepad_just_disconnected(state, 7))
  assert_eq(gamepad_connection_duration(state, 7), 2)
  assert_true(!is_gamepad_button_pressed(state, 7, 1))
  assert_true(is_gamepad_button_just_released(state, 7, 1))
  assert_true(is_gamepad_button_pressed(state, 7, 3))
  assert_eq(gamepad_button_press_duration(state, 7, 3), 2)

  update_gamepad_input_state(state, snapshot_with_gamepads([]))
  assert_true(!is_gamepad_connected(state, 7))
  assert_true(is_gamepad_just_disconnected(state, 7))
  assert_true(is_gamepad_button_just_released(state, 7, 3))
  assert_eq(gamepad_connection_duration(state, 7), 0)
  assert_eq(gamepad_button_press_duration(state, 7, 3), 0)
  let just_disconnected = append_just_disconnected_gamepad_ids(state, [])
  assert_eq(just_disconnected.length(), 1)
  assert_eq(just_disconnected[0], 7)
}
