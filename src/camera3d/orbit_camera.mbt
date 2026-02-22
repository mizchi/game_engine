///|
pub struct OrbitCamera {
  target : @math3d.Vec3
  distance : Double
  yaw : Double
  pitch : Double
  fov_y_rad : Double
  aspect : Double
  near : Double
  far : Double
}

///|
pub fn OrbitCamera::new(
  target : @math3d.Vec3,
  distance : Double,
  yaw : Double,
  pitch : Double,
  fov_y_rad : Double,
  aspect : Double,
  near : Double,
  far : Double,
) -> OrbitCamera {
  {
    target,
    distance,
    yaw,
    pitch: clamp_pitch(pitch),
    fov_y_rad,
    aspect,
    near,
    far,
  }
}

///|
pub fn OrbitCamera::default() -> OrbitCamera {
  OrbitCamera::new(
    @math3d.Vec3::zero(),
    5.0,
    0.0,
    0.3,
    @math.PI / 4.0,
    16.0 / 9.0,
    0.1,
    100.0,
  )
}

///|
pub fn OrbitCamera::orbit(
  self : OrbitCamera,
  delta_yaw : Double,
  delta_pitch : Double,
) -> OrbitCamera {
  {
    ..self,
    yaw: self.yaw + delta_yaw,
    pitch: clamp_pitch(self.pitch + delta_pitch),
  }
}

///|
pub fn OrbitCamera::zoom(self : OrbitCamera, delta : Double) -> OrbitCamera {
  let d = self.distance + delta
  let clamped = if d < 0.1 { 0.1 } else { d }
  { ..self, distance: clamped }
}

///|
pub fn OrbitCamera::pan(
  self : OrbitCamera,
  delta_right : Double,
  delta_up : Double,
) -> OrbitCamera {
  let orient = self.orientation()
  let right = orient.rotate_vec3(@math3d.Vec3::unit_x())
  let up = orient.rotate_vec3(@math3d.Vec3::unit_y())
  let offset = right.scale(delta_right).add(up.scale(delta_up))
  { ..self, target: self.target.add(offset) }
}

///|
pub fn OrbitCamera::with_target(
  self : OrbitCamera,
  target : @math3d.Vec3,
) -> OrbitCamera {
  { ..self, target }
}

///|
pub fn OrbitCamera::with_distance(
  self : OrbitCamera,
  distance : Double,
) -> OrbitCamera {
  { ..self, distance }
}

///|
/// Camera view orientation (looking from position toward target).
/// Negates pitch so positive pitch = camera above target, looking down.
pub fn OrbitCamera::orientation(self : OrbitCamera) -> @math3d.Quaternion {
  yaw_pitch_orientation(self.yaw, -self.pitch)
}

///|
/// Camera world position computed from spherical coordinates.
/// Positive pitch = elevation above target.
pub fn OrbitCamera::position(self : OrbitCamera) -> @math3d.Vec3 {
  let cp = @math.cos(self.pitch)
  let sp = @math.sin(self.pitch)
  let cy = @math.cos(self.yaw)
  let sy = @math.sin(self.yaw)
  let offset = @math3d.Vec3::new(
    self.distance * cp * sy,
    self.distance * sp,
    self.distance * cp * cy,
  )
  self.target.add(offset)
}

///|
pub fn OrbitCamera::to_camera3d(self : OrbitCamera) -> Camera3D {
  Camera3D::new_perspective(
    self.position(),
    self.target,
    @math3d.Vec3::unit_y(),
    self.fov_y_rad,
    self.aspect,
    self.near,
    self.far,
  )
}
