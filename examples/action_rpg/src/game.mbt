// Action RPG Showcase - Full-feature demo using 20 engine packages

// === Constants ===

///|
let map_columns : Int = 20

///|
let map_rows : Int = 15

///|
let tile_size : Double = 16.0

///|
let world_w : Double = 320.0

///|
let world_h : Double = 240.0

///|
let screen_w : Double = 320.0

///|
let screen_h : Double = 240.0

///|
let player_speed : Double = 1.5

///|
let enemy_speed : Double = 0.5

///|
let attack_range : Double = 24.0

///|
let attack_cooldown : Int = 20

///|
let damage_flash_duration : Int = 10

///|
let chase_range : Double = 80.0

// Game mode constants

///|
let mode_title : Int = 0

///|
let mode_playing : Int = 1

///|
let mode_paused : Int = 2

///|
let mode_gameover : Int = 3

// Tile type constants

///|
let tile_floor : Int = 0

///|
let tile_wall : Int = 1

///|
let tile_water : Int = 2

// === Data Structures ===

///|
struct Entity {
  mut x : Double
  mut y : Double
  mut vx : Double
  mut vy : Double
  mut hp : Int
  max_hp : Int
  size : Double
  mut alive : Bool
  mut damage_timer : Int
}

///|
struct ItemDrop {
  x : Double
  y : Double
  kind : Int // 0=gem, 1=health
  mut collected : Bool
}

// === Main Game State ===

///|
struct ShowcaseState {
  mut mode : Int
  mut frame_count : Int
  player : Entity
  enemies : Array[Entity]
  items : Array[ItemDrop]
  camera : @camera2d.Camera2D
  tilemap : Array[Int]
  input : @inpututil.InputHelper
  mut score : Int
  mut attack_timer : Int
  // AI (using AIRuntimeState public API)
  ai_runtime : @ai.AIRuntimeState
  // Audio
  audio_ctx : @audio.SimpleAudioContext
  sfx_attack : @audio.PlayerId?
  sfx_pickup : @audio.PlayerId?
  // UI
  focus_mgr : @ui.UIFocusManager
  ui_tree : @ui.UITree
  menu_node_ids : Array[@ui.UINodeId]
  mut menu_selection : Int
  // Asset
  atlas_repo : @asset.SimpleAtlasImageRepository
  tile_table : @tilemap2d.TileAtlasTable
  // Visual
  mut screen_flash : Int
  // SVG path
  level_border_path : @vector.Path
  // Text metrics
  text_style : @text.TextStyle
}

// === Tilemap Generation ===

///|
fn generate_tilemap() -> Array[Int] {
  let tiles : Array[Int] = []
  for row = 0; row < map_rows; row = row + 1 {
    for col = 0; col < map_columns; col = col + 1 {
      if row == 0 || row == map_rows - 1 || col == 0 || col == map_columns - 1 {
        tiles.push(tile_wall)
      } else if (row == 5 && col >= 3 && col <= 7) ||
        (row == 10 && col >= 12 && col <= 16) {
        tiles.push(tile_wall)
      } else if (row == 7 && col >= 10 && col <= 13) ||
        (row == 8 && col >= 10 && col <= 13) {
        tiles.push(tile_water)
      } else {
        tiles.push(tile_floor)
      }
    }
  }
  tiles
}

///|
fn is_wall_at(tilemap : Array[Int], col : Int, row : Int) -> Bool {
  if col < 0 || col >= map_columns || row < 0 || row >= map_rows {
    return true
  }
  let idx = row * map_columns + col
  if idx < 0 || idx >= tilemap.length() {
    return true
  }
  tilemap[idx] == tile_wall
}

// === Atlas Setup ===

///|
fn setup_atlas(
  repo : @asset.SimpleAtlasImageRepository,
) -> @tilemap2d.TileAtlasTable {
  // Floor: cobblestone pattern (gray variations)
  let floor_pixels : Array[Int] = [
    // Row 0
    0x55, 0x55, 0x55, 0xFF, 0x66, 0x66, 0x66, 0xFF, 0x5A, 0x5A, 0x5A, 0xFF, 0x55,
    0x55, 0x55, 0xFF,
    // Row 1
     0x66, 0x66, 0x66, 0xFF, 0x50, 0x50, 0x50, 0xFF, 0x66, 0x66, 0x66, 0xFF, 0x5A,
    0x5A, 0x5A, 0xFF,
    // Row 2
     0x5A, 0x5A, 0x5A, 0xFF, 0x66, 0x66, 0x66, 0xFF, 0x55, 0x55, 0x55, 0xFF, 0x66,
    0x66, 0x66, 0xFF,
    // Row 3
     0x55, 0x55, 0x55, 0xFF, 0x5A, 0x5A, 0x5A, 0xFF, 0x66, 0x66, 0x66, 0xFF, 0x50,
    0x50, 0x50, 0xFF,
  ]
  // Wall: brick pattern (brown tones with dark mortar)
  let wall_pixels : Array[Int] = [
    // Row 0
    0x6B, 0x42, 0x26, 0xFF, 0x6B, 0x42, 0x26, 0xFF, 0x33, 0x22, 0x11, 0xFF, 0x55,
    0x33, 0x11, 0xFF,
    // Row 1
     0x6B, 0x42, 0x26, 0xFF, 0x6B, 0x42, 0x26, 0xFF, 0x33, 0x22, 0x11, 0xFF, 0x55,
    0x33, 0x11, 0xFF,
    // Row 2
     0x33, 0x22, 0x11, 0xFF, 0x55, 0x33, 0x11, 0xFF, 0x6B, 0x42, 0x26, 0xFF, 0x6B,
    0x42, 0x26, 0xFF,
    // Row 3
     0x33, 0x22, 0x11, 0xFF, 0x55, 0x33, 0x11, 0xFF, 0x6B, 0x42, 0x26, 0xFF, 0x6B,
    0x42, 0x26, 0xFF,
  ]
  // Water: wave ripple pattern (blue variations)
  let water_pixels : Array[Int] = [
    // Row 0
    0x22, 0x44, 0xAA, 0xFF, 0x33, 0x55, 0xCC, 0xFF, 0x22, 0x44, 0xAA, 0xFF, 0x33,
    0x55, 0xCC, 0xFF,
    // Row 1
     0x33, 0x55, 0xCC, 0xFF, 0x22, 0x44, 0xAA, 0xFF, 0x44, 0x66, 0xDD, 0xFF, 0x22,
    0x44, 0xAA, 0xFF,
    // Row 2
     0x22, 0x44, 0xAA, 0xFF, 0x44, 0x66, 0xDD, 0xFF, 0x22, 0x44, 0xAA, 0xFF, 0x33,
    0x55, 0xCC, 0xFF,
    // Row 3
     0x33, 0x55, 0xCC, 0xFF, 0x22, 0x44, 0xAA, 0xFF, 0x33, 0x55, 0xCC, 0xFF, 0x44,
    0x66, 0xDD, 0xFF,
  ]
  let floor_key = @asset.new_asset_key("tile_floor")
  let wall_key = @asset.new_asset_key("tile_wall")
  let water_key = @asset.new_asset_key("tile_water")
  let floor_spec = @asset.image_spec_with_rgba8(4, 4, floor_pixels)
  let wall_spec = @asset.image_spec_with_rgba8(4, 4, wall_pixels)
  let water_spec = @asset.image_spec_with_rgba8(4, 4, water_pixels)
  let _ = @asset.create_atlas_image(repo, floor_key, floor_spec)
  let _ = @asset.create_atlas_image(repo, wall_key, wall_spec)
  let _ = @asset.create_atlas_image(repo, water_key, water_spec)
  @tilemap2d.new_tile_atlas_table([
    @tilemap2d.new_tile_atlas_entry(tile_floor, floor_key),
    @tilemap2d.new_tile_atlas_entry(tile_wall, wall_key),
    @tilemap2d.new_tile_atlas_entry(tile_water, water_key),
  ])
}

// === Audio Setup ===

///|
fn create_silent_clip() -> @audio.AudioClip {
  let format = @audio.mono_format(22050)
  let byte_count = @audio.samples_to_bytes(format, 100)
  let arr : FixedArray[Byte] = FixedArray::make(byte_count, b'\x00')
  let data = Bytes::from_array(arr)
  @audio.new_audio_clip(format, data, false)
}

// === Constructor ===

///|
fn ShowcaseState::new() -> ShowcaseState {
  let tilemap = generate_tilemap()
  let atlas_repo = @asset.new_simple_atlas_image_repository(128, 128, 1)
  let tile_table = setup_atlas(atlas_repo)
  // Audio
  let audio_ctx = @audio.SimpleAudioContext::new(@audio.default_audio_format())
  let clip = create_silent_clip()
  let sfx_attack_id = audio_ctx.create_player(clip) catch {
    _ => abort("audio create_player failed")
  }
  let sfx_attack : @audio.PlayerId? = Some(sfx_attack_id)
  let clip2 = create_silent_clip()
  let sfx_pickup_id = audio_ctx.create_player(clip2) catch {
    _ => abort("audio create_player failed")
  }
  let sfx_pickup : @audio.PlayerId? = Some(sfx_pickup_id)
  // SVG path
  let level_border_path = @svg.svg_path_to_vector_path(
    "M 0 0 L 320 0 L 320 240 L 0 240 Z",
  )
  // Text
  let text_style = @text.default_text_style("mono", 12.0)
  // UI: create UITree and add menu nodes to get UINodeIds
  let ui_tree = @ui.UITree::new()
  let menu_style = @ui.default_node_style()
  let menu_node_ids : Array[@ui.UINodeId] = [
    ui_tree.add_node(menu_style, []),
    ui_tree.add_node(menu_style, []),
    ui_tree.add_node(menu_style, []),
  ]
  let focus_mgr = @ui.UIFocusManager::new()
  focus_mgr.set_focusable(menu_node_ids)
  // AI (using AIRuntimeState public API)
  let ai_runtime = @ai.AIRuntimeState::new()
  ai_runtime.set_enabled(true)
  ai_runtime.set_trace_enabled(true)
  // Camera
  let camera = @camera2d.Camera2D::new(screen_w, screen_h, world_w, world_h)
  // Player
  let player : Entity = {
    x: 48.0,
    y: 48.0,
    vx: 0.0,
    vy: 0.0,
    hp: 10,
    max_hp: 10,
    size: 10.0,
    alive: true,
    damage_timer: 0,
  }
  // Enemies
  let enemies : Array[Entity] = [
    {
      x: 150.0,
      y: 80.0,
      vx: 0.0,
      vy: 0.0,
      hp: 3,
      max_hp: 3,
      size: 10.0,
      alive: true,
      damage_timer: 0,
    },
    {
      x: 200.0,
      y: 150.0,
      vx: 0.0,
      vy: 0.0,
      hp: 3,
      max_hp: 3,
      size: 10.0,
      alive: true,
      damage_timer: 0,
    },
    {
      x: 100.0,
      y: 180.0,
      vx: 0.0,
      vy: 0.0,
      hp: 3,
      max_hp: 3,
      size: 10.0,
      alive: true,
      damage_timer: 0,
    },
  ]
  // Items
  let items : Array[ItemDrop] = [
    { x: 80.0, y: 60.0, kind: 0, collected: false },
    { x: 180.0, y: 100.0, kind: 0, collected: false },
    { x: 250.0, y: 50.0, kind: 1, collected: false },
    { x: 120.0, y: 200.0, kind: 0, collected: false },
    { x: 280.0, y: 200.0, kind: 1, collected: false },
  ]
  {
    mode: mode_title,
    frame_count: 0,
    player,
    enemies,
    items,
    camera,
    tilemap,
    input: @inpututil.new_input_helper(),
    score: 0,
    attack_timer: 0,
    ai_runtime,
    audio_ctx,
    sfx_attack,
    sfx_pickup,
    focus_mgr,
    ui_tree,
    menu_node_ids,
    menu_selection: 0,
    atlas_repo,
    tile_table,
    screen_flash: 0,
    level_border_path,
    text_style,
  }
}

// === Update Logic ===

///|
fn ShowcaseState::update(
  self : ShowcaseState,
  input : @core.InputSnapshot,
) -> Unit {
  self.frame_count = self.frame_count + 1
  @inpututil.update_input_helper(self.input, input)
  match self.mode {
    m if m == mode_title => self.update_title()
    m if m == mode_playing => self.update_playing()
    m if m == mode_paused => self.update_paused()
    m if m == mode_gameover => self.update_gameover()
    _ => ()
  }
}

///|
fn ShowcaseState::update_title(self : ShowcaseState) -> Unit {
  if @inpututil.is_confirm_just_pressed(self.input) {
    self.mode = mode_playing
  }
}

///|
fn ShowcaseState::update_gameover(self : ShowcaseState) -> Unit {
  if @inpututil.is_confirm_just_pressed(self.input) {
    // Reset game
    self.mode = mode_title
    self.player.hp = self.player.max_hp
    self.player.alive = true
    self.player.x = 48.0
    self.player.y = 48.0
    self.score = 0
    for enemy in self.enemies {
      enemy.alive = true
      enemy.hp = enemy.max_hp
    }
    for item in self.items {
      item.collected = false
    }
  }
}

///|
fn ShowcaseState::update_paused(self : ShowcaseState) -> Unit {
  if @inpututil.is_up_just_pressed(self.input) {
    let _ = self.focus_mgr.focus_prev()
  }
  if @inpututil.is_down_just_pressed(self.input) {
    let _ = self.focus_mgr.focus_next()
  }
  if @inpututil.is_confirm_just_pressed(self.input) {
    self.mode = mode_playing
  }
}

///|
fn ShowcaseState::update_playing(self : ShowcaseState) -> Unit {
  // Check for pause (Escape key = 27)
  if @inpututil.is_key_just_pressed(self.input.key_state, 27) {
    self.mode = mode_paused
    let _ = self.focus_mgr.focus(self.menu_node_ids[0])
    return
  }
  // Player movement
  let mut dx = 0.0
  let mut dy = 0.0
  if @inpututil.is_move_up(self.input.key_state) {
    dy = dy - 1.0
  }
  if @inpututil.is_move_down(self.input.key_state) {
    dy = dy + 1.0
  }
  if @inpututil.is_move_left(self.input.key_state) {
    dx = dx - 1.0
  }
  if @inpututil.is_move_right(self.input.key_state) {
    dx = dx + 1.0
  }
  // Normalize diagonal movement
  if dx != 0.0 && dy != 0.0 {
    let v = @vector.Vec2::new(dx, dy).normalize()
    dx = v.x
    dy = v.y
  }
  let next_x = self.player.x + dx * player_speed
  let next_y = self.player.y + dy * player_speed
  // Wall collision for X
  if not(self.check_wall_collision(next_x, self.player.y, self.player.size)) {
    self.player.x = next_x
  }
  // Wall collision for Y
  if not(self.check_wall_collision(self.player.x, next_y, self.player.size)) {
    self.player.y = next_y
  }
  // Clamp to world bounds
  let half = self.player.size / 2.0
  self.player.x = @cmp.maximum(
    half,
    @cmp.minimum(world_w - half, self.player.x),
  )
  self.player.y = @cmp.maximum(
    half,
    @cmp.minimum(world_h - half, self.player.y),
  )
  // Camera follow
  self.camera.follow_target(self.player.x, self.player.y)
  // Attack
  if self.attack_timer > 0 {
    self.attack_timer = self.attack_timer - 1
  }
  if @inpututil.is_confirm_just_pressed(self.input) && self.attack_timer <= 0 {
    self.attack_timer = attack_cooldown
    self.screen_flash = 3
    // Play attack SFX
    match self.sfx_attack {
      Some(id) => self.audio_ctx.play(id) catch { _ => () }
      None => ()
    }
    // Check enemy hits
    for enemy in self.enemies {
      if enemy.alive {
        let edx = enemy.x - self.player.x
        let edy = enemy.y - self.player.y
        let dist = (edx * edx + edy * edy).sqrt()
        if dist < attack_range {
          enemy.hp = enemy.hp - 1
          enemy.damage_timer = damage_flash_duration
          if enemy.hp <= 0 {
            enemy.alive = false
            self.score = self.score + 100
          }
        }
      }
    }
  }
  // Enemy AI: direct chase/patrol logic
  // (AIRuntimeState API is used for demonstration, but actual enemy movement
  //  is done directly since external packages can't implement AI traits)
  let _bb = self.ai_runtime.current_blackboard()
  let _total = self.ai_runtime.total_decisions()
  for enemy in self.enemies {
    if enemy.alive {
      let cdx = self.player.x - enemy.x
      let cdy = self.player.y - enemy.y
      let dist = (cdx * cdx + cdy * cdy).sqrt()
      if dist < chase_range && dist > 1.0 {
        // Chase player
        enemy.vx = cdx / dist * enemy_speed
        enemy.vy = cdy / dist * enemy_speed
      } else {
        // Patrol: simple wandering based on frame_count
        let angle = ((self.frame_count + enemy.x.to_int()) % 360).to_double() *
          3.14159 /
          180.0
        enemy.vx = @math.cos(angle) * enemy_speed * 0.3
        enemy.vy = @math.sin(angle) * enemy_speed * 0.3
      }
    }
  }
  // Apply enemy movement
  for enemy in self.enemies {
    if enemy.alive {
      let enx = enemy.x + enemy.vx
      let eny = enemy.y + enemy.vy
      if not(self.check_wall_collision(enx, eny, enemy.size)) {
        enemy.x = enx
        enemy.y = eny
      }
      enemy.vx = 0.0
      enemy.vy = 0.0
      // Check collision with player
      if @vector.aabb_overlap_center(
          self.player.x,
          self.player.y,
          self.player.size / 2.0,
          self.player.size / 2.0,
          enemy.x,
          enemy.y,
          enemy.size / 2.0,
          enemy.size / 2.0,
        ) {
        if self.frame_count % 30 == 0 {
          self.player.hp = self.player.hp - 1
          self.player.damage_timer = damage_flash_duration
          if self.player.hp <= 0 {
            self.player.alive = false
            self.mode = mode_gameover
          }
        }
      }
    }
    // Decrement damage timers
    if enemy.damage_timer > 0 {
      enemy.damage_timer = enemy.damage_timer - 1
    }
  }
  // Item collection
  for item in self.items {
    if not(item.collected) {
      if @vector.aabb_overlap_center(
          self.player.x,
          self.player.y,
          self.player.size / 2.0,
          self.player.size / 2.0,
          item.x,
          item.y,
          6.0,
          6.0,
        ) {
        item.collected = true
        if item.kind == 0 {
          self.score = self.score + 50
        } else {
          self.player.hp = @cmp.minimum(self.player.max_hp, self.player.hp + 3)
        }
        // Play pickup SFX
        match self.sfx_pickup {
          Some(id) => self.audio_ctx.play(id) catch { _ => () }
          None => ()
        }
      }
    }
  }
  // Decrement player damage timer
  if self.player.damage_timer > 0 {
    self.player.damage_timer = self.player.damage_timer - 1
  }
  // Decrement screen flash
  if self.screen_flash > 0 {
    self.screen_flash = self.screen_flash - 1
  }
}

///|
fn ShowcaseState::check_wall_collision(
  self : ShowcaseState,
  x : Double,
  y : Double,
  size : Double,
) -> Bool {
  let half = size / 2.0
  let left_col = ((x - half) / tile_size).to_int()
  let right_col = ((x + half) / tile_size).to_int()
  let top_row = ((y - half) / tile_size).to_int()
  let bottom_row = ((y + half) / tile_size).to_int()
  for row = top_row; row <= bottom_row; row = row + 1 {
    for col = left_col; col <= right_col; col = col + 1 {
      if is_wall_at(self.tilemap, col, row) {
        return true
      }
    }
  }
  false
}

// === View (Declarative Scene API) ===

///|
fn ShowcaseState::view(self : ShowcaseState) -> @scene.SceneNode {
  match self.mode {
    m if m == mode_title => self.view_title()
    m if m == mode_playing || m == mode_paused => self.view_playing()
    m if m == mode_gameover => self.view_gameover()
    _ => @scene.rect(w=screen_w, h=screen_h, fill=0x000000)
  }
}

///|
fn ShowcaseState::view_title(self : ShowcaseState) -> @scene.SceneNode {
  @scene.fragment(
    [
      @scene.rect(w=screen_w, h=screen_h, fill=0x1A1A2E),
      @scene.label(
        x=screen_w / 2.0,
        y=screen_h / 2.0 - 30.0,
        content="DUNGEON",
        scale=3.0,
      ),
      @scene.show(fn() { self.frame_count / 30 % 2 == 0 }, fn() {
        @scene.label(
          x=screen_w / 2.0,
          y=screen_h / 2.0 + 30.0,
          content="PRESS SPACE",
          color=0xFFCC00,
        )
      }),
    ],
  )
}

///|
fn ShowcaseState::view_playing(self : ShowcaseState) -> @scene.SceneNode {
  let view_left = self.camera.x
  let view_top = self.camera.y
  let px = self.player.x - view_left
  let py = self.player.y - view_top
  let phs = self.player.size / 2.0
  let player_fill = if self.player.damage_timer > 0 { 0xFFFFFF } else { 0x00FFCC }
  let hp_ratio = self.player.hp.to_double() / self.player.max_hp.to_double()
  let hp_width = 60.0 * hp_ratio
  let item_visible = self.frame_count / 8 % 2 == 0
  @scene.fragment(
    [
      // Background
      @scene.rect(w=screen_w, h=screen_h, fill=0x000000),
      // Tilemap
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        for row = 0; row < map_rows; row = row + 1 {
          for col = 0; col < map_columns; col = col + 1 {
            let sx = col.to_double() * tile_size - view_left
            let sy = row.to_double() * tile_size - view_top
            if sx > -tile_size &&
              sx < screen_w + tile_size &&
              sy > -tile_size &&
              sy < screen_h + tile_size {
              let idx = row * map_columns + col
              let fill = match self.tilemap[idx] {
                t if t == tile_wall => 0x6B4226
                t if t == tile_water => 0x2244AA
                _ => 0x555555
              }
              nodes.push(
                @scene.rect(x=sx, y=sy, w=tile_size, h=tile_size, fill=fill),
              )
            }
          }
        }
        nodes
      }),
      // Grid lines
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        let grid_spacing = tile_size
        let start_gx = @math.floor(view_left / grid_spacing) * grid_spacing
        let mut gx = start_gx
        while gx < view_left + screen_w + grid_spacing {
          let screen_x = gx - view_left
          if screen_x >= 0.0 && screen_x < screen_w {
            nodes.push(
              @scene.rect(
                x=screen_x,
                w=1.0,
                h=screen_h,
                fill=0x444444,
                alpha=0.3,
              ),
            )
          }
          gx = gx + grid_spacing
        }
        let start_gy = @math.floor(view_top / grid_spacing) * grid_spacing
        let mut gy = start_gy
        while gy < view_top + screen_h + grid_spacing {
          let screen_y = gy - view_top
          if screen_y >= 0.0 && screen_y < screen_h {
            nodes.push(
              @scene.rect(
                y=screen_y,
                w=screen_w,
                h=1.0,
                fill=0x444444,
                alpha=0.3,
              ),
            )
          }
          gy = gy + grid_spacing
        }
        nodes
      }),
      // Items (blinking)
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        for item in self.items {
          if not(item.collected) && item_visible {
            let sx = item.x - view_left
            let sy = item.y - view_top
            if sx >= -10.0 &&
              sx <= screen_w + 10.0 &&
              sy >= -10.0 &&
              sy <= screen_h + 10.0 {
              let fill = if item.kind == 0 { 0x00FFFF } else { 0x00FF66 }
              nodes.push(
                @scene.rect(x=sx - 4.0, y=sy - 4.0, w=8.0, h=8.0, fill=fill),
              )
            }
          }
        }
        nodes
      }),
      // Enemies with HP bars
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        for enemy in self.enemies {
          if enemy.alive {
            let sx = enemy.x - view_left
            let sy = enemy.y - view_top
            if sx >= -20.0 &&
              sx <= screen_w + 20.0 &&
              sy >= -20.0 &&
              sy <= screen_h + 20.0 {
              let fill = if enemy.damage_timer > 0 { 0xFFFFFF } else { 0xCC2222 }
              let ehs = enemy.size / 2.0
              // Enemy body
              nodes.push(
                @scene.rect(
                  x=sx - ehs,
                  y=sy - ehs,
                  w=enemy.size,
                  h=enemy.size,
                  fill=fill,
                ),
              )
              // HP bar background
              nodes.push(
                @scene.rect(
                  x=sx - ehs,
                  y=sy - ehs - 4.0,
                  w=enemy.size,
                  h=2.0,
                  fill=0x440000,
                ),
              )
              // HP bar fill
              let ehp_ratio = enemy.hp.to_double() / enemy.max_hp.to_double()
              nodes.push(
                @scene.rect(
                  x=sx - ehs,
                  y=sy - ehs - 4.0,
                  w=enemy.size * ehp_ratio,
                  h=2.0,
                  fill=0xCC0000,
                ),
              )
            }
          }
        }
        nodes
      }),
      // Player
      @scene.rect(
        x=px - phs,
        y=py - phs,
        w=self.player.size,
        h=self.player.size,
        fill=player_fill,
      ),
      // Attack indicator (cross pattern)
      @scene.show(fn() { self.attack_timer > attack_cooldown - 3 }, fn() {
        let cross_thick = 4.0
        let cross_len = attack_range
        @scene.fragment(
          [
            @scene.rect(
              x=px - cross_len / 2.0,
              y=py - cross_thick / 2.0,
              w=cross_len,
              h=cross_thick,
              fill=0xFFFFFF,
              alpha=0.4,
            ),
            @scene.rect(
              x=px - cross_thick / 2.0,
              y=py - cross_len / 2.0,
              w=cross_thick,
              h=cross_len,
              fill=0xFFFFFF,
              alpha=0.4,
            ),
          ],
        )
      }),
      // Screen flash
      @scene.show(fn() { self.screen_flash > 0 }, fn() {
        let flash_alpha = self.screen_flash.to_double() / 5.0
        if self.player.damage_timer > 0 {
          @scene.rect(
            w=screen_w,
            h=screen_h,
            fill=0xFF0000,
            alpha=flash_alpha * 0.15 / 0.6,
          )
        } else {
          @scene.rect(
            w=screen_w,
            h=screen_h,
            fill=0xFFFFFF,
            alpha=flash_alpha,
          )
        }
      }),
      // HUD: HP bar
      @scene.group(
        x=4.0,
        y=4.0,
        children=[
          @scene.rect(w=62.0, h=8.0, fill=0x440000, alpha=0.8),
          @scene.rect(x=1.0, y=1.0, w=hp_width, h=6.0, fill=0x00CC00),
          @scene.rect(y=10.0, w=62.0, h=1.0, fill=0xFFFFFF, alpha=0.2),
        ],
      ),
      // HUD: Score
      @scene.label(
        x=screen_w - 60.0,
        y=8.0,
        content=self.score.to_string(),
        color=0xFFCC00,
        scale=0.8,
      ),
      // Paused overlay
      @scene.show(fn() { self.mode == mode_paused }, fn() {
        let focused_id = self.focus_mgr.current_focus()
        @scene.fragment(
          [
            @scene.rect(w=screen_w, h=screen_h, fill=0x000000, alpha=0.5),
            @scene.label(
              x=screen_w / 2.0,
              y=screen_h / 2.0 - 20.0,
              content="PAUSED",
              scale=2.0,
            ),
            @scene.for_each(fn() {
              let nodes : Array[@scene.SceneNode] = []
              let labels = ["RESUME", "RESET", "QUIT"]
              for i = 0; i < labels.length(); i = i + 1 {
                let color = match focused_id {
                  Some(id) if id.value == self.menu_node_ids[i].value =>
                    0xFFFF00
                  _ => 0xFFFFFF
                }
                nodes.push(
                  @scene.label(
                    x=screen_w / 2.0,
                    y=screen_h / 2.0 + 10.0 + i.to_double() * 18.0,
                    content=labels[i],
                    color=color,
                  ),
                )
              }
              nodes
            }),
          ],
        )
      }),
    ],
  )
}

///|
fn ShowcaseState::view_gameover(self : ShowcaseState) -> @scene.SceneNode {
  @scene.fragment(
    [
      @scene.rect(w=screen_w, h=screen_h, fill=0x2E0000),
      @scene.label(
        x=screen_w / 2.0,
        y=screen_h / 2.0 - 20.0,
        content="GAME OVER",
        color=0xFF0000,
        scale=2.0,
      ),
      @scene.label(
        x=screen_w / 2.0,
        y=screen_h / 2.0 + 10.0,
        content="SCORE",
        color=0xFFCC00,
      ),
      @scene.label(
        x=screen_w / 2.0,
        y=screen_h / 2.0 + 30.0,
        content=self.score.to_string(),
        scale=2.0,
      ),
    ],
  )
}
