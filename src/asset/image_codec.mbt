///|
/// Image codec bridge powered by mizchi/image.
/// Keeps kagura's ImageSpec as the primary data shape.

///|
pub enum RasterResizeMethod {
  Nearest
  Bilinear
  Bicubic
} derive(Show)

///|
pub enum RasterImageFormat {
  Png
  Jpeg
  Bmp
} derive(Show, Eq)

///|
pub fn raster_resize_nearest() -> RasterResizeMethod {
  Nearest
}

///|
pub fn raster_resize_bilinear() -> RasterResizeMethod {
  Bilinear
}

///|
pub fn raster_resize_bicubic() -> RasterResizeMethod {
  Bicubic
}

///|
pub fn raster_image_format_png() -> RasterImageFormat {
  RasterImageFormat::Png
}

///|
pub fn raster_image_format_jpeg() -> RasterImageFormat {
  RasterImageFormat::Jpeg
}

///|
pub fn raster_image_format_bmp() -> RasterImageFormat {
  RasterImageFormat::Bmp
}

///|
fn clamp_u8_channel_for_bytes(channel : Int) -> Int {
  if channel < 0 {
    0
  } else if channel > 255 {
    255
  } else {
    channel
  }
}

///|
fn bytes_to_rgba8_channels(data : Bytes) -> Array[Int] {
  let channels : Array[Int] = []
  for byte in data.to_array() {
    channels.push(byte.to_int())
  }
  channels
}

///|
fn rgba8_channels_to_bytes(channels : Array[Int]) -> Bytes {
  let out : Array[Byte] = []
  for channel in channels {
    out.push(clamp_u8_channel_for_bytes(channel).to_byte())
  }
  Bytes::from_array(out)
}

///|
fn image_data_to_image_spec(image_data : @image.ImageData) -> ImageSpec {
  image_spec_with_rgba8(
    image_data.width,
    image_data.height,
    bytes_to_rgba8_channels(image_data.data),
  )
}

///|
fn image_spec_to_image_data(spec : ImageSpec) -> @image.ImageData {
  let safe_width = if spec.width <= 0 { 1 } else { spec.width }
  let safe_height = if spec.height <= 0 { 1 } else { spec.height }
  let normalized = normalized_rgba8_channels(
    spec.pixels_rgba8,
    safe_width,
    safe_height,
  )
  let expected = expected_rgba8_channel_count(safe_width, safe_height)
  let channels = if normalized.length() >= expected {
    normalized
  } else {
    let fallback : Array[Int] = []
    for _ in 0..<expected {
      fallback.push(0)
    }
    fallback
  }
  {
    width: safe_width,
    height: safe_height,
    data: rgba8_channels_to_bytes(channels),
  }
}

///|
fn to_image_resize_method(
  resize_method : RasterResizeMethod,
) -> @image.ResizeMethod {
  match resize_method {
    RasterResizeMethod::Nearest => @image.ResizeMethod::Nearest
    RasterResizeMethod::Bilinear => @image.ResizeMethod::Bilinear
    RasterResizeMethod::Bicubic => @image.ResizeMethod::Bicubic
  }
}

///|
fn bytes_has_prefix(bytes : Bytes, prefix : Array[Int]) -> Bool {
  if bytes.length() < prefix.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if bytes[i].to_int() != prefix[i] {
      return false
    }
  }
  true
}

///|
pub fn detect_raster_image_format(bytes : Bytes) -> RasterImageFormat? {
  if bytes_has_prefix(bytes, [137, 80, 78, 71, 13, 10, 26, 10]) {
    return Some(RasterImageFormat::Png)
  }
  if bytes_has_prefix(bytes, [255, 216, 255]) {
    return Some(RasterImageFormat::Jpeg)
  }
  if bytes_has_prefix(bytes, [66, 77]) {
    return Some(RasterImageFormat::Bmp)
  }
  None
}

///|
pub fn decode_png_image_spec(
  bytes : Bytes,
) -> ImageSpec raise @image.DecodeError {
  image_data_to_image_spec(@image.decode_png(bytes))
}

///|
pub fn decode_jpeg_image_spec(
  bytes : Bytes,
) -> ImageSpec raise @image.DecodeError {
  image_data_to_image_spec(@image.decode_jpeg(bytes))
}

///|
pub fn decode_bmp_image_spec(
  bytes : Bytes,
) -> ImageSpec raise @image.DecodeError {
  image_data_to_image_spec(@image.decode_bmp(bytes))
}

///|
pub fn decode_image_spec(
  bytes : Bytes,
  format : RasterImageFormat,
) -> ImageSpec raise @image.DecodeError {
  match format {
    RasterImageFormat::Png => decode_png_image_spec(bytes)
    RasterImageFormat::Jpeg => decode_jpeg_image_spec(bytes)
    RasterImageFormat::Bmp => decode_bmp_image_spec(bytes)
  }
}

///|
pub fn decode_image_spec_auto(
  bytes : Bytes,
) -> ImageSpec? raise @image.DecodeError {
  match detect_raster_image_format(bytes) {
    Some(format) => Some(decode_image_spec(bytes, format))
    None => None
  }
}

///|
pub fn create_image_from_raster_bytes(
  repository : SimpleImageRepository,
  key : AssetKey,
  bytes : Bytes,
) -> @gfx.ImageHandle? raise {
  match decode_image_spec_auto(bytes) {
    Some(spec) => Some(repository.create_image(key, spec))
    None => None
  }
}

///|
pub fn update_image_from_raster_bytes(
  repository : SimpleImageRepository,
  key : AssetKey,
  bytes : Bytes,
) -> @gfx.ImageHandle? raise {
  match decode_image_spec_auto(bytes) {
    Some(spec) => update_image_spec(repository, key, spec)
    None => None
  }
}

///|
pub fn create_atlas_image_from_raster_bytes(
  repository : SimpleAtlasImageRepository,
  key : AssetKey,
  bytes : Bytes,
) -> @gfx.ImageHandle? raise {
  match decode_image_spec_auto(bytes) {
    Some(spec) => create_atlas_image(repository, key, spec)
    None => None
  }
}

///|
pub fn update_atlas_image_from_raster_bytes(
  repository : SimpleAtlasImageRepository,
  key : AssetKey,
  bytes : Bytes,
) -> @gfx.ImageHandle? raise {
  match decode_image_spec_auto(bytes) {
    Some(spec) => update_atlas_image_spec(repository, key, spec)
    None => None
  }
}

///|
pub fn encode_png_image_spec(
  spec : ImageSpec,
) -> Bytes raise @image.EncodeError {
  @image.encode_png(image_spec_to_image_data(spec))
}

///|
pub fn encode_jpeg_image_spec(
  spec : ImageSpec,
  quality? : Int,
) -> Bytes raise @image.EncodeError {
  @image.encode_jpeg(image_spec_to_image_data(spec), quality?)
}

///|
pub fn encode_bmp_image_spec(
  spec : ImageSpec,
) -> Bytes raise @image.EncodeError {
  @image.encode_bmp(image_spec_to_image_data(spec))
}

///|
pub fn encode_image_spec(
  spec : ImageSpec,
  format : RasterImageFormat,
) -> Bytes raise @image.EncodeError {
  match format {
    RasterImageFormat::Png => encode_png_image_spec(spec)
    RasterImageFormat::Jpeg => encode_jpeg_image_spec(spec, quality=95)
    RasterImageFormat::Bmp => encode_bmp_image_spec(spec)
  }
}

///|
pub fn resize_image_spec(
  spec : ImageSpec,
  width : Int,
  height : Int,
  resize_method : RasterResizeMethod,
) -> ImageSpec raise @image.EncodeError {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  let resized = @image.resize(
    image_spec_to_image_data(spec),
    safe_width,
    safe_height,
    to_image_resize_method(resize_method),
  )
  image_data_to_image_spec(resized)
}
