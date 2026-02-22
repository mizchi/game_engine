let screen_w : Int = 320

let screen_h : Int = 240

let player_speed : Double = 2.0

let player_size : Double = 16.0

struct Game {
  score : @signals.Signal[Int]
  player_x : @signals.Signal[Double]
  player_y : @signals.Signal[Double]
  frame : @signals.Signal[Int]
  input : @inpututil.InputHelper
}

fn Game::new() -> Game {
  {
    score: @signals.signal(0),
    player_x: @signals.signal(160.0 - player_size / 2.0),
    player_y: @signals.signal(120.0 - player_size / 2.0),
    frame: @signals.signal(0),
    input: @inpututil.new_input_helper(),
  }
}

fn Game::update(self : Game, input : @core.InputSnapshot) -> Unit {
  @inpututil.update_input_helper(self.input, input)
  @signals.batch(fn() {
    self.frame.set(self.frame.get() + 1)
    let mut dx = 0.0
    let mut dy = 0.0
    if @inpututil.is_move_up(self.input.key_state) {
      dy = dy - player_speed
    }
    if @inpututil.is_move_down(self.input.key_state) {
      dy = dy + player_speed
    }
    if @inpututil.is_move_left(self.input.key_state) {
      dx = dx - player_speed
    }
    if @inpututil.is_move_right(self.input.key_state) {
      dx = dx + player_speed
    }
    if dx != 0.0 || dy != 0.0 {
      let nx = self.player_x.get() + dx
      let ny = self.player_y.get() + dy
      let sw = screen_w.to_double()
      let sh = screen_h.to_double()
      self.player_x.set(
        if nx < 0.0 {
          0.0
        } else if nx > sw - player_size {
          sw - player_size
        } else {
          nx
        },
      )
      self.player_y.set(
        if ny < 0.0 {
          0.0
        } else if ny > sh - player_size {
          sh - player_size
        } else {
          ny
        },
      )
    }
    if @inpututil.is_confirm_just_pressed(self.input) {
      self.score.set(self.score.get() + 10)
    }
  })
}

fn Game::view(self : Game) -> @scene.SceneNode {
  let pulse = if self.frame.get() % 60 < 30 { 1.0 } else { 0.7 }
  @scene.fragment(
    [
      // Background
      @scene.rect(
        w=screen_w.to_double(),
        h=screen_h.to_double(),
        fill=0x1a1a2e,
      ),
      // Border
      @scene.rect_outline(
        x=1.0,
        y=1.0,
        w=screen_w.to_double() - 2.0,
        h=screen_h.to_double() - 2.0,
        color=0x444466,
      ),
      // Grid lines
      @scene.for_each(fn() {
        let lines : Array[@scene.SceneNode] = []
        let mut gx = 40.0
        while gx < screen_w.to_double() {
          lines.push(
            @scene.line(
              x0=gx,
              y0=0.0,
              x1=gx,
              y1=screen_h.to_double(),
              color=0x222244,
            ),
          )
          gx = gx + 40.0
        }
        let mut gy = 40.0
        while gy < screen_h.to_double() {
          lines.push(
            @scene.line(
              x0=0.0,
              y0=gy,
              x1=screen_w.to_double(),
              y1=gy,
              color=0x222244,
            ),
          )
          gy = gy + 40.0
        }
        lines
      }),
      // Player
      @scene.rect(
        x=self.player_x.get(),
        y=self.player_y.get(),
        w=player_size,
        h=player_size,
        fill=0x00FF88,
        alpha=pulse,
      ),
      // Player outline
      @scene.rect_outline(
        x=self.player_x.get() - 1.0,
        y=self.player_y.get() - 1.0,
        w=player_size + 2.0,
        h=player_size + 2.0,
        color=0x00FFAA,
      ),
      // Score label
      @scene.label(
        x=screen_w.to_double() / 2.0,
        y=12.0,
        content="SCORE:" + self.score.get().to_string(),
        color=0xFFFF00,
      ),
      // Instructions
      @scene.label(
        x=screen_w.to_double() / 2.0,
        y=screen_h.to_double() - 12.0,
        content="WASD:MOVE SPACE:+10",
        color=0x888888,
      ),
      // Win message
      @scene.show(fn() { self.score.get() >= 100 }, fn() {
        @scene.fragment(
          [
            @scene.rect(
              x=80.0,
              y=90.0,
              w=160.0,
              h=60.0,
              fill=0x000000,
              alpha=0.8,
            ),
            @scene.label(
              x=screen_w.to_double() / 2.0,
              y=120.0,
              content="YOU WIN",
              color=0xFFFF00,
              scale=3.0,
            ),
          ],
        )
      }),
    ],
  )
}
