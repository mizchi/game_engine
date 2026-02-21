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
  key_state : @inpututil.KeyInputState
  mouse_state : @inpututil.MouseButtonInputState
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
    key_state: @inpututil.new_key_input_state(),
    mouse_state: @inpututil.new_mouse_input_state(),
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
fn FlappyState::action_pressed(self : FlappyState, input : @core.InputSnapshot) -> Bool {
  // Accept any key just pressed (not only Space)
  self.key_state.just_pressed_keys.length() > 0 ||
    self.mouse_state.just_pressed_buttons.length() > 0 ||
    input.touches.length() > 0
}

///|
fn FlappyState::update(self : FlappyState, input : @core.InputSnapshot) -> Unit {
  @inpututil.update_key_input_state(self.key_state, input)
  @inpututil.update_mouse_input_state(self.mouse_state, input)
  self.frame_count = self.frame_count + 1
  let action = self.action_pressed(input)
  match self.game_mode {
    0 => {
      // Title screen
      if action {
        self.game_mode = 1
        self.velocity = self.jump_velocity
      }
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
        let gap_y = min_gap_y + pseudo_random(self.frame_count) * (max_gap_y - min_gap_y)
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
    _ => {
      // Game over
      if action {
        self.reset()
      }
    }
  }
}

// --- NDC rect drawing ---
// The WebGPU vertex shader passes pos directly as clip-space coordinates.
// We must convert pixel coordinates to NDC: x in [-1,1], y in [1,-1] (y-down).

///|
fn ndc_rect(
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  px : Double,
  py : Double,
  pw : Double,
  ph : Double,
  sw : Double,
  sh : Double,
  color : @gfx.Color,
) -> @gfx.DrawTrianglesCommand {
  let x0 = px / sw * 2.0 - 1.0
  let y0 = 1.0 - py / sh * 2.0
  let x1 = (px + pw) / sw * 2.0 - 1.0
  let y1 = 1.0 - (py + ph) / sh * 2.0
  let vertices = [x0, y0, 0.0, 0.0, x1, y0, 1.0, 0.0, x1, y1, 1.0, 1.0, x0, y1, 0.0, 1.0]
  let indices = [0, 1, 2, 2, 3, 0]
  let r_int = (color.r * 255.0).to_int()
  let g_int = (color.g * 255.0).to_int()
  let b_int = (color.b * 255.0).to_int()
  let a_int = (color.a * 255.0).to_int()
  @gfx.new_draw_triangles_command(
    dst,
    shader,
    [@gfx.new_dst_region(0, 0, sw.to_int(), sh.to_int(), 6)],
    0,
    0,
    0,
    @gfx.blend_mode_from_int(1),
    vertices,
    indices,
    [],
    [r_int, g_int, b_int, a_int],
  )
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
  cmds.push(ndc_rect(dst, shader, 0.0, 0.0, sw, sh, sw, sh, sky_color))
  // Ground
  let ground_y = sh - self.ground_h
  cmds.push(
    ndc_rect(dst, shader, 0.0, ground_y, sw, self.ground_h, sw, sh, ground_color),
  )
  // Pipes
  for pipe in self.pipes {
    // Upper pipe
    if pipe.gap_y > 0.0 {
      cmds.push(
        ndc_rect(
          dst, shader, pipe.x, 0.0, self.pipe_width, pipe.gap_y, sw, sh, pipe_color,
        ),
      )
    }
    // Lower pipe
    let lower_y = pipe.gap_y + self.pipe_gap
    let lower_h = ground_y - lower_y
    if lower_h > 0.0 {
      cmds.push(
        ndc_rect(
          dst, shader, pipe.x, lower_y, self.pipe_width, lower_h, sw, sh, pipe_color,
        ),
      )
    }
  }
  // Bird
  cmds.push(
    ndc_rect(
      dst,
      shader,
      self.bird_x,
      self.bird_y,
      self.bird_size,
      self.bird_size,
      sw,
      sh,
      bird_color,
    ),
  )
  // Score display
  draw_score_digits(cmds, dst, shader, self.score, sw / 2.0 - 10.0, 20.0, sw, sh, white)
  // Title / Game Over overlay
  if self.game_mode == 0 {
    // "TAP" text, blinking
    if self.frame_count / 30 % 2 == 0 {
      let text_color = @debugutil.color_from_hex_alpha(0xFFFFFF, 0.8)
      // T=84, A=65, P=80
      draw_dot_text(
        cmds, dst, shader, [84, 65, 80], sw / 2.0, sh / 2.0 + 30.0, sw, sh, text_color, 2.0,
      )
    }
  } else if self.game_mode == 2 {
    // Dark overlay background
    let overlay_color = @debugutil.color_from_hex_alpha(0x000000, 0.5)
    cmds.push(
      ndc_rect(
        dst, shader, sw / 2.0 - 50.0, sh / 2.0 - 20.0, 100.0, 40.0, sw, sh, overlay_color,
      ),
    )
    // "END" text
    let text_color = @debugutil.color_from_hex_alpha(0xFFFFFF, 0.9)
    // E=69, N=78, D=68
    draw_dot_text(
      cmds, dst, shader, [69, 78, 68], sw / 2.0, sh / 2.0, sw, sh, text_color, 2.0,
    )
  }
  cmds
}

// Dot-matrix glyph rendering (3x5 grid)

///|
fn glyph_pattern(ch : Int) -> Array[Int] {
  match ch {
    // Digits 0-9
    0 => [1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1]
    1 => [0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1]
    2 => [1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1]
    3 => [1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1]
    4 => [1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 1]
    5 => [1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1]
    6 => [1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1]
    7 => [1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1]
    8 => [1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1]
    9 => [1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1]
    // Letters (ASCII codes)
    // A
    65 => [0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1]
    // D
    68 => [1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0]
    // E
    69 => [1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1]
    // N
    78 => [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1]
    // P
    80 => [1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0]
    // T
    84 => [1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0]
    _ => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  }
}

///|
fn digit_pattern(d : Int) -> Array[Int] {
  glyph_pattern(d)
}

///|
fn draw_single_digit(
  cmds : Array[@gfx.DrawTrianglesCommand],
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  digit : Int,
  ox : Double,
  oy : Double,
  sw : Double,
  sh : Double,
  color : @gfx.Color,
) -> Unit {
  let pattern = digit_pattern(digit)
  let px_size = 3.0
  for row = 0; row < 5; row = row + 1 {
    for col = 0; col < 3; col = col + 1 {
      if pattern[row * 3 + col] == 1 {
        let x = ox + col.to_double() * px_size
        let y = oy + row.to_double() * px_size
        cmds.push(ndc_rect(dst, shader, x, y, px_size, px_size, sw, sh, color))
      }
    }
  }
}

///|
fn draw_dot_text(
  cmds : Array[@gfx.DrawTrianglesCommand],
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  chars : Array[Int],
  cx : Double,
  cy : Double,
  sw : Double,
  sh : Double,
  color : @gfx.Color,
  scale : Double,
) -> Unit {
  let px_size = 3.0 * scale
  let char_w = 3.0 * px_size
  let gap = px_size
  let total_w = chars.length().to_double() * char_w +
    (chars.length() - 1).to_double() * gap
  let char_h = 5.0 * px_size
  let start_x = cx - total_w / 2.0
  let start_y = cy - char_h / 2.0
  for i = 0; i < chars.length(); i = i + 1 {
    let pattern = glyph_pattern(chars[i])
    let ox = start_x + i.to_double() * (char_w + gap)
    for row = 0; row < 5; row = row + 1 {
      for col = 0; col < 3; col = col + 1 {
        if pattern[row * 3 + col] == 1 {
          let x = ox + col.to_double() * px_size
          let y = start_y + row.to_double() * px_size
          cmds.push(ndc_rect(dst, shader, x, y, px_size, px_size, sw, sh, color))
        }
      }
    }
  }
}

///|
fn draw_score_digits(
  cmds : Array[@gfx.DrawTrianglesCommand],
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  score : Int,
  ox : Double,
  oy : Double,
  sw : Double,
  sh : Double,
  color : @gfx.Color,
) -> Unit {
  if score == 0 {
    draw_single_digit(cmds, dst, shader, 0, ox, oy, sw, sh, color)
    return
  }
  let digits : Array[Int] = []
  let mut n = score
  while n > 0 {
    digits.push(n % 10)
    n = n / 10
  }
  let len = digits.length()
  let digit_width = 12.0
  let total_width = len.to_double() * digit_width
  let start_x = ox - total_width / 2.0 + digit_width / 2.0
  for i = 0; i < len; i = i + 1 {
    let d = digits[len - 1 - i]
    draw_single_digit(
      cmds, dst, shader, d, start_x + i.to_double() * digit_width, oy, sw, sh, color,
    )
  }
}
