///|
test "resolve_touch_points_with_mouse_fallback appends left click before native touch observed" {
  let resolved = resolve_touch_points_with_mouse_fallback(
    [],
    [0],
    11.5,
    22.5,
    false,
    true,
  )
  assert_eq(resolved.touches.length(), 1)
  assert_eq(resolved.touches[0].id, 0)
  assert_eq(resolved.touches[0].x.to_int(), 11)
  assert_eq(resolved.touches[0].y.to_int(), 22)
  assert_true(!resolved.saw_native_touch)
  // Mouse fallback touch should have Mouse source
  assert_eq(@core.touch_source_to_int(resolved.touches[0].source), 2)
}

///|
test "resolve_touch_points_with_mouse_fallback skips fallback when disabled" {
  let resolved = resolve_touch_points_with_mouse_fallback(
    [],
    [0],
    50.0,
    60.0,
    false,
    false,
  )
  assert_eq(resolved.touches.length(), 0)
  assert_true(!resolved.saw_native_touch)
}

///|
test "resolve_touch_points_with_mouse_fallback works when enabled explicitly" {
  let resolved = resolve_touch_points_with_mouse_fallback(
    [],
    [0],
    50.0,
    60.0,
    false,
    true,
  )
  assert_eq(resolved.touches.length(), 1)
  assert_eq(resolved.touches[0].x.to_int(), 50)
}

///|
test "touch point source preserved in resolve" {
  let direct_touch = @core.new_touch_point_with_source(
    1, 10.0, 20.0, @core.touch_source_from_int(0),
  )
  let indirect_touch = @core.new_touch_point_with_source(
    2, 30.0, 40.0, @core.touch_source_from_int(1),
  )
  let resolved = resolve_touch_points_with_mouse_fallback(
    [direct_touch, indirect_touch],
    [],
    0.0,
    0.0,
    false,
    true,
  )
  assert_eq(resolved.touches.length(), 2)
  assert_eq(@core.touch_source_to_int(resolved.touches[0].source), 0)
  assert_eq(@core.touch_source_to_int(resolved.touches[1].source), 1)
}

///|
test "resolve_touch_points_with_mouse_fallback disables mouse fallback once native touch observed" {
  let real_touch = @core.new_touch_point(42, 3.0, 4.0)
  let after_real_touch = resolve_touch_points_with_mouse_fallback(
    [real_touch],
    [],
    0.0,
    0.0,
    false,
    true,
  )
  assert_eq(after_real_touch.touches.length(), 1)
  assert_eq(after_real_touch.touches[0].id, 42)
  assert_true(after_real_touch.saw_native_touch)

  let after_mouse_click = resolve_touch_points_with_mouse_fallback(
    [],
    [0],
    9.0,
    8.0,
    after_real_touch.saw_native_touch,
    true,
  )
  assert_eq(after_mouse_click.touches.length(), 0)
  assert_true(after_mouse_click.saw_native_touch)
}
