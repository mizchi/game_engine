///|
pub struct WebCanvasHooks {
  try_initialize : (String, WindowOptions) -> Bool
  poll : (Bool) -> Unit
  should_close : () -> Bool
  outside_size : (Int, Int) -> @core.OutsideSize
  current_surface : (String, WindowOptions) -> SurfaceToken
  capture_input : (Bool, Int) -> @core.InputSnapshot
  set_fullscreen : (String, Bool, Bool) -> Bool
  is_fullscreen : (String, Bool, Bool) -> Bool
  set_cursor_mode : (String, Bool, CursorMode) -> CursorMode
  cursor_mode : (String, Bool, CursorMode) -> CursorMode
  set_device_scale_factor : (String, Bool, Double) -> Double
  device_scale_factor : (String, Bool, Double) -> Double
  set_vsync_enabled : (String, Bool, Bool) -> Bool
  is_vsync_enabled : (String, Bool, Bool) -> Bool
  close_window : (String, Bool) -> Unit
  request_attention : (String, Bool) -> Unit
  set_mouse_touch_fallback : (String, Bool, Bool) -> Unit
  mouse_touch_fallback_enabled : (String, Bool) -> Bool
  fullscreen_request_status : (String, Bool, Int) -> Int
  cursor_mode_request_status : (String, Bool, Int) -> Int
}

///|
pub fn new_web_canvas_hooks(
  try_initialize : (String, WindowOptions) -> Bool,
  poll : (Bool) -> Unit,
  should_close : () -> Bool,
  outside_size : (Int, Int) -> @core.OutsideSize,
  current_surface : (String, WindowOptions) -> SurfaceToken,
  capture_input : (Bool, Int) -> @core.InputSnapshot,
  set_fullscreen : (String, Bool, Bool) -> Bool,
  is_fullscreen : (String, Bool, Bool) -> Bool,
  set_cursor_mode : (String, Bool, CursorMode) -> CursorMode,
  cursor_mode : (String, Bool, CursorMode) -> CursorMode,
  set_device_scale_factor : (String, Bool, Double) -> Double,
  device_scale_factor : (String, Bool, Double) -> Double,
  set_vsync_enabled : (String, Bool, Bool) -> Bool,
  is_vsync_enabled : (String, Bool, Bool) -> Bool,
  close_window : (String, Bool) -> Unit,
  request_attention : (String, Bool) -> Unit,
  set_mouse_touch_fallback : (String, Bool, Bool) -> Unit,
  mouse_touch_fallback_enabled : (String, Bool) -> Bool,
  fullscreen_request_status : (String, Bool, Int) -> Int,
  cursor_mode_request_status : (String, Bool, Int) -> Int,
) -> WebCanvasHooks {
  {
    try_initialize,
    poll,
    should_close,
    outside_size,
    current_surface,
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
    fullscreen_request_status,
    cursor_mode_request_status,
  }
}

///|
fn default_web_try_initialize(
  _canvas_selector : String,
  _options : WindowOptions,
) -> Bool {
  false
}

///|
fn default_web_poll(_active : Bool) -> Unit {
  ()
}

///|
fn default_web_should_close() -> Bool {
  false
}

///|
fn default_web_outside_size(width : Int, height : Int) -> @core.OutsideSize {
  @core.new_outside_size(width.to_double(), height.to_double())
}

///|
fn default_web_current_surface(
  _canvas_selector : String,
  options : WindowOptions,
) -> SurfaceToken {
  {
    kind: SurfaceKind::WebGpuCanvasContext,
    opaque_id: 2,
    width: options.width,
    height: options.height,
    device_scale_factor: 1.0,
  }
}

///|
fn default_web_capture_input(
  _active : Bool,
  _tick : Int,
) -> @core.InputSnapshot {
  @core.empty_input_snapshot()
}

///|
fn default_web_set_fullscreen(
  _canvas_selector : String,
  _active : Bool,
  enabled : Bool,
) -> Bool {
  enabled
}

///|
fn default_web_is_fullscreen(
  _canvas_selector : String,
  _active : Bool,
  current : Bool,
) -> Bool {
  current
}

///|
fn default_web_set_cursor_mode(
  _canvas_selector : String,
  _active : Bool,
  mode : CursorMode,
) -> CursorMode {
  mode
}

///|
fn default_web_cursor_mode(
  _canvas_selector : String,
  _active : Bool,
  current : CursorMode,
) -> CursorMode {
  current
}

///|
fn default_web_set_device_scale_factor(
  _canvas_selector : String,
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
fn default_web_device_scale_factor(
  _canvas_selector : String,
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
fn default_web_set_vsync_enabled(
  _canvas_selector : String,
  _active : Bool,
  enabled : Bool,
) -> Bool {
  enabled
}

///|
fn default_web_is_vsync_enabled(
  _canvas_selector : String,
  _active : Bool,
  current : Bool,
) -> Bool {
  current
}

///|
fn default_web_close_window(_canvas_selector : String, _active : Bool) -> Unit {
  ()
}

///|
fn default_web_request_attention(
  _canvas_selector : String,
  _active : Bool,
) -> Unit {
  ()
}

///|
fn default_web_set_mouse_touch_fallback(
  _canvas_selector : String,
  _active : Bool,
  _enabled : Bool,
) -> Unit {
  ()
}

///|
fn default_web_mouse_touch_fallback_enabled(
  _canvas_selector : String,
  _active : Bool,
) -> Bool {
  false
}

///|
fn default_web_fullscreen_request_status(
  _canvas_selector : String,
  _active : Bool,
  current : Int,
) -> Int {
  current
}

///|
fn default_web_cursor_mode_request_status(
  _canvas_selector : String,
  _active : Bool,
  current : Int,
) -> Int {
  current
}

///|
fn default_web_canvas_hooks() -> WebCanvasHooks {
  new_web_canvas_hooks(
    default_web_try_initialize, default_web_poll, default_web_should_close, default_web_outside_size,
    default_web_current_surface, default_web_capture_input, default_web_set_fullscreen,
    default_web_is_fullscreen, default_web_set_cursor_mode, default_web_cursor_mode,
    default_web_set_device_scale_factor, default_web_device_scale_factor, default_web_set_vsync_enabled,
    default_web_is_vsync_enabled, default_web_close_window, default_web_request_attention,
    default_web_set_mouse_touch_fallback, default_web_mouse_touch_fallback_enabled,
    default_web_fullscreen_request_status, default_web_cursor_mode_request_status,
  )
}

///|
let web_canvas_hooks : Ref[WebCanvasHooks] = Ref::new(
  default_web_canvas_hooks(),
)

///|
pub fn set_web_canvas_hooks(hooks : WebCanvasHooks) -> Unit {
  web_canvas_hooks.val = hooks
}

///|
pub fn reset_web_canvas_hooks() -> Unit {
  web_canvas_hooks.val = default_web_canvas_hooks()
}

///|
fn web_try_initialize(
  canvas_selector : String,
  options : WindowOptions,
) -> Bool {
  (web_canvas_hooks.val.try_initialize)(canvas_selector, options)
}

///|
fn web_poll(active : Bool) -> Unit {
  (web_canvas_hooks.val.poll)(active)
}

///|
fn web_should_close() -> Bool {
  (web_canvas_hooks.val.should_close)()
}

///|
fn web_outside_size(width : Int, height : Int) -> @core.OutsideSize {
  (web_canvas_hooks.val.outside_size)(width, height)
}

///|
fn web_current_surface(
  canvas_selector : String,
  options : WindowOptions,
) -> SurfaceToken {
  (web_canvas_hooks.val.current_surface)(canvas_selector, options)
}

///|
fn web_capture_input(active : Bool, tick : Int) -> @core.InputSnapshot {
  (web_canvas_hooks.val.capture_input)(active, tick)
}

///|
fn web_set_fullscreen(
  canvas_selector : String,
  active : Bool,
  enabled : Bool,
) -> Bool {
  (web_canvas_hooks.val.set_fullscreen)(canvas_selector, active, enabled)
}

///|
fn web_is_fullscreen(
  canvas_selector : String,
  active : Bool,
  current : Bool,
) -> Bool {
  (web_canvas_hooks.val.is_fullscreen)(canvas_selector, active, current)
}

///|
fn web_set_cursor_mode(
  canvas_selector : String,
  active : Bool,
  mode : CursorMode,
) -> CursorMode {
  (web_canvas_hooks.val.set_cursor_mode)(canvas_selector, active, mode)
}

///|
fn web_cursor_mode(
  canvas_selector : String,
  active : Bool,
  current : CursorMode,
) -> CursorMode {
  (web_canvas_hooks.val.cursor_mode)(canvas_selector, active, current)
}

///|
fn web_set_device_scale_factor(
  canvas_selector : String,
  active : Bool,
  scale : Double,
) -> Double {
  (web_canvas_hooks.val.set_device_scale_factor)(canvas_selector, active, scale)
}

///|
fn web_device_scale_factor(
  canvas_selector : String,
  active : Bool,
  current : Double,
) -> Double {
  (web_canvas_hooks.val.device_scale_factor)(canvas_selector, active, current)
}

///|
fn web_set_vsync_enabled(
  canvas_selector : String,
  active : Bool,
  enabled : Bool,
) -> Bool {
  (web_canvas_hooks.val.set_vsync_enabled)(canvas_selector, active, enabled)
}

///|
fn web_is_vsync_enabled(
  canvas_selector : String,
  active : Bool,
  current : Bool,
) -> Bool {
  (web_canvas_hooks.val.is_vsync_enabled)(canvas_selector, active, current)
}

///|
fn web_close_window(canvas_selector : String, active : Bool) -> Unit {
  (web_canvas_hooks.val.close_window)(canvas_selector, active)
}

///|
fn web_request_attention(canvas_selector : String, active : Bool) -> Unit {
  (web_canvas_hooks.val.request_attention)(canvas_selector, active)
}

///|
fn web_set_mouse_touch_fallback(
  canvas_selector : String,
  active : Bool,
  enabled : Bool,
) -> Unit {
  (web_canvas_hooks.val.set_mouse_touch_fallback)(
    canvas_selector, active, enabled,
  )
}

///|
fn web_mouse_touch_fallback_enabled(
  canvas_selector : String,
  active : Bool,
) -> Bool {
  (web_canvas_hooks.val.mouse_touch_fallback_enabled)(canvas_selector, active)
}

///|
fn web_fullscreen_request_status(
  canvas_selector : String,
  active : Bool,
  current : Int,
) -> Int {
  (web_canvas_hooks.val.fullscreen_request_status)(
    canvas_selector, active, current,
  )
}

///|
fn web_cursor_mode_request_status(
  canvas_selector : String,
  active : Bool,
  current : Int,
) -> Int {
  (web_canvas_hooks.val.cursor_mode_request_status)(
    canvas_selector, active, current,
  )
}
