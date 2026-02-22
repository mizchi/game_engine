///|
struct Pipe {
  mut x : Double
  gap_y : Double
}

///|
struct FlappyState {
  mut bird_y : Double
  mut velocity : Double
  mut game_mode : Int // 0=title, 1=playing, 2=gameover
  mut score : Int
  mut frame_count : Int
  mut pipes : Array[Pipe]
  mut pipe_timer : Int
  input : @inpututil.InputHelper
  // constants
  screen_w : Double
  screen_h : Double
  bird_x : Double
  bird_size : Double
  gravity : Double
  jump_velocity : Double
  pipe_width : Double
  pipe_gap : Double
  pipe_speed : Double
  pipe_interval : Int
  ground_h : Double
}

///|
fn FlappyState::new() -> FlappyState {
  let screen_w = 320.0
  let screen_h = 240.0
  {
    bird_y: screen_h / 2.0,
    velocity: 0.0,
    game_mode: 0, // title screen
    score: 0,
    frame_count: 0,
    pipes: [],
    pipe_timer: 0,
    input: @inpututil.new_input_helper(),
    screen_w,
    screen_h,
    bird_x: 60.0,
    bird_size: 12.0,
    gravity: 0.25,
    jump_velocity: -4.5,
    pipe_width: 36.0,
    pipe_gap: 70.0,
    pipe_speed: 1.5,
    pipe_interval: 120,
    ground_h: 20.0,
  }
}

///|
fn pseudo_random(seed : Int) -> Double {
  let x = seed * 1103515245 + 12345
  let normalized = ((x >> 16) & 0x7FFF).to_double() / 32767.0
  normalized
}

///|
fn FlappyState::reset(self : FlappyState) -> Unit {
  self.bird_y = self.screen_h / 2.0
  self.velocity = 0.0
  self.game_mode = 0
  self.score = 0
  self.pipes = []
  self.pipe_timer = 0
}

///|
fn FlappyState::update(self : FlappyState, input : @core.InputSnapshot) -> Unit {
  @inpututil.update_input_helper(self.input, input)
  self.frame_count = self.frame_count + 1
  let action = @inpututil.is_any_action_just_pressed(self.input, input)
  match self.game_mode {
    0 =>
      // Title screen
      if action {
        self.game_mode = 1
        self.velocity = self.jump_velocity
      }
    1 => {
      // Playing
      self.velocity = self.velocity + self.gravity
      self.bird_y = self.bird_y + self.velocity
      if action {
        self.velocity = self.jump_velocity
      }
      // Pipe generation
      self.pipe_timer = self.pipe_timer + 1
      if self.pipe_timer >= self.pipe_interval {
        self.pipe_timer = 0
        let min_gap_y = 40.0
        let max_gap_y = self.screen_h - self.ground_h - self.pipe_gap - 40.0
        let gap_y = min_gap_y +
          pseudo_random(self.frame_count) * (max_gap_y - min_gap_y)
        self.pipes.push({ x: self.screen_w, gap_y })
      }
      // Move pipes and check scoring
      let mut i = 0
      while i < self.pipes.length() {
        let pipe = self.pipes[i]
        let old_x = pipe.x
        pipe.x = pipe.x - self.pipe_speed
        // Score: bird passes pipe right edge
        let pipe_right = old_x + self.pipe_width
        let pipe_right_new = pipe.x + self.pipe_width
        if pipe_right >= self.bird_x && pipe_right_new < self.bird_x {
          self.score = self.score + 1
        }
        i = i + 1
      }
      // Remove off-screen pipes
      let new_pipes : Array[Pipe] = []
      for pipe in self.pipes {
        if pipe.x + self.pipe_width > 0.0 {
          new_pipes.push(pipe)
        }
      }
      self.pipes = new_pipes
      // Collision detection
      let ground_top = self.screen_h - self.ground_h
      if self.bird_y + self.bird_size > ground_top || self.bird_y < 0.0 {
        self.game_mode = 2
      }
      // Pipe collision
      for pipe in self.pipes {
        let bird_right = self.bird_x + self.bird_size
        let bird_bottom = self.bird_y + self.bird_size
        let pipe_right = pipe.x + self.pipe_width
        // Check horizontal overlap
        if bird_right > pipe.x && self.bird_x < pipe_right {
          // Check if bird is outside the gap
          let gap_bottom = pipe.gap_y + self.pipe_gap
          if self.bird_y < pipe.gap_y || bird_bottom > gap_bottom {
            self.game_mode = 2
          }
        }
      }
    }
    _ =>
      // Game over
      if action {
        self.reset()
      }
  }
}

///|
fn FlappyState::build_draw_commands(
  self : FlappyState,
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
) -> Array[@gfx.DrawTrianglesCommand] {
  let cmds : Array[@gfx.DrawTrianglesCommand] = []
  let sw = self.screen_w
  let sh = self.screen_h
  let sky_color = @debugutil.color_from_hex(0x87CEEB)
  let ground_color = @debugutil.color_from_hex(0x8B4513)
  let pipe_color = @debugutil.color_from_hex(0x228B22)
  let bird_color = @debugutil.color_from_hex(0xFFD700)
  let white = @debugutil.color_white()
  // Sky background
  cmds.push(
    @debugutil.new_ndc_rect_fill_command(
      dst, shader, 0.0, 0.0, sw, sh, sw, sh, sky_color, 0,
    ),
  )
  // Ground
  let ground_y = sh - self.ground_h
  cmds.push(
    @debugutil.new_ndc_rect_fill_command(
      dst,
      shader,
      0.0,
      ground_y,
      sw,
      self.ground_h,
      sw,
      sh,
      ground_color,
      0,
    ),
  )
  // Pipes
  for pipe in self.pipes {
    // Upper pipe
    if pipe.gap_y > 0.0 {
      cmds.push(
        @debugutil.new_ndc_rect_fill_command(
          dst,
          shader,
          pipe.x,
          0.0,
          self.pipe_width,
          pipe.gap_y,
          sw,
          sh,
          pipe_color,
          0,
        ),
      )
    }
    // Lower pipe
    let lower_y = pipe.gap_y + self.pipe_gap
    let lower_h = ground_y - lower_y
    if lower_h > 0.0 {
      cmds.push(
        @debugutil.new_ndc_rect_fill_command(
          dst,
          shader,
          pipe.x,
          lower_y,
          self.pipe_width,
          lower_h,
          sw,
          sh,
          pipe_color,
          0,
        ),
      )
    }
  }
  // Bird
  cmds.push(
    @debugutil.new_ndc_rect_fill_command(
      dst,
      shader,
      self.bird_x,
      self.bird_y,
      self.bird_size,
      self.bird_size,
      sw,
      sh,
      bird_color,
      0,
    ),
  )
  // Score display
  @debugutil.draw_number(
    cmds,
    dst,
    shader,
    self.score,
    sw / 2.0 - 10.0,
    20.0,
    sw,
    sh,
    white,
    1.0,
  )
  // Title / Game Over overlay
  if self.game_mode == 0 {
    // "TAP" text, blinking
    if self.frame_count / 30 % 2 == 0 {
      let text_color = @debugutil.color_from_hex_alpha(0xFFFFFF, 0.8)
      // T=84, A=65, P=80
      @debugutil.draw_dot_text(
        cmds,
        dst,
        shader,
        [84, 65, 80],
        sw / 2.0,
        sh / 2.0 + 30.0,
        sw,
        sh,
        text_color,
        2.0,
      )
    }
  } else if self.game_mode == 2 {
    // Dark overlay background
    let overlay_color = @debugutil.color_from_hex_alpha(0x000000, 0.5)
    cmds.push(
      @debugutil.new_ndc_rect_fill_command(
        dst,
        shader,
        sw / 2.0 - 50.0,
        sh / 2.0 - 20.0,
        100.0,
        40.0,
        sw,
        sh,
        overlay_color,
        0,
      ),
    )
    // "END" text
    let text_color = @debugutil.color_from_hex_alpha(0xFFFFFF, 0.9)
    // E=69, N=78, D=68
    @debugutil.draw_dot_text(
      cmds,
      dst,
      shader,
      [69, 78, 68],
      sw / 2.0,
      sh / 2.0,
      sw,
      sh,
      text_color,
      2.0,
    )
  }
  cmds
}
