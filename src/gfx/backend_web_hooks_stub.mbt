///|
pub struct WebGraphicsHooks {
  try_initialize : (GraphicsBackendKind, Int, Int) -> Bool
  on_begin : (Bool, GraphicsBackendKind, RenderPassDesc) -> Unit
  on_end : (Bool, GraphicsBackendKind, Bool) -> Unit
  on_draw : (Bool, GraphicsBackendKind, DrawTrianglesCommand) -> Unit
  on_resize : (Bool, GraphicsBackendKind, Int, Int) -> Unit
  on_read_pixels : (Bool, GraphicsBackendKind, Int, Int, Int, Int) -> Array[Int]?
}

///|
pub fn new_web_graphics_hooks(
  try_initialize : (GraphicsBackendKind, Int, Int) -> Bool,
  on_begin : (Bool, GraphicsBackendKind, RenderPassDesc) -> Unit,
  on_end : (Bool, GraphicsBackendKind, Bool) -> Unit,
  on_draw : (Bool, GraphicsBackendKind, DrawTrianglesCommand) -> Unit,
  on_resize : (Bool, GraphicsBackendKind, Int, Int) -> Unit,
) -> WebGraphicsHooks {
  {
    try_initialize,
    on_begin,
    on_end,
    on_draw,
    on_resize,
    on_read_pixels: default_web_on_read_pixels,
  }
}

///|
pub fn new_web_graphics_hooks_full(
  try_initialize : (GraphicsBackendKind, Int, Int) -> Bool,
  on_begin : (Bool, GraphicsBackendKind, RenderPassDesc) -> Unit,
  on_end : (Bool, GraphicsBackendKind, Bool) -> Unit,
  on_draw : (Bool, GraphicsBackendKind, DrawTrianglesCommand) -> Unit,
  on_resize : (Bool, GraphicsBackendKind, Int, Int) -> Unit,
  on_read_pixels : (Bool, GraphicsBackendKind, Int, Int, Int, Int) -> Array[Int]?,
) -> WebGraphicsHooks {
  { try_initialize, on_begin, on_end, on_draw, on_resize, on_read_pixels }
}

///|
fn default_web_try_initialize(
  _kind : GraphicsBackendKind,
  _width : Int,
  _height : Int,
) -> Bool {
  false
}

///|
fn default_web_on_begin(
  _active : Bool,
  _kind : GraphicsBackendKind,
  _pass : RenderPassDesc,
) -> Unit {
  ()
}

///|
fn default_web_on_end(
  _active : Bool,
  _kind : GraphicsBackendKind,
  _present : Bool,
) -> Unit {
  ()
}

///|
fn default_web_on_draw(
  _active : Bool,
  _kind : GraphicsBackendKind,
  _command : DrawTrianglesCommand,
) -> Unit {
  ()
}

///|
fn default_web_on_resize(
  _active : Bool,
  _kind : GraphicsBackendKind,
  _width : Int,
  _height : Int,
) -> Unit {
  ()
}

///|
fn default_web_on_read_pixels(
  _active : Bool,
  _kind : GraphicsBackendKind,
  _x : Int,
  _y : Int,
  _width : Int,
  _height : Int,
) -> Array[Int]? {
  None
}

///|
fn default_web_graphics_hooks() -> WebGraphicsHooks {
  new_web_graphics_hooks(
    default_web_try_initialize, default_web_on_begin, default_web_on_end, default_web_on_draw,
    default_web_on_resize,
  )
}

///|
let web_graphics_hooks : Ref[WebGraphicsHooks] = Ref::new(
  default_web_graphics_hooks(),
)

///|
pub fn set_web_graphics_hooks(hooks : WebGraphicsHooks) -> Unit {
  web_graphics_hooks.val = hooks
}

///|
pub fn reset_web_graphics_hooks() -> Unit {
  web_graphics_hooks.val = default_web_graphics_hooks()
}

///|
fn web_graphics_try_initialize(
  kind : GraphicsBackendKind,
  width : Int,
  height : Int,
) -> Bool {
  (web_graphics_hooks.val.try_initialize)(kind, width, height)
}

///|
fn web_graphics_on_begin(
  active : Bool,
  kind : GraphicsBackendKind,
  pass : RenderPassDesc,
) -> Unit {
  (web_graphics_hooks.val.on_begin)(active, kind, pass)
}

///|
fn web_graphics_on_end(
  active : Bool,
  kind : GraphicsBackendKind,
  present : Bool,
) -> Unit {
  (web_graphics_hooks.val.on_end)(active, kind, present)
}

///|
fn web_graphics_on_draw(
  active : Bool,
  kind : GraphicsBackendKind,
  command : DrawTrianglesCommand,
) -> Unit {
  (web_graphics_hooks.val.on_draw)(active, kind, command)
}

///|
fn web_graphics_on_resize(
  active : Bool,
  kind : GraphicsBackendKind,
  width : Int,
  height : Int,
) -> Unit {
  (web_graphics_hooks.val.on_resize)(active, kind, width, height)
}

///|
fn web_graphics_on_read_pixels(
  active : Bool,
  kind : GraphicsBackendKind,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Array[Int]? {
  (web_graphics_hooks.val.on_read_pixels)(active, kind, x, y, width, height)
}
