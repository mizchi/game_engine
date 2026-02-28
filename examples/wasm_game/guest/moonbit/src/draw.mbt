///| Create a DrawCmd for a filled rectangle.
///| Coordinates are in pixel space; converted to NDC internally.
fn rect_cmd(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  screen_w : Double,
  screen_h : Double,
  r : Int,
  g : Int,
  b : Int,
  alpha : Int
) -> DrawCmd {
  // Pixel to NDC: ndc_x = (px / screen_w) * 2 - 1, ndc_y = 1 - (py / screen_h) * 2
  let x0 = Float::from_double(x / screen_w * 2.0 - 1.0)
  let y0 = Float::from_double(1.0 - y / screen_h * 2.0)
  let x1 = Float::from_double((x + w) / screen_w * 2.0 - 1.0)
  let y1 = Float::from_double(1.0 - (y + h) / screen_h * 2.0)
  {
    vertex_count: 4,
    index_count: 6,
    src_image_id: 0,
    uniform_r: r,
    uniform_g: g,
    uniform_b: b,
    uniform_a: alpha,
    vertices: [
      x0, y0, 0.0, 0.0, // top-left
      x1, y0, 1.0, 0.0, // top-right
      x1, y1, 1.0, 1.0, // bottom-right
      x0, y1, 0.0, 1.0, // bottom-left
    ],
    indices: [0, 1, 2, 0, 2, 3],
  }
}

///| Create a DrawCmd from a hex color (0xRRGGBB).
fn rect_cmd_hex(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  screen_w : Double,
  screen_h : Double,
  fill : Int,
  alpha~ : Int = 255
) -> DrawCmd {
  let r = (fill >> 16) & 0xFF
  let g = (fill >> 8) & 0xFF
  let b = fill & 0xFF
  rect_cmd(x, y, w, h, screen_w, screen_h, r, g, b, alpha)
}
