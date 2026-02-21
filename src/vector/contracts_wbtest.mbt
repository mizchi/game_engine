///|
fn approx(a : Double, b : Double) -> Bool {
  (a - b).abs() < 1.0e-9
}

///|
test "Vec2 constructors" {
  let z = Vec2::zero()
  assert_eq(z.x, 0.0)
  assert_eq(z.y, 0.0)
  let o = Vec2::one()
  assert_eq(o.x, 1.0)
  assert_eq(o.y, 1.0)
  let ux = Vec2::unit_x()
  assert_eq(ux.x, 1.0)
  assert_eq(ux.y, 0.0)
  let uy = Vec2::unit_y()
  assert_eq(uy.x, 0.0)
  assert_eq(uy.y, 1.0)
}

///|
test "Vec2 arithmetic" {
  let a = Vec2::new(3.0, 4.0)
  let b = Vec2::new(1.0, 2.0)
  let sum = a.add(b)
  assert_eq(sum.x, 4.0)
  assert_eq(sum.y, 6.0)
  let diff = a.sub(b)
  assert_eq(diff.x, 2.0)
  assert_eq(diff.y, 2.0)
  let scaled = a.scale(2.0)
  assert_eq(scaled.x, 6.0)
  assert_eq(scaled.y, 8.0)
  let neg = a.negate()
  assert_eq(neg.x, -3.0)
  assert_eq(neg.y, -4.0)
  let m = a.mul(b)
  assert_eq(m.x, 3.0)
  assert_eq(m.y, 8.0)
}

///|
test "Vec2 dot and cross" {
  let a = Vec2::new(1.0, 0.0)
  let b = Vec2::new(0.0, 1.0)
  assert_eq(a.dot(b), 0.0)
  assert_eq(a.cross(b), 1.0)
  let c = Vec2::new(3.0, 4.0)
  let d = Vec2::new(2.0, 1.0)
  assert_eq(c.dot(d), 10.0)
  assert_eq(c.cross(d), -5.0)
}

///|
test "Vec2 length and normalize" {
  let v = Vec2::new(3.0, 4.0)
  assert_eq(v.length_squared(), 25.0)
  assert_eq(v.length(), 5.0)
  let n = v.normalize()
  assert_true(approx(n.length(), 1.0))
  assert_true(approx(n.x, 0.6))
  assert_true(approx(n.y, 0.8))
  // zero vector normalization
  let z = Vec2::zero().normalize()
  assert_eq(z.x, 0.0)
  assert_eq(z.y, 0.0)
}

///|
test "Vec2 distance" {
  let a = Vec2::new(0.0, 0.0)
  let b = Vec2::new(3.0, 4.0)
  assert_eq(a.distance(b), 5.0)
  assert_eq(a.distance_squared(b), 25.0)
}

///|
test "Vec2 lerp" {
  let a = Vec2::new(0.0, 0.0)
  let b = Vec2::new(10.0, 20.0)
  let mid = a.lerp(b, 0.5)
  assert_eq(mid.x, 5.0)
  assert_eq(mid.y, 10.0)
  let start = a.lerp(b, 0.0)
  assert_eq(start.x, 0.0)
  let end_ = a.lerp(b, 1.0)
  assert_eq(end_.x, 10.0)
}

///|
test "Vec2 perpendicular" {
  let v = Vec2::new(1.0, 0.0)
  let p = v.perpendicular()
  assert_eq(p.x, 0.0)
  assert_eq(p.y, 1.0)
  // perpendicular is orthogonal
  assert_true(approx(v.dot(p), 0.0))
}

///|
test "Vec2 rotate" {
  let v = Vec2::new(1.0, 0.0)
  let pi = 3.14159265358979323846
  let rotated = v.rotate(pi / 2.0)
  assert_true(approx(rotated.x, 0.0))
  assert_true(approx(rotated.y, 1.0))
  let rotated2 = v.rotate(pi)
  assert_true(approx(rotated2.x, -1.0))
  assert_true(approx(rotated2.y, 0.0))
}

///|
test "Vec2 angle" {
  let pi = 3.14159265358979323846
  let v = Vec2::new(1.0, 0.0)
  assert_true(approx(v.angle(), 0.0))
  let v2 = Vec2::new(0.0, 1.0)
  assert_true(approx(v2.angle(), pi / 2.0))
}

///|
test "Vec2 angle_between" {
  let pi = 3.14159265358979323846
  let a = Vec2::new(1.0, 0.0)
  let b = Vec2::new(0.0, 1.0)
  assert_true(approx(a.angle_between(b), pi / 2.0))
}

///|
test "Vec2 min max clamp" {
  let a = Vec2::new(1.0, 5.0)
  let b = Vec2::new(3.0, 2.0)
  let mn = a.min(b)
  assert_eq(mn.x, 1.0)
  assert_eq(mn.y, 2.0)
  let mx = a.max(b)
  assert_eq(mx.x, 3.0)
  assert_eq(mx.y, 5.0)
  let v = Vec2::new(-1.0, 10.0)
  let clamped = v.clamp(Vec2::zero(), Vec2::one())
  assert_eq(clamped.x, 0.0)
  assert_eq(clamped.y, 1.0)
}

///|
test "Vec2 approx_eq" {
  let a = Vec2::new(1.0, 2.0)
  let b = Vec2::new(1.0000000001, 2.0000000001)
  assert_true(a.approx_eq(b, 1.0e-6))
  let c = Vec2::new(1.1, 2.0)
  assert_true(not(a.approx_eq(c, 1.0e-6)))
}

///|
test "Vec2 reflect" {
  let v = Vec2::new(1.0, -1.0)
  let n = Vec2::new(0.0, 1.0)
  let r = v.reflect(n)
  assert_true(approx(r.x, 1.0))
  assert_true(approx(r.y, 1.0))
}

///|
test "Vec2 div" {
  let a = Vec2::new(6.0, 8.0)
  let b = Vec2::new(2.0, 4.0)
  let result = a.div(b)
  assert_true(approx(result.x, 3.0))
  assert_true(approx(result.y, 2.0))
}

///|
test "Vec2 perpendicular is orthogonal" {
  let v = Vec2::new(3.0, 7.0)
  let p = v.perpendicular()
  assert_true(approx(v.dot(p), 0.0))
}

///|
test "Vec2 normalize preserves direction" {
  let v = Vec2::new(100.0, 0.0)
  let n = v.normalize()
  assert_true(approx(n.x, 1.0))
  assert_true(approx(n.y, 0.0))
  let v2 = Vec2::new(-3.0, -4.0)
  let n2 = v2.normalize()
  assert_true(approx(n2.length(), 1.0))
  assert_true(n2.x < 0.0)
  assert_true(n2.y < 0.0)
}

///|
test "Vec2 reflect preserves incident angle" {
  let v = Vec2::new(1.0, -1.0).normalize()
  let n = Vec2::new(0.0, 1.0)
  let r = v.reflect(n)
  // |incident angle| should equal |reflected angle| relative to normal
  let incident_cos = v.negate().dot(n).abs()
  let reflected_cos = r.dot(n).abs()
  assert_true(approx(incident_cos, reflected_cos))
}

// ============================================================
// AABB collision tests
// ============================================================

///|
test "aabb_overlap: overlapping rects" {
  assert_true!(aabb_overlap(0.0, 0.0, 10.0, 10.0, 5.0, 5.0, 10.0, 10.0))
}

///|
test "aabb_overlap: non-overlapping rects" {
  assert_true!(!aabb_overlap(0.0, 0.0, 10.0, 10.0, 20.0, 20.0, 10.0, 10.0))
}

///|
test "aabb_overlap: touching edges do not overlap" {
  assert_true!(!aabb_overlap(0.0, 0.0, 10.0, 10.0, 10.0, 0.0, 10.0, 10.0))
}

///|
test "aabb_overlap: contained rect" {
  assert_true!(aabb_overlap(0.0, 0.0, 20.0, 20.0, 5.0, 5.0, 5.0, 5.0))
}

///|
test "aabb_overlap_center: overlapping" {
  // Two objects at (10,10) and (15,15) with half-sizes 5
  assert_true!(aabb_overlap_center(10.0, 10.0, 5.0, 5.0, 15.0, 15.0, 5.0, 5.0))
}

///|
test "aabb_overlap_center: non-overlapping" {
  assert_true!(!aabb_overlap_center(0.0, 0.0, 5.0, 5.0, 20.0, 20.0, 5.0, 5.0))
}

///|
test "aabb_overlap_center: same position" {
  assert_true!(aabb_overlap_center(10.0, 10.0, 5.0, 5.0, 10.0, 10.0, 5.0, 5.0))
}

///|
test "aabb_overlap_center: touching edges do not overlap" {
  // Distance = 10, half_sum = 5+5 = 10, abs(10) < 10 is false
  assert_true!(!aabb_overlap_center(0.0, 0.0, 5.0, 5.0, 10.0, 0.0, 5.0, 5.0))
}

///|
test "Vec2 rotate 360 degrees returns original" {
  let pi = 3.14159265358979323846
  let v = Vec2::new(3.0, 4.0)
  let rotated = v.rotate(pi * 2.0)
  assert_true(approx(rotated.x, v.x))
  assert_true(approx(rotated.y, v.y))
}
