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
test "blend factor int conversion roundtrip" {
  let factors : Array[BlendFactor] = [
    BlendFactor::Zero,
    BlendFactor::One,
    BlendFactor::SrcAlpha,
    BlendFactor::OneMinusSrcAlpha,
    BlendFactor::DstAlpha,
    BlendFactor::OneMinusDstAlpha,
    BlendFactor::SrcColor,
    BlendFactor::OneMinusSrcColor,
    BlendFactor::DstColor,
    BlendFactor::OneMinusDstColor,
  ]
  for factor in factors {
    let i = blend_factor_to_int(factor)
    let rt = blend_factor_from_int(i)
    assert_eq(blend_factor_to_int(rt), i)
  }
  // Invalid defaults to One
  assert_eq(blend_factor_to_int(blend_factor_from_int(99)), 1)
}

///|
test "blend operation int conversion roundtrip" {
  let ops : Array[BlendOperation] = [
    BlendOperation::Add,
    BlendOperation::Subtract,
    BlendOperation::ReverseSubtract,
    BlendOperation::Min,
    BlendOperation::Max,
  ]
  for op in ops {
    let i = blend_operation_to_int(op)
    let rt = blend_operation_from_int(i)
    assert_eq(blend_operation_to_int(rt), i)
  }
  // Invalid defaults to Add
  assert_eq(blend_operation_to_int(blend_operation_from_int(99)), 0)
}

///|
test "blend_mode_to_equation preset Copy" {
  let eq = blend_mode_to_equation(BlendMode::Copy)
  assert_eq(blend_factor_to_int(eq.src_factor_rgb), blend_factor_to_int(BlendFactor::One))
  assert_eq(blend_factor_to_int(eq.dst_factor_rgb), blend_factor_to_int(BlendFactor::Zero))
  assert_eq(blend_operation_to_int(eq.op_rgb), blend_operation_to_int(BlendOperation::Add))
}

///|
test "blend_mode_to_equation preset Alpha" {
  let eq = blend_mode_to_equation(BlendMode::Alpha)
  assert_eq(blend_factor_to_int(eq.src_factor_rgb), blend_factor_to_int(BlendFactor::SrcAlpha))
  assert_eq(
    blend_factor_to_int(eq.dst_factor_rgb),
    blend_factor_to_int(BlendFactor::OneMinusSrcAlpha),
  )
}

///|
test "blend_mode_to_equation preset Add" {
  let eq = blend_mode_to_equation(BlendMode::Add)
  assert_eq(blend_factor_to_int(eq.src_factor_rgb), blend_factor_to_int(BlendFactor::SrcAlpha))
  assert_eq(blend_factor_to_int(eq.dst_factor_rgb), blend_factor_to_int(BlendFactor::One))
}

///|
test "blend_mode_to_equation preset Multiply" {
  let eq = blend_mode_to_equation(BlendMode::Multiply)
  assert_eq(blend_factor_to_int(eq.src_factor_rgb), blend_factor_to_int(BlendFactor::DstColor))
  assert_eq(blend_factor_to_int(eq.dst_factor_rgb), blend_factor_to_int(BlendFactor::Zero))
}

///|
test "Custom blend mode equality" {
  let eq1 : BlendEquation = {
    src_factor_rgb: BlendFactor::SrcAlpha,
    dst_factor_rgb: BlendFactor::One,
    op_rgb: BlendOperation::Add,
    src_factor_alpha: BlendFactor::One,
    dst_factor_alpha: BlendFactor::One,
    op_alpha: BlendOperation::Add,
  }
  let eq2 : BlendEquation = {
    src_factor_rgb: BlendFactor::SrcAlpha,
    dst_factor_rgb: BlendFactor::One,
    op_rgb: BlendOperation::Add,
    src_factor_alpha: BlendFactor::One,
    dst_factor_alpha: BlendFactor::One,
    op_alpha: BlendOperation::Add,
  }
  let eq3 : BlendEquation = {
    src_factor_rgb: BlendFactor::Zero,
    dst_factor_rgb: BlendFactor::One,
    op_rgb: BlendOperation::Add,
    src_factor_alpha: BlendFactor::One,
    dst_factor_alpha: BlendFactor::One,
    op_alpha: BlendOperation::Add,
  }
  assert_true(blend_mode_eq(BlendMode::Custom(eq1), BlendMode::Custom(eq2)))
  assert_true(!blend_mode_eq(BlendMode::Custom(eq1), BlendMode::Custom(eq3)))
  assert_true(!blend_mode_eq(BlendMode::Custom(eq1), BlendMode::Alpha))
  assert_true(!blend_mode_eq(BlendMode::Alpha, BlendMode::Custom(eq1)))
}

///|
test "Custom blend mode to_int returns 4" {
  let eq : BlendEquation = {
    src_factor_rgb: BlendFactor::One,
    dst_factor_rgb: BlendFactor::Zero,
    op_rgb: BlendOperation::Add,
    src_factor_alpha: BlendFactor::One,
    dst_factor_alpha: BlendFactor::Zero,
    op_alpha: BlendOperation::Add,
  }
  assert_eq(blend_mode_to_int(BlendMode::Custom(eq)), 4)
}

///|
test "Custom blend mode to_equation roundtrip" {
  let eq : BlendEquation = {
    src_factor_rgb: BlendFactor::DstColor,
    dst_factor_rgb: BlendFactor::OneMinusSrcAlpha,
    op_rgb: BlendOperation::Subtract,
    src_factor_alpha: BlendFactor::SrcAlpha,
    dst_factor_alpha: BlendFactor::DstAlpha,
    op_alpha: BlendOperation::Max,
  }
  let mode = BlendMode::Custom(eq)
  let eq_out = blend_mode_to_equation(mode)
  assert_true(blend_equation_eq(eq, eq_out))
}

///|
test "command queue does not merge when custom blend differs" {
  let queue = new_simple_command_queue()
  let eq1 : BlendEquation = {
    src_factor_rgb: BlendFactor::SrcAlpha,
    dst_factor_rgb: BlendFactor::One,
    op_rgb: BlendOperation::Add,
    src_factor_alpha: BlendFactor::One,
    dst_factor_alpha: BlendFactor::One,
    op_alpha: BlendOperation::Add,
  }
  let eq2 : BlendEquation = {
    src_factor_rgb: BlendFactor::Zero,
    dst_factor_rgb: BlendFactor::SrcColor,
    op_rgb: BlendOperation::Add,
    src_factor_alpha: BlendFactor::One,
    dst_factor_alpha: BlendFactor::One,
    op_alpha: BlendOperation::Add,
  }
  let base = {
    dst: { id: 1, width: 10, height: 10 },
    shader: { id: 1, source: "s" },
    dst_regions: [{ x: 0, y: 0, width: 10, height: 10, index_count: 3 }],
    index_offset: 0,
    pipeline_id: 1,
    uniform_hash: 0,
    blend: BlendMode::Custom(eq1),
    vertex_data: [],
    indices: [],
    src_image_ids: [],
    uniform_dwords: [],
  }
  queue.enqueue_draw_triangles(base)
  queue.enqueue_draw_triangles({
    ..base,
    blend: BlendMode::Custom(eq2),
  })
  let flushed = queue.flush()
  assert_eq(flushed.length(), 2)
}

///|
test "null graphics backend constructors are available" {
  let surface = @platform.create_offscreen_surface_token(320, 240)
  let options = default_graphics_backend_options()
  let _ = create_webgpu_graphics(surface, options)
  let _ = create_webgl_graphics(surface, options)
  let _ = create_wgpu_native_graphics(surface, options)
}

///|
test "graphics_resize_stats tracks resize and suppressed counts" {
  let driver = create_null_graphics(640, 480)
  driver.initialize()
  let stats0 = graphics_resize_stats(driver)
  assert_eq(stats0.resize_count, 0)
  assert_eq(stats0.suppressed_count, 0)
  assert_eq(stats0.current_width, 640)
  assert_eq(stats0.current_height, 480)

  // Actual resize
  driver.resize(800, 600)
  let stats1 = graphics_resize_stats(driver)
  assert_eq(stats1.resize_count, 1)
  assert_eq(stats1.suppressed_count, 0)
  assert_eq(stats1.current_width, 800)
  assert_eq(stats1.current_height, 600)

  // Suppressed (same dimensions)
  driver.resize(800, 600)
  let stats2 = graphics_resize_stats(driver)
  assert_eq(stats2.resize_count, 1)
  assert_eq(stats2.suppressed_count, 1)

  // Another actual resize
  driver.resize(1024, 768)
  let stats3 = graphics_resize_stats(driver)
  assert_eq(stats3.resize_count, 2)
  assert_eq(stats3.suppressed_count, 1)
  assert_eq(stats3.current_width, 1024)
  assert_eq(stats3.current_height, 768)
}

///|
test "graphics_resize_stats multiple suppressions" {
  let driver = create_null_graphics(320, 240)
  driver.initialize()

  // Resize once
  driver.resize(640, 480)
  // Five suppressed calls
  driver.resize(640, 480)
  driver.resize(640, 480)
  driver.resize(640, 480)
  driver.resize(640, 480)
  driver.resize(640, 480)

  let stats = graphics_resize_stats(driver)
  assert_eq(stats.resize_count, 1)
  assert_eq(stats.suppressed_count, 5)
}

///|
test "graphics_resize_stats zero and negative dimensions normalize" {
  let driver = create_null_graphics(100, 100)
  driver.initialize()

  // Resize to 0x0 → normalized to 1x1
  driver.resize(0, 0)
  let stats1 = graphics_resize_stats(driver)
  assert_eq(stats1.resize_count, 1)
  assert_eq(stats1.current_width, 1)
  assert_eq(stats1.current_height, 1)

  // Resize with negative → still 1x1, suppressed
  driver.resize(-10, -20)
  let stats2 = graphics_resize_stats(driver)
  assert_eq(stats2.resize_count, 1)
  assert_eq(stats2.suppressed_count, 1)
  assert_eq(stats2.current_width, 1)
  assert_eq(stats2.current_height, 1)
}

///|
test "read_pixels returns None when not initialized" {
  let driver = create_null_graphics(64, 64)
  let result = driver.read_pixels(0, 0, 32, 32)
  assert_true(result is None)
}

///|
test "read_pixels returns None for out-of-bounds region" {
  let driver = create_null_graphics(64, 64)
  driver.initialize()
  // Completely outside
  let result = driver.read_pixels(100, 100, 32, 32)
  assert_true(result is None)
}

///|
test "read_pixels clamps to framebuffer bounds" {
  let read_pixels_width : Ref[Int] = Ref::new(0)
  let read_pixels_height : Ref[Int] = Ref::new(0)
  set_native_graphics_hooks({
    try_initialize: fn(_w, _h) { true },
    on_begin: fn(_a, _p) {},
    on_end: fn(_a, _pr) {},
    on_draw: fn(_a, _c) {},
    on_resize: fn(_a, _w, _h) {},
    on_read_pixels: fn(active, _x, _y, w, h) -> Array[Int]? {
      if active {
        read_pixels_width.val = w
        read_pixels_height.val = h
        Some([])
      } else {
        None
      }
    },
  })
  let surface = @platform.create_offscreen_surface_token(64, 64)
  let options = default_graphics_backend_options()
  let driver = create_wgpu_native_graphics(surface, options)
  driver.initialize()
  // Read region extends beyond right/bottom edge
  let _ = driver.read_pixels(48, 48, 32, 32)
  assert_eq(read_pixels_width.val, 16)
  assert_eq(read_pixels_height.val, 16)
  reset_native_graphics_hooks()
}

///|
test "read_pixels delegates to native hook and returns pixels" {
  set_native_graphics_hooks({
    try_initialize: fn(_w, _h) { true },
    on_begin: fn(_a, _p) {},
    on_end: fn(_a, _pr) {},
    on_draw: fn(_a, _c) {},
    on_resize: fn(_a, _w, _h) {},
    on_read_pixels: fn(active, _x, _y, _w, _h) -> Array[Int]? {
      if active {
        Some([255, 0, 0, 255])
      } else {
        None
      }
    },
  })
  let surface = @platform.create_offscreen_surface_token(64, 64)
  let options = default_graphics_backend_options()
  let driver = create_wgpu_native_graphics(surface, options)
  driver.initialize()
  let result = driver.read_pixels(0, 0, 1, 1)
  match result {
    Some(pixels) => {
      assert_eq(pixels.length(), 4)
      assert_eq(pixels[0], 255)
    }
    None => fail("expected Some pixels")
  }
  reset_native_graphics_hooks()
}

///|
test "read_pixels delegates to web hook when native returns None" {
  reset_native_graphics_hooks()
  set_web_graphics_hooks({
    try_initialize: fn(_k, _w, _h) { true },
    on_begin: fn(_a, _k, _p) {},
    on_end: fn(_a, _k, _pr) {},
    on_draw: fn(_a, _k, _c) {},
    on_resize: fn(_a, _k, _w, _h) {},
    on_read_pixels: fn(active, _k, _x, _y, _w, _h) -> Array[Int]? {
      if active {
        Some([0, 255, 0, 255])
      } else {
        None
      }
    },
  })
  let surface = @platform.create_offscreen_surface_token(64, 64)
  let options = default_graphics_backend_options()
  let driver = create_webgpu_graphics(surface, options)
  driver.initialize()
  let result = driver.read_pixels(0, 0, 1, 1)
  match result {
    Some(pixels) => {
      assert_eq(pixels.length(), 4)
      assert_eq(pixels[1], 255)
    }
    None => fail("expected Some pixels from web hook")
  }
  reset_web_graphics_hooks()
}

///|
test "graphics_resize_stats initial state is zero" {
  let surface = @platform.create_offscreen_surface_token(320, 240)
  let options = default_graphics_backend_options()
  let native_driver = create_wgpu_native_graphics(surface, options)
  let native_stats = graphics_resize_stats(native_driver)
  assert_eq(native_stats.resize_count, 0)
  assert_eq(native_stats.suppressed_count, 0)
  assert_eq(native_stats.last_resize_duration_ms, 0.0)
  assert_eq(native_stats.total_resize_duration_ms, 0.0)

  let web_driver = create_webgpu_graphics(surface, options)
  let web_stats = graphics_resize_stats(web_driver)
  assert_eq(web_stats.resize_count, 0)
  assert_eq(web_stats.suppressed_count, 0)
  assert_eq(web_stats.last_resize_duration_ms, 0.0)
  assert_eq(web_stats.total_resize_duration_ms, 0.0)
}

///|
fn queue_test_quad_command(
  dst_id : Int,
  shader_id : Int,
  blend : BlendMode,
  src_image_ids : Array[Int],
) -> DrawTrianglesCommand {
  {
    dst: { id: dst_id, width: 64, height: 64 },
    shader: { id: shader_id, source: "shader-\{shader_id}" },
    dst_regions: [{ x: 0, y: 0, width: 32, height: 32, index_count: 6 }],
    index_offset: 0,
    pipeline_id: 1,
    uniform_hash: 0,
    blend,
    vertex_data: [
      0.0, 0.0, 0.0, 0.0,
      1.0, 0.0, 1.0, 0.0,
      1.0, 1.0, 1.0, 1.0,
      0.0, 1.0, 0.0, 1.0,
    ],
    indices: [0, 1, 2, 2, 3, 0],
    src_image_ids,
    uniform_dwords: [],
  }
}

///|
test "command queue merges compatible explicit geometry commands" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Alpha, [10]),
  )
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Alpha, [10]),
  )
  let commands = queue.flush()
  assert_eq(commands.length(), 1)
  // 2 quads: 4 verts * 4 floats * 2 = 32
  assert_eq(commands[0].vertex_data.length(), 32)
  // 2 quads: 6 indices * 2 = 12
  assert_eq(commands[0].indices.length(), 12)
  // Second quad indices should be offset by 4 (first quad vertex count)
  assert_eq(commands[0].indices[6], 4)
  assert_eq(commands[0].indices[7], 5)
  assert_eq(commands[0].indices[8], 6)
  assert_eq(commands[0].indices[9], 6)
  assert_eq(commands[0].indices[10], 7)
  assert_eq(commands[0].indices[11], 4)
  assert_eq(commands[0].dst_regions.length(), 2)
}

///|
test "command queue does not merge explicit geometry with different src_image_ids" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Alpha, [10]),
  )
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Alpha, [20]),
  )
  let commands = queue.flush()
  assert_eq(commands.length(), 2)
}

///|
test "command queue does not merge explicit geometry with different blend" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Alpha, [10]),
  )
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Add, [10]),
  )
  let commands = queue.flush()
  assert_eq(commands.length(), 2)
}

///|
test "command queue does not merge region-only with explicit geometry" {
  let queue = new_simple_command_queue()
  // region-only command
  queue.enqueue_draw_triangles(
    queue_test_command(1, 1, BlendMode::Alpha, 0, 1, 0, 0),
  )
  // explicit geometry command
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Alpha, []),
  )
  let commands = queue.flush()
  assert_eq(commands.length(), 2)
}

///|
test "command queue does not merge explicit geometry exceeding budget" {
  let queue = new_simple_command_queue()
  // Create a command with vertex_data near the budget limit
  let big_vertex_data : Array[Double] = []
  for i in 0..<(max_merge_vertex_floats - 4) {
    let _ = i
    big_vertex_data.push(0.0)
  }
  let cmd1 : DrawTrianglesCommand = {
    dst: { id: 1, width: 64, height: 64 },
    shader: { id: 1, source: "shader-1" },
    dst_regions: [{ x: 0, y: 0, width: 32, height: 32, index_count: 6 }],
    index_offset: 0,
    pipeline_id: 1,
    uniform_hash: 0,
    blend: BlendMode::Alpha,
    vertex_data: big_vertex_data,
    indices: [0, 1, 2],
    src_image_ids: [10],
    uniform_dwords: [],
  }
  queue.enqueue_draw_triangles(cmd1)
  // Second command would push over the limit
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Alpha, [10]),
  )
  let commands = queue.flush()
  assert_eq(commands.length(), 2)
}

///|
test "command queue merges three consecutive explicit geometry commands" {
  let queue = new_simple_command_queue()
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Alpha, [10]),
  )
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Alpha, [10]),
  )
  queue.enqueue_draw_triangles(
    queue_test_quad_command(1, 1, BlendMode::Alpha, [10]),
  )
  let commands = queue.flush()
  assert_eq(commands.length(), 1)
  // 3 quads: 4 verts * 4 floats * 3 = 48
  assert_eq(commands[0].vertex_data.length(), 48)
  // 3 quads: 6 indices * 3 = 18
  assert_eq(commands[0].indices.length(), 18)
  // Third quad indices should be offset by 8 (2 * 4 vertices)
  assert_eq(commands[0].indices[12], 8)
  assert_eq(commands[0].indices[13], 9)
  assert_eq(commands[0].indices[14], 10)
  assert_eq(commands[0].indices[15], 10)
  assert_eq(commands[0].indices[16], 11)
  assert_eq(commands[0].indices[17], 8)
  assert_eq(commands[0].dst_regions.length(), 3)
}

///|
test "graphics_resize_stats measures resize duration with clock provider" {
  let clock_time : Ref[Double] = Ref::new(0.0)
  set_graphics_clock_provider(fn() { clock_time.val })
  let driver = create_null_graphics(640, 480)
  driver.initialize()

  // First resize: simulate 2.5ms duration
  clock_time.val = 100.0
  // The clock will return 100.0 for t0, then we need it to return 102.5 for t1
  // Since the clock is called twice per resize, we use a counter
  let call_count : Ref[Int] = Ref::new(0)
  set_graphics_clock_provider(fn() {
    call_count.val = call_count.val + 1
    if call_count.val % 2 == 1 {
      100.0
    } else {
      102.5
    }
  })
  driver.resize(800, 600)
  let stats1 = graphics_resize_stats(driver)
  assert_eq(stats1.last_resize_duration_ms, 2.5)
  assert_eq(stats1.total_resize_duration_ms, 2.5)

  // Second resize: simulate 1.0ms duration
  call_count.val = 0
  set_graphics_clock_provider(fn() {
    call_count.val = call_count.val + 1
    if call_count.val % 2 == 1 {
      200.0
    } else {
      201.0
    }
  })
  driver.resize(1024, 768)
  let stats2 = graphics_resize_stats(driver)
  assert_eq(stats2.last_resize_duration_ms, 1.0)
  assert_eq(stats2.total_resize_duration_ms, 3.5)

  reset_graphics_clock_provider()
}

///|
test "graphics_resize_stats suppressed resize does not affect timing" {
  let call_count : Ref[Int] = Ref::new(0)
  set_graphics_clock_provider(fn() {
    call_count.val = call_count.val + 1
    if call_count.val % 2 == 1 {
      50.0
    } else {
      55.0
    }
  })
  let driver = create_null_graphics(640, 480)
  driver.initialize()

  // Actual resize
  driver.resize(800, 600)
  let stats1 = graphics_resize_stats(driver)
  assert_eq(stats1.last_resize_duration_ms, 5.0)
  assert_eq(stats1.total_resize_duration_ms, 5.0)

  // Suppressed resize: timing should not change
  driver.resize(800, 600)
  let stats2 = graphics_resize_stats(driver)
  assert_eq(stats2.last_resize_duration_ms, 5.0)
  assert_eq(stats2.total_resize_duration_ms, 5.0)
  assert_eq(stats2.suppressed_count, 1)

  reset_graphics_clock_provider()
}

///|
test "graphics_resize_stats default clock returns zero duration" {
  reset_graphics_clock_provider()
  let driver = create_null_graphics(100, 100)
  driver.initialize()
  driver.resize(200, 200)
  let stats = graphics_resize_stats(driver)
  assert_eq(stats.last_resize_duration_ms, 0.0)
  assert_eq(stats.total_resize_duration_ms, 0.0)
}

///|
test "create_framebuffer_snapshot wraps read_pixels result" {
  set_native_graphics_hooks({
    try_initialize: fn(_w, _h) { true },
    on_begin: fn(_a, _p) {},
    on_end: fn(_a, _pr) {},
    on_draw: fn(_a, _c) {},
    on_resize: fn(_a, _w, _h) {},
    on_read_pixels: fn(active, _x, _y, _w, _h) -> Array[Int]? {
      if active {
        Some([255, 128, 64, 255])
      } else {
        None
      }
    },
  })
  let surface = @platform.create_offscreen_surface_token(64, 64)
  let options = default_graphics_backend_options()
  let driver = create_wgpu_native_graphics(surface, options)
  driver.initialize()
  let snap = create_framebuffer_snapshot(driver, 10, 20, 1, 1)
  match snap {
    Some(s) => {
      assert_eq(s.x, 10)
      assert_eq(s.y, 20)
      assert_eq(s.width, 1)
      assert_eq(s.height, 1)
      assert_eq(s.pixels[0], 255)
      assert_eq(s.pixels[2], 64)
    }
    None => fail("expected snapshot")
  }
  reset_native_graphics_hooks()
}

///|
test "create_framebuffer_snapshot returns None when not initialized" {
  let driver = create_null_graphics(64, 64)
  let snap = create_framebuffer_snapshot(driver, 0, 0, 32, 32)
  assert_true(snap is None)
}

///|
test "compare_framebuffer_snapshots identical pixels" {
  let pixels : Array[Int] = [255, 0, 0, 255, 0, 255, 0, 255]
  let a : FramebufferSnapshot = { x: 0, y: 0, width: 2, height: 1, pixels }
  let b : FramebufferSnapshot = {
    x: 0,
    y: 0,
    width: 2,
    height: 1,
    pixels: [255, 0, 0, 255, 0, 255, 0, 255],
  }
  let result = compare_framebuffer_snapshots(a, b, 0)
  assert_eq(result.diff_pixels, 0)
  assert_eq(result.max_channel_diff, 0)
  assert_eq(result.total_pixels, 2)
}

///|
test "compare_framebuffer_snapshots with threshold" {
  let a : FramebufferSnapshot = {
    x: 0,
    y: 0,
    width: 2,
    height: 1,
    pixels: [100, 100, 100, 255, 200, 200, 200, 255],
  }
  let b : FramebufferSnapshot = {
    x: 0,
    y: 0,
    width: 2,
    height: 1,
    pixels: [102, 100, 100, 255, 220, 200, 200, 255],
  }
  // threshold=5: first pixel diff=2 (within), second pixel diff=20 (exceeds)
  let result = compare_framebuffer_snapshots(a, b, 5)
  assert_eq(result.diff_pixels, 1)
  assert_eq(result.max_channel_diff, 20)
  assert_eq(result.total_pixels, 2)
}

///|
test "compare_framebuffer_snapshots mismatched dimensions" {
  let a : FramebufferSnapshot = {
    x: 0,
    y: 0,
    width: 2,
    height: 2,
    pixels: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  }
  let b : FramebufferSnapshot = {
    x: 0,
    y: 0,
    width: 3,
    height: 2,
    pixels: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  }
  let result = compare_framebuffer_snapshots(a, b, 0)
  assert_eq(result.diff_pixels, 4)
  assert_eq(result.max_channel_diff, 255)
}

///|
test "new_native_graphics_hooks_full sets on_read_pixels" {
  let read_pixels_called : Ref[Bool] = Ref::new(false)
  let hooks = new_native_graphics_hooks_full(
    fn(_w, _h) { false },
    fn(_a, _p) {},
    fn(_a, _pr) {},
    fn(_a, _c) {},
    fn(_a, _w, _h) {},
    fn(_active, _x, _y, _w, _h) -> Array[Int]? {
      read_pixels_called.val = true
      Some([1, 2, 3, 4])
    },
  )
  let result = (hooks.on_read_pixels)(true, 0, 0, 1, 1)
  assert_true(read_pixels_called.val)
  match result {
    Some(pixels) => assert_eq(pixels.length(), 4)
    None => fail("expected Some")
  }
}

///|
test "new_web_graphics_hooks_full sets on_read_pixels" {
  let read_pixels_called : Ref[Bool] = Ref::new(false)
  let hooks = new_web_graphics_hooks_full(
    fn(_k, _w, _h) { false },
    fn(_a, _k, _p) {},
    fn(_a, _k, _pr) {},
    fn(_a, _k, _c) {},
    fn(_a, _k, _w, _h) {},
    fn(_active, _k, _x, _y, _w, _h) -> Array[Int]? {
      read_pixels_called.val = true
      Some([5, 6, 7, 8])
    },
  )
  let result = (hooks.on_read_pixels)(
    true, GraphicsBackendKind::WebGpu, 0, 0, 1, 1,
  )
  assert_true(read_pixels_called.val)
  match result {
    Some(pixels) => assert_eq(pixels.length(), 4)
    None => fail("expected Some")
  }
}

///|
test "pixel_diff_ratio calculates correctly" {
  let result : PixelDiffResult = {
    total_pixels: 100,
    diff_pixels: 25,
    max_channel_diff: 10,
  }
  assert_true(pixel_diff_ratio(result) > 0.24)
  assert_true(pixel_diff_ratio(result) < 0.26)

  let empty : PixelDiffResult = {
    total_pixels: 0,
    diff_pixels: 0,
    max_channel_diff: 0,
  }
  assert_eq(pixel_diff_ratio(empty), 0.0)
}
