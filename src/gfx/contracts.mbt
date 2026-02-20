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
/// Blend factor for custom blend equations.
///
/// Ebiten refs:
/// - internal/graphicsdriver/blend.go
pub enum BlendFactor {
  Zero
  One
  SrcAlpha
  OneMinusSrcAlpha
  DstAlpha
  OneMinusDstAlpha
  SrcColor
  OneMinusSrcColor
  DstColor
  OneMinusDstColor
} derive(Show)

///|
/// Blend operation for custom blend equations.
pub enum BlendOperation {
  Add
  Subtract
  ReverseSubtract
  Min
  Max
} derive(Show)

///|
/// Custom blend equation with separate RGB and Alpha channels.
pub struct BlendEquation {
  src_factor_rgb : BlendFactor
  dst_factor_rgb : BlendFactor
  op_rgb : BlendOperation
  src_factor_alpha : BlendFactor
  dst_factor_alpha : BlendFactor
  op_alpha : BlendOperation
} derive(Show)

///|
pub enum BlendMode {
  Copy
  Alpha
  Add
  Multiply
  Custom(BlendEquation)
} derive(Show)

///|
pub fn blend_mode_to_int(mode : BlendMode) -> Int {
  match mode {
    BlendMode::Copy => 0
    BlendMode::Alpha => 1
    BlendMode::Add => 2
    BlendMode::Multiply => 3
    BlendMode::Custom(_) => 4
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
/// Get the blend equation for any BlendMode including presets.
pub fn blend_mode_to_equation(mode : BlendMode) -> BlendEquation {
  match mode {
    BlendMode::Copy => {
      src_factor_rgb: BlendFactor::One,
      dst_factor_rgb: BlendFactor::Zero,
      op_rgb: BlendOperation::Add,
      src_factor_alpha: BlendFactor::One,
      dst_factor_alpha: BlendFactor::Zero,
      op_alpha: BlendOperation::Add,
    }
    BlendMode::Alpha => {
      src_factor_rgb: BlendFactor::SrcAlpha,
      dst_factor_rgb: BlendFactor::OneMinusSrcAlpha,
      op_rgb: BlendOperation::Add,
      src_factor_alpha: BlendFactor::One,
      dst_factor_alpha: BlendFactor::OneMinusSrcAlpha,
      op_alpha: BlendOperation::Add,
    }
    BlendMode::Add => {
      src_factor_rgb: BlendFactor::SrcAlpha,
      dst_factor_rgb: BlendFactor::One,
      op_rgb: BlendOperation::Add,
      src_factor_alpha: BlendFactor::One,
      dst_factor_alpha: BlendFactor::One,
      op_alpha: BlendOperation::Add,
    }
    BlendMode::Multiply => {
      src_factor_rgb: BlendFactor::DstColor,
      dst_factor_rgb: BlendFactor::Zero,
      op_rgb: BlendOperation::Add,
      src_factor_alpha: BlendFactor::DstAlpha,
      dst_factor_alpha: BlendFactor::Zero,
      op_alpha: BlendOperation::Add,
    }
    BlendMode::Custom(eq) => eq
  }
}

///|
pub fn blend_factor_to_int(factor : BlendFactor) -> Int {
  match factor {
    BlendFactor::Zero => 0
    BlendFactor::One => 1
    BlendFactor::SrcAlpha => 2
    BlendFactor::OneMinusSrcAlpha => 3
    BlendFactor::DstAlpha => 4
    BlendFactor::OneMinusDstAlpha => 5
    BlendFactor::SrcColor => 6
    BlendFactor::OneMinusSrcColor => 7
    BlendFactor::DstColor => 8
    BlendFactor::OneMinusDstColor => 9
  }
}

///|
pub fn blend_factor_from_int(value : Int) -> BlendFactor {
  match value {
    0 => BlendFactor::Zero
    1 => BlendFactor::One
    2 => BlendFactor::SrcAlpha
    3 => BlendFactor::OneMinusSrcAlpha
    4 => BlendFactor::DstAlpha
    5 => BlendFactor::OneMinusDstAlpha
    6 => BlendFactor::SrcColor
    7 => BlendFactor::OneMinusSrcColor
    8 => BlendFactor::DstColor
    9 => BlendFactor::OneMinusDstColor
    _ => BlendFactor::One
  }
}

///|
pub fn blend_operation_to_int(op : BlendOperation) -> Int {
  match op {
    BlendOperation::Add => 0
    BlendOperation::Subtract => 1
    BlendOperation::ReverseSubtract => 2
    BlendOperation::Min => 3
    BlendOperation::Max => 4
  }
}

///|
pub fn blend_operation_from_int(value : Int) -> BlendOperation {
  match value {
    0 => BlendOperation::Add
    1 => BlendOperation::Subtract
    2 => BlendOperation::ReverseSubtract
    3 => BlendOperation::Min
    4 => BlendOperation::Max
    _ => BlendOperation::Add
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

  /// Read back framebuffer pixels as flat RGBA8 array.
  /// Returns None if readback is not supported by the backend.
  read_pixels(Self, x : Int, y : Int, width : Int, height : Int) -> Array[Int]? raise
}

///|
pub struct FramebufferSnapshot {
  x : Int
  y : Int
  width : Int
  height : Int
  pixels : Array[Int]
} derive(Show)

///|
pub fn create_framebuffer_snapshot(
  driver : &GraphicsDriver,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> FramebufferSnapshot? raise {
  match driver.read_pixels(x, y, width, height) {
    Some(pixels) => Some({ x, y, width, height, pixels })
    None => None
  }
}

///|
pub struct PixelDiffResult {
  total_pixels : Int
  diff_pixels : Int
  max_channel_diff : Int
} derive(Show)

///|
pub fn compare_framebuffer_snapshots(
  a : FramebufferSnapshot,
  b : FramebufferSnapshot,
  threshold : Int,
) -> PixelDiffResult {
  let total = a.width * a.height
  if a.width != b.width || a.height != b.height {
    return { total_pixels: total, diff_pixels: total, max_channel_diff: 255 }
  }
  let pixel_count = a.width * a.height
  let mut diff_pixels = 0
  let mut max_diff = 0
  for i = 0; i < pixel_count; i = i + 1 {
    let base = i * 4
    if base + 3 < a.pixels.length() && base + 3 < b.pixels.length() {
      let dr = abs_int(a.pixels[base] - b.pixels[base])
      let dg = abs_int(a.pixels[base + 1] - b.pixels[base + 1])
      let db = abs_int(a.pixels[base + 2] - b.pixels[base + 2])
      let da = abs_int(a.pixels[base + 3] - b.pixels[base + 3])
      let channel_max = @cmp.maximum(
        @cmp.maximum(dr, dg),
        @cmp.maximum(db, da),
      )
      if channel_max > max_diff {
        max_diff = channel_max
      }
      if channel_max > threshold {
        diff_pixels = diff_pixels + 1
      }
    }
  }
  { total_pixels: pixel_count, diff_pixels, max_channel_diff: max_diff }
}

///|
fn abs_int(x : Int) -> Int {
  if x < 0 { -x } else { x }
}

///|
pub fn pixel_diff_ratio(result : PixelDiffResult) -> Double {
  if result.total_pixels == 0 {
    return 0.0
  }
  result.diff_pixels.to_double() / result.total_pixels.to_double()
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
fn blend_factor_eq(lhs : BlendFactor, rhs : BlendFactor) -> Bool {
  blend_factor_to_int(lhs) == blend_factor_to_int(rhs)
}

///|
fn blend_operation_eq(lhs : BlendOperation, rhs : BlendOperation) -> Bool {
  blend_operation_to_int(lhs) == blend_operation_to_int(rhs)
}

///|
fn blend_equation_eq(lhs : BlendEquation, rhs : BlendEquation) -> Bool {
  blend_factor_eq(lhs.src_factor_rgb, rhs.src_factor_rgb) &&
  blend_factor_eq(lhs.dst_factor_rgb, rhs.dst_factor_rgb) &&
  blend_operation_eq(lhs.op_rgb, rhs.op_rgb) &&
  blend_factor_eq(lhs.src_factor_alpha, rhs.src_factor_alpha) &&
  blend_factor_eq(lhs.dst_factor_alpha, rhs.dst_factor_alpha) &&
  blend_operation_eq(lhs.op_alpha, rhs.op_alpha)
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
    BlendMode::Custom(eq_l) =>
      match rhs {
        BlendMode::Custom(eq_r) => blend_equation_eq(eq_l, eq_r)
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
let vertex_stride : Int = 4

///|
let max_merge_vertex_floats : Int = 16384

///|
fn can_merge_draw_triangles(
  lhs : DrawTrianglesCommand,
  rhs : DrawTrianglesCommand,
) -> Bool {
  let lhs_explicit = lhs.vertex_data.length() > 0 || lhs.indices.length() > 0
  let rhs_explicit = rhs.vertex_data.length() > 0 || rhs.indices.length() > 0
  lhs_explicit == rhs_explicit &&
  lhs.vertex_data.length() + rhs.vertex_data.length() <= max_merge_vertex_floats &&
  lhs.dst.id == rhs.dst.id &&
  lhs.shader.id == rhs.shader.id &&
  blend_mode_eq(lhs.blend, rhs.blend) &&
  lhs.pipeline_id == rhs.pipeline_id &&
  lhs.uniform_hash == rhs.uniform_hash &&
  lhs.index_offset == rhs.index_offset &&
  int_array_eq(lhs.src_image_ids, rhs.src_image_ids) &&
  int_array_eq(lhs.uniform_dwords, rhs.uniform_dwords)
}

///|
fn can_merge_draw_triangles_with_vertex_budget(
  lhs : DrawTrianglesCommand,
  rhs : DrawTrianglesCommand,
  lhs_vertex_float_count : Int,
) -> Bool {
  can_merge_draw_triangles(lhs, rhs) &&
  lhs_vertex_float_count + rhs.vertex_data.length() <= max_merge_vertex_floats
}

///|
fn merge_draw_triangles_range(
  commands : Array[DrawTrianglesCommand],
  start : Int,
  end : Int,
) -> DrawTrianglesCommand {
  let base = commands[start]
  let explicit = base.vertex_data.length() > 0 || base.indices.length() > 0
  let merged_regions : Array[DstRegion] = []
  for i in start..<end {
    let command = commands[i]
    for region in command.dst_regions {
      merged_regions.push(region)
    }
  }
  if !explicit {
    {
      dst: base.dst,
      shader: base.shader,
      dst_regions: merged_regions,
      index_offset: base.index_offset,
      pipeline_id: base.pipeline_id,
      uniform_hash: base.uniform_hash,
      blend: base.blend,
      vertex_data: [],
      indices: [],
      src_image_ids: base.src_image_ids,
      uniform_dwords: base.uniform_dwords,
    }
  } else {
    let mut merged_vertex_float_count = 0
    let mut merged_index_count = 0
    for i in start..<end {
      merged_vertex_float_count = merged_vertex_float_count +
        commands[i].vertex_data.length()
      merged_index_count = merged_index_count + commands[i].indices.length()
    }
    let merged_vertex_data : Array[Double] = Array::make(
      merged_vertex_float_count,
      0.0,
    )
    let merged_indices : Array[Int] = Array::make(merged_index_count, 0)
    let mut vertex_offset = 0
    let mut index_offset = 0
    let mut vertex_base = 0
    for i in start..<end {
      let command = commands[i]
      for v in command.vertex_data {
        merged_vertex_data[vertex_offset] = v
        vertex_offset = vertex_offset + 1
      }
      for idx in command.indices {
        merged_indices[index_offset] = idx + vertex_base
        index_offset = index_offset + 1
      }
      vertex_base = vertex_base + command.vertex_data.length() / vertex_stride
    }
    {
      dst: base.dst,
      shader: base.shader,
      dst_regions: merged_regions,
      index_offset: base.index_offset,
      pipeline_id: base.pipeline_id,
      uniform_hash: base.uniform_hash,
      blend: base.blend,
      vertex_data: merged_vertex_data,
      indices: merged_indices,
      src_image_ids: base.src_image_ids,
      uniform_dwords: base.uniform_dwords,
    }
  }
}

///|
pub impl CommandQueue for SimpleCommandQueue with enqueue_draw_triangles(
  self,
  command,
) {
  self.commands.push(command)
}

///|
pub impl CommandQueue for SimpleCommandQueue with flush(self) {
  let buffered = self.commands
  self.commands = []
  if buffered.length() <= 1 {
    return buffered
  }
  let out : Array[DrawTrianglesCommand] = []
  let mut start = 0
  while start < buffered.length() {
    let base = buffered[start]
    let mut end = start + 1
    let mut vertex_budget = base.vertex_data.length()
    while end < buffered.length() {
      let command = buffered[end]
      if
        can_merge_draw_triangles_with_vertex_budget(
          base,
          command,
          vertex_budget,
        ) {
        vertex_budget = vertex_budget + command.vertex_data.length()
        end = end + 1
      } else {
        break
      }
    }
    if end - start == 1 {
      out.push(base)
    } else {
      out.push(merge_draw_triangles_range(buffered, start, end))
    }
    start = end
  }
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
