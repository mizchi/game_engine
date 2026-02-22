// ============================================================
// Helper Tests
// ============================================================

///|
test "pseudo_random: deterministic output" {
  let a = pseudo_random(42)
  let b = pseudo_random(42)
  inspect(a, content=b.to_string())
  // Different seeds produce different results
  let c = pseudo_random(100)
  assert_true(a != c)
}

///|
test "pseudo_random_double: range 0..1" {
  let v = pseudo_random_double(42)
  assert_true(v >= 0.0 && v <= 1.0)
  let v2 = pseudo_random_double(999)
  assert_true(v2 >= 0.0 && v2 <= 1.0)
}

///|
test "distance_sq: basic" {
  let d = distance_sq(0.0, 0.0, 3.0, 4.0)
  assert_true((d - 25.0).abs() < 0.001)
}

///|
test "distance_sq: same point" {
  let d = distance_sq(5.0, 5.0, 5.0, 5.0)
  assert_true((d - 0.0).abs() < 0.001)
}

///|
test "normalize_dir: unit vector" {
  let (nx, ny) = normalize_dir(3.0, 4.0)
  let len = (nx * nx + ny * ny).sqrt()
  assert_true((len - 1.0).abs() < 0.001)
  assert_true((nx - 0.6).abs() < 0.001)
  assert_true((ny - 0.8).abs() < 0.001)
}

///|
test "normalize_dir: zero vector" {
  let (nx, ny) = normalize_dir(0.0, 0.0)
  assert_true((nx - 0.0).abs() < 0.001)
  assert_true((ny - 0.0).abs() < 0.001)
}

///|
test "world_to_screen: camera offset" {
  let cam = @camera2d.Camera2D::new(320.0, 240.0, 960.0, 720.0)
  // follow_target(260,170) -> cam.x=260-160=100, cam.y=170-120=50
  cam.follow_target(260.0, 170.0)
  let sx = cam.world_to_screen_x(150.0)
  let sy = cam.world_to_screen_y(80.0)
  assert_true((sx - 50.0).abs() < 0.001)
  assert_true((sy - 30.0).abs() < 0.001)
}

// ============================================================
// Player Movement Tests
// ============================================================

///|
test "player: initial position at world center" {
  let state = SurvivorState::new()
  assert_true((state.player.x - 480.0).abs() < 0.001)
  assert_true((state.player.y - 360.0).abs() < 0.001)
}

///|
test "player: move right with D key" {
  let state = SurvivorState::new()
  state.game_mode = 1
  let old_x = state.player.x
  // Press D key (68)
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [68])
  state.update(input)
  assert_true(state.player.x > old_x)
}

///|
test "player: move left with A key" {
  let state = SurvivorState::new()
  state.game_mode = 1
  let old_x = state.player.x
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [65])
  state.update(input)
  assert_true(state.player.x < old_x)
}

///|
test "player: move up with W key" {
  let state = SurvivorState::new()
  state.game_mode = 1
  let old_y = state.player.y
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [87])
  state.update(input)
  assert_true(state.player.y < old_y)
}

///|
test "player: diagonal movement normalized" {
  let state = SurvivorState::new()
  state.game_mode = 1
  let start_x = state.player.x
  let start_y = state.player.y
  // Press W + D simultaneously
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [87, 68])
  state.update(input)
  let dx = state.player.x - start_x
  let dy = state.player.y - start_y
  let move_dist = (dx * dx + dy * dy).sqrt()
  // Should be approximately equal to speed (2.0), not speed * sqrt(2)
  assert_true((move_dist - state.player.speed).abs() < 0.01)
}

///|
test "player: clamp to world boundary" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.player.x = 2.0
  state.player.y = 2.0
  // Move left + up to try to go out of bounds
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [65, 87])
  state.update(input)
  let half = state.player.size / 2.0
  assert_true(state.player.x >= half)
  assert_true(state.player.y >= half)
}

///|
test "camera: follows player" {
  let state = SurvivorState::new()
  state.game_mode = 1
  // Move player right
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [68])
  state.update(input)
  // Camera should be centered on player
  let expected_cam_x = state.player.x - state.screen_w / 2.0
  assert_true((state.camera.x - expected_cam_x).abs() < 0.01)
}

// ============================================================
// Enemy Tests
// ============================================================

///|
test "enemy spawn: creates enemy at camera edge" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.spawn_timer = 119
  let input = @core.empty_input_snapshot()
  state.update(input)
  assert_true(state.enemies.length() >= 1)
  let e = state.enemies[state.enemies.length() - 1]
  assert_true(e.alive)
}

///|
test "enemy: chases player" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.player.x = 480.0
  state.player.y = 360.0
  state.enemies.push({
    x: 580.0,
    y: 360.0,
    hp: 3,
    speed: 0.6,
    size: 10.0,
    kind: 0,
    alive: true,
    hit_timer: 0,
  })
  let old_x = state.enemies[0].x
  let input = @core.empty_input_snapshot()
  state.update(input)
  // Enemy should move closer to player (left)
  assert_true(state.enemies[0].x < old_x)
}

///|
test "enemy: max limit enforced" {
  let state = SurvivorState::new()
  state.game_mode = 1
  // Fill to max
  for i = 0; i < max_enemies; i = i + 1 {
    state.enemies.push({
      x: 100.0 + i.to_double(),
      y: 100.0,
      hp: 3,
      speed: 0.6,
      size: 10.0,
      kind: 0,
      alive: true,
      hit_timer: 0,
    })
  }
  state.spawn_timer = 119
  let input = @core.empty_input_snapshot()
  state.update(input)
  assert_true(state.enemies.length() <= max_enemies)
}

// ============================================================
// Projectile Weapon Tests
// ============================================================

///|
test "projectile weapon: fires at nearest enemy" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.player.x = 480.0
  state.player.y = 360.0
  // Place enemy to the right
  state.enemies.push({
    x: 580.0,
    y: 360.0,
    hp: 3,
    speed: 0.6,
    size: 10.0,
    kind: 0,
    alive: true,
    hit_timer: 0,
  })
  state.projectile_weapon.timer = 44
  let input = @core.empty_input_snapshot()
  state.update(input)
  assert_true(state.projectiles.length() >= 1)
  let p = state.projectiles[0]
  assert_true(p.vx > 0.0) // Moving right toward enemy
  assert_true(p.vy.abs() < 0.01) // Not moving vertically
}

///|
test "projectile: hits enemy and damages" {
  let state = SurvivorState::new()
  state.game_mode = 1
  // Place projectile right on top of enemy
  state.enemies.push({
    x: 500.0,
    y: 360.0,
    hp: 3,
    speed: 0.6,
    size: 10.0,
    kind: 0,
    alive: true,
    hit_timer: 0,
  })
  state.projectiles.push({
    x: 500.0,
    y: 360.0,
    vx: 1.0,
    vy: 0.0,
    alive: true,
    lifetime: 60,
    damage: 1,
    size: 4.0,
  })
  let input = @core.empty_input_snapshot()
  state.update(input)
  // Projectile should be consumed
  let proj_alive = state.projectiles.iter().filter(fn(p) { p.alive }).count()
  inspect(proj_alive, content="0")
  // Enemy should have taken damage
  assert_true(state.enemies[0].hp < 3)
}

///|
test "projectile: kills enemy and spawns gem" {
  let state = SurvivorState::new()
  state.game_mode = 1
  // Place enemy far enough that gem won't be auto-collected (> gem_collect_dist)
  state.enemies.push({
    x: 550.0,
    y: 360.0,
    hp: 1,
    speed: 0.6,
    size: 10.0,
    kind: 0,
    alive: true,
    hit_timer: 0,
  })
  state.projectiles.push({
    x: 550.0,
    y: 360.0,
    vx: 1.0,
    vy: 0.0,
    alive: true,
    lifetime: 60,
    damage: 1,
    size: 4.0,
  })
  let input = @core.empty_input_snapshot()
  state.update(input)
  // Gem should be spawned and still alive (too far to collect)
  assert_true(state.gems.length() >= 1)
  assert_true(state.gems[0].alive)
}

// ============================================================
// Orbit Weapon Tests
// ============================================================

///|
test "orbit weapon: position calculation" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.orbit_weapons.push({
    angle: 0.0,
    speed: 0.05,
    radius: 40.0,
    size: 8.0,
    damage: 2,
  })
  let orb = state.orbit_weapons[0]
  let ox = state.player.x + @math.cos(orb.angle) * orb.radius
  let oy = state.player.y + @math.sin(orb.angle) * orb.radius
  // At angle 0, should be to the right of player
  assert_true((ox - (state.player.x + 40.0)).abs() < 0.01)
  assert_true((oy - state.player.y).abs() < 0.01)
}

///|
test "orbit weapon: damages enemy on contact" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.player.x = 480.0
  state.player.y = 360.0
  state.orbit_weapons.push({
    angle: 0.0,
    speed: 0.05,
    radius: 40.0,
    size: 8.0,
    damage: 2,
  })
  // Place enemy at orbit position (right of player by radius)
  state.enemies.push({
    x: 520.0,
    y: 360.0,
    hp: 5,
    speed: 0.6,
    size: 10.0,
    kind: 0,
    alive: true,
    hit_timer: 0,
  })
  let input = @core.empty_input_snapshot()
  state.update(input)
  // Enemy should have taken damage
  assert_true(state.enemies[0].hp < 5)
}

// ============================================================
// Area Weapon Tests
// ============================================================

///|
test "area weapon: damages enemies in range" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.player.x = 480.0
  state.player.y = 360.0
  state.area_weapon.timer = 179 // about to fire
  // Enemy in range
  state.enemies.push({
    x: 500.0,
    y: 360.0,
    hp: 5,
    speed: 0.6,
    size: 10.0,
    kind: 0,
    alive: true,
    hit_timer: 0,
  })
  // Enemy out of range
  state.enemies.push({
    x: 700.0,
    y: 360.0,
    hp: 5,
    speed: 0.6,
    size: 10.0,
    kind: 0,
    alive: true,
    hit_timer: 0,
  })
  let input = @core.empty_input_snapshot()
  state.update(input)
  // In-range enemy should be damaged
  assert_true(state.enemies[0].hp < 5)
  // Out-of-range enemy should be fine
  inspect(state.enemies[1].hp, content="5")
}

// ============================================================
// Gem & XP Tests
// ============================================================

///|
test "gem: collected when near player" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.player.x = 480.0
  state.player.y = 360.0
  state.gems.push({ x: 490.0, y: 360.0, alive: true, value: 1 })
  let input = @core.empty_input_snapshot()
  state.update(input)
  // Gem should be collected (distance < 24)
  let alive_gems = state.gems.iter().filter(fn(g) { g.alive }).count()
  inspect(alive_gems, content="0")
  inspect(state.xp, content="1")
}

///|
test "gem: not collected when far" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.player.x = 480.0
  state.player.y = 360.0
  state.gems.push({ x: 600.0, y: 360.0, alive: true, value: 1 })
  let input = @core.empty_input_snapshot()
  state.update(input)
  let alive_gems = state.gems.iter().filter(fn(g) { g.alive }).count()
  inspect(alive_gems, content="1")
  inspect(state.xp, content="0")
}

///|
test "xp: level up triggers" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.xp = 7
  state.xp_to_next = 8
  state.player.x = 480.0
  state.player.y = 360.0
  state.gems.push({ x: 480.0, y: 360.0, alive: true, value: 1 })
  let input = @core.empty_input_snapshot()
  state.update(input)
  // Should transition to level up mode
  inspect(state.game_mode, content="2")
  inspect(state.level, content="2")
  inspect(state.upgrade_choices.length(), content="3")
}

// ============================================================
// Upgrade Tests
// ============================================================

///|
test "upgrade: proj rate decreases interval" {
  let state = SurvivorState::new()
  let old_interval = state.projectile_weapon.interval
  state.apply_upgrade(upgrade_proj_rate)
  assert_true(state.projectile_weapon.interval < old_interval)
}

///|
test "upgrade: proj dmg increases damage" {
  let state = SurvivorState::new()
  let old_dmg = state.projectile_weapon.damage
  state.apply_upgrade(upgrade_proj_dmg)
  inspect(state.projectile_weapon.damage, content=(old_dmg + 1).to_string())
}

///|
test "upgrade: orbit add creates orbiter" {
  let state = SurvivorState::new()
  inspect(state.orbit_weapons.length(), content="0")
  state.apply_upgrade(upgrade_orbit_add)
  inspect(state.orbit_weapons.length(), content="1")
}

///|
test "upgrade: hp heal restores hp" {
  let state = SurvivorState::new()
  state.player.hp = 5
  state.apply_upgrade(upgrade_hp_heal)
  inspect(state.player.hp, content="8")
}

///|
test "upgrade: hp heal capped at max" {
  let state = SurvivorState::new()
  state.player.hp = 9
  state.apply_upgrade(upgrade_hp_heal)
  inspect(state.player.hp, content="10")
}

// ============================================================
// Game Mode Transition Tests
// ============================================================

///|
test "title to play on space press" {
  let state = SurvivorState::new()
  state.game_mode = 0
  // First frame: no input
  let empty = @core.empty_input_snapshot()
  state.update(empty)
  inspect(state.game_mode, content="0")
  // Second frame: press space
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input)
  inspect(state.game_mode, content="1")
}

///|
test "gameover on zero hp" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.player.hp = 0
  let input = @core.empty_input_snapshot()
  state.update(input)
  inspect(state.game_mode, content="3")
}

///|
test "gameover to title on space press" {
  let state = SurvivorState::new()
  state.game_mode = 3
  state.score = 100
  // First frame: no input
  let empty = @core.empty_input_snapshot()
  state.update(empty)
  inspect(state.game_mode, content="3")
  // Second frame: press space
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input)
  inspect(state.game_mode, content="0")
  inspect(state.score, content="0")
}

///|
test "levelup: select and confirm" {
  let state = SurvivorState::new()
  state.game_mode = 2
  state.upgrade_choices = [
    upgrade_proj_rate, upgrade_proj_dmg, upgrade_orbit_add,
  ]
  state.selected_upgrade = 0
  let old_interval = state.projectile_weapon.interval
  // First frame: no input (needed for edge detection)
  let empty = @core.empty_input_snapshot()
  state.update(empty)
  // Confirm with space
  let input = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  state.update(input)
  inspect(state.game_mode, content="1")
  assert_true(state.projectile_weapon.interval < old_interval)
}

// ============================================================
// Draw Command Tests
// ============================================================

///|
test "draw: title screen produces commands" {
  let state = SurvivorState::new()
  state.game_mode = 0
  state.frame_count = 0
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  // Background + SURVIVOR text + SPACE text
  assert_true(cmds.length() > 10)
}

///|
test "draw: play screen has background and player" {
  let state = SurvivorState::new()
  state.game_mode = 1
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  // At minimum: bg + grid lines + player + HP bar(2) + XP bar(2) + time + score + level
  assert_true(cmds.length() >= 5)
}

///|
test "draw: gameover screen produces commands" {
  let state = SurvivorState::new()
  state.game_mode = 3
  state.frame_count = 0
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  // Background + GAME OVER text + score + time + SPACE text
  assert_true(cmds.length() > 10)
}

///|
test "draw: levelup overlay adds to play commands" {
  let state = SurvivorState::new()
  state.game_mode = 2
  state.upgrade_choices = [0, 1, 2]
  state.selected_upgrade = 0
  let dst = @gfx.new_image_handle(1, 320, 240)
  let shader = @gfx.new_shader_handle(1, "test")
  let cmds = state.build_draw_commands(dst, shader)
  // Play commands + overlay + LEVEL UP text + 3 choices
  assert_true(cmds.length() > 20)
}

// ============================================================
// Enemy Collision Tests
// ============================================================

///|
test "enemy-player collision: damages player" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.player.x = 480.0
  state.player.y = 360.0
  state.player.hp = 10
  // Place enemy overlapping player
  state.enemies.push({
    x: 480.0,
    y: 360.0,
    hp: 3,
    speed: 0.6,
    size: 10.0,
    kind: 0,
    alive: true,
    hit_timer: 0,
  })
  let input = @core.empty_input_snapshot()
  state.update(input)
  assert_true(state.player.hp < 10)
}

///|
test "difficulty: increases over time" {
  let state = SurvivorState::new()
  state.game_mode = 1
  state.survival_time = 599
  let input = @core.empty_input_snapshot()
  state.update(input)
  inspect(state.difficulty_level, content="1")
}

///|
test "reset: restores initial state" {
  let state = SurvivorState::new()
  state.game_mode = 3
  state.score = 100
  state.level = 5
  state.xp = 10
  state.enemies.push({
    x: 100.0,
    y: 100.0,
    hp: 3,
    speed: 0.6,
    size: 10.0,
    kind: 0,
    alive: true,
    hit_timer: 0,
  })
  state.reset()
  inspect(state.game_mode, content="0")
  inspect(state.score, content="0")
  inspect(state.level, content="1")
  inspect(state.enemies.length(), content="0")
  assert_true((state.player.x - 480.0).abs() < 0.001)
}
