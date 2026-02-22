///|
/// Clamp pitch to avoid gimbal lock at poles.
fn clamp_pitch(pitch : Double) -> Double {
  let limit = @math.PI / 2.0 - 0.01
  if pitch > limit {
    limit
  } else if pitch < -limit {
    -limit
  } else {
    pitch
  }
}

///|
/// Build orientation quaternion from yaw (Y-axis) and pitch (X-axis).
fn yaw_pitch_orientation(yaw : Double, pitch : Double) -> @math3d.Quaternion {
  let qy = @math3d.Quaternion::from_axis_angle(@math3d.Vec3::unit_y(), yaw)
  let qx = @math3d.Quaternion::from_axis_angle(@math3d.Vec3::unit_x(), pitch)
  qy.multiply(qx).normalize()
}
