///|
fn approx(a : Double, b : Double) -> Bool {
  (a - b).abs() < 1.0e-6
}

///|
test "ColorM identity" {
  let m = ColorM::identity()
  assert_true!(m.is_identity())
}

///|
test "ColorM identity apply" {
  let m = ColorM::identity()
  let (r, g, b, a) = m.apply(0.5, 0.3, 0.7, 1.0)
  assert_true!(approx(r, 0.5))
  assert_true!(approx(g, 0.3))
  assert_true!(approx(b, 0.7))
  assert_true!(approx(a, 1.0))
}

///|
test "ColorM scale" {
  let m = ColorM::identity().scale(0.5, 2.0, 0.0, 1.0)
  let (r, g, b, a) = m.apply(1.0, 0.5, 0.8, 1.0)
  assert_true!(approx(r, 0.5))
  assert_true!(approx(g, 1.0))
  assert_true!(approx(b, 0.0))
  assert_true!(approx(a, 1.0))
}

///|
test "ColorM translate" {
  let m = ColorM::identity().translate(0.1, -0.1, 0.0, 0.0)
  let (r, g, _b, a) = m.apply(0.5, 0.5, 0.5, 1.0)
  assert_true!(approx(r, 0.6))
  assert_true!(approx(g, 0.4))
  assert_true!(approx(a, 1.0))
}

///|
test "ColorM concat order" {
  // scale then translate: result should be scaled first, then offset applied
  let scaled = ColorM::identity().scale(2.0, 2.0, 2.0, 1.0)
  let translated = ColorM::identity().translate(0.1, 0.1, 0.1, 0.0)
  let combined = translated.concat(scaled)
  let (r, _g, _b, _a) = combined.apply(0.3, 0.3, 0.3, 1.0)
  // 0.3 * 2.0 + 0.1 = 0.7
  assert_true!(approx(r, 0.7))
}

///|
test "ColorM monochrome" {
  let m = ColorM::identity().monochrome()
  let (r, g, b, a) = m.apply(1.0, 0.0, 0.0, 1.0)
  // Pure red -> luminance 0.2126
  assert_true!(approx(r, 0.2126))
  assert_true!(approx(g, 0.2126))
  assert_true!(approx(b, 0.2126))
  assert_true!(approx(a, 1.0))
}

///|
test "ColorM monochrome white" {
  let m = ColorM::identity().monochrome()
  let (r, g, b, _a) = m.apply(1.0, 1.0, 1.0, 1.0)
  // White -> luminance 1.0
  assert_true!(approx(r, 1.0))
  assert_true!(approx(g, 1.0))
  assert_true!(approx(b, 1.0))
}

///|
test "ColorM invert" {
  let m = ColorM::identity().invert()
  let (r, g, b, a) = m.apply(0.0, 0.0, 0.0, 1.0)
  // Black inverted -> white
  assert_true!(approx(r, 1.0))
  assert_true!(approx(g, 1.0))
  assert_true!(approx(b, 1.0))
  assert_true!(approx(a, 1.0))
}

///|
test "ColorM invert white" {
  let m = ColorM::identity().invert()
  let (r, g, b, _a) = m.apply(1.0, 1.0, 1.0, 1.0)
  // White inverted -> black
  assert_true!(approx(r, 0.0))
  assert_true!(approx(g, 0.0))
  assert_true!(approx(b, 0.0))
}

///|
test "ColorM apply_clamped" {
  let m = ColorM::identity().translate(2.0, -2.0, 0.0, 0.0)
  let (r, g, _b, _a) = m.apply_clamped(0.5, 0.5, 0.5, 1.0)
  assert_true!(approx(r, 1.0))
  assert_true!(approx(g, 0.0))
}

///|
test "ColorM apply_color" {
  let m = ColorM::identity().scale(0.5, 0.5, 0.5, 1.0)
  let color = @gfx.new_color(1.0, 0.8, 0.6, 1.0)
  let result = m.apply_color(color)
  assert_true!(approx(result.r, 0.5))
  assert_true!(approx(result.g, 0.4))
  assert_true!(approx(result.b, 0.3))
  assert_true!(approx(result.a, 1.0))
}

///|
test "ColorM rotate_hue preserves luminance roughly" {
  let pi = 3.14159265358979323846
  let m = ColorM::identity().rotate_hue(pi)
  // Rotating hue 180 degrees should keep luminance roughly the same
  let (r, g, b, _a) = m.apply(1.0, 1.0, 1.0, 1.0)
  // White should stay roughly white after hue rotation
  let lum = 0.213 * r + 0.715 * g + 0.072 * b
  assert_true!(approx(lum, 1.0))
}

///|
test "ColorM is_identity false after scale" {
  let m = ColorM::identity().scale(0.5, 1.0, 1.0, 1.0)
  assert_true!(not(m.is_identity()))
}
