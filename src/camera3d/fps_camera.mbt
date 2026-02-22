///|
pub struct FPSCamera {
  position : @math3d.Vec3
  yaw : Double
  pitch : Double
  fov_y_rad : Double
  aspect : Double
  near : Double
  far : Double
}

///|
pub fn FPSCamera::new(
  position : @math3d.Vec3,
  yaw : Double,
  pitch : Double,
  fov_y_rad : Double,
  aspect : Double,
  near : Double,
  far : Double,
) -> FPSCamera {
  { position, yaw, pitch: clamp_pitch(pitch), fov_y_rad, aspect, near, far }
}

///|
pub fn FPSCamera::default() -> FPSCamera {
  FPSCamera::new(
    @math3d.Vec3::new(0.0, 1.7, 5.0),
    0.0,
    0.0,
    @math.PI / 4.0,
    16.0 / 9.0,
    0.1,
    100.0,
  )
}

///|
pub fn FPSCamera::look(
  self : FPSCamera,
  delta_yaw : Double,
  delta_pitch : Double,
) -> FPSCamera {
  {
    ..self,
    yaw: self.yaw + delta_yaw,
    pitch: clamp_pitch(self.pitch + delta_pitch),
  }
}

///|
pub fn FPSCamera::orientation(self : FPSCamera) -> @math3d.Quaternion {
  yaw_pitch_orientation(self.yaw, self.pitch)
}

///|
pub fn FPSCamera::forward(self : FPSCamera) -> @math3d.Vec3 {
  self.orientation().rotate_vec3(@math3d.Vec3::new(0.0, 0.0, -1.0))
}

///|
pub fn FPSCamera::right(self : FPSCamera) -> @math3d.Vec3 {
  self.orientation().rotate_vec3(@math3d.Vec3::unit_x())
}

///|
pub fn FPSCamera::move_forward(self : FPSCamera, delta : Double) -> FPSCamera {
  let dir = self.forward()
  { ..self, position: self.position.add(dir.scale(delta)) }
}

///|
pub fn FPSCamera::move_right(self : FPSCamera, delta : Double) -> FPSCamera {
  let dir = self.right()
  { ..self, position: self.position.add(dir.scale(delta)) }
}

///|
pub fn FPSCamera::move_up(self : FPSCamera, delta : Double) -> FPSCamera {
  { ..self, position: self.position.add(@math3d.Vec3::unit_y().scale(delta)) }
}

///|
pub fn FPSCamera::to_camera3d(self : FPSCamera) -> Camera3D {
  let fwd = self.forward()
  let target = self.position.add(fwd)
  Camera3D::new_perspective(
    self.position,
    target,
    @math3d.Vec3::unit_y(),
    self.fov_y_rad,
    self.aspect,
    self.near,
    self.far,
  )
}
