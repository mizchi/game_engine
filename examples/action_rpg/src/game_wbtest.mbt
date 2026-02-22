// ============================================================
// Initialization Tests
// ============================================================

///|
test "ShowcaseState new initializes correctly" {
  let state = ShowcaseState::new()
  assert_eq(state.mode, mode_title)
  assert_eq(state.frame_count, 0)
  assert_eq(state.score, 0)
  assert_eq(state.attack_timer, 0)
  assert_true(state.player.alive)
  assert_eq(state.player.hp, 10)
  assert_eq(state.player.max_hp, 10)
}

///|
test "initial player position" {
  let state = ShowcaseState::new()
  assert_true((state.player.x - 48.0).abs() < 0.001)
  assert_true((state.player.y - 48.0).abs() < 0.001)
}

///|
test "enemies initialized alive" {
  let state = ShowcaseState::new()
  assert_eq(state.enemies.length(), 3)
  for enemy in state.enemies {
    assert_true(enemy.alive)
    assert_eq(enemy.hp, 3)
  }
}

///|
test "items initialized not collected" {
  let state = ShowcaseState::new()
  assert_eq(state.items.length(), 5)
  for item in state.items {
    assert_true(not(item.collected))
  }
}

// ============================================================
// Tilemap Tests
// ============================================================

///|
test "tilemap has walls on borders" {
  let tiles = generate_tilemap()
  assert_eq(tiles.length(), map_columns * map_rows)
  // Top row: all walls
  for col = 0; col < map_columns; col = col + 1 {
    assert_eq(tiles[col], tile_wall)
  }
  // Bottom row: all walls
  for col = 0; col < map_columns; col = col + 1 {
    assert_eq(tiles[(map_rows - 1) * map_columns + col], tile_wall)
  }
  // Left column: all walls
  for row = 0; row < map_rows; row = row + 1 {
    assert_eq(tiles[row * map_columns], tile_wall)
  }
  // Right column: all walls
  for row = 0; row < map_rows; row = row + 1 {
    assert_eq(tiles[row * map_columns + (map_columns - 1)], tile_wall)
  }
}

///|
test "tilemap interior has floor" {
  let tiles = generate_tilemap()
  // (1,1) should be floor
  assert_eq(tiles[1 * map_columns + 1], tile_floor)
  // (2,2) should be floor
  assert_eq(tiles[2 * map_columns + 2], tile_floor)
}

///|
test "tilemap has water tiles" {
  let tiles = generate_tilemap()
  // Row 7, col 10-13 should be water
  assert_eq(tiles[7 * map_columns + 10], tile_water)
  assert_eq(tiles[7 * map_columns + 13], tile_water)
}

///|
test "is_wall_at detects walls" {
  let tiles = generate_tilemap()
  assert_true(is_wall_at(tiles, 0, 0))
  assert_true(is_wall_at(tiles, 19, 0))
  assert_true(is_wall_at(tiles, 0, 14))
}

///|
test "is_wall_at detects floor" {
  let tiles = generate_tilemap()
  assert_true(not(is_wall_at(tiles, 1, 1)))
  assert_true(not(is_wall_at(tiles, 2, 2)))
}

///|
test "is_wall_at out of bounds returns true" {
  let tiles = generate_tilemap()
  assert_true(is_wall_at(tiles, -1, 0))
  assert_true(is_wall_at(tiles, 0, -1))
  assert_true(is_wall_at(tiles, 20, 0))
  assert_true(is_wall_at(tiles, 0, 15))
}

// ============================================================
// Atlas / Asset Tests
// ============================================================

///|
test "atlas repo has tile images" {
  let repo = @asset.new_simple_atlas_image_repository(64, 64, 1)
  let _ = setup_atlas(repo)
  let floor_src = @asset.get_atlas_draw_source(
    repo,
    @asset.new_asset_key("tile_floor"),
  )
  let wall_src = @asset.get_atlas_draw_source(
    repo,
    @asset.new_asset_key("tile_wall"),
  )
  let water_src = @asset.get_atlas_draw_source(
    repo,
    @asset.new_asset_key("tile_water"),
  )
  assert_true(not(floor_src.is_empty()))
  assert_true(not(wall_src.is_empty()))
  assert_true(not(water_src.is_empty()))
}

// ============================================================
// Audio Tests
// ============================================================

///|
test "audio clip creation" {
  let clip = create_silent_clip()
  let sample_count = @audio.clip_sample_count(clip)
  assert_true(sample_count > 0)
}

///|
test "audio context player creation" {
  let ctx = @audio.SimpleAudioContext::new(@audio.default_audio_format())
  let clip = create_silent_clip()
  let _id = ctx.create_player(clip) catch {
    _ => abort("create_player should not fail")
  }
  assert_eq(ctx.player_count(), 1)
}

// ============================================================
// Player Movement Tests
// ============================================================

///|
test "player moves with input" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  let initial_x = state.player.x
  // Simulate right key press (D key = 68)
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [68])
  state.update(input)
  assert_true(state.player.x > initial_x)
}

///|
test "player blocked by wall tiles" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  // Place player near left wall
  state.player.x = 10.0
  state.player.y = 48.0
  let initial_x = state.player.x
  // Try to move left (A key = 65)
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [65])
  state.update(input)
  // Player should be clamped, not move past wall
  assert_true(state.player.x >= state.player.size / 2.0)
}

///|
test "player cannot move out of bounds" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  state.player.x = 5.0
  state.player.y = 5.0
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [65, 87]) // A+W
  state.update(input)
  assert_true(state.player.x >= state.player.size / 2.0)
  assert_true(state.player.y >= state.player.size / 2.0)
}

// ============================================================
// Wall Collision Tests
// ============================================================

///|
test "check_wall_collision detects wall" {
  let state = ShowcaseState::new()
  // Position inside the top-left wall tile (0,0)
  assert_true(state.check_wall_collision(8.0, 8.0, 10.0))
}

///|
test "check_wall_collision allows floor" {
  let state = ShowcaseState::new()
  // Position in middle of floor area
  assert_true(not(state.check_wall_collision(48.0, 48.0, 10.0)))
}

// ============================================================
// Enemy AI Tests
// ============================================================

///|
test "enemy chase logic moves toward player" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  // Place enemy close to player
  state.enemies[0].x = 70.0
  state.enemies[0].y = 48.0
  let initial_dist = (state.enemies[0].x - state.player.x).abs()
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(input)
  let new_dist = (state.enemies[0].x - state.player.x).abs()
  // Enemy should be closer to player after chase
  assert_true(new_dist < initial_dist)
}

///|
test "enemy patrol when player far" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  // Place enemy far from player
  state.enemies[0].x = 250.0
  state.enemies[0].y = 200.0
  state.player.x = 48.0
  state.player.y = 48.0
  let old_x = state.enemies[0].x
  let old_y = state.enemies[0].y
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(input)
  // Enemy should have moved (patrol)
  let moved = (state.enemies[0].x - old_x).abs() > 0.001 ||
    (state.enemies[0].y - old_y).abs() > 0.001
  assert_true(moved)
}

///|
test "ai runtime state API" {
  let state = ShowcaseState::new()
  let _bb = state.ai_runtime.current_blackboard()
  let total = state.ai_runtime.total_decisions()
  assert_eq(total, 0)
  let ticks = state.ai_runtime.total_ticks()
  assert_eq(ticks, 0)
}

// ============================================================
// Attack Tests
// ============================================================

///|
test "attack kills enemy in range" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  // Place enemy next to player
  state.enemies[0].x = state.player.x + 10.0
  state.enemies[0].y = state.player.y
  state.enemies[0].hp = 1
  // Simulate confirm press (Space = 32)
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input)
  assert_true(not(state.enemies[0].alive))
  assert_eq(state.score, 100)
}

///|
test "attack does not reach far enemies" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  // Place enemy far away
  state.enemies[0].x = state.player.x + 100.0
  state.enemies[0].y = state.player.y
  let initial_hp = state.enemies[0].hp
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input)
  assert_eq(state.enemies[0].hp, initial_hp)
}

///|
test "attack cooldown prevents spam" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  state.enemies[0].x = state.player.x + 10.0
  state.enemies[0].y = state.player.y
  // First attack
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input)
  assert_true(state.attack_timer > 0)
  // Second attack immediately - should not trigger
  let initial_hp = state.enemies[0].hp
  // Need to release and press again
  let no_input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(no_input)
  let input2 = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input2)
  // Attack timer should prevent second attack
  assert_eq(state.enemies[0].hp, initial_hp)
}

// ============================================================
// Item Collection Tests
// ============================================================

///|
test "item collection increases score" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  // Place player on first gem item
  state.player.x = state.items[0].x
  state.player.y = state.items[0].y
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(input)
  assert_true(state.items[0].collected)
  assert_eq(state.score, 50) // gem = 50 points
}

///|
test "health item heals player" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  state.player.hp = 5
  // Item at index 2 is health (kind=1)
  state.player.x = state.items[2].x
  state.player.y = state.items[2].y
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(input)
  assert_true(state.items[2].collected)
  assert_eq(state.player.hp, 8) // +3 health
}

// ============================================================
// Game Mode Tests
// ============================================================

///|
test "title to playing transition" {
  let state = ShowcaseState::new()
  assert_eq(state.mode, mode_title)
  // Press space to start
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input)
  assert_eq(state.mode, mode_playing)
}

///|
test "gameover on player death" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  state.player.hp = 1
  // Place enemy overlapping player to trigger damage
  state.enemies[0].x = state.player.x
  state.enemies[0].y = state.player.y
  // Need frame_count divisible by 30 for damage
  state.frame_count = 29 // will become 30 in update
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
  state.update(input)
  assert_eq(state.mode, mode_gameover)
  assert_true(not(state.player.alive))
}

///|
test "gameover reset returns to title" {
  let state = ShowcaseState::new()
  state.mode = mode_gameover
  state.player.hp = 0
  state.player.alive = false
  state.score = 500
  // Press confirm to reset
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input)
  assert_eq(state.mode, mode_title)
  assert_true(state.player.alive)
  assert_eq(state.player.hp, state.player.max_hp)
  assert_eq(state.score, 0)
}

// ============================================================
// UI / Focus Manager Tests
// ============================================================

///|
test "focus manager cycles menu items" {
  let state = ShowcaseState::new()
  let _ = state.focus_mgr.focus(state.menu_node_ids[0])
  let focused = state.focus_mgr.current_focus()
  match focused {
    Some(id) => assert_eq(id.value, state.menu_node_ids[0].value)
    None => assert_true(false)
  }
  let _ = state.focus_mgr.focus_next()
  let focused2 = state.focus_mgr.current_focus()
  match focused2 {
    Some(id) => assert_eq(id.value, state.menu_node_ids[1].value)
    None => assert_true(false)
  }
}

///|
test "ui tree has menu nodes" {
  let state = ShowcaseState::new()
  assert_eq(state.ui_tree.node_count(), 3)
  assert_eq(state.menu_node_ids.length(), 3)
}

// ============================================================
// Camera Tests
// ============================================================

///|
test "camera follows player" {
  // Use a larger world so camera can actually scroll
  let cam = @camera2d.Camera2D::new(320.0, 240.0, 960.0, 720.0)
  cam.follow_target(400.0, 300.0)
  // cam.x = target_x - screen_w/2 = 400 - 160 = 240
  // cam.y = target_y - screen_h/2 = 300 - 120 = 180
  assert_true((cam.x - 240.0).abs() < 0.001)
  assert_true((cam.y - 180.0).abs() < 0.001)
}

// ============================================================
// Tilemap Drawing Tests
// ============================================================

///|
test "visible tile chunk estimation" {
  let chunk = @tilemap2d.estimate_visible_tile_chunk(
    map_columns, map_rows, 0.0, 0.0, tile_size, tile_size, 0.0, 0.0, screen_w, screen_h,
    1,
  )
  assert_true(chunk.tile_width > 0)
  assert_true(chunk.tile_height > 0)
  assert_true(chunk.tile_width <= map_columns)
  assert_true(chunk.tile_height <= map_rows)
}

// ============================================================
// ColorM Tests
// ============================================================

///|
test "damage flash color transform" {
  let cm = @colorm.ColorM::identity().scale(1.0, 0.3, 0.3, 1.0)
  let result = cm.apply_color(@gfx.new_color(0.8, 0.2, 0.2, 1.0))
  // R should stay similar, G and B should be reduced
  assert_true(result.r > 0.5)
  assert_true(result.g < 0.2)
  assert_true(result.b < 0.2)
}

///|
test "monochrome transform" {
  let cm = @colorm.ColorM::identity().monochrome()
  let result = cm.apply_color(@gfx.new_color(1.0, 0.0, 0.0, 1.0))
  // Monochrome should make R=G=B
  assert_true((result.r - result.g).abs() < 0.01)
  assert_true((result.g - result.b).abs() < 0.01)
}

// ============================================================
// SVG Tests
// ============================================================

///|
test "svg path conversion produces commands" {
  let path = @svg.svg_path_to_vector_path("M 0 0 L 10 0 L 10 10 Z")
  assert_true(path.command_count() > 0)
}

// ============================================================
// Text Tests
// ============================================================

///|
test "text style creation" {
  let style = @text.default_text_style("mono", 12.0)
  let _ = style
  // Just verify it doesn't crash
  assert_true(true)
}

// ============================================================
// Draw Command Tests
// ============================================================

///|
test "build_draw_commands returns commands for title" {
  let state = ShowcaseState::new()
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  assert_true(cmds.length() > 0)
}

///|
test "build_draw_commands returns commands for playing" {
  let state = ShowcaseState::new()
  state.mode = mode_playing
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  assert_true(cmds.length() > 0)
}

///|
test "game over draw commands" {
  let state = ShowcaseState::new()
  state.mode = mode_gameover
  state.score = 250
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  assert_true(cmds.length() > 0)
}

///|
test "paused mode draw commands include menu" {
  let state = ShowcaseState::new()
  state.mode = mode_paused
  let _ = state.focus_mgr.focus(state.menu_node_ids[0])
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  // Should have more commands than playing mode (overlay + menu text)
  assert_true(cmds.length() > 5)
}

// ============================================================
// Image Palette Tests
// ============================================================

///|
test "image palette creation" {
  let palette = @image_palette.new_solid_palette(
    @image_palette.new_rgba(255, 0, 0, 255),
  )
  let _ = palette
  assert_true(true)
}

///|
test "checker palette from seed" {
  let palette = @image_palette.checker_palette_from_seed(42)
  let _ = palette
  assert_true(true)
}

// ============================================================
// Vector / AABB Tests
// ============================================================

///|
test "aabb overlap center detects collision" {
  let result = @vector.aabb_overlap_center(
    10.0, 10.0, 5.0, 5.0, 12.0, 12.0, 5.0, 5.0,
  )
  assert_true(result)
}

///|
test "aabb overlap center no collision" {
  let result = @vector.aabb_overlap_center(
    10.0, 10.0, 5.0, 5.0, 100.0, 100.0, 5.0, 5.0,
  )
  assert_true(not(result))
}
