///|
pub struct SmoothCamera {
  current_position : @math3d.Vec3
  current_orientation : @math3d.Quaternion
  target_position : @math3d.Vec3
  target_orientation : @math3d.Quaternion
  speed : Double
  fov_y_rad : Double
  aspect : Double
  near : Double
  far : Double
}

///|
pub fn SmoothCamera::new(
  position : @math3d.Vec3,
  orientation : @math3d.Quaternion,
  speed : Double,
  fov_y_rad : Double,
  aspect : Double,
  near : Double,
  far : Double,
) -> SmoothCamera {
  {
    current_position: position,
    current_orientation: orientation,
    target_position: position,
    target_orientation: orientation,
    speed,
    fov_y_rad,
    aspect,
    near,
    far,
  }
}

///|
pub fn SmoothCamera::set_target(
  self : SmoothCamera,
  position : @math3d.Vec3,
  orientation : @math3d.Quaternion,
) -> SmoothCamera {
  { ..self, target_position: position, target_orientation: orientation }
}

///|
pub fn SmoothCamera::set_target_look_at(
  self : SmoothCamera,
  position : @math3d.Vec3,
  target : @math3d.Vec3,
  up : @math3d.Vec3,
) -> SmoothCamera {
  let orientation = look_at_orientation(position, target, up)
  { ..self, target_position: position, target_orientation: orientation }
}

///|
pub fn SmoothCamera::update(self : SmoothCamera, dt : Double) -> SmoothCamera {
  let raw = self.speed * dt
  let t = if raw > 1.0 { 1.0 } else if raw < 0.0 { 0.0 } else { raw }
  let pos = self.current_position.lerp(self.target_position, t)
  let orient = self.current_orientation.slerp(self.target_orientation, t)
  { ..self, current_position: pos, current_orientation: orient }
}

///|
pub fn SmoothCamera::snap(self : SmoothCamera) -> SmoothCamera {
  {
    ..self,
    current_position: self.target_position,
    current_orientation: self.target_orientation,
  }
}

///|
pub fn SmoothCamera::is_settled(
  self : SmoothCamera,
  epsilon : Double,
) -> Bool {
  self.current_position.approx_eq(self.target_position, epsilon) &&
  self.current_orientation.approx_eq(self.target_orientation, epsilon)
}

///|
pub fn SmoothCamera::to_camera3d(self : SmoothCamera) -> Camera3D {
  let fwd = self.current_orientation.rotate_vec3(
    @math3d.Vec3::new(0.0, 0.0, -1.0),
  )
  let target = self.current_position.add(fwd)
  Camera3D::new_perspective(
    self.current_position,
    target,
    @math3d.Vec3::unit_y(),
    self.fov_y_rad,
    self.aspect,
    self.near,
    self.far,
  )
}

///|
/// Compute orientation quaternion from a look-at specification.
fn look_at_orientation(
  eye : @math3d.Vec3,
  target : @math3d.Vec3,
  up : @math3d.Vec3,
) -> @math3d.Quaternion {
  let fwd = target.sub(eye).normalize()
  let right = fwd.cross(up).normalize()
  let actual_up = right.cross(fwd)
  // Build rotation matrix columns (camera looks along -Z)
  // right = +X, actual_up = +Y, -fwd = +Z
  let m00 = right.x
  let m01 = right.y
  let m02 = right.z
  let m10 = actual_up.x
  let m11 = actual_up.y
  let m12 = actual_up.z
  let m20 = -fwd.x
  let m21 = -fwd.y
  let m22 = -fwd.z
  // Convert rotation matrix to quaternion (Shepperd's method)
  let trace = m00 + m11 + m22
  if trace > 0.0 {
    let s = (trace + 1.0).sqrt() * 2.0
    @math3d.Quaternion::new(
      (m12 - m21) / s,
      (m20 - m02) / s,
      (m01 - m10) / s,
      0.25 * s,
    ).normalize()
  } else if m00 > m11 && m00 > m22 {
    let s = (1.0 + m00 - m11 - m22).sqrt() * 2.0
    @math3d.Quaternion::new(
      0.25 * s,
      (m01 + m10) / s,
      (m20 + m02) / s,
      (m12 - m21) / s,
    ).normalize()
  } else if m11 > m22 {
    let s = (1.0 + m11 - m00 - m22).sqrt() * 2.0
    @math3d.Quaternion::new(
      (m01 + m10) / s,
      0.25 * s,
      (m12 + m21) / s,
      (m20 - m02) / s,
    ).normalize()
  } else {
    let s = (1.0 + m22 - m00 - m11).sqrt() * 2.0
    @math3d.Quaternion::new(
      (m20 + m02) / s,
      (m12 + m21) / s,
      0.25 * s,
      (m01 - m10) / s,
    ).normalize()
  }
}
