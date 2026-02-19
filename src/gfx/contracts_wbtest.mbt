///|
let test_native_gfx_init_calls : Ref[Int] = Ref::new(0)

///|
let test_native_gfx_begin_calls : Ref[Int] = Ref::new(0)

///|
let test_native_gfx_end_calls : Ref[Int] = Ref::new(0)

///|
let test_native_gfx_draw_calls : Ref[Int] = Ref::new(0)

///|
let test_native_gfx_resize_calls : Ref[Int] = Ref::new(0)

///|
let test_native_gfx_last_resize_width : Ref[Int] = Ref::new(0)

///|
let test_native_gfx_last_resize_height : Ref[Int] = Ref::new(0)

///|
fn test_native_gfx_try_initialize(_width : Int, _height : Int) -> Bool {
  test_native_gfx_init_calls.val = test_native_gfx_init_calls.val + 1
  true
}

///|
fn test_native_gfx_on_begin(active : Bool, _pass : RenderPassDesc) -> Unit {
  if active {
    test_native_gfx_begin_calls.val = test_native_gfx_begin_calls.val + 1
  }
}

///|
fn test_native_gfx_on_end(active : Bool, present : Bool) -> Unit {
  if active && present {
    test_native_gfx_end_calls.val = test_native_gfx_end_calls.val + 1
  }
}

///|
fn test_native_gfx_on_draw(
  active : Bool,
  _command : DrawTrianglesCommand,
) -> Unit {
  if active {
    test_native_gfx_draw_calls.val = test_native_gfx_draw_calls.val + 1
  }
}

///|
fn test_native_gfx_on_resize(active : Bool, width : Int, height : Int) -> Unit {
  if active {
    test_native_gfx_resize_calls.val = test_native_gfx_resize_calls.val + 1
    test_native_gfx_last_resize_width.val = width
    test_native_gfx_last_resize_height.val = height
  }
}

///|
let test_web_gfx_init_calls : Ref[Int] = Ref::new(0)

///|
let test_web_gfx_begin_calls : Ref[Int] = Ref::new(0)

///|
let test_web_gfx_end_calls : Ref[Int] = Ref::new(0)

///|
let test_web_gfx_draw_calls : Ref[Int] = Ref::new(0)

///|
let test_web_gfx_resize_calls : Ref[Int] = Ref::new(0)

///|
let test_web_gfx_last_resize_width : Ref[Int] = Ref::new(0)

///|
let test_web_gfx_last_resize_height : Ref[Int] = Ref::new(0)

///|
fn test_web_gfx_try_initialize(
  kind : GraphicsBackendKind,
  _width : Int,
  _height : Int,
) -> Bool {
  test_web_gfx_init_calls.val = test_web_gfx_init_calls.val + 1
  match kind {
    GraphicsBackendKind::WebGpu => true
    GraphicsBackendKind::WebGl2 => true
    _ => false
  }
}

///|
fn test_web_gfx_on_begin(
  active : Bool,
  kind : GraphicsBackendKind,
  _pass : RenderPassDesc,
) -> Unit {
  if active {
    match kind {
      GraphicsBackendKind::WebGpu | GraphicsBackendKind::WebGl2 =>
        test_web_gfx_begin_calls.val = test_web_gfx_begin_calls.val + 1
      _ => ()
    }
  }
}

///|
fn test_web_gfx_on_end(
  active : Bool,
  kind : GraphicsBackendKind,
  present : Bool,
) -> Unit {
  if active && present {
    match kind {
      GraphicsBackendKind::WebGpu | GraphicsBackendKind::WebGl2 =>
        test_web_gfx_end_calls.val = test_web_gfx_end_calls.val + 1
      _ => ()
    }
  }
}

///|
fn test_web_gfx_on_draw(
  active : Bool,
  kind : GraphicsBackendKind,
  _command : DrawTrianglesCommand,
) -> Unit {
  if active {
    match kind {
      GraphicsBackendKind::WebGpu | GraphicsBackendKind::WebGl2 =>
        test_web_gfx_draw_calls.val = test_web_gfx_draw_calls.val + 1
      _ => ()
    }
  }
}

///|
fn test_web_gfx_on_resize(
  active : Bool,
  kind : GraphicsBackendKind,
  width : Int,
  height : Int,
) -> Unit {
  if active {
    match kind {
      GraphicsBackendKind::WebGpu | GraphicsBackendKind::WebGl2 => {
        test_web_gfx_resize_calls.val = test_web_gfx_resize_calls.val + 1
        test_web_gfx_last_resize_width.val = width
        test_web_gfx_last_resize_height.val = height
      }
      _ => ()
    }
  }
}

///|
fn queue_test_command(
  dst_id : Int,
  shader_id : Int,
  blend : BlendMode,
  index_offset : Int,
  pipeline_id : Int,
  uniform_hash : Int,
  region_x : Int,
) -> DrawTrianglesCommand {
  {
    dst: { id: dst_id, width: 64, height: 64 },
    shader: { id: shader_id, source: "shader-\{shader_id}" },
    dst_regions: [{ x: region_x, y: 0, width: 32, height: 32, index_count: 3 }],
    index_offset,
    pipeline_id,
    uniform_hash,
    blend,
    vertex_data: [],
    indices: [],
    src_image_ids: [],
    uniform_dwords: [],
  }
}

///|
fn queue_test_command_with_source_ids(
  dst_id : Int,
  shader_id : Int,
  blend : BlendMode,
  index_offset : Int,
  pipeline_id : Int,
  uniform_hash : Int,
  region_x : Int,
  src_image_ids : Array[Int],
) -> DrawTrianglesCommand {
  {
    dst: { id: dst_id, width: 64, height: 64 },
    shader: { id: shader_id, source: "shader-\{shader_id}" },
    dst_regions: [{ x: region_x, y: 0, width: 32, height: 32, index_count: 3 }],
    index_offset,
    pipeline_id,
    uniform_hash,
    blend,
    vertex_data: [],
    indices: [],
    src_image_ids,
    uniform_dwords: [],
  }
}

///|
fn queue_test_command_with_sources_and_uniforms(
  dst_id : Int,
  shader_id : Int,
  blend : BlendMode,
  index_offset : Int,
  pipeline_id : Int,
  uniform_hash : Int,
  region_x : Int,
  src_image_ids : Array[Int],
  uniform_dwords : Array[Int],
) -> DrawTrianglesCommand {
  {
    dst: { id: dst_id, width: 64, height: 64 },
    shader: { id: shader_id, source: "shader-\{shader_id}" },
    dst_regions: [{ x: region_x, y: 0, width: 32, height: 32, index_count: 3 }],
    index_offset,
    pipeline_id,
    uniform_hash,
    blend,
    vertex_data: [],
    indices: [],
    src_image_ids,
    uniform_dwords,
  }
}

///|
test "native graphics hooks can be overridden and reset" {
  reset_native_graphics_hooks()
  test_native_gfx_init_calls.val = 0
  test_native_gfx_begin_calls.val = 0
  test_native_gfx_end_calls.val = 0
  test_native_gfx_draw_calls.val = 0
  test_native_gfx_resize_calls.val = 0
  test_native_gfx_last_resize_width.val = 0
  test_native_gfx_last_resize_height.val = 0

  set_native_graphics_hooks(
    new_native_graphics_hooks(
      test_native_gfx_try_initialize, test_native_gfx_on_begin, test_native_gfx_on_end,
      test_native_gfx_on_draw, test_native_gfx_on_resize,
    ),
  )

  let surface = @platform.create_offscreen_surface_token(320, 240)
  let options = default_graphics_backend_options()
  let driver = create_wgpu_native_graphics(surface, options)
  driver.initialize()

  let dst = driver.new_image(64, 64)
  let shader = driver.new_shader("shader")
  let command : DrawTrianglesCommand = {
    dst,
    shader,
    dst_regions: [{ x: 0, y: 0, width: 64, height: 64, index_count: 3 }],
    index_offset: 0,
    pipeline_id: 1,
    uniform_hash: 1,
    blend: BlendMode::Alpha,
    vertex_data: [],
    indices: [],
    src_image_ids: [],
    uniform_dwords: [],
  }
  let pass = new_render_pass_desc(new_color(0.0, 0.0, 0.0, 1.0), true)

  driver.begin(pass)
  driver.draw_triangles(command)
  driver.end(true)
  driver.resize(640, 360)

  assert_eq(test_native_gfx_init_calls.val, 1)
  assert_eq(test_native_gfx_begin_calls.val, 1)
  assert_eq(test_native_gfx_end_calls.val, 1)
  assert_eq(test_native_gfx_draw_calls.val, 1)
  assert_eq(test_native_gfx_resize_calls.val, 1)
  assert_eq(test_native_gfx_last_resize_width.val, 640)
  assert_eq(test_native_gfx_last_resize_height.val, 360)
  assert_eq(driver.width, 640)
  assert_eq(driver.height, 360)

  reset_native_graphics_hooks()

  let before_init_calls = test_native_gfx_init_calls.val
  let before_begin_calls = test_native_gfx_begin_calls.val
  let before_end_calls = test_native_gfx_end_calls.val
  let before_draw_calls = test_native_gfx_draw_calls.val
  let before_resize_calls = test_native_gfx_resize_calls.val
  let driver2 = create_wgpu_native_graphics(surface, options)
  driver2.initialize()

  let dst2 = driver2.new_image(64, 64)
  let shader2 = driver2.new_shader("shader")
  driver2.begin(pass)
  driver2.draw_triangles({
    dst: dst2,
    shader: shader2,
    dst_regions: [{ x: 0, y: 0, width: 64, height: 64, index_count: 3 }],
    index_offset: 0,
    pipeline_id: 1,
    uniform_hash: 1,
    blend: BlendMode::Alpha,
    vertex_data: [],
    indices: [],
    src_image_ids: [],
    uniform_dwords: [],
  })
  driver2.end(true)
  driver2.resize(320, 200)

  assert_true(!driver2.native_active)
  assert_eq(test_native_gfx_init_calls.val, before_init_calls)
  assert_eq(test_native_gfx_begin_calls.val, before_begin_calls)
  assert_eq(test_native_gfx_end_calls.val, before_end_calls)
  assert_eq(test_native_gfx_draw_calls.val, before_draw_calls)
  assert_eq(test_native_gfx_resize_calls.val, before_resize_calls)
  assert_eq(driver2.width, 320)
  assert_eq(driver2.height, 200)
}

///|
test "web graphics hooks can be overridden and reset" {
  reset_web_graphics_hooks()
  test_web_gfx_init_calls.val = 0
  test_web_gfx_begin_calls.val = 0
  test_web_gfx_end_calls.val = 0
  test_web_gfx_draw_calls.val = 0
  test_web_gfx_resize_calls.val = 0
  test_web_gfx_last_resize_width.val = 0
  test_web_gfx_last_resize_height.val = 0

  set_web_graphics_hooks(
    new_web_graphics_hooks(
      test_web_gfx_try_initialize, test_web_gfx_on_begin, test_web_gfx_on_end, test_web_gfx_on_draw,
      test_web_gfx_on_resize,
    ),
  )

  let surface = @platform.create_offscreen_surface_token(320, 240)
  let options = default_graphics_backend_options()
  let driver = create_webgpu_graphics(surface, options)
  driver.initialize()

  let dst = driver.new_image(64, 64)
  let shader = driver.new_shader("shader")
  let command : DrawTrianglesCommand = {
    dst,
    shader,
    dst_regions: [{ x: 0, y: 0, width: 64, height: 64, index_count: 3 }],
    index_offset: 0,
    pipeline_id: 1,
    uniform_hash: 1,
    blend: BlendMode::Alpha,
    vertex_data: [],
    indices: [],
    src_image_ids: [],
    uniform_dwords: [],
  }
  let pass = new_render_pass_desc(new_color(0.0, 0.0, 0.0, 1.0), true)

  driver.begin(pass)
  driver.draw_triangles(command)
  driver.end(true)
  driver.resize(800, 450)

  assert_eq(test_web_gfx_init_calls.val, 1)
  assert_eq(test_web_gfx_begin_calls.val, 1)
  assert_eq(test_web_gfx_end_calls.val, 1)
  assert_eq(test_web_gfx_draw_calls.val, 1)
  assert_eq(test_web_gfx_resize_calls.val, 1)
  assert_eq(test_web_gfx_last_resize_width.val, 800)
  assert_eq(test_web_gfx_last_resize_height.val, 450)
  assert_eq(driver.width, 800)
  assert_eq(driver.height, 450)

  reset_web_graphics_hooks()

  let before_init_calls = test_web_gfx_init_calls.val
  let before_begin_calls = test_web_gfx_begin_calls.val
  let before_end_calls = test_web_gfx_end_calls.val
  let before_draw_calls = test_web_gfx_draw_calls.val
  let before_resize_calls = test_web_gfx_resize_calls.val
  let driver2 = create_webgpu_graphics(surface, options)
  driver2.initialize()

  let dst2 = driver2.new_image(64, 64)
  let shader2 = driver2.new_shader("shader")
  driver2.begin(pass)
  driver2.draw_triangles({
    dst: dst2,
    shader: shader2,
    dst_regions: [{ x: 0, y: 0, width: 64, height: 64, index_count: 3 }],
    index_offset: 0,
    pipeline_id: 1,
    uniform_hash: 1,
    blend: BlendMode::Alpha,
    vertex_data: [],
    indices: [],
    src_image_ids: [],
    uniform_dwords: [],
  })
  driver2.end(true)
  driver2.resize(400, 225)

  assert_eq(test_web_gfx_init_calls.val, before_init_calls)
  assert_eq(test_web_gfx_begin_calls.val, before_begin_calls)
  assert_eq(test_web_gfx_end_calls.val, before_end_calls)
  assert_eq(test_web_gfx_draw_calls.val, before_draw_calls)
  assert_eq(test_web_gfx_resize_calls.val, before_resize_calls)
  assert_eq(driver2.width, 400)
  assert_eq(driver2.height, 225)
}

///|
test "command queue flush calls driver draw" {
  let driver = create_null_graphics(320, 240)
  driver.initialize()

  let dst = driver.new_image(64, 64)
  let shader = driver.new_shader("shader")
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles({
    dst,
    shader,
    dst_regions: [{ x: 0, y: 0, width: 64, height: 64, index_count: 3 }],
    index_offset: 0,
    pipeline_id: 1,
    uniform_hash: 1,
    blend: BlendMode::Alpha,
    vertex_data: [],
    indices: [],
    src_image_ids: [],
    uniform_dwords: [],
  })

  flush_commands(driver, queue, true)

  assert_eq(driver.draw_count, 1)
  assert_eq(driver.begin_count, 1)
  assert_eq(driver.end_count, 1)
}

///|
test "command queue merges consecutive compatible draw commands" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Alpha, 0, 1, 7, 0),
  )
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Alpha, 0, 1, 7, 32),
  )

  let commands = queue.flush()
  assert_eq(commands.length(), 1)
  assert_eq(commands[0].dst_regions.length(), 2)
}

///|
test "command queue does not merge when blend mode differs" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Alpha, 0, 1, 7, 0),
  )
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Add, 0, 1, 7, 32),
  )

  let commands = queue.flush()
  assert_eq(commands.length(), 2)
}

///|
test "command queue does not merge when index_offset differs" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Alpha, 0, 1, 7, 0),
  )
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Alpha, 3, 1, 7, 32),
  )

  let commands = queue.flush()
  assert_eq(commands.length(), 2)
}

///|
test "command queue does not merge when pipeline differs" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Alpha, 0, 1, 7, 0),
  )
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Alpha, 0, 2, 7, 32),
  )

  let commands = queue.flush()
  assert_eq(commands.length(), 2)
}

///|
test "command queue does not merge when uniform hash differs" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Alpha, 0, 1, 7, 0),
  )
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Alpha, 0, 1, 8, 32),
  )

  let commands = queue.flush()
  assert_eq(commands.length(), 2)
}

///|
test "command queue merges compatible commands with same source image ids" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_command_with_source_ids(
      1,
      1,
      BlendMode::Alpha,
      0,
      1,
      7,
      0,
      [801],
    ),
  )
  queue.enqueue_draw_triangles(
    queue_test_command_with_source_ids(
      1,
      1,
      BlendMode::Alpha,
      0,
      1,
      7,
      32,
      [801],
    ),
  )

  let commands = queue.flush()
  assert_eq(commands.length(), 1)
  assert_eq(commands[0].dst_regions.length(), 2)
  assert_eq(commands[0].src_image_ids.length(), 1)
  assert_eq(commands[0].src_image_ids[0], 801)
}

///|
test "command queue does not merge when source image ids differ" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_command_with_source_ids(
      1,
      1,
      BlendMode::Alpha,
      0,
      1,
      7,
      0,
      [801],
    ),
  )
  queue.enqueue_draw_triangles(
    queue_test_command_with_source_ids(
      1,
      1,
      BlendMode::Alpha,
      0,
      1,
      7,
      32,
      [802],
    ),
  )

  let commands = queue.flush()
  assert_eq(commands.length(), 2)
}

///|
test "command queue merges compatible commands with same uniform dwords" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_command_with_sources_and_uniforms(
      1,
      1,
      BlendMode::Alpha,
      0,
      1,
      7,
      0,
      [801],
      [1, 2, 3, 4],
    ),
  )
  queue.enqueue_draw_triangles(
    queue_test_command_with_sources_and_uniforms(
      1,
      1,
      BlendMode::Alpha,
      0,
      1,
      7,
      32,
      [801],
      [1, 2, 3, 4],
    ),
  )

  let commands = queue.flush()
  assert_eq(commands.length(), 1)
  assert_eq(commands[0].uniform_dwords.length(), 4)
  assert_eq(commands[0].uniform_dwords[0], 1)
}

///|
test "command queue does not merge when uniform dwords differ" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_command_with_sources_and_uniforms(
      1,
      1,
      BlendMode::Alpha,
      0,
      1,
      7,
      0,
      [801],
      [1, 2, 3, 4],
    ),
  )
  queue.enqueue_draw_triangles(
    queue_test_command_with_sources_and_uniforms(
      1,
      1,
      BlendMode::Alpha,
      0,
      1,
      7,
      32,
      [801],
      [5, 6, 7, 8],
    ),
  )

  let commands = queue.flush()
  assert_eq(commands.length(), 2)
}

///|
test "estimated_draw_call_count uses region index_count as triangle budget" {
  let command : DrawTrianglesCommand = {
    dst: { id: 1, width: 64, height: 64 },
    shader: { id: 1, source: "shader-1" },
    dst_regions: [
      { x: 0, y: 0, width: 32, height: 32, index_count: 6 },
      { x: 32, y: 0, width: 32, height: 32, index_count: 3 },
      { x: 0, y: 32, width: 32, height: 32, index_count: 4 },
      { x: 32, y: 32, width: 32, height: 32, index_count: 0 },
      { x: 0, y: 64, width: 32, height: 32, index_count: -1 },
    ],
    index_offset: 0,
    pipeline_id: 1,
    uniform_hash: 1,
    blend: BlendMode::Alpha,
    vertex_data: [],
    indices: [],
    src_image_ids: [],
    uniform_dwords: [],
  }

  assert_eq(estimated_draw_call_count(command), 6)
}

///|
test "estimated_draw_call_count is zero for empty regions" {
  let command : DrawTrianglesCommand = {
    dst: { id: 1, width: 64, height: 64 },
    shader: { id: 1, source: "shader-1" },
    dst_regions: [],
    index_offset: 0,
    pipeline_id: 1,
    uniform_hash: 1,
    blend: BlendMode::Alpha,
    vertex_data: [],
    indices: [],
    src_image_ids: [],
    uniform_dwords: [],
  }

  assert_eq(estimated_draw_call_count(command), 0)
}

///|
test "blend mode int conversion roundtrip" {
  assert_eq(blend_mode_to_int(BlendMode::Copy), 0)
  assert_eq(blend_mode_to_int(BlendMode::Alpha), 1)
  assert_eq(blend_mode_to_int(BlendMode::Add), 2)
  assert_eq(blend_mode_to_int(BlendMode::Multiply), 3)

  assert_eq(blend_mode_to_int(blend_mode_from_int(0)), 0)
  assert_eq(blend_mode_to_int(blend_mode_from_int(1)), 1)
  assert_eq(blend_mode_to_int(blend_mode_from_int(2)), 2)
  assert_eq(blend_mode_to_int(blend_mode_from_int(3)), 3)
  assert_eq(blend_mode_to_int(blend_mode_from_int(-1)), 1)
  assert_eq(blend_mode_to_int(blend_mode_from_int(99)), 1)
}

///|
test "filter mode int conversion roundtrip" {
  assert_eq(filter_mode_to_int(FilterMode::Nearest), 0)
  assert_eq(filter_mode_to_int(FilterMode::Linear), 1)
  assert_eq(filter_mode_to_int(FilterMode::Pixelated), 2)

  assert_eq(filter_mode_to_int(filter_mode_from_int(0)), 0)
  assert_eq(filter_mode_to_int(filter_mode_from_int(1)), 1)
  assert_eq(filter_mode_to_int(filter_mode_from_int(2)), 2)
  assert_eq(filter_mode_to_int(filter_mode_from_int(-1)), 0)
  assert_eq(filter_mode_to_int(filter_mode_from_int(99)), 0)
}

///|
test "draw command dispatch captures backend boundary payload" {
  let command : DrawTrianglesCommand = {
    dst: { id: 10, width: 64, height: 64 },
    shader: { id: 20, source: "shader-20" },
    dst_regions: [
      { x: 0, y: 0, width: 32, height: 32, index_count: 6 },
      { x: 32, y: 0, width: 32, height: 32, index_count: 3 },
    ],
    index_offset: 0,
    pipeline_id: 7,
    uniform_hash: 11,
    blend: BlendMode::Add,
    vertex_data: [
      -0.5, -0.5, 0.0, 0.0, 0.5, -0.5, 1.0, 0.0, 0.5, 0.5, 1.0, 1.0, -0.5, 0.5, 0.0,
      1.0,
    ],
    indices: [0, 1, 2, 2, 3, 0],
    src_image_ids: [30, 31],
    uniform_dwords: [1, 2, 3],
  }

  let dispatch = build_draw_command_dispatch(command)
  assert_eq(dispatch.draw_calls, 3)
  assert_eq(dispatch.pipeline_id, 7)
  assert_eq(dispatch.uniform_hash, 11)
  assert_eq(dispatch.blend_mode, 2)
  assert_eq(dispatch.dst_image_id, 10)
  assert_eq(dispatch.shader_id, 20)
  assert_eq(dispatch.index_offset, 0)
  assert_eq(dispatch.region_count, 2)
  assert_eq(dispatch.total_index_count, 9)
  assert_eq(dispatch.vertex_float_count, 16)
  assert_eq(dispatch.index_count, 6)
  assert_eq(dispatch.src_image_count, 2)
  assert_eq(dispatch.uniform_dword_count, 3)
}

///|
test "draw command dispatch falls back index count to region totals" {
  let command : DrawTrianglesCommand = {
    dst: { id: 1, width: 64, height: 64 },
    shader: { id: 2, source: "shader-2" },
    dst_regions: [
      { x: 0, y: 0, width: 32, height: 32, index_count: 6 },
      { x: 32, y: 0, width: 32, height: 32, index_count: 3 },
    ],
    index_offset: 0,
    pipeline_id: 3,
    uniform_hash: 4,
    blend: BlendMode::Alpha,
    vertex_data: [],
    indices: [],
    src_image_ids: [],
    uniform_dwords: [],
  }

  let dispatch = build_draw_command_dispatch(command)
  assert_eq(dispatch.total_index_count, 9)
  assert_eq(dispatch.index_count, 9)
  assert_eq(dispatch.vertex_float_count, 0)
  assert_eq(dispatch.src_image_count, 0)
  assert_eq(dispatch.uniform_dword_count, 0)
}

///|
test "null graphics backend constructors are available" {
  let surface = @platform.create_offscreen_surface_token(320, 240)
  let options = default_graphics_backend_options()
  let _ = create_webgpu_graphics(surface, options)
  let _ = create_webgl_graphics(surface, options)
  let _ = create_wgpu_native_graphics(surface, options)
}
