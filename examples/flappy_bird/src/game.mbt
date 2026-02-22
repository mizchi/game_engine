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

///|
struct Game {
  game_mode : @signals.Signal[Int]
  score : @signals.Signal[Int]
  bird_y : @signals.Signal[Double]
  frame_count : @signals.Signal[Int]
  pipes : @signals.Signal[Array[Pipe]]
  mut velocity : Double
  mut pipe_timer : Int
  input : @inpututil.InputHelper
}

///|
fn pseudo_random(seed : Int) -> Double {
  let x = seed * 1103515245 + 12345
  let normalized = ((x >> 16) & 0x7FFF).to_double() / 32767.0
  normalized
}

///|
fn Game::new() -> Game {
  {
    game_mode: @signals.signal(0),
    score: @signals.signal(0),
    bird_y: @signals.signal(screen_h.to_double() / 2.0),
    frame_count: @signals.signal(0),
    pipes: @signals.signal([]),
    velocity: 0.0,
    pipe_timer: 0,
    input: @inpututil.new_input_helper(),
  }
}

///|
fn Game::reset(self : Game) -> Unit {
  self.bird_y.set(screen_h.to_double() / 2.0)
  self.velocity = 0.0
  self.game_mode.set(0)
  self.score.set(0)
  self.pipes.set([])
  self.pipe_timer = 0
}

///|
fn Game::update(self : Game, input : @core.InputSnapshot) -> Unit {
  @inpututil.update_input_helper(self.input, input)
  @signals.batch(fn() {
    self.frame_count.set(self.frame_count.get() + 1)
    let action = @inpututil.is_any_action_just_pressed(self.input, input)
    match self.game_mode.get() {
      0 => {
        if action {
          self.game_mode.set(1)
          self.velocity = jump_velocity
        }
      }
      1 => {
        // Physics
        self.velocity = self.velocity + gravity
        self.bird_y.set(self.bird_y.get() + self.velocity)
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
            pseudo_random(self.frame_count.get()) * (max_gap_y - min_gap_y)
          let current_pipes = self.pipes.get()
          current_pipes.push({ x: sw, gap_y })
          self.pipes.set(current_pipes)
        }
        // Move pipes and check scoring
        let pipes = self.pipes.get()
        let mut i = 0
        while i < pipes.length() {
          let pipe = pipes[i]
          let old_x = pipe.x
          pipe.x = pipe.x - pipe_speed
          let pipe_right = old_x + pipe_width
          let pipe_right_new = pipe.x + pipe_width
          if pipe_right >= bird_x && pipe_right_new < bird_x {
            self.score.set(self.score.get() + 1)
          }
          i = i + 1
        }
        // Remove off-screen pipes
        let new_pipes : Array[Pipe] = []
        for pipe in pipes {
          if pipe.x + pipe_width > 0.0 {
            new_pipes.push(pipe)
          }
        }
        self.pipes.set(new_pipes)
        // Collision: ground/ceiling
        let ground_top = screen_h.to_double() - ground_h
        if self.bird_y.get() + bird_size > ground_top || self.bird_y.get() < 0.0 {
          self.game_mode.set(2)
        }
        // Collision: pipes
        for pipe in self.pipes.get() {
          let bird_right = bird_x + bird_size
          let bird_bottom = self.bird_y.get() + bird_size
          let pipe_right = pipe.x + pipe_width
          if bird_right > pipe.x && bird_x < pipe_right {
            let gap_bottom = pipe.gap_y + pipe_gap
            if self.bird_y.get() < pipe.gap_y || bird_bottom > gap_bottom {
              self.game_mode.set(2)
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
  })
}

///|
fn Game::view(self : Game) -> @scene.SceneNode {
  let sw = screen_w.to_double()
  let sh = screen_h.to_double()
  let ground_y = sh - ground_h
  @scene.fragment(
    [
      // Sky
      @scene.rect(w=sw, h=sh, fill=0x87CEEB),
      // Ground
      @scene.rect(x=0.0, y=ground_y, w=sw, h=ground_h, fill=0x8B4513),
      // Pipes
      @scene.for_each(fn() {
        let nodes : Array[@scene.SceneNode] = []
        for pipe in self.pipes.get() {
          if pipe.gap_y > 0.0 {
            nodes.push(
              @scene.rect(x=pipe.x, w=pipe_width, h=pipe.gap_y, fill=0x228B22),
            )
          }
          let lower_y = pipe.gap_y + pipe_gap
          let lower_h = ground_y - lower_y
          if lower_h > 0.0 {
            nodes.push(
              @scene.rect(
                x=pipe.x,
                y=lower_y,
                w=pipe_width,
                h=lower_h,
                fill=0x228B22,
              ),
            )
          }
        }
        nodes
      }),
      // Bird
      @scene.rect(
        x=bird_x,
        y=self.bird_y.get(),
        w=bird_size,
        h=bird_size,
        fill=0xFFD700,
      ),
      // Score
      @scene.label(
        x=sw / 2.0 - 10.0,
        y=20.0,
        content=self.score.get().to_string(),
      ),
      // Title "TAP" (blinking)
      @scene.show(
        fn() {
          self.game_mode.get() == 0 && self.frame_count.get() / 30 % 2 == 0
        },
        fn() {
          @scene.label(x=sw / 2.0, y=sh / 2.0 + 30.0, content="TAP", scale=2.0)
        },
      ),
      // Game over overlay
      @scene.show(fn() { self.game_mode.get() == 2 }, fn() {
        @scene.fragment(
          [
            @scene.rect(
              x=sw / 2.0 - 50.0,
              y=sh / 2.0 - 20.0,
              w=100.0,
              h=40.0,
              fill=0x000000,
              alpha=0.5,
            ),
            @scene.label(
              x=sw / 2.0,
              y=sh / 2.0,
              content="END",
              scale=2.0,
            ),
          ],
        )
      }),
    ],
  )
}
