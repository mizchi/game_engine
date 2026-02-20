///|
pub struct DesktopNativeHooks {
  try_initialize : (WindowOptions) -> Bool
  poll : (Bool) -> Unit
  should_close : () -> Bool
  outside_size : (Int, Int) -> @core.OutsideSize
  capture_input : (Bool, Int) -> @core.InputSnapshot
  set_fullscreen : (Bool, Bool) -> Bool
  is_fullscreen : (Bool, Bool) -> Bool
  set_cursor_mode : (Bool, CursorMode) -> CursorMode
  cursor_mode : (Bool, CursorMode) -> CursorMode
  set_device_scale_factor : (Bool, Double) -> Double
  device_scale_factor : (Bool, Double) -> Double
  set_vsync_enabled : (Bool, Bool) -> Bool
  is_vsync_enabled : (Bool, Bool) -> Bool
  close_window : (Bool) -> Unit
  request_attention : (Bool) -> Unit
  set_mouse_touch_fallback : (Bool, Bool) -> Unit
  mouse_touch_fallback_enabled : (Bool) -> Bool
}

///|
pub fn new_desktop_native_hooks(
  try_initialize : (WindowOptions) -> Bool,
  poll : (Bool) -> Unit,
  should_close : () -> Bool,
  outside_size : (Int, Int) -> @core.OutsideSize,
  capture_input : (Bool, Int) -> @core.InputSnapshot,
  set_fullscreen : (Bool, Bool) -> Bool,
  is_fullscreen : (Bool, Bool) -> Bool,
  set_cursor_mode : (Bool, CursorMode) -> CursorMode,
  cursor_mode : (Bool, CursorMode) -> CursorMode,
  set_device_scale_factor : (Bool, Double) -> Double,
  device_scale_factor : (Bool, Double) -> Double,
  set_vsync_enabled : (Bool, Bool) -> Bool,
  is_vsync_enabled : (Bool, Bool) -> Bool,
  close_window : (Bool) -> Unit,
  request_attention : (Bool) -> Unit,
  set_mouse_touch_fallback : (Bool, Bool) -> Unit,
  mouse_touch_fallback_enabled : (Bool) -> Bool,
) -> DesktopNativeHooks {
  {
    try_initialize,
    poll,
    should_close,
    outside_size,
    capture_input,
    set_fullscreen,
    is_fullscreen,
    set_cursor_mode,
    cursor_mode,
    set_device_scale_factor,
    device_scale_factor,
    set_vsync_enabled,
    is_vsync_enabled,
    close_window,
    request_attention,
    set_mouse_touch_fallback,
    mouse_touch_fallback_enabled,
  }
}

///|
fn default_desktop_try_initialize(_options : WindowOptions) -> Bool {
  false
}

///|
fn default_desktop_poll(_active : Bool) -> Unit {
  ()
}

///|
fn default_desktop_should_close() -> Bool {
  false
}

///|
fn default_desktop_outside_size(width : Int, height : Int) -> @core.OutsideSize {
  @core.new_outside_size(width.to_double(), height.to_double())
}

///|
fn default_desktop_capture_input(
  _active : Bool,
  _tick : Int,
) -> @core.InputSnapshot {
  @core.empty_input_snapshot()
}

///|
fn default_desktop_set_fullscreen(_active : Bool, enabled : Bool) -> Bool {
  enabled
}

///|
fn default_desktop_is_fullscreen(_active : Bool, current : Bool) -> Bool {
  current
}

///|
fn default_desktop_set_cursor_mode(
  _active : Bool,
  mode : CursorMode,
) -> CursorMode {
  mode
}

///|
fn default_desktop_cursor_mode(
  _active : Bool,
  current : CursorMode,
) -> CursorMode {
  current
}

///|
fn default_desktop_set_device_scale_factor(
  _active : Bool,
  scale : Double,
) -> Double {
  if scale <= 0.0 {
    1.0
  } else {
    scale
  }
}

///|
fn default_desktop_device_scale_factor(
  _active : Bool,
  current : Double,
) -> Double {
  if current <= 0.0 {
    1.0
  } else {
    current
  }
}

///|
fn default_desktop_set_vsync_enabled(_active : Bool, enabled : Bool) -> Bool {
  enabled
}

///|
fn default_desktop_is_vsync_enabled(_active : Bool, current : Bool) -> Bool {
  current
}

///|
fn default_desktop_close_window(_active : Bool) -> Unit {
  ()
}

///|
fn default_desktop_request_attention(_active : Bool) -> Unit {
  ()
}

///|
fn default_desktop_set_mouse_touch_fallback(
  _active : Bool,
  _enabled : Bool,
) -> Unit {
  ()
}

///|
fn default_desktop_mouse_touch_fallback_enabled(_active : Bool) -> Bool {
  false
}

///|
fn default_desktop_native_hooks() -> DesktopNativeHooks {
  new_desktop_native_hooks(
    default_desktop_try_initialize, default_desktop_poll, default_desktop_should_close,
    default_desktop_outside_size, default_desktop_capture_input, default_desktop_set_fullscreen,
    default_desktop_is_fullscreen, default_desktop_set_cursor_mode, default_desktop_cursor_mode,
    default_desktop_set_device_scale_factor, default_desktop_device_scale_factor,
    default_desktop_set_vsync_enabled, default_desktop_is_vsync_enabled, default_desktop_close_window,
    default_desktop_request_attention,
    default_desktop_set_mouse_touch_fallback,
    default_desktop_mouse_touch_fallback_enabled,
  )
}

///|
let desktop_native_hooks : Ref[DesktopNativeHooks] = Ref::new(
  default_desktop_native_hooks(),
)

///|
pub fn set_desktop_native_hooks(hooks : DesktopNativeHooks) -> Unit {
  desktop_native_hooks.val = hooks
}

///|
pub fn reset_desktop_native_hooks() -> Unit {
  desktop_native_hooks.val = default_desktop_native_hooks()
}

///|
fn desktop_try_native_initialize(options : WindowOptions) -> Bool {
  (desktop_native_hooks.val.try_initialize)(options)
}

///|
fn desktop_poll_native(active : Bool) -> Unit {
  (desktop_native_hooks.val.poll)(active)
}

///|
fn desktop_native_should_close() -> Bool {
  (desktop_native_hooks.val.should_close)()
}

///|
fn desktop_native_outside_size(width : Int, height : Int) -> @core.OutsideSize {
  (desktop_native_hooks.val.outside_size)(width, height)
}

///|
fn desktop_native_capture_input(
  active : Bool,
  tick : Int,
) -> @core.InputSnapshot {
  (desktop_native_hooks.val.capture_input)(active, tick)
}

///|
fn desktop_native_set_fullscreen(active : Bool, enabled : Bool) -> Bool {
  (desktop_native_hooks.val.set_fullscreen)(active, enabled)
}

///|
fn desktop_native_is_fullscreen(active : Bool, current : Bool) -> Bool {
  (desktop_native_hooks.val.is_fullscreen)(active, current)
}

///|
fn desktop_native_set_cursor_mode(
  active : Bool,
  mode : CursorMode,
) -> CursorMode {
  (desktop_native_hooks.val.set_cursor_mode)(active, mode)
}

///|
fn desktop_native_cursor_mode(
  active : Bool,
  current : CursorMode,
) -> CursorMode {
  (desktop_native_hooks.val.cursor_mode)(active, current)
}

///|
fn desktop_native_set_device_scale_factor(
  active : Bool,
  scale : Double,
) -> Double {
  (desktop_native_hooks.val.set_device_scale_factor)(active, scale)
}

///|
fn desktop_native_device_scale_factor(
  active : Bool,
  current : Double,
) -> Double {
  (desktop_native_hooks.val.device_scale_factor)(active, current)
}

///|
fn desktop_native_set_vsync_enabled(active : Bool, enabled : Bool) -> Bool {
  (desktop_native_hooks.val.set_vsync_enabled)(active, enabled)
}

///|
fn desktop_native_is_vsync_enabled(active : Bool, current : Bool) -> Bool {
  (desktop_native_hooks.val.is_vsync_enabled)(active, current)
}

///|
fn desktop_native_close_window(active : Bool) -> Unit {
  (desktop_native_hooks.val.close_window)(active)
}

///|
fn desktop_native_request_attention(active : Bool) -> Unit {
  (desktop_native_hooks.val.request_attention)(active)
}

///|
fn desktop_native_set_mouse_touch_fallback(
  active : Bool,
  enabled : Bool,
) -> Unit {
  (desktop_native_hooks.val.set_mouse_touch_fallback)(active, enabled)
}

///|
fn desktop_native_mouse_touch_fallback_enabled(active : Bool) -> Bool {
  (desktop_native_hooks.val.mouse_touch_fallback_enabled)(active)
}
