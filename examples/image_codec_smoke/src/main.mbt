///|
fn main {
  let source = @asset.image_spec_with_rgba8(2, 2, [
    255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255,
  ])
  let png_format = @asset.raster_image_format_png()
  let encoded = @asset.encode_image_spec(source, png_format) catch {
    _ => panic()
  }
  let detected = @asset.detect_raster_image_format(encoded)
  match detected {
    Some(format) => if format != png_format { panic() }
    None => panic()
  }
  let decoded = @asset.decode_image_spec_auto(encoded) catch { _ => panic() }
  match decoded {
    Some(spec) => {
      if spec.width != 2 || spec.height != 2 {
        panic()
      }
      let resized = @asset.resize_image_spec(
        spec,
        4,
        3,
        @asset.raster_resize_nearest(),
      ) catch {
        _ => panic()
      }
      if resized.width != 4 || resized.height != 3 {
        panic()
      }
      if resized.pixels_rgba8.length() != 4 * 3 * 4 {
        panic()
      }
    }
    None => panic()
  }
  println("image_codec_smoke: ok")
}
