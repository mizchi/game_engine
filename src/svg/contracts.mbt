///|
/// SVG integration bridge.
///
/// Reference:
/// - mizchi/svg (SVG parsing and rasterization)
/// - vector.Path (path-based drawing)

///|
/// Render an SVG string to RGBA pixel data.
/// Returns (width, height, pixels) where pixels is a flat RGBA8 array.
pub fn render_svg_to_rgba(
  svg_source : String,
  width : Int,
  height : Int,
) -> (Int, Int, Array[Int])? {
  let image = @msvg.render_svg_to_image(svg_source, width, height)
  match image {
    None => None
    Some(img) => {
      let w = img.width
      let h = img.height
      let pixels : Array[Int] = []
      for i = 0; i < img.pixels.length(); i = i + 1 {
        let color = img.pixels[i]
        pixels.push(color.r)
        pixels.push(color.g)
        pixels.push(color.b)
        pixels.push(color.a)
      }
      Some((w, h, pixels))
    }
  }
}

///|
/// Parse an SVG path data string (e.g. "M 0 0 L 10 10") into a vector Path.
pub fn svg_path_to_vector_path(path_data : String) -> @vector.Path {
  let commands = @msvg.parse_path(path_data)
  let path = @vector.Path::new()
  let mut cx = 0.0
  let mut cy = 0.0
  let mut last_cp_x = 0.0
  let mut last_cp_y = 0.0
  for cmd in commands {
    match cmd {
      @msvg.PathCommand::MoveTo(x, y) => {
        path.move_to(x, y)
        cx = x
        cy = y
      }
      @msvg.PathCommand::MoveToRel(dx, dy) => {
        let x = cx + dx
        let y = cy + dy
        path.move_to(x, y)
        cx = x
        cy = y
      }
      @msvg.PathCommand::LineTo(x, y) => {
        path.line_to(x, y)
        cx = x
        cy = y
      }
      @msvg.PathCommand::LineToRel(dx, dy) => {
        let x = cx + dx
        let y = cy + dy
        path.line_to(x, y)
        cx = x
        cy = y
      }
      @msvg.PathCommand::HorizontalLineTo(x) => {
        path.line_to(x, cy)
        cx = x
      }
      @msvg.PathCommand::HorizontalLineToRel(dx) => {
        let x = cx + dx
        path.line_to(x, cy)
        cx = x
      }
      @msvg.PathCommand::VerticalLineTo(y) => {
        path.line_to(cx, y)
        cy = y
      }
      @msvg.PathCommand::VerticalLineToRel(dy) => {
        let y = cy + dy
        path.line_to(cx, y)
        cy = y
      }
      @msvg.PathCommand::CurveTo(x1, y1, x2, y2, x, y) => {
        path.cubic_to(x1, y1, x2, y2, x, y)
        last_cp_x = x2
        last_cp_y = y2
        cx = x
        cy = y
      }
      @msvg.PathCommand::CurveToRel(dx1, dy1, dx2, dy2, dx, dy) => {
        let x1 = cx + dx1
        let y1 = cy + dy1
        let x2 = cx + dx2
        let y2 = cy + dy2
        let x = cx + dx
        let y = cy + dy
        path.cubic_to(x1, y1, x2, y2, x, y)
        last_cp_x = x2
        last_cp_y = y2
        cx = x
        cy = y
      }
      @msvg.PathCommand::SmoothCurveTo(x2, y2, x, y) => {
        let x1 = 2.0 * cx - last_cp_x
        let y1 = 2.0 * cy - last_cp_y
        path.cubic_to(x1, y1, x2, y2, x, y)
        last_cp_x = x2
        last_cp_y = y2
        cx = x
        cy = y
      }
      @msvg.PathCommand::SmoothCurveToRel(dx2, dy2, dx, dy) => {
        let x1 = 2.0 * cx - last_cp_x
        let y1 = 2.0 * cy - last_cp_y
        let x2 = cx + dx2
        let y2 = cy + dy2
        let x = cx + dx
        let y = cy + dy
        path.cubic_to(x1, y1, x2, y2, x, y)
        last_cp_x = x2
        last_cp_y = y2
        cx = x
        cy = y
      }
      @msvg.PathCommand::QuadraticCurveTo(x1, y1, x, y) => {
        path.quad_to(x1, y1, x, y)
        last_cp_x = x1
        last_cp_y = y1
        cx = x
        cy = y
      }
      @msvg.PathCommand::QuadraticCurveToRel(dx1, dy1, dx, dy) => {
        let x1 = cx + dx1
        let y1 = cy + dy1
        let x = cx + dx
        let y = cy + dy
        path.quad_to(x1, y1, x, y)
        last_cp_x = x1
        last_cp_y = y1
        cx = x
        cy = y
      }
      @msvg.PathCommand::SmoothQuadraticCurveTo(x, y) => {
        let cpx = 2.0 * cx - last_cp_x
        let cpy = 2.0 * cy - last_cp_y
        path.quad_to(cpx, cpy, x, y)
        last_cp_x = cpx
        last_cp_y = cpy
        cx = x
        cy = y
      }
      @msvg.PathCommand::SmoothQuadraticCurveToRel(dx, dy) => {
        let cpx = 2.0 * cx - last_cp_x
        let cpy = 2.0 * cy - last_cp_y
        let x = cx + dx
        let y = cy + dy
        path.quad_to(cpx, cpy, x, y)
        last_cp_x = cpx
        last_cp_y = cpy
        cx = x
        cy = y
      }
      @msvg.PathCommand::ArcTo(rx, ry, _, _, _, x, y) => {
        // Approximate arc with line for now
        // Full arc-to-bezier conversion is complex
        let _ = rx
        let _ = ry
        path.line_to(x, y)
        cx = x
        cy = y
      }
      @msvg.PathCommand::ArcToRel(rx, ry, _, _, _, dx, dy) => {
        let _ = rx
        let _ = ry
        let x = cx + dx
        let y = cy + dy
        path.line_to(x, y)
        cx = x
        cy = y
      }
      @msvg.PathCommand::ClosePath => path.close()
    }
  }
  path
}

///|
/// Parse an SVG path string and flatten to vertices for stroke rendering.
pub fn svg_path_to_stroke_vertices(
  path_data : String,
  width : Double,
  tolerance : Double,
) -> (Array[Double], Array[Int]) {
  let path = svg_path_to_vector_path(path_data)
  let points = path.flatten(tolerance)
  @vector.stroke_path(points, width)
}

///|
/// Parse an SVG path string and flatten to vertices for fill rendering.
pub fn svg_path_to_fill_vertices(
  path_data : String,
  tolerance : Double,
) -> (Array[Double], Array[Int]) {
  let path = svg_path_to_vector_path(path_data)
  let points = path.flatten(tolerance)
  @vector.fill_path(points)
}

///|
/// Create an ImageSpec-compatible RGBA8 pixel array from an SVG.
/// Useful for uploading SVG renders as textures.
pub struct SVGRenderResult {
  width : Int
  height : Int
  pixels : Array[Int]
} derive(Show)

///|
pub fn render_svg(
  svg_source : String,
  width : Int,
  height : Int,
) -> SVGRenderResult? {
  match render_svg_to_rgba(svg_source, width, height) {
    Some((w, h, pixels)) => Some({ width: w, height: h, pixels })
    None => None
  }
}
