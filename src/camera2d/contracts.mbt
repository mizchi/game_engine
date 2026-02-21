///|
pub struct Camera2D {
  mut x : Double
  mut y : Double
  screen_w : Double
  screen_h : Double
  world_w : Double
  world_h : Double
}

///|
pub fn Camera2D::new(
  screen_w : Double,
  screen_h : Double,
  world_w : Double,
  world_h : Double,
) -> Camera2D {
  { x: 0.0, y: 0.0, screen_w, screen_h, world_w, world_h }
}

///|
pub fn Camera2D::world_to_screen_x(self : Camera2D, wx : Double) -> Double {
  wx - self.x
}

///|
pub fn Camera2D::world_to_screen_y(self : Camera2D, wy : Double) -> Double {
  wy - self.y
}

///|
pub fn Camera2D::follow_target(
  self : Camera2D,
  target_x : Double,
  target_y : Double,
) -> Unit {
  self.x = target_x - self.screen_w / 2.0
  self.y = target_y - self.screen_h / 2.0
  // Clamp to world bounds
  self.x = @cmp.maximum(0.0, @cmp.minimum(self.world_w - self.screen_w, self.x))
  self.y = @cmp.maximum(0.0, @cmp.minimum(self.world_h - self.screen_h, self.y))
}
