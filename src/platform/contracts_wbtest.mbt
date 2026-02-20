///|
fn default_window_options_for_test() -> WindowOptions {
  {
    title: "test",
    width: 320,
    height: 240,
    transparent: false,
    resizable: true,
  }
}

///|
let test_native_init_calls : Ref[Int] = Ref::new(0)

///|
let test_native_poll_calls : Ref[Int] = Ref::new(0)

///|
let test_native_should_close_value : Ref[Bool] = Ref::new(false)

///|
let test_native_capture_calls : Ref[Int] = Ref::new(0)

///|
let test_native_fullscreen_value : Ref[Bool] = Ref::new(false)

///|
let test_native_cursor_mode_value : Ref[CursorMode] = Ref::new(
  CursorMode::Visible,
)

///|
let test_native_device_scale_factor_value : Ref[Double] = Ref::new(1.0)

///|
let test_native_vsync_enabled_value : Ref[Bool] = Ref::new(true)

///|
let test_native_close_window_calls : Ref[Int] = Ref::new(0)

///|
let test_native_request_attention_calls : Ref[Int] = Ref::new(0)

///|
fn test_native_try_initialize(_options : WindowOptions) -> Bool {
  test_native_init_calls.val = test_native_init_calls.val + 1
  true
}

///|
fn test_native_poll(active : Bool) -> Unit {
  if active {
    test_native_poll_calls.val = test_native_poll_calls.val + 1
  }
}

///|
fn test_native_should_close() -> Bool {
  test_native_should_close_value.val
}

///|
fn test_native_outside_size(width : Int, height : Int) -> @core.OutsideSize {
  @core.new_outside_size((width * 2).to_double(), (height * 3).to_double())
}

///|
fn test_native_capture_input(active : Bool, tick : Int) -> @core.InputSnapshot {
  if active {
    test_native_capture_calls.val = test_native_capture_calls.val + 1
    @core.new_input_snapshot(
      tick.to_double(),
      (tick * 2).to_double(),
      0.0,
      1.0,
      [tick],
    )
  } else {
    @core.empty_input_snapshot()
  }
}

///|
fn test_native_set_fullscreen(active : Bool, enabled : Bool) -> Bool {
  if active {
    test_native_fullscreen_value.val = enabled
  }
  test_native_fullscreen_value.val
}

///|
fn test_native_is_fullscreen(active : Bool, current : Bool) -> Bool {
  if active {
    test_native_fullscreen_value.val
  } else {
    current
  }
}

///|
fn test_native_set_cursor_mode(active : Bool, mode : CursorMode) -> CursorMode {
  if active {
    test_native_cursor_mode_value.val = mode
  }
  test_native_cursor_mode_value.val
}

///|
fn test_native_cursor_mode(active : Bool, current : CursorMode) -> CursorMode {
  if active {
    test_native_cursor_mode_value.val
  } else {
    current
  }
}

///|
fn test_native_set_device_scale_factor(active : Bool, scale : Double) -> Double {
  let normalized = if scale <= 0.0 { 1.0 } else { scale }
  if active {
    test_native_device_scale_factor_value.val = normalized
  }
  test_native_device_scale_factor_value.val
}

///|
fn test_native_device_scale_factor(active : Bool, current : Double) -> Double {
  if active {
    test_native_device_scale_factor_value.val
  } else if current <= 0.0 {
    1.0
  } else {
    current
  }
}

///|
fn test_native_set_vsync_enabled(active : Bool, enabled : Bool) -> Bool {
  if active {
    test_native_vsync_enabled_value.val = enabled
  }
  test_native_vsync_enabled_value.val
}

///|
fn test_native_is_vsync_enabled(active : Bool, current : Bool) -> Bool {
  if active {
    test_native_vsync_enabled_value.val
  } else {
    current
  }
}

///|
fn test_native_close_window(active : Bool) -> Unit {
  if active {
    test_native_close_window_calls.val = test_native_close_window_calls.val + 1
  }
}

///|
fn test_native_request_attention(active : Bool) -> Unit {
  if active {
    test_native_request_attention_calls.val = test_native_request_attention_calls.val +
      1
  }
}

///|
let test_web_init_calls : Ref[Int] = Ref::new(0)

///|
let test_web_poll_calls : Ref[Int] = Ref::new(0)

///|
let test_web_should_close_value : Ref[Bool] = Ref::new(false)

///|
let test_web_capture_calls : Ref[Int] = Ref::new(0)

///|
let test_web_fullscreen_value : Ref[Bool] = Ref::new(false)

///|
let test_web_cursor_mode_value : Ref[CursorMode] = Ref::new(CursorMode::Visible)

///|
let test_web_device_scale_factor_value : Ref[Double] = Ref::new(1.0)

///|
let test_web_vsync_enabled_value : Ref[Bool] = Ref::new(true)

///|
let test_web_close_window_calls : Ref[Int] = Ref::new(0)

///|
let test_web_request_attention_calls : Ref[Int] = Ref::new(0)

///|
fn test_web_try_initialize(
  _canvas_selector : String,
  _options : WindowOptions,
) -> Bool {
  test_web_init_calls.val = test_web_init_calls.val + 1
  true
}

///|
fn test_web_poll(active : Bool) -> Unit {
  if active {
    test_web_poll_calls.val = test_web_poll_calls.val + 1
  }
}

///|
fn test_web_should_close() -> Bool {
  test_web_should_close_value.val
}

///|
fn test_web_outside_size(width : Int, height : Int) -> @core.OutsideSize {
  @core.new_outside_size((width * 4).to_double(), (height * 5).to_double())
}

///|
fn test_web_current_surface(
  _canvas_selector : String,
  options : WindowOptions,
) -> SurfaceToken {
  {
    kind: SurfaceKind::WebGlCanvasContext,
    opaque_id: 99,
    width: options.width + 1,
    height: options.height + 2,
    device_scale_factor: 2.0,
  }
}

///|
fn test_web_capture_input(active : Bool, tick : Int) -> @core.InputSnapshot {
  if active {
    test_web_capture_calls.val = test_web_capture_calls.val + 1
    @core.new_input_snapshot(
      (tick * 3).to_double(),
      (tick * 4).to_double(),
      -1.0,
      2.0,
      [tick, tick + 100],
    )
  } else {
    @core.empty_input_snapshot()
  }
}

///|
fn test_web_set_fullscreen(
  _canvas_selector : String,
  active : Bool,
  enabled : Bool,
) -> Bool {
  if active {
    test_web_fullscreen_value.val = enabled
  }
  test_web_fullscreen_value.val
}

///|
fn test_web_is_fullscreen(
  _canvas_selector : String,
  active : Bool,
  current : Bool,
) -> Bool {
  if active {
    test_web_fullscreen_value.val
  } else {
    current
  }
}

///|
fn test_web_set_cursor_mode(
  _canvas_selector : String,
  active : Bool,
  mode : CursorMode,
) -> CursorMode {
  if active {
    test_web_cursor_mode_value.val = mode
  }
  test_web_cursor_mode_value.val
}

///|
fn test_web_cursor_mode(
  _canvas_selector : String,
  active : Bool,
  current : CursorMode,
) -> CursorMode {
  if active {
    test_web_cursor_mode_value.val
  } else {
    current
  }
}

///|
fn test_web_set_device_scale_factor(
  _canvas_selector : String,
  active : Bool,
  scale : Double,
) -> Double {
  let normalized = if scale <= 0.0 { 1.0 } else { scale }
  if active {
    test_web_device_scale_factor_value.val = normalized
  }
  test_web_device_scale_factor_value.val
}

///|
fn test_web_device_scale_factor(
  _canvas_selector : String,
  active : Bool,
  current : Double,
) -> Double {
  if active {
    test_web_device_scale_factor_value.val
  } else if current <= 0.0 {
    1.0
  } else {
    current
  }
}

///|
fn test_web_set_vsync_enabled(
  _canvas_selector : String,
  active : Bool,
  enabled : Bool,
) -> Bool {
  if active {
    test_web_vsync_enabled_value.val = enabled
  }
  test_web_vsync_enabled_value.val
}

///|
fn test_web_is_vsync_enabled(
  _canvas_selector : String,
  active : Bool,
  current : Bool,
) -> Bool {
  if active {
    test_web_vsync_enabled_value.val
  } else {
    current
  }
}

///|
fn test_web_close_window(_canvas_selector : String, active : Bool) -> Unit {
  if active {
    test_web_close_window_calls.val = test_web_close_window_calls.val + 1
  }
}

///|
fn test_web_request_attention(_canvas_selector : String, active : Bool) -> Unit {
  if active {
    test_web_request_attention_calls.val = test_web_request_attention_calls.val +
      1
  }
}

///|
fn is_webgl_canvas_context(kind : SurfaceKind) -> Bool {
  match kind {
    SurfaceKind::WebGlCanvasContext => true
    _ => false
  }
}

///|
fn is_webgpu_canvas_context(kind : SurfaceKind) -> Bool {
  match kind {
    SurfaceKind::WebGpuCanvasContext => true
    _ => false
  }
}

///|
fn is_cursor_visible(mode : CursorMode) -> Bool {
  match mode {
    CursorMode::Visible => true
    _ => false
  }
}

///|
fn is_cursor_hidden(mode : CursorMode) -> Bool {
  match mode {
    CursorMode::Hidden => true
    _ => false
  }
}

///|
fn is_cursor_captured(mode : CursorMode) -> Bool {
  match mode {
    CursorMode::Captured => true
    _ => false
  }
}

///|
test "desktop native hooks can be overridden and reset" {
  reset_desktop_native_hooks()
  test_native_init_calls.val = 0
  test_native_poll_calls.val = 0
  test_native_should_close_value.val = true
  test_native_capture_calls.val = 0
  test_native_fullscreen_value.val = false
  test_native_cursor_mode_value.val = CursorMode::Visible
  test_native_device_scale_factor_value.val = 1.0
  test_native_vsync_enabled_value.val = true
  test_native_close_window_calls.val = 0
  test_native_request_attention_calls.val = 0

  set_desktop_native_hooks(
    new_desktop_native_hooks(
      test_native_try_initialize, test_native_poll, test_native_should_close, test_native_outside_size,
      test_native_capture_input, test_native_set_fullscreen, test_native_is_fullscreen,
      test_native_set_cursor_mode, test_native_cursor_mode, test_native_set_device_scale_factor,
      test_native_device_scale_factor, test_native_set_vsync_enabled, test_native_is_vsync_enabled,
      test_native_close_window, test_native_request_attention,
      fn(_active, _enabled) { () }, fn(_active) { false },
    ),
  )

  let p = create_desktop_glfw_platform()
  p.initialize(default_window_options_for_test())
  p.poll_events()

  let outside = p.outside_size()
  assert_eq(outside.width.to_int(), 640)
  assert_eq(outside.height.to_int(), 720)
  let input = p.capture_input(7)
  assert_eq(input.cursor_x.to_int(), 7)
  assert_eq(input.cursor_y.to_int(), 14)
  assert_eq(input.pressed_keys.length(), 1)
  assert_eq(input.pressed_keys[0], 7)
  assert_true(p.should_close())
  assert_eq(test_native_init_calls.val, 1)
  assert_eq(test_native_poll_calls.val, 1)
  assert_eq(test_native_capture_calls.val, 1)
  p.set_fullscreen(true)
  assert_true(p.is_fullscreen())
  p.set_cursor_mode(CursorMode::Hidden)
  assert_true(is_cursor_hidden(p.cursor_mode()))
  p.set_device_scale_factor(1.25)
  assert_eq(p.device_scale_factor(), 1.25)
  p.set_vsync_enabled(false)
  assert_true(!p.is_vsync_enabled())
  p.request_attention()
  p.close_window()
  assert_eq(test_native_close_window_calls.val, 1)
  assert_eq(test_native_request_attention_calls.val, 1)

  reset_desktop_native_hooks()

  let before_init_calls = test_native_init_calls.val
  let before_poll_calls = test_native_poll_calls.val
  let p2 = create_desktop_glfw_platform()
  p2.initialize(default_window_options_for_test())
  p2.poll_events()
  let input2 = p2.capture_input(9)

  let outside2 = p2.outside_size()
  assert_eq(outside2.width.to_int(), 320)
  assert_eq(outside2.height.to_int(), 240)
  assert_eq(input2.pressed_keys.length(), 0)
  assert_true(!p2.should_close())
  assert_eq(test_native_init_calls.val, before_init_calls)
  assert_eq(test_native_poll_calls.val, before_poll_calls)
  assert_eq(test_native_capture_calls.val, 1)
}

///|
test "web canvas hooks can be overridden and reset" {
  reset_web_canvas_hooks()
  test_web_init_calls.val = 0
  test_web_poll_calls.val = 0
  test_web_should_close_value.val = true
  test_web_capture_calls.val = 0
  test_web_fullscreen_value.val = false
  test_web_cursor_mode_value.val = CursorMode::Visible
  test_web_device_scale_factor_value.val = 1.0
  test_web_vsync_enabled_value.val = true
  test_web_close_window_calls.val = 0
  test_web_request_attention_calls.val = 0

  set_web_canvas_hooks(
    new_web_canvas_hooks(
      test_web_try_initialize, test_web_poll, test_web_should_close, test_web_outside_size,
      test_web_current_surface, test_web_capture_input, test_web_set_fullscreen,
      test_web_is_fullscreen, test_web_set_cursor_mode, test_web_cursor_mode, test_web_set_device_scale_factor,
      test_web_device_scale_factor, test_web_set_vsync_enabled, test_web_is_vsync_enabled,
      test_web_close_window, test_web_request_attention,
      fn(_s, _a, _e) { () }, fn(_s, _a) { false },
      fn(_s, _a, c) { c }, fn(_s, _a, c) { c },
    ),
  )

  let p = create_web_canvas_platform("#hooked")
  p.initialize(default_window_options_for_test())
  p.poll_events()

  let outside = p.outside_size()
  assert_eq(outside.width.to_int(), 1280)
  assert_eq(outside.height.to_int(), 1200)
  let input = p.capture_input(5)
  assert_eq(input.cursor_x.to_int(), 15)
  assert_eq(input.cursor_y.to_int(), 20)
  assert_eq(input.wheel_x.to_int(), -1)
  assert_eq(input.wheel_y.to_int(), 2)
  assert_eq(input.pressed_keys.length(), 2)
  assert_eq(input.pressed_keys[0], 5)
  assert_eq(input.pressed_keys[1], 105)
  assert_true(p.should_close())
  assert_eq(test_web_init_calls.val, 1)
  assert_eq(test_web_poll_calls.val, 1)
  assert_eq(test_web_capture_calls.val, 1)
  p.set_fullscreen(true)
  assert_true(p.is_fullscreen())
  p.set_cursor_mode(CursorMode::Hidden)
  assert_true(is_cursor_hidden(p.cursor_mode()))
  p.set_device_scale_factor(2.5)
  assert_eq(p.device_scale_factor(), 2.5)
  p.set_vsync_enabled(false)
  assert_true(!p.is_vsync_enabled())
  p.request_attention()
  p.close_window()
  assert_eq(test_web_close_window_calls.val, 1)
  assert_eq(test_web_request_attention_calls.val, 1)

  let surface = p.current_surface()
  assert_true(is_webgl_canvas_context(surface.kind))
  assert_eq(surface.opaque_id, 99)
  assert_eq(surface.width, 321)
  assert_eq(surface.height, 242)
  assert_eq(surface.device_scale_factor, 2.0)

  reset_web_canvas_hooks()

  let before_init_calls = test_web_init_calls.val
  let before_poll_calls = test_web_poll_calls.val
  let p2 = create_web_canvas_platform("#default")
  p2.initialize(default_window_options_for_test())
  p2.poll_events()
  let input2 = p2.capture_input(11)

  let outside2 = p2.outside_size()
  assert_eq(outside2.width.to_int(), 320)
  assert_eq(outside2.height.to_int(), 240)
  assert_eq(input2.pressed_keys.length(), 0)
  assert_true(!p2.should_close())
  let surface2 = p2.current_surface()
  assert_true(is_webgpu_canvas_context(surface2.kind))
  assert_eq(test_web_init_calls.val, before_init_calls)
  assert_eq(test_web_poll_calls.val, before_poll_calls)
  assert_eq(test_web_capture_calls.val, 1)
}

///|
test "desktop window system API contract" {
  let p = create_desktop_glfw_platform()

  assert_true(!p.is_fullscreen())
  p.set_fullscreen(true)
  assert_true(p.is_fullscreen())
  p.set_fullscreen(false)
  assert_true(!p.is_fullscreen())

  assert_true(is_cursor_visible(p.cursor_mode()))
  p.set_cursor_mode(CursorMode::Hidden)
  assert_true(is_cursor_hidden(p.cursor_mode()))
  p.set_cursor_mode(CursorMode::Captured)
  assert_true(is_cursor_captured(p.cursor_mode()))

  assert_true(p.is_vsync_enabled())
  p.set_vsync_enabled(false)
  assert_true(!p.is_vsync_enabled())
  p.set_vsync_enabled(true)
  assert_true(p.is_vsync_enabled())

  p.set_device_scale_factor(2.5)
  assert_eq(p.device_scale_factor(), 2.5)
  assert_eq(p.monitor_info().device_scale_factor, 2.5)
  p.set_device_scale_factor(0.0)
  assert_eq(p.device_scale_factor(), 1.0)
  assert_eq(p.monitor_info().device_scale_factor, 1.0)

  assert_true(!p.should_close())
  p.close_window()
  assert_true(p.should_close())

  assert_eq(p.attention_requests, 0)
  p.request_attention()
  p.request_attention()
  assert_eq(p.attention_requests, 2)

  p.initialize(default_window_options_for_test())
  assert_eq(p.attention_requests, 0)
  assert_true(!p.close_requested)
}

///|
test "web window system API contract" {
  let p = create_web_canvas_platform("#contract")

  assert_true(!p.is_fullscreen())
  p.set_fullscreen(true)
  assert_true(p.is_fullscreen())
  p.set_fullscreen(false)
  assert_true(!p.is_fullscreen())

  assert_true(is_cursor_visible(p.cursor_mode()))
  p.set_cursor_mode(CursorMode::Hidden)
  assert_true(is_cursor_hidden(p.cursor_mode()))
  p.set_cursor_mode(CursorMode::Captured)
  assert_true(is_cursor_captured(p.cursor_mode()))

  assert_true(p.is_vsync_enabled())
  p.set_vsync_enabled(false)
  assert_true(!p.is_vsync_enabled())
  p.set_vsync_enabled(true)
  assert_true(p.is_vsync_enabled())

  p.set_device_scale_factor(1.5)
  assert_eq(p.device_scale_factor(), 1.5)
  assert_eq(p.monitor_info().device_scale_factor, 1.5)
  p.set_device_scale_factor(-10.0)
  assert_eq(p.device_scale_factor(), 1.0)
  assert_eq(p.monitor_info().device_scale_factor, 1.0)

  assert_true(!p.should_close())
  p.close_window()
  assert_true(p.should_close())

  assert_eq(p.attention_requests, 0)
  p.request_attention()
  assert_eq(p.attention_requests, 1)

  p.initialize(default_window_options_for_test())
  assert_eq(p.attention_requests, 0)
  assert_true(!p.close_requested)
}

///|
test "desktop platform stub provides input and size" {
  let p = create_desktop_glfw_platform()
  p.initialize(default_window_options_for_test())
  p.poll_events()

  let outside = p.outside_size()
  assert_eq(outside.width.to_int(), 320)
  assert_eq(outside.height.to_int(), 240)

  let input = p.capture_input(1)
  assert_eq(input.pressed_keys.length(), 0)

  let monitor = p.monitor_info()
  assert_true(monitor.device_scale_factor >= 1.0)
}

///|
test "web platform stub has surface token" {
  let p = create_web_canvas_platform("#app")
  p.initialize(default_window_options_for_test())
  p.poll_events()

  let token = p.current_surface()
  assert_eq(token.width, 320)
  assert_eq(token.height, 240)
}

///|
test "desktop platform close then reinitialize resets close and attention" {
  let p = create_desktop_glfw_platform()
  p.initialize(default_window_options_for_test())
  p.close_window()
  assert_true(p.should_close())
  p.request_attention()
  p.request_attention()
  assert_eq(p.attention_requests, 2)
  p.initialize(default_window_options_for_test())
  assert_true(!p.close_requested)
  assert_eq(p.attention_requests, 0)
}

///|
test "web platform close then reinitialize resets close and attention" {
  let p = create_web_canvas_platform("#reset")
  p.initialize(default_window_options_for_test())
  p.close_window()
  assert_true(p.should_close())
  p.request_attention()
  assert_eq(p.attention_requests, 1)
  p.initialize(default_window_options_for_test())
  assert_true(!p.close_requested)
  assert_eq(p.attention_requests, 0)
}

///|
test "desktop device scale factor normalizes non-positive to 1.0" {
  let p = create_desktop_glfw_platform()
  p.set_device_scale_factor(-5.0)
  assert_eq(p.device_scale_factor(), 1.0)
  p.set_device_scale_factor(0.0)
  assert_eq(p.device_scale_factor(), 1.0)
  p.set_device_scale_factor(3.0)
  assert_eq(p.device_scale_factor(), 3.0)
}

///|
test "desktop fullscreen toggle cycle" {
  let p = create_desktop_glfw_platform()
  assert_true(!p.is_fullscreen())
  p.set_fullscreen(true)
  assert_true(p.is_fullscreen())
  p.set_fullscreen(true)
  assert_true(p.is_fullscreen())
  p.set_fullscreen(false)
  assert_true(!p.is_fullscreen())
  p.set_fullscreen(false)
  assert_true(!p.is_fullscreen())
}

///|
test "desktop cursor mode all transitions" {
  let p = create_desktop_glfw_platform()
  // Visible -> Hidden -> Captured -> Visible
  assert_true(is_cursor_visible(p.cursor_mode()))
  p.set_cursor_mode(CursorMode::Hidden)
  assert_true(is_cursor_hidden(p.cursor_mode()))
  p.set_cursor_mode(CursorMode::Captured)
  assert_true(is_cursor_captured(p.cursor_mode()))
  p.set_cursor_mode(CursorMode::Visible)
  assert_true(is_cursor_visible(p.cursor_mode()))
  // Visible -> Captured -> Hidden
  p.set_cursor_mode(CursorMode::Captured)
  assert_true(is_cursor_captured(p.cursor_mode()))
  p.set_cursor_mode(CursorMode::Hidden)
  assert_true(is_cursor_hidden(p.cursor_mode()))
}

///|
test "desktop multiple capture_input ticks are independent" {
  let p = create_desktop_glfw_platform()
  p.initialize(default_window_options_for_test())
  let i1 = p.capture_input(0)
  let i2 = p.capture_input(1)
  let i3 = p.capture_input(100)
  // Stub returns empty input for all ticks
  assert_eq(i1.pressed_keys.length(), 0)
  assert_eq(i2.pressed_keys.length(), 0)
  assert_eq(i3.pressed_keys.length(), 0)
}

///|
test "web device scale factor edge cases" {
  let p = create_web_canvas_platform("#scale")
  p.set_device_scale_factor(-100.0)
  assert_eq(p.device_scale_factor(), 1.0)
  p.set_device_scale_factor(0.001)
  assert_eq(p.device_scale_factor(), 0.001)
  p.set_device_scale_factor(10.0)
  assert_eq(p.device_scale_factor(), 10.0)
}

///|
test "web surface token after initialization" {
  let p = create_web_canvas_platform("#surface")
  p.initialize(default_window_options_for_test())
  let token = p.current_surface()
  assert_eq(token.width, 320)
  assert_eq(token.height, 240)
  assert_true(token.device_scale_factor >= 1.0)
}

///|
test "cursor mode int conversion roundtrip" {
  assert_true(is_cursor_visible(cursor_mode_from_int(0)))
  assert_true(is_cursor_hidden(cursor_mode_from_int(1)))
  assert_true(is_cursor_captured(cursor_mode_from_int(2)))
  assert_true(is_cursor_visible(cursor_mode_from_int(-1)))

  assert_eq(cursor_mode_to_int(CursorMode::Visible), 0)
  assert_eq(cursor_mode_to_int(CursorMode::Hidden), 1)
  assert_eq(cursor_mode_to_int(CursorMode::Captured), 2)
}

///|
test "fullscreen mode int conversion roundtrip" {
  assert_eq(fullscreen_mode_to_int(FullscreenMode::Windowed), 0)
  assert_eq(fullscreen_mode_to_int(FullscreenMode::Borderless), 1)
  assert_eq(fullscreen_mode_to_int(FullscreenMode::Exclusive), 2)
  assert_eq(fullscreen_mode_to_int(fullscreen_mode_from_int(0)), 0)
  assert_eq(fullscreen_mode_to_int(fullscreen_mode_from_int(1)), 1)
  assert_eq(fullscreen_mode_to_int(fullscreen_mode_from_int(2)), 2)
  // Invalid defaults to Windowed
  assert_eq(fullscreen_mode_to_int(fullscreen_mode_from_int(-1)), 0)
  assert_eq(fullscreen_mode_to_int(fullscreen_mode_from_int(99)), 0)
}

///|
test "monitor info includes refresh rate" {
  let p = create_desktop_glfw_platform()
  p.initialize(default_window_options_for_test())
  let monitor = p.monitor_info()
  assert_eq(monitor.refresh_rate_hz, 60)
}

///|
test "web monitor info includes refresh rate" {
  let p = create_web_canvas_platform("#app")
  p.initialize(default_window_options_for_test())
  let monitor = p.monitor_info()
  assert_eq(monitor.refresh_rate_hz, 60)
}

///|
test "desktop mouse touch fallback default is false" {
  let p = create_desktop_glfw_platform()
  assert_true(!p.mouse_touch_fallback_enabled())
  p.set_mouse_touch_fallback(true)
  assert_true(p.mouse_touch_fallback_enabled())
  p.set_mouse_touch_fallback(false)
  assert_true(!p.mouse_touch_fallback_enabled())
}

///|
test "web mouse touch fallback default is false" {
  let p = create_web_canvas_platform("#fallback")
  assert_true(!p.mouse_touch_fallback_enabled())
  p.set_mouse_touch_fallback(true)
  assert_true(p.mouse_touch_fallback_enabled())
  p.set_mouse_touch_fallback(false)
  assert_true(!p.mouse_touch_fallback_enabled())
}

///|
test "async request status int conversion roundtrip" {
  assert_eq(async_request_status_to_int(AsyncRequestStatus::Idle), 0)
  assert_eq(async_request_status_to_int(AsyncRequestStatus::Pending), 1)
  assert_eq(async_request_status_to_int(AsyncRequestStatus::Confirmed), 2)
  assert_eq(async_request_status_to_int(AsyncRequestStatus::Rejected), 3)
  assert_eq(
    async_request_status_to_int(async_request_status_from_int(0)),
    0,
  )
  assert_eq(
    async_request_status_to_int(async_request_status_from_int(1)),
    1,
  )
  assert_eq(
    async_request_status_to_int(async_request_status_from_int(2)),
    2,
  )
  assert_eq(
    async_request_status_to_int(async_request_status_from_int(3)),
    3,
  )
  assert_eq(
    async_request_status_to_int(async_request_status_from_int(-1)),
    0,
  )
  assert_eq(
    async_request_status_to_int(async_request_status_from_int(99)),
    0,
  )
}

///|
test "desktop fullscreen request status is Confirmed after set" {
  let p = create_desktop_glfw_platform()
  assert_eq(
    async_request_status_to_int(p.fullscreen_request_status()),
    0,
  )
  p.set_fullscreen(true)
  assert_eq(
    async_request_status_to_int(p.fullscreen_request_status()),
    2,
  )
}

///|
test "desktop cursor mode request status is Confirmed after set" {
  let p = create_desktop_glfw_platform()
  assert_eq(
    async_request_status_to_int(p.cursor_mode_request_status()),
    0,
  )
  p.set_cursor_mode(CursorMode::Hidden)
  assert_eq(
    async_request_status_to_int(p.cursor_mode_request_status()),
    2,
  )
}

///|
test "web fullscreen request status starts Idle then Pending after set" {
  let p = create_web_canvas_platform("#async")
  assert_eq(
    async_request_status_to_int(p.fullscreen_request_status()),
    0,
  )
  p.set_fullscreen(true)
  assert_eq(
    async_request_status_to_int(p.fullscreen_request_status()),
    1,
  )
}

///|
test "web cursor mode request status starts Idle then Pending after set" {
  let p = create_web_canvas_platform("#async2")
  assert_eq(
    async_request_status_to_int(p.cursor_mode_request_status()),
    0,
  )
  p.set_cursor_mode(CursorMode::Captured)
  assert_eq(
    async_request_status_to_int(p.cursor_mode_request_status()),
    1,
  )
}
