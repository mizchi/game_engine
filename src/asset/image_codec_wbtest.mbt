///|
fn sample_codec_spec() -> ImageSpec {
  image_spec_with_rgba8(2, 2, [
    255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255,
  ])
}

///|
test "png encode/decode roundtrip keeps exact channels" {
  let source = sample_codec_spec()
  let encoded = encode_png_image_spec(source) catch { _ => panic() }
  let decoded = decode_png_image_spec(encoded) catch { _ => panic() }
  assert_eq(decoded.width, 2)
  assert_eq(decoded.height, 2)
  assert_eq(decoded.pixels_rgba8.length(), 16)
  assert_eq(decoded.pixels_rgba8[0], 255)
  assert_eq(decoded.pixels_rgba8[1], 0)
  assert_eq(decoded.pixels_rgba8[2], 0)
  assert_eq(decoded.pixels_rgba8[3], 255)
  assert_eq(decoded.pixels_rgba8[12], 255)
  assert_eq(decoded.pixels_rgba8[13], 255)
  assert_eq(decoded.pixels_rgba8[14], 255)
  assert_eq(decoded.pixels_rgba8[15], 255)
}

///|
test "bmp encode/decode roundtrip keeps dimensions and pixel length" {
  let source = sample_codec_spec()
  let encoded = encode_bmp_image_spec(source) catch { _ => panic() }
  let decoded = decode_bmp_image_spec(encoded) catch { _ => panic() }
  assert_eq(decoded.width, 2)
  assert_eq(decoded.height, 2)
  assert_eq(decoded.pixels_rgba8.length(), 16)
}

///|
test "jpeg encode/decode keeps dimensions" {
  let source = sample_codec_spec()
  let encoded = encode_jpeg_image_spec(source, quality=95) catch {
    _ => panic()
  }
  let decoded = decode_jpeg_image_spec(encoded) catch { _ => panic() }
  assert_eq(decoded.width, 2)
  assert_eq(decoded.height, 2)
  assert_eq(decoded.pixels_rgba8.length(), 16)
}

///|
test "resize image spec with nearest updates dimensions and payload length" {
  let source = sample_codec_spec()
  let resized = resize_image_spec(source, 4, 3, Nearest) catch { _ => panic() }
  assert_eq(resized.width, 4)
  assert_eq(resized.height, 3)
  assert_eq(resized.pixels_rgba8.length(), 4 * 3 * 4)
}
