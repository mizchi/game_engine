///|
/// Graphics backend selection contracts.
///
/// Ebiten refs:
/// - internal/graphicsdriver/graphics.go
/// - internal/ui/ui_glfw.go (platform dependent surface binding)

///|
pub enum GraphicsBackendKind {
  WgpuNative
  WebGpu
  WebGl2
  Null
} derive(Show)

///|
pub struct GraphicsBackendOptions {
  enable_validation : Bool
  prefer_low_power : Bool
  enable_vsync : Bool
} derive(Show)

///|
pub struct StubGraphicsDriver {
  backend : GraphicsBackendKind
  mut width : Int
  mut height : Int
  mut initialized : Bool
  mut native_active : Bool
  mut web_active : Bool
  mut next_id : Int
  mut begin_count : Int
  mut end_count : Int
  mut draw_count : Int
  mut resize_count : Int
  mut resize_suppressed_count : Int
  mut last_resize_duration_ms : Double
  mut total_resize_duration_ms : Double
}

///|
pub struct GraphicsResizeStats {
  resize_count : Int
  suppressed_count : Int
  current_width : Int
  current_height : Int
  last_resize_duration_ms : Double
  total_resize_duration_ms : Double
} derive(Show)

///|
pub type NativeGraphicsDriver = StubGraphicsDriver

///|
pub type WebGpuGraphicsDriver = StubGraphicsDriver

///|
pub type WebGlGraphicsDriver = StubGraphicsDriver

///|
pub type NullGraphicsDriver = StubGraphicsDriver

///|
pub trait GraphicsBackendFactory {
  create(
    Self,
    kind : GraphicsBackendKind,
    surface : @platform.SurfaceToken,
    options : GraphicsBackendOptions,
  ) -> Unit raise
}

///|
pub fn default_graphics_backend_options() -> GraphicsBackendOptions {
  { enable_validation: true, prefer_low_power: false, enable_vsync: true }
}

///|
fn default_clock_now_ms() -> Double {
  0.0
}

///|
let graphics_clock_provider : Ref[() -> Double] = Ref::new(default_clock_now_ms)

///|
pub fn set_graphics_clock_provider(clock : () -> Double) -> Unit {
  graphics_clock_provider.val = clock
}

///|
pub fn reset_graphics_clock_provider() -> Unit {
  graphics_clock_provider.val = default_clock_now_ms
}

///|
pub fn create_wgpu_native_graphics(
  surface : @platform.SurfaceToken,
  options : GraphicsBackendOptions,
) -> NativeGraphicsDriver {
  let _ = options
  {
    backend: GraphicsBackendKind::WgpuNative,
    width: surface.width,
    height: surface.height,
    initialized: false,
    native_active: false,
    web_active: false,
    next_id: 0,
    begin_count: 0,
    end_count: 0,
    draw_count: 0,
    resize_count: 0,
    resize_suppressed_count: 0,
    last_resize_duration_ms: 0.0,
    total_resize_duration_ms: 0.0,
  }
}

///|
pub fn create_webgpu_graphics(
  surface : @platform.SurfaceToken,
  options : GraphicsBackendOptions,
) -> WebGpuGraphicsDriver {
  let _ = options
  {
    backend: GraphicsBackendKind::WebGpu,
    width: surface.width,
    height: surface.height,
    initialized: false,
    native_active: false,
    web_active: false,
    next_id: 0,
    begin_count: 0,
    end_count: 0,
    draw_count: 0,
    resize_count: 0,
    resize_suppressed_count: 0,
    last_resize_duration_ms: 0.0,
    total_resize_duration_ms: 0.0,
  }
}

///|
pub fn create_webgl_graphics(
  surface : @platform.SurfaceToken,
  options : GraphicsBackendOptions,
) -> WebGlGraphicsDriver {
  let _ = options
  {
    backend: GraphicsBackendKind::WebGl2,
    width: surface.width,
    height: surface.height,
    initialized: false,
    native_active: false,
    web_active: false,
    next_id: 0,
    begin_count: 0,
    end_count: 0,
    draw_count: 0,
    resize_count: 0,
    resize_suppressed_count: 0,
    last_resize_duration_ms: 0.0,
    total_resize_duration_ms: 0.0,
  }
}

///|
pub fn create_null_graphics(width : Int, height : Int) -> NullGraphicsDriver {
  {
    backend: GraphicsBackendKind::Null,
    width,
    height,
    initialized: false,
    native_active: false,
    web_active: false,
    next_id: 0,
    begin_count: 0,
    end_count: 0,
    draw_count: 0,
    resize_count: 0,
    resize_suppressed_count: 0,
    last_resize_duration_ms: 0.0,
    total_resize_duration_ms: 0.0,
  }
}

///|
pub impl GraphicsDriver for StubGraphicsDriver with initialize(self) {
  if self.initialized {
    return
  }
  match self.backend {
    GraphicsBackendKind::WgpuNative =>
      self.native_active = native_try_initialize(self.width, self.height)
    GraphicsBackendKind::WebGpu | GraphicsBackendKind::WebGl2 =>
      self.web_active = web_graphics_try_initialize(
        self.backend,
        self.width,
        self.height,
      )
    _ => ()
  }
  self.initialized = true
}

///|
pub impl GraphicsDriver for StubGraphicsDriver with begin(self, pass) {
  let _ = self.backend
  if self.initialized {
    self.begin_count = self.begin_count + 1
    native_on_begin(self.native_active, pass)
    web_graphics_on_begin(self.web_active, self.backend, pass)
  }
}

///|
pub impl GraphicsDriver for StubGraphicsDriver with end(self, present) {
  if self.initialized {
    self.end_count = self.end_count + 1
    native_on_end(self.native_active, present)
    web_graphics_on_end(self.web_active, self.backend, present)
  }
}

///|
pub impl GraphicsDriver for StubGraphicsDriver with resize(self, width, height) {
  let next_width = if width <= 0 { 1 } else { width }
  let next_height = if height <= 0 { 1 } else { height }
  if self.width == next_width && self.height == next_height {
    self.resize_suppressed_count = self.resize_suppressed_count + 1
    return ()
  }
  let t0 = (graphics_clock_provider.val)()
  self.resize_count = self.resize_count + 1
  self.width = next_width
  self.height = next_height
  if self.initialized {
    native_on_resize(self.native_active, next_width, next_height)
    web_graphics_on_resize(
      self.web_active,
      self.backend,
      next_width,
      next_height,
    )
  }
  let t1 = (graphics_clock_provider.val)()
  let duration = t1 - t0
  self.last_resize_duration_ms = duration
  self.total_resize_duration_ms = self.total_resize_duration_ms + duration
}

///|
pub fn graphics_resize_stats(
  driver : StubGraphicsDriver,
) -> GraphicsResizeStats {
  {
    resize_count: driver.resize_count,
    suppressed_count: driver.resize_suppressed_count,
    current_width: driver.width,
    current_height: driver.height,
    last_resize_duration_ms: driver.last_resize_duration_ms,
    total_resize_duration_ms: driver.total_resize_duration_ms,
  }
}

///|
pub impl GraphicsDriver for StubGraphicsDriver with new_image(
  self,
  width,
  height,
) {
  self.next_id = self.next_id + 1
  native_on_new_image(self.native_active, self.next_id, width, height)
  { id: self.next_id, width, height }
}

///|
pub impl GraphicsDriver for StubGraphicsDriver with new_shader(self, source) {
  self.next_id = self.next_id + 1
  { id: self.next_id, source }
}

///|
pub impl GraphicsDriver for StubGraphicsDriver with draw_triangles(
  self,
  command,
) {
  if self.initialized {
    self.draw_count = self.draw_count + 1
    native_on_draw(self.native_active, command)
    web_graphics_on_draw(self.web_active, self.backend, command)
  }
}

///|
pub impl GraphicsDriver for StubGraphicsDriver with read_pixels(
  self,
  x,
  y,
  width,
  height,
) {
  if not(self.initialized) {
    return None
  }
  let read_w = if x + width > self.width { self.width - x } else { width }
  let read_h = if y + height > self.height { self.height - y } else { height }
  if read_w <= 0 || read_h <= 0 {
    return None
  }
  match native_on_read_pixels(self.native_active, x, y, read_w, read_h) {
    Some(pixels) => Some(pixels)
    None =>
      web_graphics_on_read_pixels(
        self.web_active, self.backend, x, y, read_w, read_h,
      )
  }
}
