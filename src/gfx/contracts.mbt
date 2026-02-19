///|
/// Graphics backend contracts.
/// Ebiten refs:
/// - internal/graphicsdriver/graphics.go
/// - internal/graphicscommand/commandqueue.go
/// - internal/atlas/image.go

///|
pub struct DstRegion {
  x : Int
  y : Int
  width : Int
  height : Int
  index_count : Int
} derive(Show)

///|
pub fn new_dst_region(
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  index_count : Int,
) -> DstRegion {
  { x, y, width, height, index_count }
}

///|
pub struct Color {
  r : Double
  g : Double
  b : Double
  a : Double
} derive(Show)

///|
pub struct RenderPassDesc {
  clear_color : Color
  present : Bool
} derive(Show)

///|
pub fn new_color(r : Double, g : Double, b : Double, a : Double) -> Color {
  { r, g, b, a }
}

///|
pub fn new_render_pass_desc(
  clear_color : Color,
  present : Bool,
) -> RenderPassDesc {
  { clear_color, present }
}

///|
pub enum BlendMode {
  Copy
  Alpha
  Add
  Multiply
} derive(Show)

///|
pub fn blend_mode_to_int(mode : BlendMode) -> Int {
  match mode {
    BlendMode::Copy => 0
    BlendMode::Alpha => 1
    BlendMode::Add => 2
    BlendMode::Multiply => 3
  }
}

///|
pub fn blend_mode_from_int(mode : Int) -> BlendMode {
  match mode {
    0 => BlendMode::Copy
    1 => BlendMode::Alpha
    2 => BlendMode::Add
    3 => BlendMode::Multiply
    _ => BlendMode::Alpha
  }
}

///|
pub enum FilterMode {
  Nearest
  Linear
  Pixelated
} derive(Show)

///|
pub fn filter_mode_to_int(mode : FilterMode) -> Int {
  match mode {
    FilterMode::Nearest => 0
    FilterMode::Linear => 1
    FilterMode::Pixelated => 2
  }
}

///|
pub fn filter_mode_from_int(mode : Int) -> FilterMode {
  match mode {
    0 => FilterMode::Nearest
    1 => FilterMode::Linear
    2 => FilterMode::Pixelated
    _ => FilterMode::Nearest
  }
}

///|
pub struct ImageHandle {
  id : Int
  width : Int
  height : Int
} derive(Show)

///|
pub fn new_image_handle(id : Int, width : Int, height : Int) -> ImageHandle {
  { id, width, height }
}

///|
pub struct ShaderHandle {
  id : Int
  source : String
} derive(Show)

///|
pub fn new_shader_handle(id : Int, source : String) -> ShaderHandle {
  { id, source }
}

///|
pub struct PipelineHandle {
  id : Int
} derive(Show)

///|
pub fn new_pipeline_handle(id : Int) -> PipelineHandle {
  { id, }
}

///|
pub struct DrawTrianglesCommand {
  dst : ImageHandle
  shader : ShaderHandle
  dst_regions : Array[DstRegion]
  index_offset : Int
  pipeline_id : Int
  uniform_hash : Int
  blend : BlendMode
  /// Optional explicit payload for backend bridge.
  /// Ebiten refs:
  /// - internal/graphicscommand/command.go (vertex/index payload)
  vertex_data : Array[Double]
  indices : Array[Int]
  src_image_ids : Array[Int]
  uniform_dwords : Array[Int]
}

///|
pub fn new_draw_triangles_command(
  dst : ImageHandle,
  shader : ShaderHandle,
  dst_regions : Array[DstRegion],
  index_offset : Int,
  pipeline_id : Int,
  uniform_hash : Int,
  blend : BlendMode,
  vertex_data : Array[Double],
  indices : Array[Int],
  src_image_ids : Array[Int],
  uniform_dwords : Array[Int],
) -> DrawTrianglesCommand {
  {
    dst,
    shader,
    dst_regions,
    index_offset,
    pipeline_id,
    uniform_hash,
    blend,
    vertex_data,
    indices,
    src_image_ids,
    uniform_dwords,
  }
}

///|
pub struct DrawCommandDispatch {
  draw_calls : Int
  pipeline_id : Int
  uniform_hash : Int
  blend_mode : Int
  dst_image_id : Int
  shader_id : Int
  index_offset : Int
  region_count : Int
  total_index_count : Int
  vertex_float_count : Int
  index_count : Int
  src_image_count : Int
  uniform_dword_count : Int
} derive(Show)

///|
fn normalized_region_triangle_count(region : DstRegion) -> Int {
  if region.index_count <= 0 {
    1
  } else {
    let triangles = region.index_count / 3
    if triangles <= 0 {
      1
    } else {
      triangles
    }
  }
}

///|
fn normalized_region_index_count(region : DstRegion) -> Int {
  if region.index_count <= 0 {
    3
  } else {
    region.index_count
  }
}

///|
pub fn estimated_draw_call_count(command : DrawTrianglesCommand) -> Int {
  let mut draw_calls = 0
  for region in command.dst_regions {
    draw_calls = draw_calls + normalized_region_triangle_count(region)
  }
  draw_calls
}

///|
pub fn estimated_total_index_count(command : DrawTrianglesCommand) -> Int {
  let mut total = 0
  for region in command.dst_regions {
    total = total + normalized_region_index_count(region)
  }
  total
}

///|
fn resolved_index_count(command : DrawTrianglesCommand) -> Int {
  let explicit = command.indices.length()
  if explicit > 0 {
    explicit
  } else {
    estimated_total_index_count(command)
  }
}

///|
pub fn build_draw_command_dispatch(
  command : DrawTrianglesCommand,
) -> DrawCommandDispatch {
  {
    draw_calls: estimated_draw_call_count(command),
    pipeline_id: command.pipeline_id,
    uniform_hash: command.uniform_hash,
    blend_mode: blend_mode_to_int(command.blend),
    dst_image_id: command.dst.id,
    shader_id: command.shader.id,
    index_offset: command.index_offset,
    region_count: command.dst_regions.length(),
    total_index_count: estimated_total_index_count(command),
    vertex_float_count: command.vertex_data.length(),
    index_count: resolved_index_count(command),
    src_image_count: command.src_image_ids.length(),
    uniform_dword_count: command.uniform_dwords.length(),
  }
}

///|
pub trait GraphicsDriver {
  /// Ebiten ref: Graphics.Initialize/Begin/End
  initialize(Self) -> Unit raise
  begin(Self, pass : RenderPassDesc) -> Unit raise
  end(Self, present : Bool) -> Unit raise
  /// Ebiten ref: surface resize / reconfigure paths
  resize(Self, width : Int, height : Int) -> Unit raise

  /// Ebiten ref: Graphics.NewImage/NewShader
  new_image(Self, width : Int, height : Int) -> ImageHandle raise
  new_shader(Self, source : String) -> ShaderHandle raise

  /// Ebiten ref: Graphics.DrawTriangles
  draw_triangles(Self, command : DrawTrianglesCommand) -> Unit raise
}

///|
pub trait CommandQueue {
  /// Ebiten ref: commandQueue.EnqueueDrawTrianglesCommand
  enqueue_draw_triangles(Self, command : DrawTrianglesCommand) -> Unit

  /// Ebiten ref: commandQueue.Flush / FlushCommands
  flush(Self) -> Array[DrawTrianglesCommand]
}

///|
pub struct SimpleCommandQueue {
  mut commands : Array[DrawTrianglesCommand]
}

///|
fn blend_mode_eq(lhs : BlendMode, rhs : BlendMode) -> Bool {
  match lhs {
    BlendMode::Copy =>
      match rhs {
        BlendMode::Copy => true
        _ => false
      }
    BlendMode::Alpha =>
      match rhs {
        BlendMode::Alpha => true
        _ => false
      }
    BlendMode::Add =>
      match rhs {
        BlendMode::Add => true
        _ => false
      }
    BlendMode::Multiply =>
      match rhs {
        BlendMode::Multiply => true
        _ => false
      }
  }
}

///|
fn int_array_eq(lhs : Array[Int], rhs : Array[Int]) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if lhs[i] != rhs[i] {
      return false
    }
  }
  true
}

///|
fn can_merge_draw_triangles(
  lhs : DrawTrianglesCommand,
  rhs : DrawTrianglesCommand,
) -> Bool {
  let lhs_has_explicit_geometry = lhs.vertex_data.length() > 0 ||
    lhs.indices.length() > 0 ||
    lhs.uniform_dwords.length() > 0
  let rhs_has_explicit_geometry = rhs.vertex_data.length() > 0 ||
    rhs.indices.length() > 0 ||
    rhs.uniform_dwords.length() > 0
  lhs.dst.id == rhs.dst.id &&
  lhs.shader.id == rhs.shader.id &&
  blend_mode_eq(lhs.blend, rhs.blend) &&
  lhs.pipeline_id == rhs.pipeline_id &&
  lhs.uniform_hash == rhs.uniform_hash &&
  lhs.index_offset == rhs.index_offset &&
  int_array_eq(lhs.src_image_ids, rhs.src_image_ids) &&
  !lhs_has_explicit_geometry &&
  !rhs_has_explicit_geometry
}

///|
fn merge_draw_triangles_commands(
  lhs : DrawTrianglesCommand,
  rhs : DrawTrianglesCommand,
) -> DrawTrianglesCommand {
  let regions = lhs.dst_regions
  for region in rhs.dst_regions {
    regions.push(region)
  }
  {
    dst: lhs.dst,
    shader: lhs.shader,
    dst_regions: regions,
    index_offset: lhs.index_offset,
    pipeline_id: lhs.pipeline_id,
    uniform_hash: lhs.uniform_hash,
    blend: lhs.blend,
    vertex_data: [],
    indices: [],
    src_image_ids: lhs.src_image_ids,
    uniform_dwords: [],
  }
}

///|
pub impl CommandQueue for SimpleCommandQueue with enqueue_draw_triangles(
  self,
  command,
) {
  let len = self.commands.length()
  if len == 0 {
    self.commands.push(command)
  } else {
    let last_index = len - 1
    let last = self.commands[last_index]
    if can_merge_draw_triangles(last, command) {
      self.commands[last_index] = merge_draw_triangles_commands(last, command)
    } else {
      self.commands.push(command)
    }
  }
}

///|
pub impl CommandQueue for SimpleCommandQueue with flush(self) {
  let out = self.commands
  self.commands = []
  out
}

///|
pub fn new_simple_command_queue() -> SimpleCommandQueue {
  { commands: [] }
}

///|
pub fn[T : CommandQueue] new_command_queue() -> T {
  panic()
}

///|
pub fn[T : GraphicsDriver, Q : CommandQueue] flush_commands(
  driver : T,
  queue : Q,
  present : Bool,
) -> Unit raise {
  let commands = queue.flush()
  if commands.length() == 0 && !present {
    ()
  } else {
    driver.begin({ clear_color: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }, present })
    for command in commands {
      driver.draw_triangles(command)
    }
    driver.end(present)
  }
}

///|
pub fn[T : GraphicsDriver] clear_screen(
  driver : T,
  color : Color,
) -> Unit raise {
  driver.begin({ clear_color: color, present: false })
  driver.end(false)
}
