///|
struct Pipe {
  mut x : Double
  gap_y : Double
}

let screen_w : Int = 320

let screen_h : Int = 240

let bird_x : Double = 60.0

let bird_size : Double = 12.0

let gravity : Double = 0.25

let jump_velocity : Double = -4.5

let pipe_width : Double = 36.0

let pipe_gap : Double = 70.0

let pipe_speed : Double = 1.5

let pipe_interval : Int = 120

let ground_h : Double = 20.0

// KeyCode constants
let key_space : Int = 32

let key_up : Int = 38

///|
struct Game {
  mut game_mode : Int // 0=start, 1=playing, 2=game_over
  mut score : Int
  mut bird_y : Double
  mut velocity : Double
  mut frame_count : Int
  mut pipe_timer : Int
  pipes : Array[Pipe]
  mut prev_action : Bool
}

///|
fn Game::new() -> Game {
  {
    game_mode: 0,
    score: 0,
    bird_y: screen_h.to_double() / 2.0,
    velocity: 0.0,
    frame_count: 0,
    pipe_timer: 0,
    pipes: [],
    prev_action: false,
  }
}

///|
fn Game::reset(self : Game) -> Unit {
  self.bird_y = screen_h.to_double() / 2.0
  self.velocity = 0.0
  self.game_mode = 0
  self.score = 0
  self.pipes.clear()
  self.pipe_timer = 0
}

///|
fn pseudo_random(seed : Int) -> Double {
  let x = seed * 1103515245 + 12345
  let normalized = ((x >> 16) & 0x7FFF).to_double() / 32767.0
  normalized
}

///|
fn Game::update(self : Game, input : InputState) -> Unit {
  self.frame_count = self.frame_count + 1
  // Detect "just pressed" (edge detection)
  let current_action = is_key_pressed(input, key_space) ||
    is_key_pressed(input, key_up) ||
    is_mouse_pressed(input)
  let action = current_action && not(self.prev_action)
  self.prev_action = current_action
  match self.game_mode {
    0 => {
      if action {
        self.game_mode = 1
        self.velocity = jump_velocity
      }
    }
    1 => {
      // Physics
      self.velocity = self.velocity + gravity
      self.bird_y = self.bird_y + self.velocity
      if action {
        self.velocity = jump_velocity
      }
      // Pipe generation
      self.pipe_timer = self.pipe_timer + 1
      if self.pipe_timer >= pipe_interval {
        self.pipe_timer = 0
        let sw = screen_w.to_double()
        let sh = screen_h.to_double()
        let min_gap_y = 40.0
        let max_gap_y = sh - ground_h - pipe_gap - 40.0
        let gap_y = min_gap_y +
          pseudo_random(self.frame_count) * (max_gap_y - min_gap_y)
        self.pipes.push({ x: sw, gap_y })
      }
      // Move pipes and check scoring
      let mut i = 0
      while i < self.pipes.length() {
        let pipe = self.pipes[i]
        let old_x = pipe.x
        pipe.x = pipe.x - pipe_speed
        let pipe_right = old_x + pipe_width
        let pipe_right_new = pipe.x + pipe_width
        if pipe_right >= bird_x && pipe_right_new < bird_x {
          self.score = self.score + 1
        }
        i = i + 1
      }
      // Remove off-screen pipes
      let new_pipes : Array[Pipe] = []
      for pipe in self.pipes {
        if pipe.x + pipe_width > 0.0 {
          new_pipes.push(pipe)
        }
      }
      self.pipes.clear()
      for pipe in new_pipes {
        self.pipes.push(pipe)
      }
      // Collision: ground/ceiling
      let ground_top = screen_h.to_double() - ground_h
      if self.bird_y + bird_size > ground_top || self.bird_y < 0.0 {
        self.game_mode = 2
      }
      // Collision: pipes
      for pipe in self.pipes {
        let bird_right = bird_x + bird_size
        let bird_bottom = self.bird_y + bird_size
        let pipe_right = pipe.x + pipe_width
        if bird_right > pipe.x && bird_x < pipe_right {
          let gap_bottom = pipe.gap_y + pipe_gap
          if self.bird_y < pipe.gap_y || bird_bottom > gap_bottom {
            self.game_mode = 2
          }
        }
      }
    }
    _ => {
      if action {
        self.reset()
      }
    }
  }
}

///|
fn Game::draw(self : Game) -> Array[DrawCmd] {
  let sw = screen_w.to_double()
  let sh = screen_h.to_double()
  let ground_y = sh - ground_h
  let cmds : Array[DrawCmd] = []
  // Sky
  cmds.push(rect_cmd_hex(0.0, 0.0, sw, sh, sw, sh, 0x87CEEB))
  // Ground
  cmds.push(rect_cmd_hex(0.0, ground_y, sw, ground_h, sw, sh, 0x8B4513))
  // Pipes
  for pipe in self.pipes {
    // Upper pipe
    if pipe.gap_y > 0.0 {
      cmds.push(
        rect_cmd_hex(pipe.x, 0.0, pipe_width, pipe.gap_y, sw, sh, 0x228B22),
      )
    }
    // Lower pipe
    let lower_y = pipe.gap_y + pipe_gap
    let lower_h = ground_y - lower_y
    if lower_h > 0.0 {
      cmds.push(
        rect_cmd_hex(pipe.x, lower_y, pipe_width, lower_h, sw, sh, 0x228B22),
      )
    }
  }
  // Bird
  cmds.push(
    rect_cmd_hex(bird_x, self.bird_y, bird_size, bird_size, sw, sh, 0xFFD700),
  )
  // Game over overlay
  if self.game_mode == 2 {
    cmds.push(
      rect_cmd_hex(
        sw / 2.0 - 50.0,
        sh / 2.0 - 20.0,
        100.0,
        40.0,
        sw,
        sh,
        0x000000,
        alpha=128,
      ),
    )
  }
  cmds
}

// --- WASM Exports ---

let game : Game = Game::new()

///|
pub fn kagura_init() -> Int {
  bump_init()
  let ptr = bump_alloc(64)
  mem_store32(ptr, screen_w)
  mem_store32(ptr + 4, screen_h)
  // Title: "Flappy Bird"
  let title = "Flappy Bird"
  let title_bytes = title.to_array()
  mem_store32(ptr + 8, title_bytes.length())
  for i = 0; i < title_bytes.length(); i = i + 1 {
    mem_store8(ptr + 12 + i, title_bytes[i].to_int())
  }
  ptr
}

///|
pub fn kagura_update_export(ptr : Int, len : Int) -> Unit {
  let input = read_input(ptr)
  game.update(input)
  ignore(len)
}

///|
pub fn kagura_draw() -> Int {
  bump_reset()
  let cmds = game.draw()
  write_draw_commands(cmds)
}

///|
pub fn kagura_alloc(size : Int) -> Int {
  bump_alloc(size)
}

///|
fn main {
  // WASM entry point - no-op, game is driven by exports
  ()
}
