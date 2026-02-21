///|
/// Debug drawing and utility functions.
///
/// Reference:
/// - Ebiten ebitenutil package (DebugPrint, DrawLine, DrawRect, etc.)

///|
pub fn color_from_hex(hex : Int) -> @gfx.Color {
  let r = ((hex >> 16) & 0xFF).to_double() / 255.0
  let g = ((hex >> 8) & 0xFF).to_double() / 255.0
  let b = (hex & 0xFF).to_double() / 255.0
  @gfx.new_color(r, g, b, 1.0)
}

///|
pub fn color_from_hex_alpha(hex : Int, alpha : Double) -> @gfx.Color {
  let r = ((hex >> 16) & 0xFF).to_double() / 255.0
  let g = ((hex >> 8) & 0xFF).to_double() / 255.0
  let b = (hex & 0xFF).to_double() / 255.0
  @gfx.new_color(r, g, b, alpha)
}

///|
pub fn color_white() -> @gfx.Color {
  @gfx.new_color(1.0, 1.0, 1.0, 1.0)
}

///|
pub fn color_black() -> @gfx.Color {
  @gfx.new_color(0.0, 0.0, 0.0, 1.0)
}

///|
pub fn color_red() -> @gfx.Color {
  @gfx.new_color(1.0, 0.0, 0.0, 1.0)
}

///|
pub fn color_green() -> @gfx.Color {
  @gfx.new_color(0.0, 1.0, 0.0, 1.0)
}

///|
pub fn color_blue() -> @gfx.Color {
  @gfx.new_color(0.0, 0.0, 1.0, 1.0)
}

///|
pub fn color_yellow() -> @gfx.Color {
  @gfx.new_color(1.0, 1.0, 0.0, 1.0)
}

///|
pub fn color_transparent() -> @gfx.Color {
  @gfx.new_color(0.0, 0.0, 0.0, 0.0)
}

///|
pub fn color_to_uniform_dwords(color : @gfx.Color) -> Array[Int] {
  [
    (color.r * 255.0).to_int(),
    (color.g * 255.0).to_int(),
    (color.b * 255.0).to_int(),
    (color.a * 255.0).to_int(),
  ]
}

///|
/// Build vertex data for a line segment as a thin quad.
/// Returns (vertex_data, indices) for a DrawTrianglesCommand.
pub fn line_vertices(
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
  width : Double,
) -> (Array[Double], Array[Int]) {
  let dx = x1 - x0
  let dy = y1 - y0
  let dir = @vector.Vec2::new(dx, dy).normalize()
  let perp = dir.perpendicular().scale(width / 2.0)
  // Four corners of the line quad
  let vertices = [
    x0 + perp.x,
    y0 + perp.y,
    0.0,
    0.0,
    x1 + perp.x,
    y1 + perp.y,
    1.0,
    0.0,
    x1 - perp.x,
    y1 - perp.y,
    1.0,
    1.0,
    x0 - perp.x,
    y0 - perp.y,
    0.0,
    1.0,
  ]
  let indices = [0, 1, 2, 2, 3, 0]
  (vertices, indices)
}

///|
/// Build vertex data for an axis-aligned rectangle outline as four line quads.
pub fn rect_outline_vertices(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  line_width : Double,
) -> (Array[Double], Array[Int]) {
  let all_vertices : Array[Double] = []
  let all_indices : Array[Int] = []
  let lines = [
    (x, y, x + w, y), // top
    (x + w, y, x + w, y + h), // right
    (x + w, y + h, x, y + h), // bottom
    (x, y + h, x, y), // left
  ]
  let mut base_index = 0
  for line in lines {
    let (x0, y0, x1, y1) = line
    let (verts, idxs) = line_vertices(x0, y0, x1, y1, line_width)
    for v in verts {
      all_vertices.push(v)
    }
    for idx in idxs {
      all_indices.push(idx + base_index)
    }
    base_index = base_index + 4
  }
  (all_vertices, all_indices)
}

///|
/// Build vertex data for a filled axis-aligned rectangle.
pub fn rect_fill_vertices(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> (Array[Double], Array[Int]) {
  let vertices = [
    x,
    y,
    0.0,
    0.0,
    x + w,
    y,
    1.0,
    0.0,
    x + w,
    y + h,
    1.0,
    1.0,
    x,
    y + h,
    0.0,
    1.0,
  ]
  let indices = [0, 1, 2, 2, 3, 0]
  (vertices, indices)
}

///|
/// Build a draw command for a filled rectangle using a solid color shader.
pub fn new_rect_fill_command(
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  color : @gfx.Color,
  pipeline_id : Int,
) -> @gfx.DrawTrianglesCommand {
  let (vertices, indices) = rect_fill_vertices(x, y, w, h)
  let uniform = color_to_uniform_dwords(color)
  @gfx.new_draw_triangles_command(
    dst,
    shader,
    [@gfx.new_dst_region(x.to_int(), y.to_int(), w.to_int(), h.to_int(), 6)],
    0,
    pipeline_id,
    0,
    @gfx.blend_mode_from_int(1),
    vertices,
    indices,
    [],
    uniform,
  )
}

///|
/// Build a debug overlay showing current input state.
/// Returns draw commands for:
/// - Cursor crosshair at the current position
/// - Small indicator squares for each pressed key
/// - Indicator for pressed mouse buttons
pub fn build_input_debug_overlay(
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  snapshot : @core.InputSnapshot,
  key_state : @inpututil.KeyInputState,
  mouse_state : @inpututil.MouseButtonInputState,
  pipeline_id : Int,
) -> Array[@gfx.DrawTrianglesCommand] {
  let commands : Array[@gfx.DrawTrianglesCommand] = []
  // Cursor crosshair (2 lines)
  let cx = snapshot.cursor_x
  let cy = snapshot.cursor_y
  let crosshair_size = 10.0
  let crosshair_color = color_from_hex_alpha(0x00FF00, 0.8)
  commands.push(
    new_line_command(
      dst,
      shader,
      cx - crosshair_size,
      cy,
      cx + crosshair_size,
      cy,
      1.0,
      crosshair_color,
      pipeline_id,
    ),
  )
  commands.push(
    new_line_command(
      dst,
      shader,
      cx,
      cy - crosshair_size,
      cx,
      cy + crosshair_size,
      1.0,
      crosshair_color,
      pipeline_id,
    ),
  )
  // Pressed keys: small 8x8 squares in a row at top-left
  let pressed_keys = @inpututil.append_pressed_keys(key_state, [])
  let key_color = color_from_hex_alpha(0xFFFF00, 0.7)
  let just_pressed_color = color_from_hex_alpha(0xFF0000, 0.9)
  let just_pressed_keys = @inpututil.append_just_pressed_keys(key_state, [])
  for i, _key in pressed_keys {
    let kx = 4.0 + i.to_double() * 10.0
    let ky = 4.0
    let is_just = contains_int_arr(just_pressed_keys, pressed_keys[i])
    let c = if is_just { just_pressed_color } else { key_color }
    commands.push(
      new_rect_fill_command(dst, shader, kx, ky, 8.0, 8.0, c, pipeline_id),
    )
  }
  // Mouse buttons: small 12x12 squares below keys
  let pressed_btns = @inpututil.append_pressed_mouse_buttons(mouse_state, [])
  let btn_color = color_from_hex_alpha(0x00AAFF, 0.8)
  for i, _btn in pressed_btns {
    let bx = 4.0 + i.to_double() * 14.0
    let by = 16.0
    commands.push(
      new_rect_fill_command(
        dst, shader, bx, by, 12.0, 12.0, btn_color, pipeline_id,
      ),
    )
  }
  commands
}

///|
fn contains_int_arr(arr : Array[Int], value : Int) -> Bool {
  for item in arr {
    if item == value {
      return true
    }
  }
  false
}

///|
/// Build a draw command for a line segment.
pub fn new_line_command(
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
  width : Double,
  color : @gfx.Color,
  pipeline_id : Int,
) -> @gfx.DrawTrianglesCommand {
  let (vertices, indices) = line_vertices(x0, y0, x1, y1, width)
  let uniform = color_to_uniform_dwords(color)
  let min_x = if x0 < x1 { x0 } else { x1 }
  let min_y = if y0 < y1 { y0 } else { y1 }
  let max_x = if x0 > x1 { x0 } else { x1 }
  let max_y = if y0 > y1 { y0 } else { y1 }
  @gfx.new_draw_triangles_command(
    dst,
    shader,
    [
      @gfx.new_dst_region(
        min_x.to_int(),
        min_y.to_int(),
        (max_x - min_x + width).to_int(),
        (max_y - min_y + width).to_int(),
        6,
      ),
    ],
    0,
    pipeline_id,
    0,
    @gfx.blend_mode_from_int(1),
    vertices,
    indices,
    [],
    uniform,
  )
}

///|
/// Build vertex data for a filled rectangle in NDC (pixel coords → clip space).
pub fn ndc_rect_fill_vertices(
  px : Double,
  py : Double,
  pw : Double,
  ph : Double,
  screen_w : Double,
  screen_h : Double,
) -> (Array[Double], Array[Int]) {
  let x0 = px / screen_w * 2.0 - 1.0
  let y0 = 1.0 - py / screen_h * 2.0
  let x1 = (px + pw) / screen_w * 2.0 - 1.0
  let y1 = 1.0 - (py + ph) / screen_h * 2.0
  let vertices = [
    x0, y0, 0.0, 0.0,
    x1, y0, 1.0, 0.0,
    x1, y1, 1.0, 1.0,
    x0, y1, 0.0, 1.0,
  ]
  let indices = [0, 1, 2, 2, 3, 0]
  (vertices, indices)
}

///|
/// Build a draw command for a filled rectangle in NDC coordinates.
pub fn new_ndc_rect_fill_command(
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  px : Double,
  py : Double,
  pw : Double,
  ph : Double,
  screen_w : Double,
  screen_h : Double,
  color : @gfx.Color,
  pipeline_id : Int,
) -> @gfx.DrawTrianglesCommand {
  let (vertices, indices) = ndc_rect_fill_vertices(
    px, py, pw, ph, screen_w, screen_h,
  )
  let uniform = color_to_uniform_dwords(color)
  @gfx.new_draw_triangles_command(
    dst,
    shader,
    [@gfx.new_dst_region(0, 0, screen_w.to_int(), screen_h.to_int(), 6)],
    0,
    pipeline_id,
    0,
    @gfx.blend_mode_from_int(1),
    vertices,
    indices,
    [],
    uniform,
  )
}

///|
/// Build a simple draw command with common defaults.
pub fn new_simple_draw_command(
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  vertices : Array[Double],
  indices : Array[Int],
  color : @gfx.Color,
) -> @gfx.DrawTrianglesCommand {
  let uniform = color_to_uniform_dwords(color)
  @gfx.new_draw_triangles_command(
    dst,
    shader,
    [@gfx.new_dst_region(0, 0, 0, 0, indices.length())],
    0,
    0,
    0,
    @gfx.blend_mode_from_int(1),
    vertices,
    indices,
    [],
    uniform,
  )
}
