///|
fn approx_d(a : Double, b : Double) -> Bool {
  (a - b).abs() < 0.01
}

///|
test "Path move_to and line_to" {
  let path = Path::new()
  path.move_to(0.0, 0.0)
  path.line_to(10.0, 0.0)
  path.line_to(10.0, 10.0)
  assert_eq!(path.command_count(), 3)
  let points = path.flatten(1.0)
  assert_eq!(points.length(), 3)
  assert_eq!(points[0].x, 0.0)
  assert_eq!(points[0].y, 0.0)
  assert_eq!(points[1].x, 10.0)
  assert_eq!(points[1].y, 0.0)
  assert_eq!(points[2].x, 10.0)
  assert_eq!(points[2].y, 10.0)
}

///|
test "Path close" {
  let path = Path::new()
  path.move_to(0.0, 0.0)
  path.line_to(10.0, 0.0)
  path.line_to(10.0, 10.0)
  path.close()
  let points = path.flatten(1.0)
  // close should add the start point back
  assert_eq!(points.length(), 4)
  assert_eq!(points[3].x, 0.0)
  assert_eq!(points[3].y, 0.0)
}

///|
test "Path quad_to flattens to multiple segments" {
  let path = Path::new()
  path.move_to(0.0, 0.0)
  path.quad_to(50.0, 100.0, 100.0, 0.0)
  let points = path.flatten(1.0)
  // Quadratic curve should produce more than 2 points
  assert_true!(points.length() > 2)
  // First point
  assert_eq!(points[0].x, 0.0)
  assert_eq!(points[0].y, 0.0)
  // Last point should be at (100, 0)
  let last = points[points.length() - 1]
  assert_true!(approx_d(last.x, 100.0))
  assert_true!(approx_d(last.y, 0.0))
}

///|
test "Path cubic_to flattens to multiple segments" {
  let path = Path::new()
  path.move_to(0.0, 0.0)
  path.cubic_to(33.0, 100.0, 66.0, -50.0, 100.0, 0.0)
  let points = path.flatten(1.0)
  assert_true!(points.length() > 2)
  let last = points[points.length() - 1]
  assert_true!(approx_d(last.x, 100.0))
  assert_true!(approx_d(last.y, 0.0))
}

///|
test "Path arc_to generates arc segments" {
  let pi = 3.14159265358979323846
  let path = Path::new()
  // Full circle with 16 segments
  path.arc_to(50.0, 50.0, 25.0, 0.0, pi * 2.0, 16)
  let points = path.flatten(1.0)
  // arc_to with 16 segments: 1 move_to + 16 line_to = 17 commands -> 17 points
  assert_eq!(points.length(), 17)
  // First point should be at (75, 50) - center + radius on x-axis
  assert_true!(approx_d(points[0].x, 75.0))
  assert_true!(approx_d(points[0].y, 50.0))
  // Last point should be close to first (full circle)
  let last = points[points.length() - 1]
  assert_true!(approx_d(last.x, 75.0))
  assert_true!(approx_d(last.y, 50.0))
}

///|
test "stroke_path generates quads" {
  let path = Path::new()
  path.move_to(0.0, 0.0)
  path.line_to(10.0, 0.0)
  path.line_to(10.0, 10.0)
  let points = path.flatten(1.0)
  let (vertices, indices) = stroke_path(points, 2.0)
  // 3 points = 2 segments = 2 quads = 8 vertices (4 doubles each) = 32
  assert_eq!(vertices.length(), 32)
  // 2 quads = 12 indices
  assert_eq!(indices.length(), 12)
}

///|
test "stroke_path degenerate" {
  let points : Array[Vec2] = [Vec2::new(5.0, 5.0)]
  let (vertices, indices) = stroke_path(points, 1.0)
  assert_eq!(vertices.length(), 0)
  assert_eq!(indices.length(), 0)
}

///|
test "fill_path triangle" {
  let points = [
    Vec2::new(0.0, 0.0),
    Vec2::new(10.0, 0.0),
    Vec2::new(5.0, 10.0),
  ]
  let (vertices, indices) = fill_path(points)
  // 3 vertices * 4 components = 12
  assert_eq!(vertices.length(), 12)
  // 1 triangle = 3 indices
  assert_eq!(indices.length(), 3)
  assert_eq!(indices[0], 0)
  assert_eq!(indices[1], 1)
  assert_eq!(indices[2], 2)
}

///|
test "fill_path quad" {
  let points = [
    Vec2::new(0.0, 0.0),
    Vec2::new(10.0, 0.0),
    Vec2::new(10.0, 10.0),
    Vec2::new(0.0, 10.0),
  ]
  let (vertices, indices) = fill_path(points)
  // 4 vertices * 4 components = 16
  assert_eq!(vertices.length(), 16)
  // 2 triangles = 6 indices
  assert_eq!(indices.length(), 6)
  // UV mapping: (0,0) -> u=0,v=0; (10,10) -> u=1,v=1
  assert_true!(approx_d(vertices[2], 0.0)) // u of vertex 0
  assert_true!(approx_d(vertices[3], 0.0)) // v of vertex 0
  assert_true!(approx_d(vertices[10], 1.0)) // u of vertex 2 (10,10)
  assert_true!(approx_d(vertices[11], 1.0)) // v of vertex 2 (10,10)
}

///|
test "fill_path degenerate" {
  let points = [Vec2::new(0.0, 0.0), Vec2::new(1.0, 1.0)]
  let (vertices, indices) = fill_path(points)
  assert_eq!(vertices.length(), 0)
  assert_eq!(indices.length(), 0)
}
