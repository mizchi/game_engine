// ============================================================
// 3D Arena Collector
// ============================================================

// Game modes
let mode_title : Int = 0
let mode_playing : Int = 1
let mode_gameover : Int = 2

// Arena dimensions
let arena_half : Double = 9.0
let wall_height : Double = 1.0
let wall_thickness : Double = 0.5

// Gameplay
let player_speed : Double = 0.08
let enemy_speed : Double = 0.03
let item_collect_dist : Double = 0.8
let enemy_hit_dist : Double = 1.0
let item_count : Int = 5
let enemy_count : Int = 3

// Rendering
let screen_w : Int = 640
let screen_h : Int = 480

// ============================================================
// Colored Lit Shader WGSL (for future WebGPU backend)
// ============================================================

fn shader3d_colored_lit_wgsl() -> String {
  "struct Uniforms {\n" +
  "  mvp: mat4x4<f32>,\n" +
  "  model: mat4x4<f32>,\n" +
  "  normal_col0: vec4<f32>,\n" +
  "  normal_col1: vec4<f32>,\n" +
  "  normal_col2: vec4<f32>,\n" +
  "  light_dir: vec4<f32>,\n" +
  "  light_color: vec4<f32>,\n" +
  "  ambient_color: vec4<f32>,\n" +
  "  material_color: vec4<f32>,\n" +
  "};\n\n" +
  "@group(0) @binding(0) var<uniform> uniforms: Uniforms;\n\n" +
  "struct VertexInput {\n" +
  "  @location(0) position: vec3<f32>,\n" +
  "  @location(1) normal: vec3<f32>,\n" +
  "  @location(2) uv: vec2<f32>,\n" +
  "};\n\n" +
  "struct VertexOutput {\n" +
  "  @builtin(position) clip_position: vec4<f32>,\n" +
  "  @location(0) world_normal: vec3<f32>,\n" +
  "};\n\n" +
  "@vertex fn vs_main(input: VertexInput) -> VertexOutput {\n" +
  "  var out: VertexOutput;\n" +
  "  out.clip_position = uniforms.mvp * vec4<f32>(input.position, 1.0);\n" +
  "  let normal_mat = mat3x3<f32>(\n" +
  "    uniforms.normal_col0.xyz,\n" +
  "    uniforms.normal_col1.xyz,\n" +
  "    uniforms.normal_col2.xyz,\n" +
  "  );\n" +
  "  out.world_normal = normalize(normal_mat * input.normal);\n" +
  "  return out;\n" +
  "}\n\n" +
  "@fragment fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {\n" +
  "  let normal = normalize(in.world_normal);\n" +
  "  let light_dir = normalize(-uniforms.light_dir.xyz);\n" +
  "  let ndotl = max(dot(normal, light_dir), 0.0);\n" +
  "  let diffuse = uniforms.light_color.xyz * ndotl;\n" +
  "  let ambient = uniforms.ambient_color.xyz;\n" +
  "  let lit_color = uniforms.material_color.rgb * (diffuse + ambient);\n" +
  "  return vec4<f32>(lit_color, uniforms.material_color.a);\n" +
  "}\n"
}

// ============================================================
// CPU-side software 3D rendering for 2D pipeline
// ============================================================

// Batched mesh projection result
struct MeshBatch {
  vertices : Array[Double] // flat vertex buffer, stride 4 (x,y,u,v)
  indices : Array[Int] // index buffer
  color_dwords : Array[Int] // single color [r,g,b,a] for the batch
  mut avg_z : Double // average depth for mesh-level sorting
  mut tri_count : Int // number of visible triangles
}

fn MeshBatch::new(color_dwords : Array[Int]) -> MeshBatch {
  { vertices: [], indices: [], color_dwords, avg_z: 0.0, tri_count: 0 }
}

fn clamp01(v : Double) -> Double {
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }
}

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

/// Compute per-mesh lighting color (ambient + hemisphere-average diffuse).
fn compute_mesh_color(
  lighting : @light3d.LightingEnvironment,
  color : @math3d.Vec4,
) -> Array[Int] {
  let amb_r = lighting.ambient.color.x * lighting.ambient.intensity
  let amb_g = lighting.ambient.color.y * lighting.ambient.intensity
  let amb_b = lighting.ambient.color.z * lighting.ambient.intensity
  // Average diffuse: hemisphere average NdotL ≈ 0.5
  let avg_ndotl = 0.5
  let diff_r = lighting.directional.color.x * lighting.directional.intensity *
    avg_ndotl
  let diff_g = lighting.directional.color.y * lighting.directional.intensity *
    avg_ndotl
  let diff_b = lighting.directional.color.z * lighting.directional.intensity *
    avg_ndotl
  [
    to_byte(color.x * (diff_r + amb_r)),
    to_byte(color.y * (diff_g + amb_g)),
    to_byte(color.z * (diff_b + amb_b)),
    to_byte(color.w),
  ]
}

/// Project all visible triangles of a mesh into a single batch.
fn project_mesh_batched(
  mesh : @mesh3d.Mesh3D,
  mvp : @math3d.Mat4,
  batch : MeshBatch,
) -> Unit {
  let vdata = mesh.vertex_data
  let indices = mesh.indices
  let stride = 8
  let tri_count = indices.length() / 3
  let mut z_sum = 0.0
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
    // Append vertices to batch (stride 4: x, y, u, v)
    let vi = batch.tri_count * 3
    batch.vertices.push(ndc0x)
    batch.vertices.push(ndc0y)
    batch.vertices.push(0.0)
    batch.vertices.push(0.0)
    batch.vertices.push(ndc1x)
    batch.vertices.push(ndc1y)
    batch.vertices.push(0.0)
    batch.vertices.push(0.0)
    batch.vertices.push(ndc2x)
    batch.vertices.push(ndc2y)
    batch.vertices.push(0.0)
    batch.vertices.push(0.0)
    batch.indices.push(vi)
    batch.indices.push(vi + 1)
    batch.indices.push(vi + 2)
    z_sum = z_sum + (ndc0z + ndc1z + ndc2z) / 3.0
    batch.tri_count = batch.tri_count + 1
  }
  if batch.tri_count > 0 {
    batch.avg_z = z_sum / batch.tri_count.to_double()
  }
}

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

fn build_batch_draw_command(
  batch : MeshBatch,
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
) -> @gfx.DrawTrianglesCommand {
  let index_count = batch.tri_count * 3
  let region = @gfx.new_dst_region(0, 0, screen_w, screen_h, index_count)
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
    [],
    batch.color_dwords,
  )
}

// ============================================================
// Entity types
// ============================================================

struct PlayerState {
  mut position : @math3d.Vec3
}

struct ItemState {
  mut position : @math3d.Vec3
  mut active : Bool
}

struct EnemyState {
  mut position : @math3d.Vec3
  waypoints : Array[@math3d.Vec3]
  mut waypoint_idx : Int
}

struct Meshes {
  player : @mesh3d.Mesh3D
  item : @mesh3d.Mesh3D
  enemy : @mesh3d.Mesh3D
  ground : @mesh3d.Mesh3D
  wall : @mesh3d.Mesh3D
}

// ============================================================
// GameState
// ============================================================

struct GameState {
  mut mode : Int
  mut score : Int
  mut frame_count : Int
  player : PlayerState
  items : Array[ItemState]
  enemies : Array[EnemyState]
  mut camera : @camera3d.OrbitCamera
  lighting : @light3d.LightingEnvironment
  input : @inpututil.InputHelper
  meshes : Meshes
}

fn GameState::new() -> GameState {
  let items : Array[ItemState] = []
  for i in 0..<item_count {
    items.push(make_item(i))
  }
  let enemies : Array[EnemyState] = []
  let wp0 : Array[@math3d.Vec3] = [
    @math3d.Vec3::new(-6.0, 0.5, -6.0),
    @math3d.Vec3::new(6.0, 0.5, -6.0),
    @math3d.Vec3::new(6.0, 0.5, 6.0),
    @math3d.Vec3::new(-6.0, 0.5, 6.0),
  ]
  let wp1 : Array[@math3d.Vec3] = [
    @math3d.Vec3::new(0.0, 0.5, -7.0),
    @math3d.Vec3::new(7.0, 0.5, 0.0),
    @math3d.Vec3::new(0.0, 0.5, 7.0),
    @math3d.Vec3::new(-7.0, 0.5, 0.0),
  ]
  let wp2 : Array[@math3d.Vec3] = [
    @math3d.Vec3::new(-4.0, 0.5, 0.0),
    @math3d.Vec3::new(4.0, 0.5, 0.0),
  ]
  enemies.push({ position: wp0[0], waypoints: wp0, waypoint_idx: 0 })
  enemies.push({ position: wp1[0], waypoints: wp1, waypoint_idx: 0 })
  enemies.push({ position: wp2[0], waypoints: wp2, waypoint_idx: 0 })
  let camera = @camera3d.OrbitCamera::new(
    @math3d.Vec3::new(0.0, 0.0, 0.0),
    12.0,
    0.0,
    0.6,
    @math.PI / 4.0,
    screen_w.to_double() / screen_h.to_double(),
    0.1,
    100.0,
  )
  let lighting = @light3d.LightingEnvironment::new(
    @light3d.DirectionalLight::new(
      @math3d.Vec3::new(-0.3, -1.0, -0.5),
      @math3d.Vec3::one(),
      0.8,
    ),
    @light3d.AmbientLight::new(@math3d.Vec3::one(), 0.3),
  )
  {
    mode: mode_playing,
    score: 0,
    frame_count: 0,
    player: { position: @math3d.Vec3::new(0.0, 0.5, 0.0) },
    items,
    enemies,
    camera,
    lighting,
    input: @inpututil.new_input_helper(),
    meshes: {
      player: @mesh3d.Mesh3D::sphere(0.5, 6, 4),
      item: @mesh3d.Mesh3D::sphere(0.3, 4, 3),
      enemy: @mesh3d.Mesh3D::cube(0.8),
      ground: @mesh3d.Mesh3D::plane(20.0, 20.0),
      wall: @mesh3d.Mesh3D::cube(1.0),
    },
  }
}

fn make_item(index : Int) -> ItemState {
  let positions : Array[@math3d.Vec3] = [
    @math3d.Vec3::new(5.0, 0.3, 5.0),
    @math3d.Vec3::new(-5.0, 0.3, 3.0),
    @math3d.Vec3::new(3.0, 0.3, -6.0),
    @math3d.Vec3::new(-7.0, 0.3, -4.0),
    @math3d.Vec3::new(0.0, 0.3, 7.0),
  ]
  let pos = positions[index % positions.length()]
  { position: pos, active: true }
}

fn respawn_item(item : ItemState, frame : Int) -> Unit {
  let angle = (frame % 360).to_double() * @math.PI / 180.0
  let r = 3.0 + (frame % 5).to_double()
  item.position = @math3d.Vec3::new(
    r * @math.cos(angle),
    0.3,
    r * @math.sin(angle),
  )
  item.position = @math3d.Vec3::new(
    clamp_arena(item.position.x),
    0.3,
    clamp_arena(item.position.z),
  )
  item.active = true
}

fn clamp_arena(v : Double) -> Double {
  let limit = arena_half - 1.0
  if v < -limit {
    -limit
  } else if v > limit {
    limit
  } else {
    v
  }
}

fn distance_xz(a : @math3d.Vec3, b : @math3d.Vec3) -> Double {
  let dx = a.x - b.x
  let dz = a.z - b.z
  (dx * dx + dz * dz).sqrt()
}

// ============================================================
// Update
// ============================================================

fn GameState::update(self : GameState, input : @core.InputSnapshot) -> Unit {
  self.frame_count = self.frame_count + 1
  @inpututil.update_input_helper(self.input, input)
  match self.mode {
    m if m == mode_title => self.update_title()
    m if m == mode_playing => self.update_playing()
    m if m == mode_gameover => self.update_gameover()
    _ => ()
  }
}

fn GameState::update_title(self : GameState) -> Unit {
  if @inpututil.is_confirm_just_pressed(self.input) {
    self.reset()
    self.mode = mode_playing
  }
}

fn GameState::update_gameover(self : GameState) -> Unit {
  if @inpututil.is_confirm_just_pressed(self.input) {
    self.reset()
    self.mode = mode_title
  }
}

fn GameState::reset(self : GameState) -> Unit {
  self.score = 0
  self.frame_count = 0
  self.player.position = @math3d.Vec3::new(0.0, 0.5, 0.0)
  for i in 0..<self.items.length() {
    let item = self.items[i]
    let fresh = make_item(i)
    item.position = fresh.position
    item.active = true
  }
  for i in 0..<self.enemies.length() {
    let e = self.enemies[i]
    e.waypoint_idx = 0
    e.position = e.waypoints[0]
  }
}

fn GameState::update_playing(self : GameState) -> Unit {
  let mut dx = 0.0
  let mut dz = 0.0
  if @inpututil.is_move_up(self.input.key_state) {
    dz = dz - player_speed
  }
  if @inpututil.is_move_down(self.input.key_state) {
    dz = dz + player_speed
  }
  if @inpututil.is_move_left(self.input.key_state) {
    dx = dx - player_speed
  }
  if @inpututil.is_move_right(self.input.key_state) {
    dx = dx + player_speed
  }
  self.player.position = @math3d.Vec3::new(
    clamp_arena(self.player.position.x + dx),
    self.player.position.y,
    clamp_arena(self.player.position.z + dz),
  )
  for i in 0..<self.items.length() {
    let item = self.items[i]
    if item.active &&
      distance_xz(self.player.position, item.position) < item_collect_dist {
      item.active = false
      self.score = self.score + 10
      respawn_item(item, self.frame_count + i * 97)
    }
  }
  for i in 0..<self.enemies.length() {
    let e = self.enemies[i]
    let target = e.waypoints[e.waypoint_idx]
    let ex_dx = target.x - e.position.x
    let ex_dz = target.z - e.position.z
    let dist = (ex_dx * ex_dx + ex_dz * ex_dz).sqrt()
    if dist < 0.2 {
      e.waypoint_idx = (e.waypoint_idx + 1) % e.waypoints.length()
    } else {
      let inv = enemy_speed / dist
      e.position = @math3d.Vec3::new(
        e.position.x + ex_dx * inv,
        e.position.y,
        e.position.z + ex_dz * inv,
      )
    }
    if distance_xz(self.player.position, e.position) < enemy_hit_dist {
      self.mode = mode_gameover
    }
  }
  self.camera = self.camera.with_target(self.player.position)
}

// ============================================================
// Draw commands (CPU-side 3D→2D projection)
// ============================================================

// Colors (RGBA, 0-1 range)
let color_player : @math3d.Vec4 = @math3d.Vec4::new(0.2, 0.8, 0.3, 1.0)
let color_item : @math3d.Vec4 = @math3d.Vec4::new(1.0, 0.9, 0.2, 1.0)
let color_enemy : @math3d.Vec4 = @math3d.Vec4::new(0.9, 0.2, 0.2, 1.0)
let color_ground : @math3d.Vec4 = @math3d.Vec4::new(0.4, 0.5, 0.4, 1.0)
let color_wall : @math3d.Vec4 = @math3d.Vec4::new(0.3, 0.3, 0.35, 1.0)

fn GameState::build_draw_commands(
  self : GameState,
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
) -> Array[@gfx.DrawTrianglesCommand] {
  let cam3d = self.camera.to_camera3d()
  let vp = cam3d.view_projection_matrix()
  let batches : Array[MeshBatch] = []
  // Pre-compute per-mesh colors
  let ground_cdw = compute_mesh_color(self.lighting, color_ground)
  let wall_cdw = compute_mesh_color(self.lighting, color_wall)
  let item_cdw = compute_mesh_color(self.lighting, color_item)
  let enemy_cdw = compute_mesh_color(self.lighting, color_enemy)
  let player_cdw = compute_mesh_color(self.lighting, color_player)
  // Ground
  let ground_batch = MeshBatch::new(ground_cdw)
  let ground_mvp = vp.multiply(@math3d.Mat4::identity())
  project_mesh_batched(self.meshes.ground, ground_mvp, ground_batch)
  if ground_batch.tri_count > 0 {
    batches.push(ground_batch)
  }
  // Walls (4 walls, each as separate batch for depth sorting)
  build_wall_batches(self.meshes.wall, vp, wall_cdw, batches)
  // Items
  for i in 0..<self.items.length() {
    let item = self.items[i]
    if item.active {
      let batch = MeshBatch::new(item_cdw)
      let mvp = vp.multiply(
        @math3d.Mat4::translation(
          item.position.x, item.position.y, item.position.z,
        ),
      )
      project_mesh_batched(self.meshes.item, mvp, batch)
      if batch.tri_count > 0 {
        batches.push(batch)
      }
    }
  }
  // Enemies
  for i in 0..<self.enemies.length() {
    let e = self.enemies[i]
    let batch = MeshBatch::new(enemy_cdw)
    let mvp = vp.multiply(
      @math3d.Mat4::translation(
        e.position.x, e.position.y, e.position.z,
      ),
    )
    project_mesh_batched(self.meshes.enemy, mvp, batch)
    if batch.tri_count > 0 {
      batches.push(batch)
    }
  }
  // Player
  let player_batch = MeshBatch::new(player_cdw)
  let player_mvp = vp.multiply(
    @math3d.Mat4::translation(
      self.player.position.x,
      self.player.position.y,
      self.player.position.z,
    ),
  )
  project_mesh_batched(self.meshes.player, player_mvp, player_batch)
  if player_batch.tri_count > 0 {
    batches.push(player_batch)
  }
  // Sort batches back-to-front (mesh-level depth sorting)
  batches.sort_by(fn(a, b) {
    if a.avg_z > b.avg_z {
      -1
    } else if a.avg_z < b.avg_z {
      1
    } else {
      0
    }
  })
  // One draw command per batch
  let cmds : Array[@gfx.DrawTrianglesCommand] = []
  for i in 0..<batches.length() {
    cmds.push(build_batch_draw_command(batches[i], dst, shader))
  }
  cmds
}

fn build_wall_batches(
  wall_mesh : @mesh3d.Mesh3D,
  vp : @math3d.Mat4,
  wall_cdw : Array[Int],
  batches : Array[MeshBatch],
) -> Unit {
  let h = arena_half
  let wh = wall_height / 2.0
  let wt = wall_thickness
  add_wall_batch(
    wall_mesh, vp, wall_cdw, batches,
    0.0, wh, -(h + wt / 2.0),
    h * 2.0 + wt * 2.0, wall_height, wt,
  )
  add_wall_batch(
    wall_mesh, vp, wall_cdw, batches,
    0.0, wh, h + wt / 2.0,
    h * 2.0 + wt * 2.0, wall_height, wt,
  )
  add_wall_batch(
    wall_mesh, vp, wall_cdw, batches,
    -(h + wt / 2.0), wh, 0.0,
    wt, wall_height, h * 2.0,
  )
  add_wall_batch(
    wall_mesh, vp, wall_cdw, batches,
    h + wt / 2.0, wh, 0.0,
    wt, wall_height, h * 2.0,
  )
}

fn add_wall_batch(
  wall_mesh : @mesh3d.Mesh3D,
  vp : @math3d.Mat4,
  wall_cdw : Array[Int],
  batches : Array[MeshBatch],
  x : Double,
  y : Double,
  z : Double,
  sx : Double,
  sy : Double,
  sz : Double,
) -> Unit {
  let batch = MeshBatch::new(wall_cdw)
  let mvp = vp.multiply(
    @math3d.Mat4::translation(x, y, z).multiply(
      @math3d.Mat4::scaling(sx, sy, sz),
    ),
  )
  project_mesh_batched(wall_mesh, mvp, batch)
  if batch.tri_count > 0 {
    batches.push(batch)
  }
}
