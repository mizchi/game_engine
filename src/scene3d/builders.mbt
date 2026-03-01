///|
pub fn object3d(
  mesh~ : @mesh3d.Mesh3D,
  position? : @math3d.Vec3 = @math3d.Vec3::zero(),
  rotation? : @math3d.Quaternion = @math3d.Quaternion::identity(),
  scale? : @math3d.Vec3 = @math3d.Vec3::one(),
  color? : @math3d.Vec4 = @math3d.Vec4::new(1.0, 1.0, 1.0, 1.0),
  material? : Material? = None,
) -> Object3D {
  {
    mesh,
    transform: @transform3d.Transform3D::from_components(
      position, rotation, scale,
    ),
    color,
    material,
  }
}

///|
pub fn object3d_with_transform(
  mesh~ : @mesh3d.Mesh3D,
  transform~ : @transform3d.Transform3D,
  color? : @math3d.Vec4 = @math3d.Vec4::new(1.0, 1.0, 1.0, 1.0),
  material? : Material? = None,
) -> Object3D {
  { mesh, transform, color, material }
}

///|
pub fn scene3d(
  objects~ : Array[Object3D],
  camera~ : @camera3d.Camera3D,
  lighting? : @light3d.LightingEnvironment = @light3d.LightingEnvironment::default(),
) -> Scene3D {
  { objects, camera, lighting }
}
