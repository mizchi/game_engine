///|
/// 2D vector math utilities.
///
/// Reference:
/// - Ebiten vector package (path/shape drawing)
/// - General 2D game math (Vec2 operations)

///|
pub struct Vec2 {
  x : Double
  y : Double
} derive(Show)

///|
pub fn Vec2::new(x : Double, y : Double) -> Vec2 {
  { x, y }
}

///|
pub fn Vec2::zero() -> Vec2 {
  { x: 0.0, y: 0.0 }
}

///|
pub fn Vec2::one() -> Vec2 {
  { x: 1.0, y: 1.0 }
}

///|
pub fn Vec2::unit_x() -> Vec2 {
  { x: 1.0, y: 0.0 }
}

///|
pub fn Vec2::unit_y() -> Vec2 {
  { x: 0.0, y: 1.0 }
}

///|
pub fn Vec2::add(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x + other.x, y: self.y + other.y }
}

///|
pub fn Vec2::sub(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x - other.x, y: self.y - other.y }
}

///|
pub fn Vec2::scale(self : Vec2, s : Double) -> Vec2 {
  { x: self.x * s, y: self.y * s }
}

///|
pub fn Vec2::negate(self : Vec2) -> Vec2 {
  { x: -self.x, y: -self.y }
}

///|
pub fn Vec2::dot(self : Vec2, other : Vec2) -> Double {
  self.x * other.x + self.y * other.y
}

///|
/// 2D cross product (returns scalar z-component).
pub fn Vec2::cross(self : Vec2, other : Vec2) -> Double {
  self.x * other.y - self.y * other.x
}

///|
pub fn Vec2::length_squared(self : Vec2) -> Double {
  self.x * self.x + self.y * self.y
}

///|
pub fn Vec2::length(self : Vec2) -> Double {
  self.length_squared().sqrt()
}

///|
pub fn Vec2::normalize(self : Vec2) -> Vec2 {
  let len = self.length()
  if len < 1.0e-12 {
    Vec2::zero()
  } else {
    self.scale(1.0 / len)
  }
}

///|
pub fn Vec2::distance(self : Vec2, other : Vec2) -> Double {
  self.sub(other).length()
}

///|
pub fn Vec2::distance_squared(self : Vec2, other : Vec2) -> Double {
  self.sub(other).length_squared()
}

///|
pub fn Vec2::lerp(self : Vec2, other : Vec2, t : Double) -> Vec2 {
  { x: self.x + (other.x - self.x) * t, y: self.y + (other.y - self.y) * t }
}

///|
pub fn Vec2::perpendicular(self : Vec2) -> Vec2 {
  { x: -self.y, y: self.x }
}

///|
pub fn Vec2::rotate(self : Vec2, angle_rad : Double) -> Vec2 {
  let cos_a = @math.cos(angle_rad)
  let sin_a = @math.sin(angle_rad)
  { x: self.x * cos_a - self.y * sin_a, y: self.x * sin_a + self.y * cos_a }
}

///|
pub fn Vec2::angle(self : Vec2) -> Double {
  @math.atan2(self.y, self.x)
}

///|
pub fn Vec2::angle_between(self : Vec2, other : Vec2) -> Double {
  let cross = self.cross(other)
  let dot = self.dot(other)
  @math.atan2(cross, dot)
}

///|
pub fn Vec2::min(self : Vec2, other : Vec2) -> Vec2 {
  { x: @cmp.minimum(self.x, other.x), y: @cmp.minimum(self.y, other.y) }
}

///|
pub fn Vec2::max(self : Vec2, other : Vec2) -> Vec2 {
  { x: @cmp.maximum(self.x, other.x), y: @cmp.maximum(self.y, other.y) }
}

///|
pub fn Vec2::clamp(self : Vec2, min : Vec2, max : Vec2) -> Vec2 {
  self.max(min).min(max)
}

///|
pub fn Vec2::approx_eq(self : Vec2, other : Vec2, epsilon : Double) -> Bool {
  (self.x - other.x).abs() < epsilon && (self.y - other.y).abs() < epsilon
}

///|
/// Reflect vector around a normal.
pub fn Vec2::reflect(self : Vec2, normal : Vec2) -> Vec2 {
  self.sub(normal.scale(2.0 * self.dot(normal)))
}

///|
pub fn Vec2::mul(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x * other.x, y: self.y * other.y }
}

///|
pub fn Vec2::div(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x / other.x, y: self.y / other.y }
}

// ============================================================
// AABB collision detection
// ============================================================

///|
/// Check if two axis-aligned bounding boxes overlap (top-left + size form).
pub fn aabb_overlap(
  ax : Double,
  ay : Double,
  aw : Double,
  ah : Double,
  bx : Double,
  by : Double,
  bw : Double,
  bh : Double,
) -> Bool {
  ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by
}

///|
/// Check if two axis-aligned bounding boxes overlap (center + half-size form).
pub fn aabb_overlap_center(
  ax : Double,
  ay : Double,
  ahw : Double,
  ahh : Double,
  bx : Double,
  by : Double,
  bhw : Double,
  bhh : Double,
) -> Bool {
  (ax - bx).abs() < ahw + bhw && (ay - by).abs() < ahh + bhh
}
