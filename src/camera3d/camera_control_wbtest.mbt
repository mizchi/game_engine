///|
fn approx_eq(a : Double, b : Double, epsilon : Double) -> Bool {
  (a - b).abs() < epsilon
}

///|
let eps : Double = 1.0e-4

// ============================================================
// OrbitCamera
// ============================================================

///|
test "OrbitCamera default position" {
  let cam = OrbitCamera::default()
  let pos = cam.position()
  // yaw=0, pitch=0.3: camera behind and above target
  // offset = orient.rotate(0,0,distance)
  // At yaw=0, pitch=0.3: z = distance * cos(pitch) ≈ 4.778
  // y = distance * sin(pitch) ≈ 1.478
  assert_true(approx_eq(pos.x, 0.0, eps))
  assert_true(pos.y > 1.0)
  assert_true(pos.z > 4.0)
}

///|
test "OrbitCamera to_camera3d" {
  let cam = OrbitCamera::default()
  let c3d = cam.to_camera3d()
  let pos = cam.position()
  assert_true(c3d.position.approx_eq(pos, eps))
  assert_true(c3d.target.approx_eq(@math3d.Vec3::zero(), eps))
}

///|
test "OrbitCamera orbit changes position" {
  let cam = OrbitCamera::default()
  let pos0 = cam.position()
  let cam2 = cam.orbit(0.5, 0.0)
  let pos1 = cam2.position()
  // yaw changed, so x should differ
  assert_true((pos0.x - pos1.x).abs() > 0.1)
}

///|
test "OrbitCamera orbit pitch clamp" {
  let cam = OrbitCamera::new(
    @math3d.Vec3::zero(),
    5.0,
    0.0,
    0.0,
    @math.PI / 4.0,
    1.0,
    0.1,
    100.0,
  )
  let cam2 = cam.orbit(0.0, 100.0) // extreme pitch
  let limit = @math.PI / 2.0 - 0.01
  assert_true(cam2.pitch <= limit + eps)
}

///|
test "OrbitCamera zoom" {
  let cam = OrbitCamera::default()
  let cam2 = cam.zoom(-2.0)
  assert_true(approx_eq(cam2.distance, 3.0, eps))
  let cam3 = cam.zoom(-100.0) // clamp to min 0.1
  assert_true(approx_eq(cam3.distance, 0.1, eps))
}

///|
test "OrbitCamera pan" {
  let cam = OrbitCamera::new(
    @math3d.Vec3::zero(),
    5.0,
    0.0,
    0.0,
    @math.PI / 4.0,
    1.0,
    0.1,
    100.0,
  )
  let cam2 = cam.pan(1.0, 0.0) // pan right
  assert_true(cam2.target.x > 0.5)
  let cam3 = cam.pan(0.0, 1.0) // pan up
  assert_true(cam3.target.y > 0.5)
}

// ============================================================
// FPSCamera
// ============================================================

///|
test "FPSCamera default forward" {
  let cam = FPSCamera::default()
  let fwd = cam.forward()
  // yaw=0, pitch=0 => forward = (0, 0, -1)
  assert_true(fwd.approx_eq(@math3d.Vec3::new(0.0, 0.0, -1.0), eps))
}

///|
test "FPSCamera look changes direction" {
  let cam = FPSCamera::default()
  let cam2 = cam.look(@math.PI / 2.0, 0.0) // yaw +90 degrees
  let fwd = cam2.forward()
  // After 90 degree yaw, forward should be roughly (-1, 0, 0)
  assert_true(fwd.approx_eq(@math3d.Vec3::new(-1.0, 0.0, 0.0), eps))
}

///|
test "FPSCamera look pitch clamp" {
  let cam = FPSCamera::default()
  let cam2 = cam.look(0.0, 100.0) // extreme pitch
  let limit = @math.PI / 2.0 - 0.01
  assert_true(cam2.pitch <= limit + eps)
}

///|
test "FPSCamera move_forward" {
  let cam = FPSCamera::default()
  let cam2 = cam.move_forward(2.0)
  // forward = (0,0,-1), so z should decrease by 2
  assert_true(approx_eq(cam2.position.z, cam.position.z - 2.0, eps))
}

///|
test "FPSCamera move_right" {
  let cam = FPSCamera::default()
  let cam2 = cam.move_right(1.0)
  // right = (1,0,0) at default
  assert_true(approx_eq(cam2.position.x, cam.position.x + 1.0, eps))
}

///|
test "FPSCamera move_up" {
  let cam = FPSCamera::default()
  let cam2 = cam.move_up(1.0)
  assert_true(approx_eq(cam2.position.y, cam.position.y + 1.0, eps))
}

///|
test "FPSCamera to_camera3d" {
  let cam = FPSCamera::default()
  let c3d = cam.to_camera3d()
  assert_true(c3d.position.approx_eq(cam.position, eps))
  // target should be position + forward
  let expected_target = cam.position.add(cam.forward())
  assert_true(c3d.target.approx_eq(expected_target, eps))
}

// ============================================================
// SmoothCamera
// ============================================================

///|
test "SmoothCamera update converges" {
  let origin = @math3d.Vec3::zero()
  let target_pos = @math3d.Vec3::new(10.0, 0.0, 0.0)
  let ident = @math3d.Quaternion::identity()
  let cam = SmoothCamera::new(
    origin,
    ident,
    5.0,
    @math.PI / 4.0,
    1.0,
    0.1,
    100.0,
  )
  let cam2 = cam.set_target(target_pos, ident)
  // After several updates, position should approach target
  let mut c = cam2
  for _ in 0..<100 {
    c = c.update(0.1)
  }
  assert_true(c.current_position.approx_eq(target_pos, 0.01))
}

///|
test "SmoothCamera snap" {
  let origin = @math3d.Vec3::zero()
  let target_pos = @math3d.Vec3::new(10.0, 5.0, 3.0)
  let ident = @math3d.Quaternion::identity()
  let cam = SmoothCamera::new(
    origin,
    ident,
    5.0,
    @math.PI / 4.0,
    1.0,
    0.1,
    100.0,
  )
  let cam2 = cam.set_target(target_pos, ident).snap()
  assert_true(cam2.current_position.approx_eq(target_pos, eps))
  assert_true(cam2.is_settled(eps))
}

///|
test "SmoothCamera is_settled" {
  let origin = @math3d.Vec3::zero()
  let ident = @math3d.Quaternion::identity()
  let cam = SmoothCamera::new(
    origin,
    ident,
    5.0,
    @math.PI / 4.0,
    1.0,
    0.1,
    100.0,
  )
  // Initially settled (target = current)
  assert_true(cam.is_settled(eps))
  // After setting target, not settled
  let cam2 = cam.set_target(@math3d.Vec3::new(10.0, 0.0, 0.0), ident)
  assert_true(not(cam2.is_settled(eps)))
}

///|
test "SmoothCamera set_target_look_at" {
  let origin = @math3d.Vec3::zero()
  let ident = @math3d.Quaternion::identity()
  let cam = SmoothCamera::new(
    origin,
    ident,
    5.0,
    @math.PI / 4.0,
    1.0,
    0.1,
    100.0,
  )
  let eye = @math3d.Vec3::new(0.0, 0.0, 5.0)
  let look_target = @math3d.Vec3::zero()
  let up = @math3d.Vec3::unit_y()
  let cam2 = cam.set_target_look_at(eye, look_target, up).snap()
  let c3d = cam2.to_camera3d()
  // Camera should be at eye position
  assert_true(c3d.position.approx_eq(eye, eps))
  // Forward should point toward look_target (along -Z)
  let fwd = cam2.current_orientation.rotate_vec3(
    @math3d.Vec3::new(0.0, 0.0, -1.0),
  )
  let expected_fwd = look_target.sub(eye).normalize()
  assert_true(fwd.approx_eq(expected_fwd, eps))
}

///|
test "SmoothCamera to_camera3d" {
  let pos = @math3d.Vec3::new(0.0, 0.0, 5.0)
  let ident = @math3d.Quaternion::identity()
  let cam = SmoothCamera::new(
    pos,
    ident,
    5.0,
    @math.PI / 4.0,
    1.0,
    0.1,
    100.0,
  )
  let c3d = cam.to_camera3d()
  assert_true(c3d.position.approx_eq(pos, eps))
  // identity orientation: forward = (0,0,-1), target = pos + (0,0,-1)
  let expected_target = pos.add(@math3d.Vec3::new(0.0, 0.0, -1.0))
  assert_true(c3d.target.approx_eq(expected_target, eps))
}

// ============================================================
// Quaternion orientation
// ============================================================

///|
test "yaw_pitch_orientation forward vector" {
  // yaw=0, pitch=0 => forward = (0, 0, -1)
  let q = yaw_pitch_orientation(0.0, 0.0)
  let fwd = q.rotate_vec3(@math3d.Vec3::new(0.0, 0.0, -1.0))
  assert_true(fwd.approx_eq(@math3d.Vec3::new(0.0, 0.0, -1.0), eps))
  // yaw=PI/2, pitch=0 => forward = (-1, 0, 0)
  let q2 = yaw_pitch_orientation(@math.PI / 2.0, 0.0)
  let fwd2 = q2.rotate_vec3(@math3d.Vec3::new(0.0, 0.0, -1.0))
  assert_true(fwd2.approx_eq(@math3d.Vec3::new(-1.0, 0.0, 0.0), eps))
}

///|
test "clamp_pitch within range" {
  let limit = @math.PI / 2.0 - 0.01
  assert_true(approx_eq(clamp_pitch(0.5), 0.5, eps))
  assert_true(approx_eq(clamp_pitch(100.0), limit, eps))
  assert_true(approx_eq(clamp_pitch(-100.0), -limit, eps))
}
