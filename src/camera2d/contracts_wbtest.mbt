///|
test "Camera2D::new initializes at origin" {
  let cam = Camera2D::new(320.0, 240.0, 960.0, 720.0)
  inspect!(cam.x, content="0")
  inspect!(cam.y, content="0")
}

///|
test "Camera2D::follow_target centers on target" {
  let cam = Camera2D::new(320.0, 240.0, 960.0, 720.0)
  cam.follow_target(480.0, 360.0)
  // 480 - 160 = 320, 360 - 120 = 240
  inspect!(cam.x, content="320")
  inspect!(cam.y, content="240")
}

///|
test "Camera2D::follow_target clamps at left-top" {
  let cam = Camera2D::new(320.0, 240.0, 960.0, 720.0)
  cam.follow_target(0.0, 0.0)
  inspect!(cam.x, content="0")
  inspect!(cam.y, content="0")
}

///|
test "Camera2D::follow_target clamps at right-bottom" {
  let cam = Camera2D::new(320.0, 240.0, 960.0, 720.0)
  cam.follow_target(960.0, 720.0)
  // max_x = 960-320=640, max_y = 720-240=480
  inspect!(cam.x, content="640")
  inspect!(cam.y, content="480")
}

///|
test "Camera2D::world_to_screen converts correctly" {
  let cam = Camera2D::new(320.0, 240.0, 960.0, 720.0)
  cam.follow_target(480.0, 360.0)
  let sx = cam.world_to_screen_x(480.0)
  let sy = cam.world_to_screen_y(360.0)
  // Player should be at screen center: 480-320=160, 360-240=120
  inspect!(sx, content="160")
  inspect!(sy, content="120")
}

///|
test "Camera2D::follow_target degenerate case (screen >= world)" {
  let cam = Camera2D::new(320.0, 240.0, 100.0, 100.0)
  cam.follow_target(50.0, 50.0)
  // world < screen: clamp keeps at 0
  inspect!(cam.x, content="0")
  inspect!(cam.y, content="0")
}
