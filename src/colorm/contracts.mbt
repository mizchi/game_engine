///|
/// Color matrix transformations.
///
/// A ColorM is a 5x4 matrix that transforms RGBA color values.
/// The matrix layout follows Ebiten convention:
///   [r']   [m00 m01 m02 m03 m04] [r]
///   [g'] = [m10 m11 m12 m13 m14] [g]
///   [b']   [m20 m21 m22 m23 m24] [b]
///   [a']   [m30 m31 m32 m33 m34] [a]
///                                [1]
/// Stored as a flat array of 20 elements (row-major, 4 rows x 5 columns).
///
/// Reference:
/// - Ebiten colorm package

///|
pub struct ColorM {
  elements : FixedArray[Double]
} derive(Show)

///|
pub fn ColorM::identity() -> ColorM {
  {
    elements: [
      1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 0.0, 1.0, 0.0,
    ],
  }
}

///|
fn element_at(self : ColorM, row : Int, col : Int) -> Double {
  self.elements[row * 5 + col]
}

///|
fn set_element(self : ColorM, row : Int, col : Int, value : Double) -> Unit {
  self.elements[row * 5 + col] = value
}

///|
pub fn ColorM::is_identity(self : ColorM) -> Bool {
  for row in 0..<4 {
    for col in 0..<5 {
      let expected = if row == col { 1.0 } else { 0.0 }
      if self.element_at(row, col) != expected {
        return false
      }
    }
  }
  true
}

///|
/// Concatenate two color matrices (self * other).
pub fn ColorM::concat(self : ColorM, other : ColorM) -> ColorM {
  let result = ColorM::identity()
  for row in 0..<4 {
    for col in 0..<5 {
      let mut sum = 0.0
      for k in 0..<4 {
        sum = sum + self.element_at(row, k) * other.element_at(k, col)
      }
      if col == 4 {
        sum = sum + self.element_at(row, 4)
      }
      result.set_element(row, col, sum)
    }
  }
  result
}

///|
/// Scale RGBA channels.
pub fn ColorM::scale(
  self : ColorM,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> ColorM {
  let s = ColorM::identity()
  s.set_element(0, 0, r)
  s.set_element(1, 1, g)
  s.set_element(2, 2, b)
  s.set_element(3, 3, a)
  s.concat(self)
}

///|
/// Translate (offset) RGBA channels.
pub fn ColorM::translate(
  self : ColorM,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> ColorM {
  let t = ColorM::identity()
  t.set_element(0, 4, r)
  t.set_element(1, 4, g)
  t.set_element(2, 4, b)
  t.set_element(3, 4, a)
  t.concat(self)
}

///|
/// Rotate hue by angle in radians.
pub fn ColorM::rotate_hue(self : ColorM, theta : Double) -> ColorM {
  // Rotation in the (R-G, B) plane via Rodrigues-style decomposition.
  // Standard approach: decompose into luminance axis rotation.
  let sin = @math.sin(theta)
  let cos = @math.cos(theta)
  let m = ColorM::identity()
  // Matrix that rotates hue while preserving luminance.
  // Based on the NTSC luminance coefficients: R=0.213, G=0.715, B=0.072
  let lr = 0.213
  let lg = 0.715
  let lb = 0.072
  m.set_element(0, 0, lr + cos * (1.0 - lr) + sin * (-lr))
  m.set_element(0, 1, lg + cos * (-lg) + sin * (-lg))
  m.set_element(0, 2, lb + cos * (-lb) + sin * (1.0 - lb))
  m.set_element(1, 0, lr + cos * (-lr) + sin * 0.143)
  m.set_element(1, 1, lg + cos * (1.0 - lg) + sin * 0.140)
  m.set_element(1, 2, lb + cos * (-lb) + sin * (-0.283))
  m.set_element(2, 0, lr + cos * (-lr) + sin * (-(1.0 - lr)))
  m.set_element(2, 1, lg + cos * (-lg) + sin * lg)
  m.set_element(2, 2, lb + cos * (1.0 - lb) + sin * lb)
  m.concat(self)
}

///|
/// Convert to monochrome (grayscale) using NTSC luminance coefficients.
pub fn ColorM::monochrome(self : ColorM) -> ColorM {
  let lr = 0.2126
  let lg = 0.7152
  let lb = 0.0722
  let m = ColorM::identity()
  m.set_element(0, 0, lr)
  m.set_element(0, 1, lg)
  m.set_element(0, 2, lb)
  m.set_element(1, 0, lr)
  m.set_element(1, 1, lg)
  m.set_element(1, 2, lb)
  m.set_element(2, 0, lr)
  m.set_element(2, 1, lg)
  m.set_element(2, 2, lb)
  m.concat(self)
}

///|
/// Invert colors.
pub fn ColorM::invert(self : ColorM) -> ColorM {
  self.scale(-1.0, -1.0, -1.0, 1.0).translate(1.0, 1.0, 1.0, 0.0)
}

///|
/// Apply color matrix to an RGBA color (all values 0.0-1.0).
pub fn ColorM::apply(
  self : ColorM,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> (Double, Double, Double, Double) {
  let nr = self.element_at(0, 0) * r +
    self.element_at(0, 1) * g +
    self.element_at(0, 2) * b +
    self.element_at(0, 3) * a +
    self.element_at(0, 4)
  let ng = self.element_at(1, 0) * r +
    self.element_at(1, 1) * g +
    self.element_at(1, 2) * b +
    self.element_at(1, 3) * a +
    self.element_at(1, 4)
  let nb = self.element_at(2, 0) * r +
    self.element_at(2, 1) * g +
    self.element_at(2, 2) * b +
    self.element_at(2, 3) * a +
    self.element_at(2, 4)
  let na = self.element_at(3, 0) * r +
    self.element_at(3, 1) * g +
    self.element_at(3, 2) * b +
    self.element_at(3, 3) * a +
    self.element_at(3, 4)
  (nr, ng, nb, na)
}

///|
/// Apply color matrix to a gfx.Color.
pub fn ColorM::apply_color(self : ColorM, color : @gfx.Color) -> @gfx.Color {
  let (r, g, b, a) = self.apply(color.r, color.g, color.b, color.a)
  @gfx.new_color(r, g, b, a)
}

///|
fn clamp01(v : Double) -> Double {
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }
}

///|
/// Apply color matrix and clamp result to [0, 1].
pub fn ColorM::apply_clamped(
  self : ColorM,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> (Double, Double, Double, Double) {
  let (nr, ng, nb, na) = self.apply(r, g, b, a)
  (clamp01(nr), clamp01(ng), clamp01(nb), clamp01(na))
}

///|
/// Change HSV: scale_hue rotates hue (radians), scale_saturation and scale_value
/// scale saturation and value.
pub fn ColorM::change_hsv(
  self : ColorM,
  scale_hue : Double,
  scale_saturation : Double,
  scale_value : Double,
) -> ColorM {
  self
  .rotate_hue(scale_hue)
  .scale(scale_value, scale_value, scale_value, 1.0)
  .scale(
    1.0 + (1.0 - scale_saturation) * (-1.0 + 0.213 / 1.0),
    1.0 + (1.0 - scale_saturation) * (-1.0 + 0.715 / 1.0),
    1.0 + (1.0 - scale_saturation) * (-1.0 + 0.072 / 1.0),
    1.0,
  )
}
