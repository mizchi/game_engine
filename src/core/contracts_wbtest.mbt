///|
test "empty_input_snapshot has zero values" {
  let snap = empty_input_snapshot()
  assert_eq(snap.cursor_x, 0.0)
  assert_eq(snap.cursor_y, 0.0)
  assert_eq(snap.wheel_x, 0.0)
  assert_eq(snap.wheel_y, 0.0)
  assert_eq(snap.pressed_keys.length(), 0)
  assert_eq(snap.pressed_mouse_buttons.length(), 0)
  assert_eq(snap.touches.length(), 0)
  assert_eq(snap.gamepads.length(), 0)
}

///|
test "new_input_snapshot fills keyboard and cursor" {
  let snap = new_input_snapshot(10.5, 20.5, 1.0, -1.0, [65, 66])
  assert_eq(snap.cursor_x, 10.5)
  assert_eq(snap.cursor_y, 20.5)
  assert_eq(snap.wheel_x, 1.0)
  assert_eq(snap.wheel_y, -1.0)
  assert_eq(snap.pressed_keys.length(), 2)
  assert_eq(snap.pressed_keys[0], 65)
  assert_eq(snap.pressed_keys[1], 66)
  assert_eq(snap.pressed_mouse_buttons.length(), 0)
}

///|
test "new_input_snapshot_full fills all fields" {
  let snap = new_input_snapshot_full(
    5.0,
    6.0,
    0.0,
    0.0,
    [1],
    [0, 2],
    [new_touch_point(10, 100.0, 200.0)],
    [new_gamepad_snapshot(7, [0.5, -0.5], [1, 3])],
  )
  assert_eq(snap.pressed_keys.length(), 1)
  assert_eq(snap.pressed_mouse_buttons.length(), 2)
  assert_eq(snap.touches.length(), 1)
  assert_eq(snap.touches[0].id, 10)
  assert_eq(snap.touches[0].x, 100.0)
  assert_eq(snap.gamepads.length(), 1)
  assert_eq(snap.gamepads[0].id, 7)
  assert_eq(snap.gamepads[0].axes.length(), 2)
  assert_eq(snap.gamepads[0].pressed_buttons.length(), 2)
}

///|
test "noop game layout returns configured dimensions" {
  let game = new_noop_game(320, 240)
  let logical = game.layout(new_outside_size(800.0, 600.0))
  assert_eq(logical.width, 320)
  assert_eq(logical.height, 240)
}

///|
test "noop game update returns none" {
  let game = new_noop_game(320, 240)
  match game.update(empty_input_snapshot()) {
    Some(_) => panic()
    None => ()
  }
}

///|
test "default_run_options has expected defaults" {
  let opts = default_run_options()
  assert_eq(opts.init_unfocused, false)
  assert_eq(opts.screen_transparent, false)
  assert_eq(opts.screen_cleared_every_frame, true)
}

///|
test "default_fixed_step_config returns 60 tps" {
  let config = default_fixed_step_config()
  assert_eq(config.tps, 60)
  assert_eq(config.max_updates_per_frame, 5)
}

///|
test "step_fixed_timestep with negative elapsed treats as zero" {
  let state = initial_fixed_step_state()
  let config = default_fixed_step_config()
  let result = step_fixed_timestep(state, -100.0, config)
  assert_eq(result.updates, 0)
  assert_eq(result.next_state.tick, 0)
}

///|
test "input snapshot with negative cursor coordinates" {
  let snap = new_input_snapshot(-100.5, -200.5, 0.0, 0.0, [])
  assert_eq(snap.cursor_x, -100.5)
  assert_eq(snap.cursor_y, -200.5)
}

///|
test "input snapshot with large wheel accumulation" {
  let snap = new_input_snapshot(0.0, 0.0, 999.0, -999.0, [])
  assert_eq(snap.wheel_x, 999.0)
  assert_eq(snap.wheel_y, -999.0)
}

///|
test "input snapshot with many simultaneous touches" {
  let touches : Array[TouchPoint] = []
  for i in 0..<10 {
    touches.push(new_touch_point(i, i.to_double() * 10.0, i.to_double() * 20.0))
  }
  let snap = new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [], [], touches, [])
  assert_eq(snap.touches.length(), 10)
  assert_eq(snap.touches[0].id, 0)
  assert_eq(snap.touches[9].id, 9)
  assert_eq(snap.touches[9].x, 90.0)
  assert_eq(snap.touches[9].y, 180.0)
}

///|
test "input snapshot with multiple gamepads" {
  let gamepads = [
    new_gamepad_snapshot(0, [0.5, -0.5, 0.0, 0.0], [0, 1, 2]),
    new_gamepad_snapshot(1, [-1.0, 1.0], [5, 6, 7, 8]),
    new_gamepad_snapshot(2, [], []),
    new_gamepad_snapshot(3, [0.0], [0]),
  ]
  let snap = new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [], [], [], gamepads)
  assert_eq(snap.gamepads.length(), 4)
  assert_eq(snap.gamepads[0].axes.length(), 4)
  assert_eq(snap.gamepads[1].pressed_buttons.length(), 4)
  assert_eq(snap.gamepads[2].axes.length(), 0)
  assert_eq(snap.gamepads[2].pressed_buttons.length(), 0)
  assert_eq(snap.gamepads[3].axes[0], 0.0)
}

///|
test "touch point with zero id and negative coordinates" {
  let tp = new_touch_point(0, -50.0, -25.0)
  assert_eq(tp.id, 0)
  assert_eq(tp.x, -50.0)
  assert_eq(tp.y, -25.0)
}

///|
test "gamepad snapshot with many buttons" {
  let buttons : Array[Int] = []
  for i in 0..<20 {
    buttons.push(i)
  }
  let gp = new_gamepad_snapshot(0, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], buttons)
  assert_eq(gp.pressed_buttons.length(), 20)
  assert_eq(gp.axes.length(), 6)
  assert_eq(gp.pressed_buttons[19], 19)
}

///|
test "step_fixed_timestep max_updates_per_frame caps updates" {
  let state = initial_fixed_step_state()
  let config = default_fixed_step_config()
  // 60 tps = 16.67ms per tick. With 200ms elapsed, we'd want 12 updates but cap at 5.
  let result = step_fixed_timestep(state, 200.0, config)
  assert_true(result.updates <= config.max_updates_per_frame)
  assert_eq(result.updates, 5)
}

///|
test "touch phase int conversion roundtrip" {
  assert_eq(touch_phase_to_int(TouchPhase::Began), 0)
  assert_eq(touch_phase_to_int(TouchPhase::Moved), 1)
  assert_eq(touch_phase_to_int(TouchPhase::Stationary), 2)
  assert_eq(touch_phase_to_int(TouchPhase::Ended), 3)
  assert_eq(touch_phase_to_int(TouchPhase::Cancelled), 4)
  for i = 0; i < 5; i = i + 1 {
    assert_eq(touch_phase_to_int(touch_phase_from_int(i)), i)
  }
  // Invalid defaults to Began
  assert_eq(touch_phase_to_int(touch_phase_from_int(-1)), 0)
  assert_eq(touch_phase_to_int(touch_phase_from_int(99)), 0)
}

///|
test "touch point ex construction and conversion" {
  let ex = new_touch_point_ex(42, 100.5, 200.5, TouchPhase::Moved)
  assert_eq(ex.id, 42)
  assert_eq(ex.pressure, 1.0)
  assert_eq(ex.delta_x, 0.0)
  assert_eq(ex.delta_y, 0.0)
  let pt = touch_point_from_ex(ex)
  assert_eq(pt.id, 42)
  assert_eq(pt.x, 100.5)
  assert_eq(pt.y, 200.5)
}

///|
test "touch point ex full construction with pressure and delta" {
  let ex = new_touch_point_ex_full(
    1,
    50.0,
    60.0,
    TouchPhase::Moved,
    0.75,
    3.0,
    -2.0,
  )
  assert_eq(ex.pressure, 0.75)
  assert_eq(ex.delta_x, 3.0)
  assert_eq(ex.delta_y, -2.0)
  match ex.phase {
    TouchPhase::Moved => ()
    _ => fail("expected Moved phase")
  }
}

///|
test "touch source int conversion roundtrip" {
  assert_eq(touch_source_to_int(TouchSource::Direct), 0)
  assert_eq(touch_source_to_int(TouchSource::Indirect), 1)
  assert_eq(touch_source_to_int(TouchSource::Mouse), 2)
  assert_eq(touch_source_to_int(TouchSource::Unknown), 3)
  for i = 0; i < 4; i = i + 1 {
    assert_eq(touch_source_to_int(touch_source_from_int(i)), i)
  }
  // Invalid defaults to Unknown
  assert_eq(touch_source_to_int(touch_source_from_int(-1)), 3)
  assert_eq(touch_source_to_int(touch_source_from_int(99)), 3)
}

///|
test "new_touch_point has Unknown source by default" {
  let tp = new_touch_point(1, 10.0, 20.0)
  match tp.source {
    TouchSource::Unknown => ()
    _ => fail("expected Unknown source")
  }
}

///|
test "new_touch_point_with_source sets source" {
  let tp = new_touch_point_with_source(1, 10.0, 20.0, TouchSource::Direct)
  match tp.source {
    TouchSource::Direct => ()
    _ => fail("expected Direct source")
  }
  let tp2 = new_touch_point_with_source(2, 30.0, 40.0, TouchSource::Indirect)
  match tp2.source {
    TouchSource::Indirect => ()
    _ => fail("expected Indirect source")
  }
  let tp3 = new_touch_point_with_source(3, 50.0, 60.0, TouchSource::Mouse)
  match tp3.source {
    TouchSource::Mouse => ()
    _ => fail("expected Mouse source")
  }
}

///|
test "touch_point_from_ex has Unknown source" {
  let ex = new_touch_point_ex(1, 10.0, 20.0, TouchPhase::Began)
  let tp = touch_point_from_ex(ex)
  match tp.source {
    TouchSource::Unknown => ()
    _ => fail("expected Unknown source")
  }
}
