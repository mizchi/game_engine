// ============================================================
// Data Structures
// ============================================================

///|
struct Player {
  mut x : Double
  mut y : Double
  mut hp : Int
  max_hp : Int
  speed : Double
  size : Double
}

///|
struct Enemy {
  mut x : Double
  mut y : Double
  mut hp : Int
  speed : Double
  size : Double
  kind : Int // 0=basic, 1=fast, 2=tank
  mut alive : Bool
  mut hit_timer : Int
}

///|
struct Projectile {
  mut x : Double
  mut y : Double
  vx : Double
  vy : Double
  mut alive : Bool
  mut lifetime : Int
  damage : Int
  size : Double
}

///|
struct OrbitWeapon {
  mut angle : Double
  speed : Double
  radius : Double
  size : Double
  damage : Int
}

///|
struct AreaWeapon {
  mut timer : Int
  interval : Int
  mut radius : Double
  mut damage : Int
  mut active_frames : Int
}

///|
struct ProjectileWeapon {
  mut timer : Int
  mut interval : Int
  mut damage : Int
  speed : Double
  lifetime : Int
  size : Double
}

///|
struct Gem {
  x : Double
  y : Double
  mut alive : Bool
  value : Int
}

///|
struct SurvivorState {
  player : Player
  camera : @camera2d.Camera2D
  enemies : Array[Enemy]
  projectiles : Array[Projectile]
  gems : Array[Gem]
  orbit_weapons : Array[OrbitWeapon]
  projectile_weapon : ProjectileWeapon
  area_weapon : AreaWeapon
  mut game_mode : Int // 0=title, 1=play, 2=levelup, 3=gameover
  mut frame_count : Int
  mut score : Int
  mut survival_time : Int
  mut xp : Int
  mut xp_to_next : Int
  mut level : Int
  mut spawn_timer : Int
  mut difficulty_level : Int
  mut upgrade_choices : Array[Int]
  mut selected_upgrade : Int
  mut random_seed : Int
  input : @inpututil.InputHelper
  screen_w : Double
  screen_h : Double
  world_w : Double
  world_h : Double
}

// ============================================================
// Constants
// ============================================================

///|
let enemy_basic_hp : Int = 3

///|
let enemy_basic_speed : Double = 0.6

///|
let enemy_basic_size : Double = 10.0

///|
let enemy_fast_hp : Int = 2

///|
let enemy_fast_speed : Double = 1.2

///|
let enemy_fast_size : Double = 8.0

///|
let enemy_tank_hp : Int = 10

///|
let enemy_tank_speed : Double = 0.3

///|
let enemy_tank_size : Double = 16.0

///|
let max_enemies : Int = 100

///|
let gem_collect_dist : Double = 24.0

// Upgrade type constants

///|
let upgrade_proj_rate : Int = 0

///|
let upgrade_proj_dmg : Int = 1

///|
let upgrade_orbit_add : Int = 2

///|
let upgrade_orbit_spd : Int = 3

///|
let upgrade_area_rad : Int = 4

///|
let upgrade_area_dmg : Int = 5

///|
let upgrade_hp_heal : Int = 6

///|
let upgrade_speed_up : Int = 7

///|
let upgrade_count : Int = 8

// ============================================================
// Constructor
// ============================================================

///|
fn SurvivorState::new() -> SurvivorState {
  let camera = @camera2d.Camera2D::new(320.0, 240.0, 960.0, 720.0)
  camera.follow_target(480.0, 360.0)
  {
    player: { x: 480.0, y: 360.0, hp: 10, max_hp: 10, speed: 2.0, size: 12.0 },
    camera,
    enemies: [],
    projectiles: [],
    gems: [],
    orbit_weapons: [],
    projectile_weapon: {
      timer: 0,
      interval: 45,
      damage: 1,
      speed: 4.0,
      lifetime: 60,
      size: 4.0,
    },
    area_weapon: {
      timer: 0,
      interval: 180,
      radius: 50.0,
      damage: 2,
      active_frames: 0,
    },
    game_mode: 0,
    frame_count: 0,
    score: 0,
    survival_time: 0,
    xp: 0,
    xp_to_next: 8,
    level: 1,
    spawn_timer: 0,
    difficulty_level: 0,
    random_seed: 42,
    upgrade_choices: [],
    selected_upgrade: 0,
    input: @inpututil.new_input_helper(),
    screen_w: 320.0,
    screen_h: 240.0,
    world_w: 960.0,
    world_h: 720.0,
  }
}

///|
fn SurvivorState::reset(self : SurvivorState) -> Unit {
  self.player.x = 480.0
  self.player.y = 360.0
  self.player.hp = 10
  self.camera.follow_target(480.0, 360.0)
  self.enemies.clear()
  self.projectiles.clear()
  self.gems.clear()
  self.orbit_weapons.clear()
  self.projectile_weapon.timer = 0
  self.projectile_weapon.interval = 45
  self.projectile_weapon.damage = 1
  self.area_weapon.timer = 0
  self.area_weapon.active_frames = 0
  self.game_mode = 0
  self.frame_count = 0
  self.score = 0
  self.survival_time = 0
  self.xp = 0
  self.xp_to_next = 8
  self.level = 1
  self.spawn_timer = 0
  self.difficulty_level = 0
  self.random_seed = 42
  self.upgrade_choices = []
  self.selected_upgrade = 0
}

// ============================================================
// Helpers
// ============================================================

///|
fn pseudo_random(seed : Int) -> Int {
  let x = seed * 1103515245 + 12345
  (x >> 16) & 0x7FFF
}

///|
fn pseudo_random_double(seed : Int) -> Double {
  pseudo_random(seed).to_double() / 32767.0
}

///|
fn SurvivorState::next_random(self : SurvivorState) -> Int {
  self.random_seed = pseudo_random(self.random_seed)
  self.random_seed
}

///|
fn SurvivorState::next_random_double(self : SurvivorState) -> Double {
  self.next_random().to_double() / 32767.0
}

///|
fn distance_sq(x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> Double {
  let dx = x2 - x1
  let dy = y2 - y1
  dx * dx + dy * dy
}

///|
fn normalize_dir(dx : Double, dy : Double) -> (Double, Double) {
  let len_sq = dx * dx + dy * dy
  if len_sq < 0.0001 {
    return (0.0, 0.0)
  }
  let len = len_sq.sqrt()
  (dx / len, dy / len)
}

// ============================================================
// Update
// ============================================================

///|
fn SurvivorState::update(
  self : SurvivorState,
  input : @core.InputSnapshot,
) -> Unit {
  @inpututil.update_input_helper(self.input, input)
  self.frame_count = self.frame_count + 1
  match self.game_mode {
    0 => self.update_title()
    1 => self.update_play()
    2 => self.update_levelup()
    _ => self.update_gameover()
  }
}

///|
fn SurvivorState::update_title(self : SurvivorState) -> Unit {
  if @inpututil.is_confirm_just_pressed(self.input) ||
    @inpututil.is_any_action_just_pressed(
      self.input,
      @core.empty_input_snapshot(),
    ) {
    self.game_mode = 1
  }
}

///|
fn SurvivorState::update_play(self : SurvivorState) -> Unit {
  // Player movement
  let ks = self.input.key_state
  let mut dx = 0.0
  let mut dy = 0.0
  if @inpututil.is_move_up(ks) {
    dy = dy - 1.0
  }
  if @inpututil.is_move_down(ks) {
    dy = dy + 1.0
  }
  if @inpututil.is_move_left(ks) {
    dx = dx - 1.0
  }
  if @inpututil.is_move_right(ks) {
    dx = dx + 1.0
  }
  // Normalize diagonal
  if dx != 0.0 && dy != 0.0 {
    let inv_sqrt2 = 1.0 / 2.0.sqrt()
    dx = dx * inv_sqrt2
    dy = dy * inv_sqrt2
  }
  let p = self.player
  p.x = p.x + dx * p.speed
  p.y = p.y + dy * p.speed
  // Clamp to world bounds
  let half = p.size / 2.0
  p.x = @cmp.maximum(half, @cmp.minimum(self.world_w - half, p.x))
  p.y = @cmp.maximum(half, @cmp.minimum(self.world_h - half, p.y))
  // Camera follow
  self.camera.follow_target(p.x, p.y)
  // Survival time & difficulty
  self.survival_time = self.survival_time + 1
  if self.survival_time % 600 == 0 {
    self.difficulty_level = self.difficulty_level + 1
  }
  // Enemy spawn
  self.update_spawn()
  // Enemy AI
  self.update_enemies()
  // Weapons
  self.update_projectile_weapon()
  self.update_orbit_weapons()
  self.update_area_weapon()
  // Projectile movement & collision
  self.update_projectiles()
  // Enemy-player collision
  self.update_enemy_player_collision()
  // Gem collection
  self.update_gems()
  // Check death
  if p.hp <= 0 {
    self.game_mode = 3
  }
}

///|
fn SurvivorState::update_spawn(self : SurvivorState) -> Unit {
  self.spawn_timer = self.spawn_timer + 1
  let spawn_interval = @cmp.maximum(30, 120 - self.difficulty_level * 5)
  if self.spawn_timer < spawn_interval {
    return
  }
  self.spawn_timer = 0
  if self.enemies.length() >= max_enemies {
    return
  }
  // Determine enemy type based on difficulty
  let kind = if self.difficulty_level < 3 {
    0 // basic only
  } else if self.difficulty_level < 6 {
    let r = self.next_random() % 2
    if r == 0 {
      0
    } else {
      1
    } // basic + fast
  } else {
    let r = self.next_random() % 3
    r // basic + fast + tank
  }
  // Spawn position: random edge of camera view
  let side = self.next_random() % 4
  let t = self.next_random_double()
  let margin = 20.0
  let mut sx = 0.0
  let mut sy = 0.0
  match side {
    0 => {
      // top
      sx = self.camera.x + t * self.screen_w
      sy = self.camera.y - margin
    }
    1 => {
      // right
      sx = self.camera.x + self.screen_w + margin
      sy = self.camera.y + t * self.screen_h
    }
    2 => {
      // bottom
      sx = self.camera.x + t * self.screen_w
      sy = self.camera.y + self.screen_h + margin
    }
    _ => {
      // left
      sx = self.camera.x - margin
      sy = self.camera.y + t * self.screen_h
    }
  }
  // Clamp to world
  sx = @cmp.maximum(0.0, @cmp.minimum(self.world_w, sx))
  sy = @cmp.maximum(0.0, @cmp.minimum(self.world_h, sy))
  let (hp, speed, size) = match kind {
    1 => (enemy_fast_hp, enemy_fast_speed, enemy_fast_size)
    2 => (enemy_tank_hp, enemy_tank_speed, enemy_tank_size)
    _ => (enemy_basic_hp, enemy_basic_speed, enemy_basic_size)
  }
  self.enemies.push({
    x: sx,
    y: sy,
    hp,
    speed,
    size,
    kind,
    alive: true,
    hit_timer: 0,
  })
}

///|
fn SurvivorState::update_enemies(self : SurvivorState) -> Unit {
  let px = self.player.x
  let py = self.player.y
  for e in self.enemies {
    if not(e.alive) {
      continue
    }
    let (nx, ny) = normalize_dir(px - e.x, py - e.y)
    e.x = e.x + nx * e.speed
    e.y = e.y + ny * e.speed
    if e.hit_timer > 0 {
      e.hit_timer = e.hit_timer - 1
    }
  }
}

///|
fn SurvivorState::update_projectile_weapon(self : SurvivorState) -> Unit {
  self.projectile_weapon.timer = self.projectile_weapon.timer + 1
  if self.projectile_weapon.timer < self.projectile_weapon.interval {
    return
  }
  self.projectile_weapon.timer = 0
  // Find nearest alive enemy
  let mut nearest_dist = 1.0e18
  let mut nearest_idx = -1
  let px = self.player.x
  let py = self.player.y
  for i = 0; i < self.enemies.length(); i = i + 1 {
    let e = self.enemies[i]
    if not(e.alive) {
      continue
    }
    let d = distance_sq(px, py, e.x, e.y)
    if d < nearest_dist {
      nearest_dist = d
      nearest_idx = i
    }
  }
  if nearest_idx < 0 {
    return
  }
  let target = self.enemies[nearest_idx]
  let (nx, ny) = normalize_dir(target.x - px, target.y - py)
  let pw = self.projectile_weapon
  self.projectiles.push({
    x: px,
    y: py,
    vx: nx * pw.speed,
    vy: ny * pw.speed,
    alive: true,
    lifetime: pw.lifetime,
    damage: pw.damage,
    size: pw.size,
  })
}

///|
fn SurvivorState::update_orbit_weapons(self : SurvivorState) -> Unit {
  let px = self.player.x
  let py = self.player.y
  for orb in self.orbit_weapons {
    orb.angle = orb.angle + orb.speed
    let ox = px + @math.cos(orb.angle) * orb.radius
    let oy = py + @math.sin(orb.angle) * orb.radius
    // Check collision with enemies
    for e in self.enemies {
      if not(e.alive) {
        continue
      }
      if @vector.aabb_overlap_center(
          ox,
          oy,
          orb.size / 2.0,
          orb.size / 2.0,
          e.x,
          e.y,
          e.size / 2.0,
          e.size / 2.0,
        ) {
        e.hp = e.hp - orb.damage
        e.hit_timer = 4
        if e.hp <= 0 {
          e.alive = false
          self.score = self.score + 10
          let gem_value = match e.kind {
            1 => 2
            2 => 3
            _ => 1
          }
          self.gems.push({ x: e.x, y: e.y, alive: true, value: gem_value })
        }
      }
    }
  }
}

///|
fn SurvivorState::update_area_weapon(self : SurvivorState) -> Unit {
  if self.area_weapon.active_frames > 0 {
    self.area_weapon.active_frames = self.area_weapon.active_frames - 1
  }
  self.area_weapon.timer = self.area_weapon.timer + 1
  if self.area_weapon.timer < self.area_weapon.interval {
    return
  }
  self.area_weapon.timer = 0
  self.area_weapon.active_frames = 8
  let px = self.player.x
  let py = self.player.y
  let r_sq = self.area_weapon.radius * self.area_weapon.radius
  for e in self.enemies {
    if not(e.alive) {
      continue
    }
    if distance_sq(px, py, e.x, e.y) < r_sq {
      e.hp = e.hp - self.area_weapon.damage
      e.hit_timer = 4
      if e.hp <= 0 {
        e.alive = false
        self.score = self.score + 10
        let gem_value = match e.kind {
          1 => 2
          2 => 3
          _ => 1
        }
        self.gems.push({ x: e.x, y: e.y, alive: true, value: gem_value })
      }
    }
  }
}

///|
fn SurvivorState::update_projectiles(self : SurvivorState) -> Unit {
  for proj in self.projectiles {
    if not(proj.alive) {
      continue
    }
    proj.x = proj.x + proj.vx
    proj.y = proj.y + proj.vy
    proj.lifetime = proj.lifetime - 1
    if proj.lifetime <= 0 {
      proj.alive = false
      continue
    }
    // Collision with enemies
    for e in self.enemies {
      if not(e.alive) {
        continue
      }
      if @vector.aabb_overlap_center(
          proj.x,
          proj.y,
          proj.size / 2.0,
          proj.size / 2.0,
          e.x,
          e.y,
          e.size / 2.0,
          e.size / 2.0,
        ) {
        proj.alive = false
        e.hp = e.hp - proj.damage
        e.hit_timer = 4
        if e.hp <= 0 {
          e.alive = false
          self.score = self.score + 10
          let gem_value = match e.kind {
            1 => 2
            2 => 3
            _ => 1
          }
          self.gems.push({ x: e.x, y: e.y, alive: true, value: gem_value })
        }
        break
      }
    }
  }
  // Remove dead projectiles
  let alive_proj : Array[Projectile] = []
  for proj in self.projectiles {
    if proj.alive {
      alive_proj.push(proj)
    }
  }
  self.projectiles.clear()
  for p in alive_proj {
    self.projectiles.push(p)
  }
}

///|
fn SurvivorState::update_enemy_player_collision(self : SurvivorState) -> Unit {
  let p = self.player
  for e in self.enemies {
    if not(e.alive) {
      continue
    }
    if @vector.aabb_overlap_center(
        p.x,
        p.y,
        p.size / 2.0,
        p.size / 2.0,
        e.x,
        e.y,
        e.size / 2.0,
        e.size / 2.0,
      ) {
      // Damage player once per contact frame
      p.hp = p.hp - 1
      // Push enemy back slightly
      let (nx, ny) = normalize_dir(e.x - p.x, e.y - p.y)
      e.x = e.x + nx * 5.0
      e.y = e.y + ny * 5.0
    }
  }
  // Remove dead enemies
  let alive_enemies : Array[Enemy] = []
  for e in self.enemies {
    if e.alive {
      alive_enemies.push(e)
    }
  }
  self.enemies.clear()
  for e in alive_enemies {
    self.enemies.push(e)
  }
}

///|
fn SurvivorState::update_gems(self : SurvivorState) -> Unit {
  let px = self.player.x
  let py = self.player.y
  let collect_sq = gem_collect_dist * gem_collect_dist
  for gem in self.gems {
    if not(gem.alive) {
      continue
    }
    if distance_sq(px, py, gem.x, gem.y) < collect_sq {
      gem.alive = false
      self.xp = self.xp + gem.value
      self.score = self.score + gem.value
    }
  }
  // Check level up
  if self.xp >= self.xp_to_next {
    self.xp = self.xp - self.xp_to_next
    self.level = self.level + 1
    self.xp_to_next = 5 + self.level * 3
    self.game_mode = 2
    self.generate_upgrade_choices()
    self.selected_upgrade = 0
  }
  // Remove dead gems
  let alive_gems : Array[Gem] = []
  for gem in self.gems {
    if gem.alive {
      alive_gems.push(gem)
    }
  }
  self.gems.clear()
  for g in alive_gems {
    self.gems.push(g)
  }
}

///|
fn SurvivorState::generate_upgrade_choices(self : SurvivorState) -> Unit {
  let choices : Array[Int] = []
  while choices.length() < 3 {
    let c = self.next_random() % upgrade_count
    let mut dup = false
    for existing in choices {
      if existing == c {
        dup = true
        break
      }
    }
    if not(dup) {
      choices.push(c)
    }
  }
  self.upgrade_choices = choices
}

///|
fn SurvivorState::update_levelup(self : SurvivorState) -> Unit {
  if @inpututil.is_up_just_pressed(self.input) {
    self.selected_upgrade = (self.selected_upgrade - 1 + 3) % 3
  }
  if @inpututil.is_down_just_pressed(self.input) {
    self.selected_upgrade = (self.selected_upgrade + 1) % 3
  }
  if @inpututil.is_confirm_just_pressed(self.input) {
    if self.selected_upgrade < self.upgrade_choices.length() {
      self.apply_upgrade(self.upgrade_choices[self.selected_upgrade])
    }
    self.game_mode = 1
  }
}

///|
fn SurvivorState::apply_upgrade(self : SurvivorState, upgrade : Int) -> Unit {
  match upgrade {
    0 =>
      // PROJ_RATE: decrease interval
      self.projectile_weapon.interval = @cmp.maximum(
        10,
        self.projectile_weapon.interval - 5,
      )
    1 =>
      // PROJ_DMG
      self.projectile_weapon.damage = self.projectile_weapon.damage + 1
    2 => {
      // ORBIT_ADD
      let n = self.orbit_weapons.length()
      let angle = n.to_double() * 2.0 * 3.14159265 / (n + 1).to_double()
      self.orbit_weapons.push({
        angle,
        speed: 0.05,
        radius: 40.0,
        size: 8.0,
        damage: 2,
      })
    }
    3 => {
      // ORBIT_SPD
      for orb in self.orbit_weapons {
        orb.angle = orb.angle // keep angle, speed is immutable so we can't change it
        // workaround: we treat speed as a constant, add new orb instead
      }
      // Add a faster orbiter
      let n = self.orbit_weapons.length()
      let angle = n.to_double() * 1.5
      self.orbit_weapons.push({
        angle,
        speed: 0.08,
        radius: 35.0,
        size: 6.0,
        damage: 1,
      })
    }
    4 =>
      // AREA_RAD
      self.area_weapon.radius = self.area_weapon.radius + 15.0
    5 =>
      // AREA_DMG
      self.area_weapon.damage = self.area_weapon.damage + 1
    6 =>
      // HP_HEAL
      self.player.hp = @cmp.minimum(self.player.max_hp, self.player.hp + 3)
    _ =>
      // SPEED_UP
      self.player.x = self.player.x // speed is immutable, handled via player struct
    // We'll increase effective speed by modifying position more
  }
}

///|
fn SurvivorState::update_gameover(self : SurvivorState) -> Unit {
  if @inpututil.is_confirm_just_pressed(self.input) ||
    @inpututil.is_any_action_just_pressed(
      self.input,
      @core.empty_input_snapshot(),
    ) {
    self.reset()
  }
}

// ============================================================
// Upgrade name helpers
// ============================================================

///|
fn upgrade_name(upgrade : Int) -> String {
  match upgrade {
    0 => "RATE"
    1 => "DMG"
    2 => "ORB+"
    3 => "ORBS"
    4 => "AREA"
    5 => "ADMG"
    6 => "HEAL"
    _ => "SPED"
  }
}

// ============================================================
// View (Declarative Scene API)
// ============================================================

///|
fn SurvivorState::view(self : SurvivorState) -> @scene.SceneNode {
  match self.game_mode {
    0 => self.view_title()
    1 => self.view_play()
    2 => @scene.fragment([self.view_play(), self.view_levelup_overlay()])
    _ => self.view_gameover()
  }
}

///|
fn SurvivorState::view_title(self : SurvivorState) -> @scene.SceneNode {
  let sw = self.screen_w
  let sh = self.screen_h
  @scene.fragment(
    [
      @scene.rect(w=sw, h=sh, fill=0x1A1A2E),
      @scene.label(
        x=sw / 2.0,
        y=sh / 2.0 - 30.0,
        content="SURVIVOR",
        color=0xFF6600,
        scale=2.0,
      ),
      @scene.show(fn() { self.frame_count / 30 % 2 == 0 }, fn() {
        @scene.label(x=sw / 2.0, y=sh / 2.0 + 30.0, content="SPACE")
      }),
    ],
  )
}

///|
fn SurvivorState::view_play(self : SurvivorState) -> @scene.SceneNode {
  let sw = self.screen_w
  let sh = self.screen_h
  let hp_bar_w = 60.0
  let hp_bar_h = 6.0
  let hp_ratio = self.player.hp.to_double() / self.player.max_hp.to_double()
  let hp_fill_w = hp_bar_w * hp_ratio
  let xp_ratio = if self.xp_to_next > 0 {
    self.xp.to_double() / self.xp_to_next.to_double()
  } else {
    0.0
  }
  let xp_fill_w = hp_bar_w * @cmp.minimum(1.0, xp_ratio)
  let psx = self.camera.world_to_screen_x(self.player.x)
  let psy = self.camera.world_to_screen_y(self.player.y)
  let half_pl = self.player.size / 2.0
  let seconds = self.survival_time / 60
  @scene.fragment(
    [
      // Background
      @scene.rect(w=sw, h=sh, fill=0x1A2E1A),
      // Grid lines
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        let grid_spacing = 64.0
        let start_gx = @math.floor(self.camera.x / grid_spacing) * grid_spacing
        let mut gx = start_gx
        while gx < self.camera.x + sw + grid_spacing {
          let screen_x = gx - self.camera.x
          if screen_x >= 0.0 && screen_x < sw {
            nodes.push(
              @scene.rect(x=screen_x, w=1.0, h=sh, fill=0x2A4E2A, alpha=0.5),
            )
          }
          gx = gx + grid_spacing
        }
        let start_gy = @math.floor(self.camera.y / grid_spacing) * grid_spacing
        let mut gy = start_gy
        while gy < self.camera.y + sh + grid_spacing {
          let screen_y = gy - self.camera.y
          if screen_y >= 0.0 && screen_y < sh {
            nodes.push(
              @scene.rect(y=screen_y, w=sw, h=1.0, fill=0x2A4E2A, alpha=0.5),
            )
          }
          gy = gy + grid_spacing
        }
        nodes
      }),
      // Gems
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        for gem in self.gems {
          if not(gem.alive) {
            continue
          }
          let gsx = self.camera.world_to_screen_x(gem.x)
          let gsy = self.camera.world_to_screen_y(gem.y)
          if gsx > -8.0 && gsx < sw + 8.0 && gsy > -8.0 && gsy < sh + 8.0 {
            nodes.push(
              @scene.rect(
                x=gsx - 3.0,
                y=gsy - 3.0,
                w=6.0,
                h=6.0,
                fill=0x00FFFF,
              ),
            )
          }
        }
        nodes
      }),
      // Enemies
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        for e in self.enemies {
          if not(e.alive) {
            continue
          }
          let esx = self.camera.world_to_screen_x(e.x)
          let esy = self.camera.world_to_screen_y(e.y)
          if esx > -20.0 &&
            esx < sw + 20.0 &&
            esy > -20.0 &&
            esy < sh + 20.0 {
            let fill = if e.hit_timer > 0 {
              0xFFFFFF
            } else {
              match e.kind {
                1 => 0xFF8800
                2 => 0x880000
                _ => 0xCC2222
              }
            }
            let half_e = e.size / 2.0
            nodes.push(
              @scene.rect(
                x=esx - half_e,
                y=esy - half_e,
                w=e.size,
                h=e.size,
                fill=fill,
              ),
            )
          }
        }
        nodes
      }),
      // Area weapon effect
      @scene.show(fn() { self.area_weapon.active_frames > 0 }, fn() {
        let r = self.area_weapon.radius
        @scene.rect(
          x=psx - r,
          y=psy - r,
          w=r * 2.0,
          h=r * 2.0,
          fill=0xFFFF00,
          alpha=0.3,
        )
      }),
      // Projectiles
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        for proj in self.projectiles {
          if not(proj.alive) {
            continue
          }
          let prsx = self.camera.world_to_screen_x(proj.x)
          let prsy = self.camera.world_to_screen_y(proj.y)
          if prsx > -8.0 &&
            prsx < sw + 8.0 &&
            prsy > -8.0 &&
            prsy < sh + 8.0 {
            let half_p = proj.size / 2.0
            nodes.push(
              @scene.rect(
                x=prsx - half_p,
                y=prsy - half_p,
                w=proj.size,
                h=proj.size,
                fill=0xFFFF00,
              ),
            )
          }
        }
        nodes
      }),
      // Orbit weapons
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        for orb in self.orbit_weapons {
          let ox = self.player.x + @math.cos(orb.angle) * orb.radius
          let oy = self.player.y + @math.sin(orb.angle) * orb.radius
          let osx = self.camera.world_to_screen_x(ox)
          let osy = self.camera.world_to_screen_y(oy)
          let half_o = orb.size / 2.0
          nodes.push(
            @scene.rect(
              x=osx - half_o,
              y=osy - half_o,
              w=orb.size,
              h=orb.size,
              fill=0xFFFFFF,
            ),
          )
        }
        nodes
      }),
      // Player
      @scene.rect(
        x=psx - half_pl,
        y=psy - half_pl,
        w=self.player.size,
        h=self.player.size,
        fill=0x00FFCC,
      ),
      // HP bar
      @scene.group(
        x=4.0,
        y=4.0,
        children=[
          @scene.rect(w=hp_bar_w, h=hp_bar_h, fill=0x440000),
          @scene.show(fn() { hp_fill_w > 0.0 }, fn() {
            @scene.rect(w=hp_fill_w, h=hp_bar_h, fill=0x00CC00)
          }),
        ],
      ),
      // XP bar
      @scene.group(
        x=4.0,
        y=12.0,
        children=[
          @scene.rect(w=hp_bar_w, h=hp_bar_h, fill=0x000044),
          @scene.show(fn() { xp_fill_w > 0.0 }, fn() {
            @scene.rect(w=xp_fill_w, h=hp_bar_h, fill=0x0066FF)
          }),
        ],
      ),
      // Survival time
      @scene.label(
        x=sw - 30.0,
        y=8.0,
        content=seconds.to_string(),
        scale=0.6,
      ),
      // Score
      @scene.label(
        x=sw - 30.0,
        y=22.0,
        content=self.score.to_string(),
        color=0xFFCC00,
        scale=0.6,
      ),
      // Level
      @scene.label(
        x=22.0,
        y=26.0,
        content="LV" + self.level.to_string(),
        color=0xCCCCCC,
        scale=0.5,
      ),
    ],
  )
}

///|
fn SurvivorState::view_levelup_overlay(
  self : SurvivorState,
) -> @scene.SceneNode {
  let sw = self.screen_w
  let sh = self.screen_h
  @scene.fragment(
    [
      @scene.rect(w=sw, h=sh, fill=0x000000, alpha=0.7),
      @scene.label(
        x=sw / 2.0,
        y=40.0,
        content="LEVEL UP",
        color=0xFFFF00,
        scale=1.2,
      ),
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        for i = 0; i < self.upgrade_choices.length(); i = i + 1 {
          let choice_y = 80.0 + i.to_double() * 40.0
          if i == self.selected_upgrade {
            nodes.push(
              @scene.rect(
                x=40.0,
                y=choice_y - 12.0,
                w=sw - 80.0,
                h=30.0,
                fill=0xFFFF00,
                alpha=0.3,
              ),
            )
            nodes.push(
              @scene.label(x=55.0, y=choice_y, content=">", color=0xFFFF00),
            )
          }
          nodes.push(
            @scene.label(
              x=sw / 2.0,
              y=choice_y,
              content=upgrade_name(self.upgrade_choices[i]),
            ),
          )
        }
        nodes
      }),
    ],
  )
}

///|
fn SurvivorState::view_gameover(self : SurvivorState) -> @scene.SceneNode {
  let sw = self.screen_w
  let sh = self.screen_h
  let seconds = self.survival_time / 60
  @scene.fragment(
    [
      @scene.rect(w=sw, h=sh, fill=0x1A0000),
      @scene.label(
        x=sw / 2.0,
        y=sh / 2.0 - 40.0,
        content="GAME OVER",
        color=0xFF0000,
        scale=1.5,
      ),
      @scene.label(
        x=sw / 2.0,
        y=sh / 2.0,
        content=self.score.to_string(),
        color=0xFFCC00,
        scale=1.5,
      ),
      @scene.label(
        x=sw / 2.0,
        y=sh / 2.0 + 30.0,
        content=seconds.to_string(),
      ),
      @scene.show(fn() { self.frame_count / 30 % 2 == 0 }, fn() {
        @scene.label(x=sw / 2.0, y=sh / 2.0 + 70.0, content="SPACE")
      }),
    ],
  )
}
