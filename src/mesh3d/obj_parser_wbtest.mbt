///|
fn approx_obj(a : Double, b : Double) -> Bool {
  (a - b).abs() < 1.0e-6
}

///|
test "from_obj basic triangle" {
  let obj =
    #|v 0.0 0.0 0.0
    #|v 1.0 0.0 0.0
    #|v 0.0 1.0 0.0
    #|f 1 2 3
  let mesh = Mesh3D::from_obj(obj)
  assert_eq(mesh.vertex_count(), 3)
  assert_eq(mesh.triangle_count(), 1)
  // Check positions
  assert_true(approx_obj(mesh.vertex_data[0], 0.0))
  assert_true(approx_obj(mesh.vertex_data[1], 0.0))
  assert_true(approx_obj(mesh.vertex_data[2], 0.0))
  assert_true(approx_obj(mesh.vertex_data[8], 1.0))
  assert_true(approx_obj(mesh.vertex_data[9], 0.0))
  assert_true(approx_obj(mesh.vertex_data[10], 0.0))
  assert_true(approx_obj(mesh.vertex_data[16], 0.0))
  assert_true(approx_obj(mesh.vertex_data[17], 1.0))
  assert_true(approx_obj(mesh.vertex_data[18], 0.0))
  // Check indices
  assert_eq(mesh.indices[0], 0)
  assert_eq(mesh.indices[1], 1)
  assert_eq(mesh.indices[2], 2)
}

///|
test "from_obj quad triangulation" {
  let obj =
    #|v 0.0 0.0 0.0
    #|v 1.0 0.0 0.0
    #|v 1.0 1.0 0.0
    #|v 0.0 1.0 0.0
    #|f 1 2 3 4
  let mesh = Mesh3D::from_obj(obj)
  assert_eq(mesh.vertex_count(), 4)
  assert_eq(mesh.triangle_count(), 2) // quad → 2 triangles
  // First triangle: 0, 1, 2
  assert_eq(mesh.indices[0], 0)
  assert_eq(mesh.indices[1], 1)
  assert_eq(mesh.indices[2], 2)
  // Second triangle: 0, 2, 3
  assert_eq(mesh.indices[3], 0)
  assert_eq(mesh.indices[4], 2)
  assert_eq(mesh.indices[5], 3)
}

///|
test "from_obj with vn and vt" {
  let obj =
    #|v 0.0 0.0 0.0
    #|v 1.0 0.0 0.0
    #|v 0.0 1.0 0.0
    #|vn 0.0 0.0 1.0
    #|vt 0.0 0.0
    #|vt 1.0 0.0
    #|vt 0.5 1.0
    #|f 1/1/1 2/2/1 3/3/1
  let mesh = Mesh3D::from_obj(obj)
  assert_eq(mesh.vertex_count(), 3)
  assert_eq(mesh.triangle_count(), 1)
  // Check normal (same for all vertices)
  assert_true(approx_obj(mesh.vertex_data[3], 0.0)) // nx
  assert_true(approx_obj(mesh.vertex_data[4], 0.0)) // ny
  assert_true(approx_obj(mesh.vertex_data[5], 1.0)) // nz
  // Check UV of second vertex
  assert_true(approx_obj(mesh.vertex_data[8 + 6], 1.0)) // u
  assert_true(approx_obj(mesh.vertex_data[8 + 7], 0.0)) // v
  // Check UV of third vertex
  assert_true(approx_obj(mesh.vertex_data[16 + 6], 0.5)) // u
  assert_true(approx_obj(mesh.vertex_data[16 + 7], 1.0)) // v
}

///|
test "from_obj scientific notation" {
  let obj =
    #|v -3.4101800e-003 1.5039200e-001 -2.9657800e-002
    #|v 3.0000000e+000 0.0000000e+000 1.5000000e+001
    #|v 1.0e1 2.0e-1 3.0e0
    #|f 1 2 3
  let mesh = Mesh3D::from_obj(obj)
  assert_eq(mesh.vertex_count(), 3)
  // First vertex
  assert_true(approx_obj(mesh.vertex_data[0], -0.00341018))
  assert_true(approx_obj(mesh.vertex_data[1], 0.15039200))
  assert_true(approx_obj(mesh.vertex_data[2], -0.02965780))
  // Second vertex
  assert_true(approx_obj(mesh.vertex_data[8], 3.0))
  assert_true(approx_obj(mesh.vertex_data[9], 0.0))
  assert_true(approx_obj(mesh.vertex_data[10], 15.0))
  // Third vertex
  assert_true(approx_obj(mesh.vertex_data[16], 10.0))
  assert_true(approx_obj(mesh.vertex_data[17], 0.2))
  assert_true(approx_obj(mesh.vertex_data[18], 3.0))
}

///|
test "from_obj flat normal computation" {
  // Triangle in XY plane: normal should be (0, 0, 1)
  let obj =
    #|v 0.0 0.0 0.0
    #|v 1.0 0.0 0.0
    #|v 0.0 1.0 0.0
    #|f 1 2 3
  let mesh = Mesh3D::from_obj(obj)
  // All three vertices should have normal (0, 0, 1)
  for i in 0..<3 {
    let base = i * 8
    assert_true(approx_obj(mesh.vertex_data[base + 3], 0.0))
    assert_true(approx_obj(mesh.vertex_data[base + 4], 0.0))
    assert_true(approx_obj(mesh.vertex_data[base + 5], 1.0))
  }
}

///|
test "from_obj negative indices" {
  let obj =
    #|v 0.0 0.0 0.0
    #|v 1.0 0.0 0.0
    #|v 0.0 1.0 0.0
    #|f -3 -2 -1
  let mesh = Mesh3D::from_obj(obj)
  assert_eq(mesh.vertex_count(), 3)
  assert_eq(mesh.triangle_count(), 1)
  // -3 = first vertex, -2 = second, -1 = third
  assert_true(approx_obj(mesh.vertex_data[0], 0.0))
  assert_true(approx_obj(mesh.vertex_data[8], 1.0))
  assert_true(approx_obj(mesh.vertex_data[16], 0.0))
  assert_true(approx_obj(mesh.vertex_data[17], 1.0))
}

///|
test "from_obj v//vn format" {
  let obj =
    #|v 0.0 0.0 0.0
    #|v 1.0 0.0 0.0
    #|v 0.0 1.0 0.0
    #|vn 0.0 0.0 -1.0
    #|f 1//1 2//1 3//1
  let mesh = Mesh3D::from_obj(obj)
  assert_eq(mesh.vertex_count(), 3)
  // Normal should be (0, 0, -1)
  for i in 0..<3 {
    let base = i * 8
    assert_true(approx_obj(mesh.vertex_data[base + 3], 0.0))
    assert_true(approx_obj(mesh.vertex_data[base + 4], 0.0))
    assert_true(approx_obj(mesh.vertex_data[base + 5], -1.0))
  }
}

///|
test "from_obj comments and blank lines" {
  let obj =
    #|# This is a comment
    #|
    #|v 0.0 0.0 0.0
    #|v 1.0 0.0 0.0
    #|v 0.0 1.0 0.0
    #|
    #|# Another comment
    #|f 1 2 3
  let mesh = Mesh3D::from_obj(obj)
  assert_eq(mesh.vertex_count(), 3)
  assert_eq(mesh.triangle_count(), 1)
}

///|
test "from_obj multiple faces" {
  let obj =
    #|v 0.0 0.0 0.0
    #|v 1.0 0.0 0.0
    #|v 1.0 1.0 0.0
    #|v 0.0 1.0 0.0
    #|v 0.0 0.0 1.0
    #|f 1 2 3
    #|f 1 3 4
    #|f 1 2 5
  let mesh = Mesh3D::from_obj(obj)
  // 3 faces * 3 vertices = 9 (each face creates new vertices)
  assert_eq(mesh.vertex_count(), 9)
  assert_eq(mesh.triangle_count(), 3)
}
