///|
test "decode_triangle_payload returns defaults without enough vertices" {
  let payload = decode_triangle_payload([0.1, 0.2], [], [], [])
  assert_true(!payload.has_payload)
  assert_eq(payload.texture_seed, 0)
  assert_true(payload.uniform_r > 0.9)
}

///|
test "decode_triangle_payload decodes xyuv and color seed" {
  let payload = decode_triangle_payload(
    [
      -0.5, -0.5, 0.0, 0.0, 0.5, -0.5, 1.0, 0.0, 0.5, 0.5, 1.0, 1.0, -0.5, 0.5, 0.0,
      1.0,
    ],
    [0, 1, 2, 2, 3, 0],
    [64, 128, 255, 255],
    [9],
  )

  assert_true(payload.has_payload)
  assert_true(payload.ax < -0.4)
  assert_true(payload.bx > 0.4)
  assert_true(payload.cx > 0.4)
  assert_true(payload.au < 0.1)
  assert_true(payload.bu > 0.9)
  assert_true(payload.cu > 0.9)
  assert_true(payload.uniform_r > 0.2)
  assert_true(payload.uniform_g > 0.4)
  assert_true(payload.uniform_b > 0.9)
  assert_true(payload.uniform_a > 0.9)
  assert_eq(payload.texture_seed, 9)
}

///|
test "decode_triangle_payload decodes xy-only vertices" {
  let payload = decode_triangle_payload(
    [-0.9, 0.7, -0.4, -0.6, 0.8, -0.3],
    [],
    [],
    [],
  )
  assert_true(payload.has_payload)
  assert_true(payload.ax < -0.8)
  assert_true(payload.ay > 0.6)
  assert_true(payload.bx < -0.3)
  assert_true(payload.by < -0.5)
  assert_true(payload.cx > 0.7)
  assert_true(payload.cy < -0.2)
  assert_true(payload.uniform_r > 0.9)
}
