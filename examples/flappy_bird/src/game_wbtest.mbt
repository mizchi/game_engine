///|
test "build_draw_commands: title screen produces correct commands" {
  let state = FlappyState::new()
  state.game_mode = 0
  state.frame_count = 0 // indicator visible (0/30%2 == 0)
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  // Expected commands: sky + ground + bird + score(0) digits + "TAP" text
  // Score "0": 12 lit pixels
  // "TAP": T=7 + A=10 + P=8 = 25 dots
  // Total: 1(sky) + 1(ground) + 1(bird) + 12(score 0) + 25("TAP") = 40
  inspect(cmds.length(), content="40")
}

///|
test "build_draw_commands: playing with pipes" {
  let state = FlappyState::new()
  state.game_mode = 1
  state.bird_y = 100.0
  state.pipes = [{ x: 200.0, gap_y: 60.0 }, { x: 100.0, gap_y: 80.0 }]
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  // sky + ground + 2 pipes * 2 (upper+lower) + bird + score(0) digits
  // Score "0": 12 lit pixels
  // Total: 1 + 1 + 4 + 1 + 12 = 19
  inspect(cmds.length(), content="19")
}

///|
test "build_draw_commands: game over with END text" {
  let state = FlappyState::new()
  state.game_mode = 2
  state.bird_y = 200.0
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  // sky + ground + bird + score(0) + overlay_rect + "END" text
  // Score "0": 12 lit pixels
  // "END": E=10 + N=12 + D=10 = 32 dots
  // Total: 1(sky) + 1(ground) + 1(bird) + 12(score 0) + 1(overlay) + 32("END") = 48
  inspect(cmds.length(), content="48")
}

///|
test "ndc_rect_fill: full screen covers -1..1" {
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let color = @debugutil.color_from_hex(0xFF0000)
  let cmd = @debugutil.new_ndc_rect_fill_command(
    dst, shader, 0.0, 0.0, 320.0, 240.0, 320.0, 240.0, color, 0,
  )
  let vd = cmd.vertex_data
  // Top-left
  assert_true(vd[0] < -0.99 && vd[0] > -1.01) // x0 ≈ -1
  assert_true(vd[1] < 1.01 && vd[1] > 0.99) // y0 ≈ 1
  // Top-right
  assert_true(vd[4] < 1.01 && vd[4] > 0.99) // x1 ≈ 1
  assert_true(vd[5] < 1.01 && vd[5] > 0.99) // y1 ≈ 1
  // Bottom-right
  assert_true(vd[8] < 1.01 && vd[8] > 0.99) // x2 ≈ 1
  assert_true(vd[9] < -0.99 && vd[9] > -1.01) // y2 ≈ -1
  // Bottom-left
  assert_true(vd[12] < -0.99 && vd[12] > -1.01) // x3 ≈ -1
  assert_true(vd[13] < -0.99 && vd[13] > -1.01) // y3 ≈ -1
}

///|
test "ndc_rect_fill: half-screen rect maps correctly" {
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let color = @debugutil.color_from_hex(0x00FF00)
  // Bird at pixel (60, 100) size 12x12 on 320x240 screen
  let cmd = @debugutil.new_ndc_rect_fill_command(
    dst, shader, 60.0, 100.0, 12.0, 12.0, 320.0, 240.0, color, 0,
  )
  let vd = cmd.vertex_data
  let eps = 0.01
  assert_true((vd[0] - -0.625).abs() < eps)
  assert_true((vd[1] - 0.1667).abs() < eps)
  assert_true((vd[4] - -0.55).abs() < eps)
  assert_true((vd[9] - 0.0667).abs() < eps)
}

///|
test "ndc_rect_fill: color encoding" {
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let color = @debugutil.color_from_hex(0x87CEEB) // sky blue
  let cmd = @debugutil.new_ndc_rect_fill_command(
    dst, shader, 0.0, 0.0, 10.0, 10.0, 320.0, 240.0, color, 0,
  )
  // uniform_dwords = [R, G, B, A]
  inspect(cmd.uniform_dwords[0], content="135") // 0x87
  inspect(cmd.uniform_dwords[1], content="206") // 0xCE
  inspect(cmd.uniform_dwords[2], content="235") // 0xEB
  inspect(cmd.uniform_dwords[3], content="255") // alpha=1.0
}

///|
test "ndc_rect_fill: sky command is first and uses correct indices" {
  let state = FlappyState::new()
  state.game_mode = 1
  state.bird_y = 120.0
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  // First command is sky
  let sky = cmds[0]
  inspect(sky.indices.length(), content="6")
  inspect(sky.indices[0], content="0")
  inspect(sky.indices[1], content="1")
  inspect(sky.indices[2], content="2")
  inspect(sky.indices[3], content="2")
  inspect(sky.indices[4], content="3")
  inspect(sky.indices[5], content="0")
  // Sky color: 0x87CEEB
  inspect(sky.uniform_dwords[0], content="135")
  inspect(sky.uniform_dwords[1], content="206")
  inspect(sky.uniform_dwords[2], content="235")
  // Sky covers full screen NDC
  let vd = sky.vertex_data
  assert_true((vd[0] - -1.0).abs() < 0.001) // x0 = -1
  assert_true((vd[1] - 1.0).abs() < 0.001) // y0 = 1
  assert_true((vd[4] - 1.0).abs() < 0.001) // x1 = 1
  assert_true((vd[9] - -1.0).abs() < 0.001) // y2 = -1
}

///|
test "ndc_rect_fill: ground position" {
  let state = FlappyState::new()
  state.game_mode = 1
  state.bird_y = 120.0
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  // Second command is ground
  let ground = cmds[1]
  let vd = ground.vertex_data
  let eps = 0.01
  assert_true((vd[0] - -1.0).abs() < eps) // x0 = -1 (full width)
  assert_true((vd[1] - -0.833).abs() < eps) // y_top
  assert_true((vd[4] - 1.0).abs() < eps) // x1 = 1
  assert_true((vd[13] - -1.0).abs() < eps) // y_bot = -1
  // Ground color: 0x8B4513
  inspect(ground.uniform_dwords[0], content="139")
  inspect(ground.uniform_dwords[1], content="69")
  inspect(ground.uniform_dwords[2], content="19")
}

///|
test "ndc_rect_fill: pipe upper and lower" {
  let state = FlappyState::new()
  state.game_mode = 1
  state.bird_y = 120.0
  state.pipes = [{ x: 160.0, gap_y: 80.0 }]
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  let upper = cmds[2]
  let lower = cmds[3]
  let eps = 0.02
  assert_true((upper.vertex_data[0] - 0.0).abs() < eps)
  assert_true((upper.vertex_data[1] - 1.0).abs() < eps)
  // Pipe color: 0x228B22
  inspect(upper.uniform_dwords[0], content="34")
  inspect(upper.uniform_dwords[1], content="139")
  inspect(upper.uniform_dwords[2], content="34")
  let eps2 = 0.02
  assert_true((lower.vertex_data[1] - -0.25).abs() < eps2)
}

///|
test "update: title to playing on any key press" {
  let state = FlappyState::new()
  state.game_mode = 0
  // First frame: no input → stays in title
  let empty_input = @core.empty_input_snapshot()
  state.update(empty_input)
  inspect(state.game_mode, content="0")
  // Second frame: press Enter (keyCode 13) → should transition to playing
  let input_with_key = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [13])
  state.update(input_with_key)
  inspect(state.game_mode, content="1")
  assert_true(state.velocity < 0.0) // jump velocity applied
}

///|
test "update: playing jump on key press" {
  let state = FlappyState::new()
  state.game_mode = 1
  state.bird_y = 100.0
  state.velocity = 2.0 // falling
  // First frame with no input
  let empty_input = @core.empty_input_snapshot()
  state.update(empty_input)
  let _y_after_fall = state.bird_y
  // Second frame: press Space (keyCode 32) → should jump
  let input_with_space = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input_with_space)
  assert_true(state.velocity < 0.0) // jump velocity
}

///|
test "update: gameover to title on action" {
  let state = FlappyState::new()
  state.game_mode = 2
  state.score = 5
  state.pipes = [{ x: 100.0, gap_y: 80.0 }]
  // First frame: no input
  let empty_input = @core.empty_input_snapshot()
  state.update(empty_input)
  inspect(state.game_mode, content="2")
  // Second frame: click → should reset
  let input_with_key = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input_with_key)
  inspect(state.game_mode, content="0")
  inspect(state.score, content="0")
  inspect(state.pipes.length(), content="0")
}

///|
test "update: gravity applies" {
  let state = FlappyState::new()
  state.game_mode = 1
  state.bird_y = 100.0
  state.velocity = 0.0
  let empty_input = @core.empty_input_snapshot()
  state.update(empty_input)
  // Gravity applied: velocity = 0.25, bird_y = 100.25
  assert_true(state.velocity > 0.0)
  assert_true(state.bird_y > 100.0)
  inspect(state.pipe_timer, content="1")
}

///|
test "update: pipe generation at interval" {
  let state = FlappyState::new()
  state.game_mode = 1
  state.bird_y = 100.0
  state.pipe_timer = 119 // one frame before pipe spawns
  let empty_input = @core.empty_input_snapshot()
  state.update(empty_input)
  // After pipe_timer reaches 120, pipe should be created
  inspect(state.pipes.length(), content="1")
  assert_true((state.pipes[0].x - 318.5).abs() < 0.01) // 320 - 1.5
  inspect(state.pipe_timer, content="0") // reset
}

///|
test "update: pipe movement" {
  let state = FlappyState::new()
  state.game_mode = 1
  state.bird_y = 100.0
  state.pipes = [{ x: 200.0, gap_y: 80.0 }]
  let empty_input = @core.empty_input_snapshot()
  state.update(empty_input)
  // Pipe moved left by pipe_speed (1.5)
  assert_true((state.pipes[0].x - 198.5).abs() < 0.01)
}
