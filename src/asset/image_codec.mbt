///|
/// Image codec bridge powered by mizchi/image.
/// Keeps game_engine's ImageSpec as the primary data shape.

///|
pub enum RasterResizeMethod {
  Nearest
  Bilinear
  Bicubic
} derive(Show)

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
