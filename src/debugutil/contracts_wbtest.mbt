///|
fn approx(a : Double, b : Double) -> Bool {
  (a - b).abs() < 1.0e-6
}

///|
test "color_to_uniform_dwords" {
  let c = color_from_hex(0xFF8000)
  let dwords = color_to_uniform_dwords(c)
  assert_eq(dwords.length(), 4)
  assert_eq(dwords[0], 255) // R
  assert_eq(dwords[1], 128) // G
  assert_eq(dwords[2], 0) // B
  assert_eq(dwords[3], 255) // A
}

///|
test "color_to_uniform_dwords with alpha" {
  let c = @gfx.new_color(0.0, 1.0, 0.0, 0.5)
  let dwords = color_to_uniform_dwords(c)
  assert_eq(dwords[0], 0)
  assert_eq(dwords[1], 255)
  assert_eq(dwords[2], 0)
  assert_eq(dwords[3], 127)
}

///|
test "color_from_hex" {
  let c = color_from_hex(0xFF8000)
  assert_true(approx(c.r, 1.0))
  assert_true(approx(c.g, 128.0 / 255.0))
  assert_true(approx(c.b, 0.0))
  assert_true(approx(c.a, 1.0))
}

///|
test "color_from_hex_alpha" {
  let c = color_from_hex_alpha(0xFF0000, 0.5)
  assert_true(approx(c.r, 1.0))
  assert_true(approx(c.a, 0.5))
}

///|
test "named colors" {
  let w = color_white()
  assert_true(approx(w.r, 1.0))
  assert_true(approx(w.g, 1.0))
  assert_true(approx(w.b, 1.0))
  let b = color_black()
  assert_true(approx(b.r, 0.0))
  assert_true(approx(b.g, 0.0))
  assert_true(approx(b.b, 0.0))
  let t = color_transparent()
  assert_true(approx(t.a, 0.0))
}

///|
test "rect_fill_vertices" {
  let (verts, indices) = rect_fill_vertices(10.0, 20.0, 100.0, 50.0)
  // 4 vertices * 4 components (x, y, u, v)
  assert_eq(verts.length(), 16)
  assert_eq(indices.length(), 6)
  // First vertex at (10, 20)
  assert_true(approx(verts[0], 10.0))
  assert_true(approx(verts[1], 20.0))
  // Third vertex at (110, 70)
  assert_true(approx(verts[8], 110.0))
  assert_true(approx(verts[9], 70.0))
}

///|
test "line_vertices" {
  let (verts, indices) = line_vertices(0.0, 0.0, 10.0, 0.0, 2.0)
  // 4 vertices * 4 components
  assert_eq(verts.length(), 16)
  assert_eq(indices.length(), 6)
  // Horizontal line at y=0, width=2 -> vertices should be at y=+1 and y=-1
  assert_true(approx(verts[1], 1.0)) // first vertex y
  assert_true(approx(verts[13], -1.0)) // last vertex y
}

///|
test "rect_outline_vertices" {
  let (verts, indices) = rect_outline_vertices(0.0, 0.0, 100.0, 50.0, 1.0)
  // 4 lines * 4 vertices * 4 components
  assert_eq(verts.length(), 64)
  // 4 lines * 6 indices
  assert_eq(indices.length(), 24)
}

///|
test "new_rect_fill_command" {
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmd = new_rect_fill_command(
    dst,
    shader,
    10.0,
    20.0,
    100.0,
    50.0,
    color_red(),
    0,
  )
  assert_eq(cmd.vertex_data.length(), 16)
  assert_eq(cmd.indices.length(), 6)
  assert_eq(cmd.uniform_dwords.length(), 4)
  assert_eq(cmd.uniform_dwords[0], 255) // R
  assert_eq(cmd.uniform_dwords[1], 0) // G
  assert_eq(cmd.uniform_dwords[2], 0) // B
  assert_eq(cmd.uniform_dwords[3], 255) // A
}

///|
test "new_line_command" {
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmd = new_line_command(
    dst,
    shader,
    0.0,
    0.0,
    100.0,
    0.0,
    2.0,
    color_green(),
    0,
  )
  assert_eq(cmd.vertex_data.length(), 16)
  assert_eq(cmd.indices.length(), 6)
  assert_eq(cmd.uniform_dwords[1], 255) // G channel
}

///|
test "build_input_debug_overlay empty state" {
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "debug")
  let snapshot = @core.new_input_snapshot_full(
    100.0,
    200.0,
    0.0,
    0.0,
    [],
    [],
    [],
    [],
  )
  let key_state = @inpututil.new_key_input_state()
  let mouse_state = @inpututil.new_mouse_input_state()
  let cmds = build_input_debug_overlay(
    dst, shader, snapshot, key_state, mouse_state, 0,
  )
  // Should have at least the crosshair (2 line commands)
  assert_eq(cmds.length(), 2)
}

///|
test "color_from_hex boundary values" {
  let black = color_from_hex(0x000000)
  assert_true(approx(black.r, 0.0))
  assert_true(approx(black.g, 0.0))
  assert_true(approx(black.b, 0.0))
  let white = color_from_hex(0xFFFFFF)
  assert_true(approx(white.r, 1.0))
  assert_true(approx(white.g, 1.0))
  assert_true(approx(white.b, 1.0))
}

///|
test "line_vertices vertical line" {
  let (verts, indices) = line_vertices(5.0, 0.0, 5.0, 10.0, 2.0)
  assert_eq(verts.length(), 16)
  assert_eq(indices.length(), 6)
  // Vertical line: perpendicular offset should be in x direction
  // First vertex x should differ from 5.0 by ±1.0
  assert_true(approx(verts[0] - 5.0, 1.0) || approx(verts[0] - 5.0, -1.0))
}

///|
test "line_vertices diagonal line" {
  let (verts, indices) = line_vertices(0.0, 0.0, 10.0, 10.0, 2.0)
  assert_eq(verts.length(), 16)
  assert_eq(indices.length(), 6)
}

///|
test "rect_fill_vertices zero size" {
  let (verts, indices) = rect_fill_vertices(5.0, 5.0, 0.0, 0.0)
  assert_eq(verts.length(), 16)
  assert_eq(indices.length(), 6)
  // All vertices should be at the same point
  assert_true(approx(verts[0], 5.0))
  assert_true(approx(verts[4], 5.0))
}

///|
test "ndc_rect_fill_vertices full screen" {
  let (verts, indices) = ndc_rect_fill_vertices(
    0.0, 0.0, 320.0, 240.0, 320.0, 240.0,
  )
  assert_eq(verts.length(), 16)
  assert_eq(indices.length(), 6)
  // Top-left: (-1, 1)
  assert_true(approx(verts[0], -1.0))
  assert_true(approx(verts[1], 1.0))
  // Bottom-right: (1, -1)
  assert_true(approx(verts[8], 1.0))
  assert_true(approx(verts[9], -1.0))
}

///|
test "ndc_rect_fill_vertices center rect" {
  let (verts, _) = ndc_rect_fill_vertices(
    160.0, 120.0, 0.0, 0.0, 320.0, 240.0,
  )
  // Center point: (0, 0) in NDC
  assert_true(approx(verts[0], 0.0))
  assert_true(approx(verts[1], 0.0))
}

///|
test "new_ndc_rect_fill_command" {
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmd = new_ndc_rect_fill_command(
    dst, shader, 60.0, 100.0, 12.0, 12.0, 320.0, 240.0, color_red(), 0,
  )
  assert_eq(cmd.vertex_data.length(), 16)
  assert_eq(cmd.indices.length(), 6)
  assert_eq(cmd.uniform_dwords[0], 255) // R
  assert_eq(cmd.uniform_dwords[3], 255) // A
  // x0 = 60/320*2-1 = -0.625
  let eps = 0.001
  assert_true((cmd.vertex_data[0] - -0.625).abs() < eps)
}

///|
test "new_simple_draw_command" {
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let vertices = [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0]
  let indices = [0, 1, 2]
  let cmd = new_simple_draw_command(dst, shader, vertices, indices, color_green())
  assert_eq(cmd.vertex_data.length(), 12)
  assert_eq(cmd.indices.length(), 3)
  assert_eq(cmd.uniform_dwords[0], 0) // R
  assert_eq(cmd.uniform_dwords[1], 255) // G
  assert_eq(cmd.uniform_dwords[2], 0) // B
  assert_eq(cmd.uniform_dwords[3], 255) // A
  assert_eq(cmd.src_image_ids.length(), 0)
}

///|
test "build_input_debug_overlay with pressed keys" {
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "debug")
  let snap1 = @core.new_input_snapshot_full(
    100.0,
    200.0,
    0.0,
    0.0,
    [65, 66],
    [0],
    [],
    [],
  )
  let key_state = @inpututil.new_key_input_state()
  let mouse_state = @inpututil.new_mouse_input_state()
  @inpututil.update_key_input_state(key_state, snap1)
  @inpututil.update_mouse_input_state(mouse_state, snap1)
  let cmds = build_input_debug_overlay(
    dst, shader, snap1, key_state, mouse_state, 0,
  )
  // 2 crosshair + 2 key squares + 1 mouse button square = 5
  assert_eq(cmds.length(), 5)
}
