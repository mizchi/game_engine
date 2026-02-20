///|
pub struct NativeGraphicsHooks {
  try_initialize : (Int, Int) -> Bool
  on_begin : (Bool, RenderPassDesc) -> Unit
  on_end : (Bool, Bool) -> Unit
  on_draw : (Bool, DrawTrianglesCommand) -> Unit
  on_resize : (Bool, Int, Int) -> Unit
  on_read_pixels : (Bool, Int, Int, Int, Int) -> Array[Int]?
}

///|
pub fn new_native_graphics_hooks(
  try_initialize : (Int, Int) -> Bool,
  on_begin : (Bool, RenderPassDesc) -> Unit,
  on_end : (Bool, Bool) -> Unit,
  on_draw : (Bool, DrawTrianglesCommand) -> Unit,
  on_resize : (Bool, Int, Int) -> Unit,
) -> NativeGraphicsHooks {
  {
    try_initialize,
    on_begin,
    on_end,
    on_draw,
    on_resize,
    on_read_pixels: default_native_on_read_pixels,
  }
}

///|
pub fn new_native_graphics_hooks_full(
  try_initialize : (Int, Int) -> Bool,
  on_begin : (Bool, RenderPassDesc) -> Unit,
  on_end : (Bool, Bool) -> Unit,
  on_draw : (Bool, DrawTrianglesCommand) -> Unit,
  on_resize : (Bool, Int, Int) -> Unit,
  on_read_pixels : (Bool, Int, Int, Int, Int) -> Array[Int]?,
) -> NativeGraphicsHooks {
  { try_initialize, on_begin, on_end, on_draw, on_resize, on_read_pixels }
}

///|
fn default_native_try_initialize(_width : Int, _height : Int) -> Bool {
  false
}

///|
fn default_native_on_begin(_active : Bool, _pass : RenderPassDesc) -> Unit {
  ()
}

///|
fn default_native_on_end(_active : Bool, _present : Bool) -> Unit {
  ()
}

///|
fn default_native_on_draw(
  _active : Bool,
  _command : DrawTrianglesCommand,
) -> Unit {
  ()
}

///|
fn default_native_on_resize(
  _active : Bool,
  _width : Int,
  _height : Int,
) -> Unit {
  ()
}

///|
fn default_native_on_read_pixels(
  _active : Bool,
  _x : Int,
  _y : Int,
  _width : Int,
  _height : Int,
) -> Array[Int]? {
  None
}

///|
fn default_native_graphics_hooks() -> NativeGraphicsHooks {
  new_native_graphics_hooks(
    default_native_try_initialize, default_native_on_begin, default_native_on_end,
    default_native_on_draw, default_native_on_resize,
  )
}

///|
let native_graphics_hooks : Ref[NativeGraphicsHooks] = Ref::new(
  default_native_graphics_hooks(),
)

///|
pub fn set_native_graphics_hooks(hooks : NativeGraphicsHooks) -> Unit {
  native_graphics_hooks.val = hooks
}

///|
pub fn reset_native_graphics_hooks() -> Unit {
  native_graphics_hooks.val = default_native_graphics_hooks()
}

///|
fn native_try_initialize(width : Int, height : Int) -> Bool {
  (native_graphics_hooks.val.try_initialize)(width, height)
}

///|
fn native_on_begin(active : Bool, pass : RenderPassDesc) -> Unit {
  (native_graphics_hooks.val.on_begin)(active, pass)
}

///|
fn native_on_end(active : Bool, present : Bool) -> Unit {
  (native_graphics_hooks.val.on_end)(active, present)
}

///|
fn native_on_draw(active : Bool, command : DrawTrianglesCommand) -> Unit {
  (native_graphics_hooks.val.on_draw)(active, command)
}

///|
fn native_on_resize(active : Bool, width : Int, height : Int) -> Unit {
  (native_graphics_hooks.val.on_resize)(active, width, height)
}

///|
fn native_on_read_pixels(
  active : Bool,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Array[Int]? {
  (native_graphics_hooks.val.on_read_pixels)(active, x, y, width, height)
}
