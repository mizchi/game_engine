///|
/// Core gameplay contracts only.
/// Ebiten refs:
/// - run.go (Game, Layout, Draw, Update)
/// - gameforui.go (final screen customization)

///|
pub enum EngineTermination {
  RegularTermination
  Fatal(String)
} derive(Show)

///|
pub struct OutsideSize {
  width : Double
  height : Double
} derive(Show)

///|
pub struct LogicalSize {
  width : Int
  height : Int
} derive(Show)

///|
pub struct FrameBudget {
  updates : Int
  alpha : Double
  tick : Int
} derive(Show)

///|
pub struct InputSnapshot {
  cursor_x : Double
  cursor_y : Double
  wheel_x : Double
  wheel_y : Double
  pressed_keys : Array[Int]
  pressed_mouse_buttons : Array[Int]
  touches : Array[TouchPoint]
  gamepads : Array[GamepadSnapshot]
} derive(Show)

///|
pub enum TouchSource {
  Direct
  Indirect
  Mouse
  Unknown
} derive(Show)

///|
pub fn touch_source_to_int(source : TouchSource) -> Int {
  match source {
    TouchSource::Direct => 0
    TouchSource::Indirect => 1
    TouchSource::Mouse => 2
    TouchSource::Unknown => 3
  }
}

///|
pub fn touch_source_from_int(source : Int) -> TouchSource {
  match source {
    0 => TouchSource::Direct
    1 => TouchSource::Indirect
    2 => TouchSource::Mouse
    _ => TouchSource::Unknown
  }
}

///|
pub struct TouchPoint {
  id : Int
  x : Double
  y : Double
  source : TouchSource
} derive(Show)

///|
pub struct GamepadSnapshot {
  id : Int
  axes : Array[Double]
  pressed_buttons : Array[Int]
} derive(Show)

///|
pub struct RunOptions {
  init_unfocused : Bool
  screen_transparent : Bool
  screen_cleared_every_frame : Bool
} derive(Show)

///|
pub fn new_outside_size(width : Double, height : Double) -> OutsideSize {
  { width, height }
}

///|
pub fn new_frame_budget(
  updates : Int,
  alpha : Double,
  tick : Int,
) -> FrameBudget {
  { updates, alpha, tick }
}

///|
pub fn new_touch_point(id : Int, x : Double, y : Double) -> TouchPoint {
  { id, x, y, source: TouchSource::Unknown }
}

///|
pub fn new_touch_point_with_source(
  id : Int,
  x : Double,
  y : Double,
  source : TouchSource,
) -> TouchPoint {
  { id, x, y, source }
}

///|
pub fn new_gamepad_snapshot(
  id : Int,
  axes : Array[Double],
  pressed_buttons : Array[Int],
) -> GamepadSnapshot {
  { id, axes, pressed_buttons }
}

///|
pub fn new_input_snapshot_full(
  cursor_x : Double,
  cursor_y : Double,
  wheel_x : Double,
  wheel_y : Double,
  pressed_keys : Array[Int],
  pressed_mouse_buttons : Array[Int],
  touches : Array[TouchPoint],
  gamepads : Array[GamepadSnapshot],
) -> InputSnapshot {
  {
    cursor_x,
    cursor_y,
    wheel_x,
    wheel_y,
    pressed_keys,
    pressed_mouse_buttons,
    touches,
    gamepads,
  }
}

///|
pub fn new_input_snapshot(
  cursor_x : Double,
  cursor_y : Double,
  wheel_x : Double,
  wheel_y : Double,
  pressed_keys : Array[Int],
) -> InputSnapshot {
  new_input_snapshot_full(
    cursor_x,
    cursor_y,
    wheel_x,
    wheel_y,
    pressed_keys,
    [],
    [],
    [],
  )
}

///|
pub fn empty_input_snapshot() -> InputSnapshot {
  new_input_snapshot(0.0, 0.0, 0.0, 0.0, [])
}

///|
pub enum TouchPhase {
  Began
  Moved
  Stationary
  Ended
  Cancelled
} derive(Show)

///|
pub fn touch_phase_to_int(phase : TouchPhase) -> Int {
  match phase {
    TouchPhase::Began => 0
    TouchPhase::Moved => 1
    TouchPhase::Stationary => 2
    TouchPhase::Ended => 3
    TouchPhase::Cancelled => 4
  }
}

///|
pub fn touch_phase_from_int(phase : Int) -> TouchPhase {
  match phase {
    0 => TouchPhase::Began
    1 => TouchPhase::Moved
    2 => TouchPhase::Stationary
    3 => TouchPhase::Ended
    4 => TouchPhase::Cancelled
    _ => TouchPhase::Began
  }
}

///|
pub struct TouchPointEx {
  id : Int
  x : Double
  y : Double
  phase : TouchPhase
  pressure : Double
  delta_x : Double
  delta_y : Double
} derive(Show)

///|
pub fn new_touch_point_ex(
  id : Int,
  x : Double,
  y : Double,
  phase : TouchPhase,
) -> TouchPointEx {
  { id, x, y, phase, pressure: 1.0, delta_x: 0.0, delta_y: 0.0 }
}

///|
pub fn new_touch_point_ex_full(
  id : Int,
  x : Double,
  y : Double,
  phase : TouchPhase,
  pressure : Double,
  delta_x : Double,
  delta_y : Double,
) -> TouchPointEx {
  { id, x, y, phase, pressure, delta_x, delta_y }
}

///|
pub fn touch_point_from_ex(ex : TouchPointEx) -> TouchPoint {
  { id: ex.id, x: ex.x, y: ex.y, source: TouchSource::Unknown }
}

///|
pub trait Game {
  /// Ebiten ref: Game.Layout in run.go
  layout(Self, outside : OutsideSize) -> LogicalSize

  /// Ebiten ref: Game.Update in run.go
  update(Self, input : InputSnapshot) -> EngineTermination?

  /// Ebiten ref: Game.Draw in run.go
  draw(Self, frame : FrameBudget) -> Unit
}

///|
pub trait FinalScreenDrawer {
  /// Ebiten ref: FinalScreenDrawer.DrawFinalScreen in run.go/gameforui.go
  draw_final_screen(Self, frame : FrameBudget) -> Unit
}

///|
pub struct NoopGame {
  logical_width : Int
  logical_height : Int
}

///|
pub fn new_noop_game(width : Int, height : Int) -> NoopGame {
  { logical_width: width, logical_height: height }
}

///|
pub impl Game for NoopGame with layout(self, _outside) {
  { width: self.logical_width, height: self.logical_height }
}

///|
pub impl Game for NoopGame with update(_self, _input) {
  None
}

///|
pub impl Game for NoopGame with draw(_self, _frame) {
  ()
}

///|
pub fn default_run_options() -> RunOptions {
  {
    init_unfocused: false,
    screen_transparent: false,
    screen_cleared_every_frame: true,
  }
}

///|
pub fn[T : Game] run_game(game : T, options : RunOptions) -> Unit {
  let _ = options
  let outside = new_outside_size(640.0, 480.0)
  let logical = game.layout(outside)
  let _ = logical
  let _ = game.update(empty_input_snapshot())
  game.draw(new_frame_budget(0, 0.0, 0))
}
