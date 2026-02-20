///|
/// Platform layer contracts (window/event/input).
/// Ebiten refs:
/// - internal/ui/ui.go
/// - internal/ui/ui_glfw.go
/// - internal/ui/input_*.go
/// - internal/inputstate/inputstate.go

///|
pub struct WindowOptions {
  title : String
  width : Int
  height : Int
  transparent : Bool
  resizable : Bool
} derive(Show)

///|
pub struct MonitorInfo {
  width : Int
  height : Int
  device_scale_factor : Double
  refresh_rate_hz : Int
} derive(Show)

///|
pub enum FullscreenMode {
  Windowed
  Borderless
  Exclusive
} derive(Show)

///|
pub fn fullscreen_mode_to_int(mode : FullscreenMode) -> Int {
  match mode {
    FullscreenMode::Windowed => 0
    FullscreenMode::Borderless => 1
    FullscreenMode::Exclusive => 2
  }
}

///|
pub fn fullscreen_mode_from_int(mode : Int) -> FullscreenMode {
  match mode {
    1 => FullscreenMode::Borderless
    2 => FullscreenMode::Exclusive
    _ => FullscreenMode::Windowed
  }
}

///|
pub enum CursorMode {
  Visible
  Hidden
  Captured
} derive(Show)

///|
pub fn cursor_mode_to_int(mode : CursorMode) -> Int {
  match mode {
    CursorMode::Visible => 0
    CursorMode::Hidden => 1
    CursorMode::Captured => 2
  }
}

///|
pub fn cursor_mode_from_int(mode : Int) -> CursorMode {
  match mode {
    1 => CursorMode::Hidden
    2 => CursorMode::Captured
    _ => CursorMode::Visible
  }
}

///|
pub enum AsyncRequestStatus {
  Idle
  Pending
  Confirmed
  Rejected
} derive(Show)

///|
pub fn async_request_status_to_int(status : AsyncRequestStatus) -> Int {
  match status {
    AsyncRequestStatus::Idle => 0
    AsyncRequestStatus::Pending => 1
    AsyncRequestStatus::Confirmed => 2
    AsyncRequestStatus::Rejected => 3
  }
}

///|
pub fn async_request_status_from_int(status : Int) -> AsyncRequestStatus {
  match status {
    1 => AsyncRequestStatus::Pending
    2 => AsyncRequestStatus::Confirmed
    3 => AsyncRequestStatus::Rejected
    _ => AsyncRequestStatus::Idle
  }
}

///|
pub fn new_window_options(
  title : String,
  width : Int,
  height : Int,
  transparent : Bool,
  resizable : Bool,
) -> WindowOptions {
  { title, width, height, transparent, resizable }
}

///|
pub trait PlatformDriver {
  /// Ebiten ref: UserInterface.init / Run
  initialize(Self, options : WindowOptions) -> Unit raise

  /// Ebiten ref: ui.loopGame event pump
  poll_events(Self) -> Unit

  /// Ebiten ref: window close handling in ui/inputstate
  should_close(Self) -> Bool

  /// Ebiten ref: Game.Layout outside size inputs
  outside_size(Self) -> @core.OutsideSize

  /// Ebiten ref: inputstate snapshot per tick
  capture_input(Self, tick : Int) -> @core.InputSnapshot

  /// Ebiten ref: device scale factor paths in ui/context
  monitor_info(Self) -> MonitorInfo

  /// Ebiten ref: SetFullscreen/IsFullscreen
  set_fullscreen(Self, enabled : Bool) -> Unit
  is_fullscreen(Self) -> Bool

  /// Ebiten ref: SetCursorMode/CursorMode
  set_cursor_mode(Self, mode : CursorMode) -> Unit
  cursor_mode(Self) -> CursorMode

  /// Ebiten ref: DeviceScaleFactor
  set_device_scale_factor(Self, scale : Double) -> Unit
  device_scale_factor(Self) -> Double

  /// Ebiten ref: SetVsyncEnabled/IsVsyncEnabled
  set_vsync_enabled(Self, enabled : Bool) -> Unit
  is_vsync_enabled(Self) -> Bool

  /// Ebiten ref: window close/requestAttention
  close_window(Self) -> Unit
  request_attention(Self) -> Unit

  /// Mouse-to-touch fallback (opt-in, default false)
  set_mouse_touch_fallback(Self, enabled : Bool) -> Unit
  mouse_touch_fallback_enabled(Self) -> Bool

  /// Async request status for fullscreen and cursor mode
  fullscreen_request_status(Self) -> AsyncRequestStatus
  cursor_mode_request_status(Self) -> AsyncRequestStatus
}

///|
pub struct DesktopGlfwPlatform {
  mut initialized : Bool
  mut poll_count : Int
  close_after_polls : Int
  mut native_active : Bool
  mut options : WindowOptions
  mut current_input : @core.InputSnapshot
  mut fullscreen : Bool
  mut cursor_mode : CursorMode
  mut device_scale_factor : Double
  mut vsync_enabled : Bool
  mut close_requested : Bool
  mut attention_requests : Int
  mut mouse_touch_fallback : Bool
  mut fullscreen_request_status : AsyncRequestStatus
  mut cursor_mode_request_status : AsyncRequestStatus
}

///|
pub struct WebCanvasPlatform {
  canvas_selector : String
  mut initialized : Bool
  mut poll_count : Int
  close_after_polls : Int
  mut web_active : Bool
  mut options : WindowOptions
  mut current_input : @core.InputSnapshot
  mut fullscreen : Bool
  mut cursor_mode : CursorMode
  mut device_scale_factor : Double
  mut vsync_enabled : Bool
  mut close_requested : Bool
  mut attention_requests : Int
  mut mouse_touch_fallback : Bool
  mut fullscreen_request_status : AsyncRequestStatus
  mut cursor_mode_request_status : AsyncRequestStatus
}

///|
pub fn create_desktop_glfw_platform() -> DesktopGlfwPlatform {
  {
    initialized: false,
    poll_count: 0,
    close_after_polls: 2,
    native_active: false,
    options: {
      title: "game_engine",
      width: 800,
      height: 600,
      transparent: false,
      resizable: true,
    },
    current_input: @core.empty_input_snapshot(),
    fullscreen: false,
    cursor_mode: CursorMode::Visible,
    device_scale_factor: 1.0,
    vsync_enabled: true,
    close_requested: false,
    attention_requests: 0,
    mouse_touch_fallback: false,
    fullscreen_request_status: AsyncRequestStatus::Idle,
    cursor_mode_request_status: AsyncRequestStatus::Idle,
  }
}

///|
pub fn create_web_canvas_platform(
  canvas_selector : String,
) -> WebCanvasPlatform {
  {
    canvas_selector,
    initialized: false,
    poll_count: 0,
    close_after_polls: 2,
    web_active: false,
    options: {
      title: "game_engine-web",
      width: 800,
      height: 600,
      transparent: true,
      resizable: true,
    },
    current_input: @core.empty_input_snapshot(),
    fullscreen: false,
    cursor_mode: CursorMode::Visible,
    device_scale_factor: 1.0,
    vsync_enabled: true,
    close_requested: false,
    attention_requests: 0,
    mouse_touch_fallback: false,
    fullscreen_request_status: AsyncRequestStatus::Idle,
    cursor_mode_request_status: AsyncRequestStatus::Idle,
  }
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with initialize(self, options) {
  self.options = options
  self.native_active = desktop_try_native_initialize(options)
  self.initialized = true
  self.poll_count = 0
  self.close_requested = false
  self.attention_requests = 0
  self.fullscreen = desktop_native_is_fullscreen(
    self.native_active,
    self.fullscreen,
  )
  self.cursor_mode = desktop_native_cursor_mode(
    self.native_active,
    self.cursor_mode,
  )
  self.device_scale_factor = desktop_native_device_scale_factor(
    self.native_active,
    self.device_scale_factor,
  )
  self.vsync_enabled = desktop_native_is_vsync_enabled(
    self.native_active,
    self.vsync_enabled,
  )
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with poll_events(self) {
  if self.initialized {
    desktop_poll_native(self.native_active)
    self.poll_count = self.poll_count + 1
  }
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with should_close(self) {
  if self.close_requested {
    true
  } else if self.native_active {
    self.initialized &&
    (desktop_native_should_close() || self.poll_count >= self.close_after_polls)
  } else {
    self.initialized && self.poll_count >= self.close_after_polls
  }
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with outside_size(self) {
  if self.native_active {
    desktop_native_outside_size(self.options.width, self.options.height)
  } else {
    @core.new_outside_size(
      self.options.width.to_double(),
      self.options.height.to_double(),
    )
  }
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with capture_input(self, tick) {
  self.current_input = desktop_native_capture_input(self.native_active, tick)
  self.current_input
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with monitor_info(self) {
  let outside = self.outside_size()
  self.device_scale_factor = desktop_native_device_scale_factor(
    self.native_active,
    self.device_scale_factor,
  )
  if self.device_scale_factor <= 0.0 {
    self.device_scale_factor = 1.0
  }
  {
    width: outside.width.to_int(),
    height: outside.height.to_int(),
    device_scale_factor: self.device_scale_factor,
    refresh_rate_hz: 60,
  }
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with set_fullscreen(
  self,
  enabled,
) {
  self.fullscreen = desktop_native_set_fullscreen(self.native_active, enabled)
  self.fullscreen_request_status = AsyncRequestStatus::Confirmed
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with is_fullscreen(self) {
  self.fullscreen = desktop_native_is_fullscreen(
    self.native_active,
    self.fullscreen,
  )
  self.fullscreen
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with set_cursor_mode(self, mode) {
  self.cursor_mode = desktop_native_set_cursor_mode(self.native_active, mode)
  self.cursor_mode_request_status = AsyncRequestStatus::Confirmed
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with cursor_mode(self) {
  self.cursor_mode = desktop_native_cursor_mode(
    self.native_active,
    self.cursor_mode,
  )
  self.cursor_mode
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with set_device_scale_factor(
  self,
  scale,
) {
  let requested_scale = if scale <= 0.0 { 1.0 } else { scale }
  self.device_scale_factor = desktop_native_set_device_scale_factor(
    self.native_active,
    requested_scale,
  )
  if self.device_scale_factor <= 0.0 {
    self.device_scale_factor = 1.0
  }
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with device_scale_factor(self) {
  self.device_scale_factor = desktop_native_device_scale_factor(
    self.native_active,
    self.device_scale_factor,
  )
  if self.device_scale_factor <= 0.0 {
    self.device_scale_factor = 1.0
  }
  self.device_scale_factor
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with set_vsync_enabled(
  self,
  enabled,
) {
  self.vsync_enabled = desktop_native_set_vsync_enabled(
    self.native_active,
    enabled,
  )
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with is_vsync_enabled(self) {
  self.vsync_enabled = desktop_native_is_vsync_enabled(
    self.native_active,
    self.vsync_enabled,
  )
  self.vsync_enabled
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with close_window(self) {
  self.close_requested = true
  desktop_native_close_window(self.native_active)
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with request_attention(self) {
  self.attention_requests = self.attention_requests + 1
  desktop_native_request_attention(self.native_active)
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with set_mouse_touch_fallback(
  self,
  enabled,
) {
  self.mouse_touch_fallback = enabled
  desktop_native_set_mouse_touch_fallback(self.native_active, enabled)
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with mouse_touch_fallback_enabled(
  self,
) {
  self.mouse_touch_fallback
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with fullscreen_request_status(
  self,
) {
  self.fullscreen_request_status
}

///|
pub impl PlatformDriver for DesktopGlfwPlatform with cursor_mode_request_status(
  self,
) {
  self.cursor_mode_request_status
}

///|
pub impl PlatformDriver for WebCanvasPlatform with initialize(self, options) {
  self.options = options
  self.web_active = web_try_initialize(self.canvas_selector, options)
  self.initialized = true
  self.poll_count = 0
  self.close_requested = false
  self.attention_requests = 0
  self.fullscreen = web_is_fullscreen(
    self.canvas_selector,
    self.web_active,
    self.fullscreen,
  )
  self.cursor_mode = web_cursor_mode(
    self.canvas_selector,
    self.web_active,
    self.cursor_mode,
  )
  self.device_scale_factor = web_device_scale_factor(
    self.canvas_selector,
    self.web_active,
    self.device_scale_factor,
  )
  self.vsync_enabled = web_is_vsync_enabled(
    self.canvas_selector,
    self.web_active,
    self.vsync_enabled,
  )
}

///|
pub impl PlatformDriver for WebCanvasPlatform with poll_events(self) {
  if self.initialized {
    web_poll(self.web_active)
    self.poll_count = self.poll_count + 1
  }
}

///|
pub impl PlatformDriver for WebCanvasPlatform with should_close(self) {
  if self.close_requested {
    true
  } else if self.web_active {
    self.initialized &&
    (web_should_close() || self.poll_count >= self.close_after_polls)
  } else {
    self.initialized && self.poll_count >= self.close_after_polls
  }
}

///|
pub impl PlatformDriver for WebCanvasPlatform with outside_size(self) {
  if self.web_active {
    web_outside_size(self.options.width, self.options.height)
  } else {
    @core.new_outside_size(
      self.options.width.to_double(),
      self.options.height.to_double(),
    )
  }
}

///|
pub impl PlatformDriver for WebCanvasPlatform with capture_input(self, tick) {
  self.current_input = web_capture_input(self.web_active, tick)
  self.current_input
}

///|
pub impl PlatformDriver for WebCanvasPlatform with monitor_info(self) {
  self.device_scale_factor = web_device_scale_factor(
    self.canvas_selector,
    self.web_active,
    self.device_scale_factor,
  )
  if self.device_scale_factor <= 0.0 {
    self.device_scale_factor = 1.0
  }
  {
    width: self.options.width,
    height: self.options.height,
    device_scale_factor: self.device_scale_factor,
    refresh_rate_hz: 60,
  }
}

///|
pub impl PlatformDriver for WebCanvasPlatform with set_fullscreen(self, enabled) {
  self.fullscreen_request_status = AsyncRequestStatus::Pending
  self.fullscreen = web_set_fullscreen(
    self.canvas_selector,
    self.web_active,
    enabled,
  )
}

///|
pub impl PlatformDriver for WebCanvasPlatform with is_fullscreen(self) {
  self.fullscreen = web_is_fullscreen(
    self.canvas_selector,
    self.web_active,
    self.fullscreen,
  )
  self.fullscreen
}

///|
pub impl PlatformDriver for WebCanvasPlatform with set_cursor_mode(self, mode) {
  self.cursor_mode_request_status = AsyncRequestStatus::Pending
  self.cursor_mode = web_set_cursor_mode(
    self.canvas_selector,
    self.web_active,
    mode,
  )
}

///|
pub impl PlatformDriver for WebCanvasPlatform with cursor_mode(self) {
  self.cursor_mode = web_cursor_mode(
    self.canvas_selector,
    self.web_active,
    self.cursor_mode,
  )
  self.cursor_mode
}

///|
pub impl PlatformDriver for WebCanvasPlatform with set_device_scale_factor(
  self,
  scale,
) {
  let requested_scale = if scale <= 0.0 { 1.0 } else { scale }
  self.device_scale_factor = web_set_device_scale_factor(
    self.canvas_selector,
    self.web_active,
    requested_scale,
  )
  if self.device_scale_factor <= 0.0 {
    self.device_scale_factor = 1.0
  }
}

///|
pub impl PlatformDriver for WebCanvasPlatform with device_scale_factor(self) {
  self.device_scale_factor = web_device_scale_factor(
    self.canvas_selector,
    self.web_active,
    self.device_scale_factor,
  )
  if self.device_scale_factor <= 0.0 {
    self.device_scale_factor = 1.0
  }
  self.device_scale_factor
}

///|
pub impl PlatformDriver for WebCanvasPlatform with set_vsync_enabled(
  self,
  enabled,
) {
  self.vsync_enabled = web_set_vsync_enabled(
    self.canvas_selector,
    self.web_active,
    enabled,
  )
}

///|
pub impl PlatformDriver for WebCanvasPlatform with is_vsync_enabled(self) {
  self.vsync_enabled = web_is_vsync_enabled(
    self.canvas_selector,
    self.web_active,
    self.vsync_enabled,
  )
  self.vsync_enabled
}

///|
pub impl PlatformDriver for WebCanvasPlatform with close_window(self) {
  self.close_requested = true
  web_close_window(self.canvas_selector, self.web_active)
}

///|
pub impl PlatformDriver for WebCanvasPlatform with request_attention(self) {
  self.attention_requests = self.attention_requests + 1
  web_request_attention(self.canvas_selector, self.web_active)
}

///|
pub impl PlatformDriver for WebCanvasPlatform with set_mouse_touch_fallback(
  self,
  enabled,
) {
  self.mouse_touch_fallback = enabled
  web_set_mouse_touch_fallback(self.canvas_selector, self.web_active, enabled)
}

///|
pub impl PlatformDriver for WebCanvasPlatform with mouse_touch_fallback_enabled(
  self,
) {
  self.mouse_touch_fallback
}

///|
pub impl PlatformDriver for WebCanvasPlatform with fullscreen_request_status(
  self,
) {
  let status = web_fullscreen_request_status(
    self.canvas_selector,
    self.web_active,
    async_request_status_to_int(self.fullscreen_request_status),
  )
  self.fullscreen_request_status = async_request_status_from_int(status)
  self.fullscreen_request_status
}

///|
pub impl PlatformDriver for WebCanvasPlatform with cursor_mode_request_status(
  self,
) {
  let status = web_cursor_mode_request_status(
    self.canvas_selector,
    self.web_active,
    async_request_status_to_int(self.cursor_mode_request_status),
  )
  self.cursor_mode_request_status = async_request_status_from_int(status)
  self.cursor_mode_request_status
}
