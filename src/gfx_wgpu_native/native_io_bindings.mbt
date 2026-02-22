// ---------------------------------------------------------------------------
// Font file I/O FFI
// ---------------------------------------------------------------------------

///|
extern "C" fn moonbit_load_font_file(path : Bytes, path_len : Int) -> Int = "moonbit_load_font_file"

///|
extern "C" fn moonbit_font_file_byte_at(offset : Int) -> Int = "moonbit_font_file_byte_at"

///|
extern "C" fn moonbit_font_file_release() = "moonbit_font_file_release"

///|
fn string_to_utf8_fixed_array(s : String) -> FixedArray[Byte] {
  let arr : Array[Byte] = []
  for ch in s {
    let code = ch.to_int()
    if code < 0x80 {
      arr.push(code.to_byte())
    } else if code < 0x800 {
      arr.push((0xC0 | (code >> 6)).to_byte())
      arr.push((0x80 | (code & 0x3F)).to_byte())
    } else if code < 0x10000 {
      arr.push((0xE0 | (code >> 12)).to_byte())
      arr.push((0x80 | ((code >> 6) & 0x3F)).to_byte())
      arr.push((0x80 | (code & 0x3F)).to_byte())
    } else {
      arr.push((0xF0 | (code >> 18)).to_byte())
      arr.push((0x80 | ((code >> 12) & 0x3F)).to_byte())
      arr.push((0x80 | ((code >> 6) & 0x3F)).to_byte())
      arr.push((0x80 | (code & 0x3F)).to_byte())
    }
  }
  let fa = FixedArray::make(arr.length(), b'\x00')
  for i, b in arr {
    fa[i] = b
  }
  fa
}

///|
pub fn load_font_file(path : String) -> Int {
  let utf8 = Bytes::from_array(string_to_utf8_fixed_array(path))
  moonbit_load_font_file(utf8, utf8.length())
}

///|
pub fn font_file_byte_at(offset : Int) -> Int {
  moonbit_font_file_byte_at(offset)
}

///|
pub fn font_file_release() -> Unit {
  moonbit_font_file_release()
}

// ---------------------------------------------------------------------------
// Audio FFI (miniaudio native backend)
// ---------------------------------------------------------------------------

///|
extern "C" fn moonbit_audio_try_initialize(
  sample_rate : Int,
  channels : Int,
) -> Int = "moonbit_audio_try_initialize"

///|
extern "C" fn moonbit_audio_write_sample(
  pos : Int,
  channel : Int,
  value : Float,
) = "moonbit_audio_write_sample"

///|
extern "C" fn moonbit_audio_get_write_pos() -> Int = "moonbit_audio_get_write_pos"

///|
extern "C" fn moonbit_audio_advance_write(frames : Int) = "moonbit_audio_advance_write"

///|
extern "C" fn moonbit_audio_suspend() = "moonbit_audio_suspend"

///|
extern "C" fn moonbit_audio_resume() = "moonbit_audio_resume"

///|
extern "C" fn moonbit_audio_close() = "moonbit_audio_close"

///|
extern "C" fn moonbit_audio_output_latency() -> Double = "moonbit_audio_output_latency"
