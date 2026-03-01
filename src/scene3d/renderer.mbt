// ============================================================
// CPU-side software 3D rendering for 2D pipeline
// ============================================================

///|
let bucket_count : Int = 8

///|
priv struct MeshBatch {
  vertices : Array[Double] // flat vertex buffer, stride 4 (x,y,u,v)
  indices : Array[Int] // index buffer
  color_dwords : Array[Int] // single color [r,g,b,a] for the batch
  src_image_id : Int // -1 = no texture
  mut tri_count : Int // number of visible triangles
}

///|
fn MeshBatch::new(
  color_dwords : Array[Int],
  src_image_id? : Int = -1,
) -> MeshBatch {
  { vertices: [], indices: [], color_dwords, src_image_id, tri_count: 0 }
}

///|
fn clamp01(v : Double) -> Double {
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }
}

///|
fn to_byte(v : Double) -> Int {
  let clamped = clamp01(v)
  let result = (clamped * 255.0 + 0.5).to_int()
  if result > 255 {
    255
  } else if result < 0 {
    0
  } else {
    result
  }
}

///|
/// Compute per-bucket lighting colors (8 brightness levels).
/// Returns an array of 8 color_dwords arrays, indexed by brightness bucket.
fn compute_bucket_colors(
  lighting : @light3d.LightingEnvironment,
  color : @math3d.Vec4,
) -> Array[Array[Int]] {
  let amb_r = lighting.ambient.color.x * lighting.ambient.intensity
  let amb_g = lighting.ambient.color.y * lighting.ambient.intensity
  let amb_b = lighting.ambient.color.z * lighting.ambient.intensity
  let dir_r = lighting.directional.color.x * lighting.directional.intensity
  let dir_g = lighting.directional.color.y * lighting.directional.intensity
  let dir_b = lighting.directional.color.z * lighting.directional.intensity
  let result : Array[Array[Int]] = []
  for i in 0..<bucket_count {
    let brightness = i.to_double() / (bucket_count - 1).to_double()
    result.push([
      to_byte(color.x * (amb_r + dir_r * brightness)),
      to_byte(color.y * (amb_g + dir_g * brightness)),
      to_byte(color.z * (amb_b + dir_b * brightness)),
      to_byte(color.w),
    ])
  }
  result
}

///|
/// Transform a point by a 4x4 matrix (manual multiply with perspective divide components).
fn mat4_transform(
  m : @math3d.Mat4,
  x : Double,
  y : Double,
  z : Double,
) -> (Double, Double, Double, Double) {
  let e = m.elements
  let rx = e[0] * x + e[4] * y + e[8] * z + e[12]
  let ry = e[1] * x + e[5] * y + e[9] * z + e[13]
  let rz = e[2] * x + e[6] * y + e[10] * z + e[14]
  let rw = e[3] * x + e[7] * y + e[11] * z + e[15]
  (rx, ry, rz, rw)
}

///|
/// Transform a normal vector by the upper-left 3x3 of a model matrix and normalize.
fn transform_normal_3x3(
  model : @math3d.Mat4,
  nx : Double,
  ny : Double,
  nz : Double,
) -> @math3d.Vec3 {
  let e = model.elements
  let rx = e[0] * nx + e[4] * ny + e[8] * nz
  let ry = e[1] * nx + e[5] * ny + e[9] * nz
  let rz = e[2] * nx + e[6] * ny + e[10] * nz
  @math3d.Vec3::new(rx, ry, rz).normalize()
}

///|
/// Project all visible triangles of a mesh into brightness-bucketed batches.
/// Each triangle is assigned to one of 8 buckets based on its face normal's NdotL.
fn project_mesh_bucketed(
  mesh : @mesh3d.Mesh3D,
  mvp : @math3d.Mat4,
  model : @math3d.Mat4,
  light_dir : @math3d.Vec3,
  batches : Array[MeshBatch],
) -> Double {
  let vdata = mesh.vertex_data
  let indices = mesh.indices
  let stride = 8
  let tri_count = indices.length() / 3
  let mut z_sum = 0.0
  let mut total_tris = 0
  for t in 0..<tri_count {
    let i0 = indices[t * 3]
    let i1 = indices[t * 3 + 1]
    let i2 = indices[t * 3 + 2]
    let p0x = vdata[i0 * stride]
    let p0y = vdata[i0 * stride + 1]
    let p0z = vdata[i0 * stride + 2]
    let p1x = vdata[i1 * stride]
    let p1y = vdata[i1 * stride + 1]
    let p1z = vdata[i1 * stride + 2]
    let p2x = vdata[i2 * stride]
    let p2y = vdata[i2 * stride + 1]
    let p2z = vdata[i2 * stride + 2]
    let c0 = mat4_transform(mvp, p0x, p0y, p0z)
    let c1 = mat4_transform(mvp, p1x, p1y, p1z)
    let c2 = mat4_transform(mvp, p2x, p2y, p2z)
    if c0.3 <= 0.001 || c1.3 <= 0.001 || c2.3 <= 0.001 {
      continue
    }
    let ndc0x = c0.0 / c0.3
    let ndc0y = c0.1 / c0.3
    let ndc0z = c0.2 / c0.3
    let ndc1x = c1.0 / c1.3
    let ndc1y = c1.1 / c1.3
    let ndc1z = c1.2 / c1.3
    let ndc2x = c2.0 / c2.3
    let ndc2y = c2.1 / c2.3
    let ndc2z = c2.2 / c2.3
    if (ndc0x < -1.5 && ndc1x < -1.5 && ndc2x < -1.5) ||
      (ndc0x > 1.5 && ndc1x > 1.5 && ndc2x > 1.5) ||
      (ndc0y < -1.5 && ndc1y < -1.5 && ndc2y < -1.5) ||
      (ndc0y > 1.5 && ndc1y > 1.5 && ndc2y > 1.5) {
      continue
    }
    let e1x = ndc1x - ndc0x
    let e1y = ndc1y - ndc0y
    let e2x = ndc2x - ndc0x
    let e2y = ndc2y - ndc0y
    let cross_z = e1x * e2y - e1y * e2x
    if cross_z < 0.0 {
      continue
    }
    // Read face normal from first vertex (faces share normals per vertex data)
    let fnx = vdata[i0 * stride + 3]
    let fny = vdata[i0 * stride + 4]
    let fnz = vdata[i0 * stride + 5]
    // Transform normal to world space
    let world_normal = transform_normal_3x3(model, fnx, fny, fnz)
    // NdotL: light_dir points toward light (negated direction)
    let ndotl = clamp01(world_normal.dot(light_dir))
    // Bucket index: 0 = darkest, bucket_count-1 = brightest
    let bucket_idx = (ndotl * (bucket_count - 1).to_double() + 0.5).to_int()
    let bi = if bucket_idx >= bucket_count {
      bucket_count - 1
    } else if bucket_idx < 0 {
      0
    } else {
      bucket_idx
    }
    let batch = batches[bi]
    // Read UV coordinates from vertex data
    let u0 = vdata[i0 * stride + 6]
    let v0 = vdata[i0 * stride + 7]
    let u1 = vdata[i1 * stride + 6]
    let v1 = vdata[i1 * stride + 7]
    let u2 = vdata[i2 * stride + 6]
    let v2 = vdata[i2 * stride + 7]
    // Append vertices to batch (stride 4: x, y, u, v)
    let vi = batch.tri_count * 3
    batch.vertices.push(ndc0x)
    batch.vertices.push(ndc0y)
    batch.vertices.push(u0)
    batch.vertices.push(v0)
    batch.vertices.push(ndc1x)
    batch.vertices.push(ndc1y)
    batch.vertices.push(u1)
    batch.vertices.push(v1)
    batch.vertices.push(ndc2x)
    batch.vertices.push(ndc2y)
    batch.vertices.push(u2)
    batch.vertices.push(v2)
    batch.indices.push(vi)
    batch.indices.push(vi + 1)
    batch.indices.push(vi + 2)
    z_sum = z_sum + (ndc0z + ndc1z + ndc2z) / 3.0
    batch.tri_count = batch.tri_count + 1
    total_tris = total_tris + 1
  }
  if total_tris > 0 {
    z_sum / total_tris.to_double()
  } else {
    0.0
  }
}

///|
fn build_batch_draw_command(
  batch : MeshBatch,
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  screen_w : Int,
  screen_h : Int,
) -> @gfx.DrawTrianglesCommand {
  let index_count = batch.tri_count * 3
  let region = @gfx.new_dst_region(0, 0, screen_w, screen_h, index_count)
  let src_image_ids : Array[Int] = if batch.src_image_id >= 0 {
    [batch.src_image_id]
  } else {
    []
  }
  @gfx.new_draw_triangles_command(
    dst,
    shader,
    [region],
    0,
    0,
    0,
    @gfx.blend_mode_from_int(1),
    batch.vertices,
    batch.indices,
    src_image_ids,
    batch.color_dwords,
  )
}

///|
/// Render a 3D scene using CPU projection, producing an array of draw commands
/// sorted back-to-front for the painter's algorithm.
/// Uses per-face diffuse lighting with 8 brightness buckets per object.
pub fn render_scene3d(
  scene : Scene3D,
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  screen_w : Int,
  screen_h : Int,
) -> Array[@gfx.DrawTrianglesCommand] {
  let vp = scene.camera.view_projection_matrix()
  // Light direction toward the light source (negate the directional light direction)
  let light_dir = scene.lighting.directional.direction.negate()
  let all_batches : Array[(MeshBatch, Double)] = []
  for i in 0..<scene.objects.length() {
    let obj = scene.objects[i]
    let (color, src_image_id) = match obj.material {
      Some(mat) => (mat.color, mat.src_image_id)
      None => (obj.color, -1)
    }
    let bucket_colors = compute_bucket_colors(scene.lighting, color)
    let buckets : Array[MeshBatch] = []
    for b in 0..<bucket_count {
      buckets.push(MeshBatch::new(bucket_colors[b], src_image_id~))
    }
    let model = obj.transform.to_mat4()
    let mvp = vp.multiply(model)
    let avg_z = project_mesh_bucketed(obj.mesh, mvp, model, light_dir, buckets)
    for b in 0..<bucket_count {
      if buckets[b].tri_count > 0 {
        all_batches.push((buckets[b], avg_z))
      }
    }
  }
  // Sort batches back-to-front (mesh-level depth sorting)
  all_batches.sort_by(fn(a, b) {
    if a.1 > b.1 {
      -1
    } else if a.1 < b.1 {
      1
    } else {
      0
    }
  })
  let cmds : Array[@gfx.DrawTrianglesCommand] = []
  for i in 0..<all_batches.length() {
    cmds.push(
      build_batch_draw_command(
        all_batches[i].0,
        dst,
        shader,
        screen_w,
        screen_h,
      ),
    )
  }
  cmds
}
