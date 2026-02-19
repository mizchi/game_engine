///|
/// Path-based vector drawing utilities.
///
/// Reference:
/// - Ebiten vector.Path (MoveTo/LineTo/QuadTo/CubicTo/ArcTo/Close)
/// - SVG path commands

///|
pub(all) enum PathCommand {
  MoveTo(Double, Double)
  LineTo(Double, Double)
  QuadTo(Double, Double, Double, Double)
  CubicTo(Double, Double, Double, Double, Double, Double)
  Close
}

///|
pub struct Path {
  commands : Array[PathCommand]
  mut current_x : Double
  mut current_y : Double
  mut start_x : Double
  mut start_y : Double
}

///|
pub fn Path::new() -> Path {
  { commands: [], current_x: 0.0, current_y: 0.0, start_x: 0.0, start_y: 0.0 }
}

///|
pub fn Path::move_to(self : Path, x : Double, y : Double) -> Unit {
  self.commands.push(MoveTo(x, y))
  self.current_x = x
  self.current_y = y
  self.start_x = x
  self.start_y = y
}

///|
pub fn Path::line_to(self : Path, x : Double, y : Double) -> Unit {
  self.commands.push(LineTo(x, y))
  self.current_x = x
  self.current_y = y
}

///|
/// Quadratic bezier curve to (x, y) with control point (cpx, cpy).
pub fn Path::quad_to(
  self : Path,
  cpx : Double,
  cpy : Double,
  x : Double,
  y : Double,
) -> Unit {
  self.commands.push(QuadTo(cpx, cpy, x, y))
  self.current_x = x
  self.current_y = y
}

///|
/// Cubic bezier curve to (x, y) with control points (cp1x, cp1y) and (cp2x, cp2y).
pub fn Path::cubic_to(
  self : Path,
  cp1x : Double,
  cp1y : Double,
  cp2x : Double,
  cp2y : Double,
  x : Double,
  y : Double,
) -> Unit {
  self.commands.push(CubicTo(cp1x, cp1y, cp2x, cp2y, x, y))
  self.current_x = x
  self.current_y = y
}

///|
/// Arc from current point around center (cx, cy) with radius r,
/// from start_angle to end_angle (radians, counter-clockwise).
pub fn Path::arc_to(
  self : Path,
  cx : Double,
  cy : Double,
  r : Double,
  start_angle : Double,
  end_angle : Double,
  segments : Int,
) -> Unit {
  let n = if segments < 3 { 3 } else { segments }
  let da = (end_angle - start_angle) / n.to_double()
  let sx = cx + r * @math.cos(start_angle)
  let sy = cy + r * @math.sin(start_angle)
  if self.commands.length() == 0 {
    self.move_to(sx, sy)
  } else {
    self.line_to(sx, sy)
  }
  for i = 1; i <= n; i = i + 1 {
    let angle = start_angle + da * i.to_double()
    let x = cx + r * @math.cos(angle)
    let y = cy + r * @math.sin(angle)
    self.line_to(x, y)
  }
}

///|
pub fn Path::close(self : Path) -> Unit {
  self.commands.push(Close)
  self.current_x = self.start_x
  self.current_y = self.start_y
}

///|
pub fn Path::command_count(self : Path) -> Int {
  self.commands.length()
}

///|
/// Flatten all curves into line segments with the given tolerance.
pub fn Path::flatten(self : Path, tolerance : Double) -> Array[Vec2] {
  let points : Array[Vec2] = []
  let mut cx = 0.0
  let mut cy = 0.0
  let mut sx = 0.0
  let mut sy = 0.0
  for cmd in self.commands {
    match cmd {
      MoveTo(x, y) => {
        points.push(Vec2::new(x, y))
        cx = x
        cy = y
        sx = x
        sy = y
      }
      LineTo(x, y) => {
        points.push(Vec2::new(x, y))
        cx = x
        cy = y
      }
      QuadTo(cpx, cpy, x, y) => {
        flatten_quad(points, cx, cy, cpx, cpy, x, y, tolerance)
        cx = x
        cy = y
      }
      CubicTo(cp1x, cp1y, cp2x, cp2y, x, y) => {
        flatten_cubic(points, cx, cy, cp1x, cp1y, cp2x, cp2y, x, y, tolerance)
        cx = x
        cy = y
      }
      Close => {
        if (cx - sx).abs() > 1.0e-9 || (cy - sy).abs() > 1.0e-9 {
          points.push(Vec2::new(sx, sy))
        }
        cx = sx
        cy = sy
      }
    }
  }
  points
}

///|
/// Flatten a quadratic bezier curve using recursive subdivision.
fn flatten_quad(
  points : Array[Vec2],
  x0 : Double,
  y0 : Double,
  cpx : Double,
  cpy : Double,
  x1 : Double,
  y1 : Double,
  tolerance : Double,
) -> Unit {
  // Flatness test: distance from control point to midpoint of line
  let mx = (x0 + x1) / 2.0
  let my = (y0 + y1) / 2.0
  let dx = cpx - mx
  let dy = cpy - my
  let dist_sq = dx * dx + dy * dy
  if dist_sq <= tolerance * tolerance {
    points.push(Vec2::new(x1, y1))
  } else {
    // Subdivide
    let qx0 = (x0 + cpx) / 2.0
    let qy0 = (y0 + cpy) / 2.0
    let qx1 = (cpx + x1) / 2.0
    let qy1 = (cpy + y1) / 2.0
    let rx = (qx0 + qx1) / 2.0
    let ry = (qy0 + qy1) / 2.0
    flatten_quad(points, x0, y0, qx0, qy0, rx, ry, tolerance)
    flatten_quad(points, rx, ry, qx1, qy1, x1, y1, tolerance)
  }
}

///|
/// Flatten a cubic bezier curve using recursive subdivision.
fn flatten_cubic(
  points : Array[Vec2],
  x0 : Double,
  y0 : Double,
  cp1x : Double,
  cp1y : Double,
  cp2x : Double,
  cp2y : Double,
  x1 : Double,
  y1 : Double,
  tolerance : Double,
) -> Unit {
  // Flatness test: max distance from control points to line
  let dx = x1 - x0
  let dy = y1 - y0
  let len_sq = dx * dx + dy * dy
  if len_sq < 1.0e-12 {
    // Degenerate line
    let d1_sq = (cp1x - x0) * (cp1x - x0) + (cp1y - y0) * (cp1y - y0)
    let d2_sq = (cp2x - x0) * (cp2x - x0) + (cp2y - y0) * (cp2y - y0)
    if d1_sq <= tolerance * tolerance && d2_sq <= tolerance * tolerance {
      points.push(Vec2::new(x1, y1))
      return
    }
  } else {
    let inv_len_sq = 1.0 / len_sq
    // Distance of cp1 from line
    let t1 = ((cp1x - x0) * dx + (cp1y - y0) * dy) * inv_len_sq
    let px1 = x0 + t1 * dx
    let py1 = y0 + t1 * dy
    let d1x = cp1x - px1
    let d1y = cp1y - py1
    let d1_sq = d1x * d1x + d1y * d1y
    // Distance of cp2 from line
    let t2 = ((cp2x - x0) * dx + (cp2y - y0) * dy) * inv_len_sq
    let px2 = x0 + t2 * dx
    let py2 = y0 + t2 * dy
    let d2x = cp2x - px2
    let d2y = cp2y - py2
    let d2_sq = d2x * d2x + d2y * d2y
    let tol_sq = tolerance * tolerance
    if d1_sq <= tol_sq && d2_sq <= tol_sq {
      points.push(Vec2::new(x1, y1))
      return
    }
  }
  // Subdivide using de Casteljau
  let ax = (x0 + cp1x) / 2.0
  let ay = (y0 + cp1y) / 2.0
  let bx = (cp1x + cp2x) / 2.0
  let by = (cp1y + cp2y) / 2.0
  let cx = (cp2x + x1) / 2.0
  let cy = (cp2y + y1) / 2.0
  let abx = (ax + bx) / 2.0
  let aby = (ay + by) / 2.0
  let bcx = (bx + cx) / 2.0
  let bcy = (by + cy) / 2.0
  let mx = (abx + bcx) / 2.0
  let my = (aby + bcy) / 2.0
  flatten_cubic(points, x0, y0, ax, ay, abx, aby, mx, my, tolerance)
  flatten_cubic(points, mx, my, bcx, bcy, cx, cy, x1, y1, tolerance)
}

///|
/// Generate stroke (outline) vertices from flattened path points.
/// Returns (vertex_data, indices) where each vertex is [x, y, u, v].
pub fn stroke_path(
  points : Array[Vec2],
  width : Double,
) -> (Array[Double], Array[Int]) {
  let vertices : Array[Double] = []
  let indices : Array[Int] = []
  let half_w = width / 2.0
  let n = points.length()
  if n < 2 {
    return (vertices, indices)
  }
  let mut vert_index = 0
  for i = 0; i < n - 1; i = i + 1 {
    let p0 = points[i]
    let p1 = points[i + 1]
    let dir = p1.sub(p0).normalize()
    let perp = dir.perpendicular().scale(half_w)
    // Four corners of the line quad
    let u = i.to_double() / (n - 1).to_double()
    let u_next = (i + 1).to_double() / (n - 1).to_double()
    vertices.push(p0.x + perp.x)
    vertices.push(p0.y + perp.y)
    vertices.push(u)
    vertices.push(0.0)
    vertices.push(p1.x + perp.x)
    vertices.push(p1.y + perp.y)
    vertices.push(u_next)
    vertices.push(0.0)
    vertices.push(p1.x - perp.x)
    vertices.push(p1.y - perp.y)
    vertices.push(u_next)
    vertices.push(1.0)
    vertices.push(p0.x - perp.x)
    vertices.push(p0.y - perp.y)
    vertices.push(u)
    vertices.push(1.0)
    indices.push(vert_index)
    indices.push(vert_index + 1)
    indices.push(vert_index + 2)
    indices.push(vert_index + 2)
    indices.push(vert_index + 3)
    indices.push(vert_index)
    vert_index = vert_index + 4
  }
  (vertices, indices)
}

///|
/// Generate fill vertices from flattened path points using fan triangulation.
/// Assumes the polygon is convex or simple (uses fan from first vertex).
/// Returns (vertex_data, indices) where each vertex is [x, y, u, v].
pub fn fill_path(points : Array[Vec2]) -> (Array[Double], Array[Int]) {
  let vertices : Array[Double] = []
  let indices : Array[Int] = []
  let n = points.length()
  if n < 3 {
    return (vertices, indices)
  }
  // Compute bounding box for UV mapping
  let mut min_x = points[0].x
  let mut min_y = points[0].y
  let mut max_x = points[0].x
  let mut max_y = points[0].y
  for p in points {
    if p.x < min_x {
      min_x = p.x
    }
    if p.y < min_y {
      min_y = p.y
    }
    if p.x > max_x {
      max_x = p.x
    }
    if p.y > max_y {
      max_y = p.y
    }
  }
  let range_x = max_x - min_x
  let range_y = max_y - min_y
  let inv_rx = if range_x > 1.0e-12 { 1.0 / range_x } else { 0.0 }
  let inv_ry = if range_y > 1.0e-12 { 1.0 / range_y } else { 0.0 }
  // Emit vertices with UV
  for p in points {
    vertices.push(p.x)
    vertices.push(p.y)
    vertices.push((p.x - min_x) * inv_rx)
    vertices.push((p.y - min_y) * inv_ry)
  }
  // Fan triangulation from vertex 0
  for i = 1; i < n - 1; i = i + 1 {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }
  (vertices, indices)
}
