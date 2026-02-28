// ============================================================
// Initialization Tests
// ============================================================

///|
test "GameState new initializes correctly" {
  let state = GameState::new()
  assert_eq(state.mode, mode_playing)
  assert_eq(state.frame_count, 0)
  assert_eq(state.score, 0)
}

///|
test "initial player position" {
  let state = GameState::new()
  assert_true((state.player.position.x - 0.0).abs() < 0.001)
  assert_true((state.player.position.y - 0.5).abs() < 0.001)
  assert_true((state.player.position.z - 0.0).abs() < 0.001)
}

///|
test "items initialized active" {
  let state = GameState::new()
  assert_eq(state.items.length(), item_count)
  for item in state.items {
    assert_true(item.active)
  }
}

///|
test "enemies initialized" {
  let state = GameState::new()
  assert_eq(state.enemies.length(), enemy_count)
  for e in state.enemies {
    assert_true(e.waypoints.length() >= 2)
  }
}

// ============================================================
// Mode Transition Tests
// ============================================================

///|
test "title to playing on space press" {
  let state = GameState::new()
  state.mode = mode_title
  // First frame: register key as pressed (not yet just_pressed)
  let input1 = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input1)
  // Space needs to be "just pressed" — prev frame had no key, this frame has key
  assert_eq(state.mode, mode_playing)
}

///|
test "gameover to title on space press" {
  let state = GameState::new()
  state.mode = mode_gameover
  // First update with no keys to clear previous state
  let empty = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(empty)
  // Now press space
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input)
  assert_eq(state.mode, mode_title)
}

// ============================================================
// Player Movement Tests
// ============================================================

///|
test "player moves forward with W key" {
  let state = GameState::new()
  state.mode = mode_playing
  let initial_z = state.player.position.z
  // W key = 87
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [87])
  state.update(input)
  assert_true(state.player.position.z < initial_z)
}

///|
test "player moves backward with S key" {
  let state = GameState::new()
  state.mode = mode_playing
  let initial_z = state.player.position.z
  // S key = 83
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [83])
  state.update(input)
  assert_true(state.player.position.z > initial_z)
}

///|
test "player moves left with A key" {
  let state = GameState::new()
  state.mode = mode_playing
  let initial_x = state.player.position.x
  // A key = 65
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [65])
  state.update(input)
  assert_true(state.player.position.x < initial_x)
}

///|
test "player moves right with D key" {
  let state = GameState::new()
  state.mode = mode_playing
  let initial_x = state.player.position.x
  // D key = 68
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [68])
  state.update(input)
  assert_true(state.player.position.x > initial_x)
}

///|
test "player clamped to arena bounds" {
  let state = GameState::new()
  state.mode = mode_playing
  state.player.position = @math3d.Vec3::new(arena_half, 0.5, 0.0)
  // Move right (D key = 68)
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [68])
  state.update(input)
  let limit = arena_half - 1.0
  assert_true(state.player.position.x <= limit + 0.001)
}

// ============================================================
// Item Collection Tests
// ============================================================

///|
test "item collection increases score" {
  let state = GameState::new()
  state.mode = mode_playing
  // Move player to first item position
  let item_pos = state.items[0].position
  state.player.position = @math3d.Vec3::new(item_pos.x, 0.5, item_pos.z)
  let empty = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(empty)
  assert_eq(state.score, 10)
}

///|
test "collected item respawns" {
  let state = GameState::new()
  state.mode = mode_playing
  let item_pos = state.items[0].position
  state.player.position = @math3d.Vec3::new(item_pos.x, 0.5, item_pos.z)
  let empty = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(empty)
  // Item should be respawned (still active with new position)
  assert_true(state.items[0].active)
}

// ============================================================
// Enemy Collision Tests
// ============================================================

///|
test "enemy collision triggers gameover" {
  let state = GameState::new()
  state.mode = mode_playing
  let enemy_pos = state.enemies[0].position
  state.player.position = @math3d.Vec3::new(enemy_pos.x, 0.5, enemy_pos.z)
  let empty = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(empty)
  assert_eq(state.mode, mode_gameover)
}

// ============================================================
// Enemy Patrol Tests
// ============================================================

///|
test "enemy moves toward next waypoint" {
  let state = GameState::new()
  state.mode = mode_playing
  let e = state.enemies[0]
  // Enemy starts at waypoints[0], so next target is waypoints[1]
  let next_wp = e.waypoints[1]
  let dist_before = distance_xz(e.position, next_wp)
  // Move player far from enemies to avoid collision
  state.player.position = @math3d.Vec3::new(0.0, 0.5, 0.0)
  // Run several updates
  for _ in 0..<10 {
    let empty = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
    state.update(empty)
  }
  let dist_after = distance_xz(e.position, next_wp)
  assert_true(dist_after < dist_before)
}

// ============================================================
// Camera Tests
// ============================================================

///|
test "camera follows player" {
  let state = GameState::new()
  state.mode = mode_playing
  // Move player
  state.player.position = @math3d.Vec3::new(5.0, 0.5, 3.0)
  let empty = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(empty)
  assert_true((state.camera.target.x - 5.0).abs() < 0.001)
  assert_true((state.camera.target.z - 3.0).abs() < 0.001)
}

// ============================================================
// Reset Tests
// ============================================================

///|
test "reset restores initial state" {
  let state = GameState::new()
  state.mode = mode_playing
  state.score = 100
  state.player.position = @math3d.Vec3::new(5.0, 0.5, 5.0)
  state.reset()
  assert_eq(state.score, 0)
  assert_true((state.player.position.x - 0.0).abs() < 0.001)
  assert_true((state.player.position.z - 0.0).abs() < 0.001)
  for item in state.items {
    assert_true(item.active)
  }
}

// ============================================================
// Draw Command Tests
// ============================================================

///|
fn render_test_scene(state : GameState) -> Array[@gfx.DrawTrianglesCommand] {
  let dst = @gfx.new_image_handle(1, screen_w, screen_h)
  let shader = @gfx.new_shader_handle(1, "test")
  let scene = state.build_scene3d()
  @scene3d.render_scene3d(scene, dst, shader, screen_w, screen_h)
}

///|
test "render returns draw commands" {
  let state = GameState::new()
  let cmds = render_test_scene(state)
  assert_true(cmds.length() >= 5)
}

///|
test "render in playing mode" {
  let state = GameState::new()
  state.mode = mode_playing
  let cmds = render_test_scene(state)
  assert_true(cmds.length() >= 5)
}

///|
test "draw commands change when items collected" {
  let state = GameState::new()
  state.mode = mode_playing
  let cmds_before = render_test_scene(state)
  state.items[0].active = false
  let cmds_after = render_test_scene(state)
  // Fewer objects → different number of draw commands
  let tris_before = cmds_before.fold(
    init=0,
    fn(acc, cmd) { acc + cmd.indices.length() / 3 },
  )
  let tris_after = cmds_after.fold(
    init=0,
    fn(acc, cmd) { acc + cmd.indices.length() / 3 },
  )
  assert_true(tris_after < tris_before)
}

// ============================================================
// Benchmark Tests
// ============================================================

///|
test "benchmark: draw command count" {
  let state = GameState::new()
  let cmds = render_test_scene(state)
  let total_tris = cmds.fold(
    init=0,
    fn(acc, cmd) { acc + cmd.indices.length() / 3 },
  )
  println("Draw commands: \{cmds.length()}, Total triangles: \{total_tris}")
  assert_true(cmds.length() >= 1)
  assert_true(total_tris > 0)
}

///|
test "benchmark: render 1000 iterations" {
  let state = GameState::new()
  for _ in 0..<1000 {
    let _ = render_test_scene(state)
  }
  assert_true(true)
}

///|
test "benchmark: build_scene3d 10000 iterations" {
  let state = GameState::new()
  for _ in 0..<10000 {
    let _ = state.build_scene3d()
  }
  assert_true(true)
}

// ============================================================
// Utility Tests
// ============================================================

///|
test "distance_xz computes correctly" {
  let a = @math3d.Vec3::new(0.0, 0.0, 0.0)
  let b = @math3d.Vec3::new(3.0, 100.0, 4.0)
  let d = distance_xz(a, b)
  assert_true((d - 5.0).abs() < 0.001)
}

///|
test "clamp_arena limits values" {
  let limit = arena_half - 1.0
  assert_true(clamp_arena(100.0) <= limit)
  assert_true(clamp_arena(-100.0) >= -limit)
  assert_true((clamp_arena(0.0) - 0.0).abs() < 0.001)
}
