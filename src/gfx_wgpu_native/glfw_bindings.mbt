// GLFW バインディング（ウィンドウ管理用）

///|
// 不透明ポインタ型
#external
type GLFWwindow

///|
// ===============================
// 構造体定義
// ===============================

///|
pub struct WindowSize {
  width : Int
  height : Int
}

///|
// ===============================
// C関数の宣言（extern "C"）
// ===============================

// GLFW 初期化
extern "C" fn glfwInit() -> Int = "glfwInit"

///|
extern "C" fn glfwTerminate() -> Unit = "glfwTerminate"

///|
// ウィンドウ作成（安全なラッパー経由）
#borrow(title)
extern "C" fn moonbit_glfw_create_window_safe(
  width : Int,
  height : Int,
  title : String,
) -> GLFWwindow = "moonbit_glfw_create_window_safe"

///|
extern "C" fn glfwDestroyWindow(window : GLFWwindow) -> Unit = "glfwDestroyWindow"

// イベント処理

///|
extern "C" fn glfwPollEvents() -> Unit = "glfwPollEvents"

///|
extern "C" fn glfwWindowShouldClose(window : GLFWwindow) -> Int = "glfwWindowShouldClose"

///|
extern "C" fn glfwSetWindowShouldClose(
  window : GLFWwindow,
  value : Int,
) -> Unit = "glfwSetWindowShouldClose"

///|
// SwapBuffers（バックバッファとフロントバッファを交換）
extern "C" fn glfwSwapBuffers(window : GLFWwindow) -> Unit = "glfwSwapBuffers"

///|
extern "C" fn glfwSwapInterval(interval : Int) -> Unit = "glfwSwapInterval"

///|
// ウィンドウサイズ取得（分割版）
extern "C" fn glfwGetWindowWidth(window : GLFWwindow) -> Int = "moonbit_glfw_get_window_width"

///|
extern "C" fn glfwGetWindowHeight(window : GLFWwindow) -> Int = "moonbit_glfw_get_window_height"

///|
// フレームバッファサイズ取得（物理ピクセル、Retina対応）
extern "C" fn glfwGetFramebufferWidth(window : GLFWwindow) -> Int = "moonbit_glfw_get_framebuffer_width"

///|
extern "C" fn glfwGetFramebufferHeight(window : GLFWwindow) -> Int = "moonbit_glfw_get_framebuffer_height"

///|
extern "C" fn moonbit_glfw_set_fullscreen(
  window : GLFWwindow,
  enabled : Int,
) -> Int = "moonbit_glfw_set_fullscreen"

///|
extern "C" fn moonbit_glfw_is_fullscreen(window : GLFWwindow) -> Int = "moonbit_glfw_is_fullscreen"

///|
extern "C" fn moonbit_glfw_set_cursor_mode(
  window : GLFWwindow,
  mode : Int,
) -> Int = "moonbit_glfw_set_cursor_mode"

///|
extern "C" fn moonbit_glfw_get_cursor_mode(window : GLFWwindow) -> Int = "moonbit_glfw_get_cursor_mode"

///|
extern "C" fn moonbit_glfw_get_cursor_x(window : GLFWwindow) -> Double = "moonbit_glfw_get_cursor_x"

///|
extern "C" fn moonbit_glfw_get_cursor_y(window : GLFWwindow) -> Double = "moonbit_glfw_get_cursor_y"

///|
extern "C" fn moonbit_glfw_take_scroll_x(window : GLFWwindow) -> Double = "moonbit_glfw_take_scroll_x"

///|
extern "C" fn moonbit_glfw_take_scroll_y(window : GLFWwindow) -> Double = "moonbit_glfw_take_scroll_y"

///|
extern "C" fn moonbit_glfw_pressed_key_count(window : GLFWwindow) -> Int = "moonbit_glfw_pressed_key_count"

///|
extern "C" fn moonbit_glfw_pressed_key_at(
  window : GLFWwindow,
  index : Int,
) -> Int = "moonbit_glfw_pressed_key_at"

///|
extern "C" fn moonbit_glfw_pressed_mouse_button_count(
  window : GLFWwindow,
) -> Int = "moonbit_glfw_pressed_mouse_button_count"

///|
extern "C" fn moonbit_glfw_pressed_mouse_button_at(
  window : GLFWwindow,
  index : Int,
) -> Int = "moonbit_glfw_pressed_mouse_button_at"

///|
extern "C" fn moonbit_glfw_touch_count(window : GLFWwindow) -> Int = "moonbit_glfw_touch_count"

///|
extern "C" fn moonbit_glfw_touch_id_at(window : GLFWwindow, index : Int) -> Int = "moonbit_glfw_touch_id_at"

///|
extern "C" fn moonbit_glfw_touch_x_at(
  window : GLFWwindow,
  index : Int,
) -> Double = "moonbit_glfw_touch_x_at"

///|
extern "C" fn moonbit_glfw_touch_y_at(
  window : GLFWwindow,
  index : Int,
) -> Double = "moonbit_glfw_touch_y_at"

///|
extern "C" fn moonbit_glfw_touch_type_at(
  window : GLFWwindow,
  index : Int,
) -> Int = "moonbit_glfw_touch_type_at"

///|
extern "C" fn moonbit_glfw_gamepad_count() -> Int = "moonbit_glfw_gamepad_count"

///|
extern "C" fn moonbit_glfw_gamepad_id_at(index : Int) -> Int = "moonbit_glfw_gamepad_id_at"

///|
extern "C" fn moonbit_glfw_gamepad_axis_count(index : Int) -> Int = "moonbit_glfw_gamepad_axis_count"

///|
extern "C" fn moonbit_glfw_gamepad_axis_at(
  gamepad_index : Int,
  axis_index : Int,
) -> Double = "moonbit_glfw_gamepad_axis_at"

///|
extern "C" fn moonbit_glfw_gamepad_pressed_button_count(index : Int) -> Int = "moonbit_glfw_gamepad_pressed_button_count"

///|
extern "C" fn moonbit_glfw_gamepad_pressed_button_at(
  gamepad_index : Int,
  button_index : Int,
) -> Int = "moonbit_glfw_gamepad_pressed_button_at"

///|
extern "C" fn moonbit_glfw_get_window_content_scale(
  window : GLFWwindow,
) -> Double = "moonbit_glfw_get_window_content_scale"

///|
extern "C" fn moonbit_glfw_request_window_attention_safe(
  window : GLFWwindow,
) -> Unit = "moonbit_glfw_request_window_attention_safe"

///|
// ===============================
// 高レベルラッパー関数
// ===============================

// GLFW 初期化
pub fn glfw_init() -> Bool {
  glfwInit() != 0
}

///|
pub fn terminate() -> Unit {
  glfwTerminate()
}

///|
// ウィンドウ作成（WebGPU 用に CLIENT_API を NO_API に設定）
pub fn create_window(width : Int, height : Int, title : String) -> GLFWwindow {
  // C スタブの安全なラッパー経由でウィンドウ作成
  // (ウィンドウヒント設定も含む)
  moonbit_glfw_create_window_safe(width, height, title)
}

///|
pub fn destroy_window(window : GLFWwindow) -> Unit {
  glfwDestroyWindow(window)
}

///|
pub fn poll_events() -> Unit {
  glfwPollEvents()
}

///|
pub fn window_should_close(window : GLFWwindow) -> Bool {
  glfwWindowShouldClose(window) != 0
}

///|
pub fn set_window_should_close(window : GLFWwindow, value : Bool) -> Unit {
  glfwSetWindowShouldClose(window, if value { 1 } else { 0 })
}

///|
pub fn swap_buffers(window : GLFWwindow) -> Unit {
  glfwSwapBuffers(window)
}

///|
pub fn set_swap_interval(enabled : Bool) -> Unit {
  glfwSwapInterval(if enabled { 1 } else { 0 })
}

///|
pub fn get_window_size(window : GLFWwindow) -> WindowSize {
  // moonbit_glfw_get_window_size_struct(window)  // 構造体返却版（クラッシュ）
  // 代わりに分割版を使用
  { width: glfwGetWindowWidth(window), height: glfwGetWindowHeight(window) }
}

///|
pub fn get_window_width(window : GLFWwindow) -> Int {
  glfwGetWindowWidth(window)
}

///|
pub fn get_window_height(window : GLFWwindow) -> Int {
  glfwGetWindowHeight(window)
}

///|
pub fn get_framebuffer_size(window : GLFWwindow) -> WindowSize {
  { width: glfwGetFramebufferWidth(window), height: glfwGetFramebufferHeight(window) }
}

///|
pub fn set_fullscreen(window : GLFWwindow, enabled : Bool) -> Bool {
  moonbit_glfw_set_fullscreen(window, if enabled { 1 } else { 0 }) != 0
}

///|
pub fn is_fullscreen(window : GLFWwindow) -> Bool {
  moonbit_glfw_is_fullscreen(window) != 0
}

///|
pub fn set_cursor_mode(window : GLFWwindow, mode : Int) -> Int {
  moonbit_glfw_set_cursor_mode(window, mode)
}

///|
pub fn get_cursor_mode(window : GLFWwindow) -> Int {
  moonbit_glfw_get_cursor_mode(window)
}

///|
pub fn get_cursor_x(window : GLFWwindow) -> Double {
  moonbit_glfw_get_cursor_x(window)
}

///|
pub fn get_cursor_y(window : GLFWwindow) -> Double {
  moonbit_glfw_get_cursor_y(window)
}

///|
pub fn take_scroll_x(window : GLFWwindow) -> Double {
  moonbit_glfw_take_scroll_x(window)
}

///|
pub fn take_scroll_y(window : GLFWwindow) -> Double {
  moonbit_glfw_take_scroll_y(window)
}

///|
pub fn pressed_key_count(window : GLFWwindow) -> Int {
  moonbit_glfw_pressed_key_count(window)
}

///|
pub fn pressed_key_at(window : GLFWwindow, index : Int) -> Int {
  moonbit_glfw_pressed_key_at(window, index)
}

///|
pub fn pressed_mouse_button_count(window : GLFWwindow) -> Int {
  moonbit_glfw_pressed_mouse_button_count(window)
}

///|
pub fn pressed_mouse_button_at(window : GLFWwindow, index : Int) -> Int {
  moonbit_glfw_pressed_mouse_button_at(window, index)
}

///|
pub fn touch_count(window : GLFWwindow) -> Int {
  moonbit_glfw_touch_count(window)
}

///|
pub fn touch_id_at(window : GLFWwindow, index : Int) -> Int {
  moonbit_glfw_touch_id_at(window, index)
}

///|
pub fn touch_x_at(window : GLFWwindow, index : Int) -> Double {
  moonbit_glfw_touch_x_at(window, index)
}

///|
pub fn touch_y_at(window : GLFWwindow, index : Int) -> Double {
  moonbit_glfw_touch_y_at(window, index)
}

///|
pub fn touch_type_at(window : GLFWwindow, index : Int) -> Int {
  moonbit_glfw_touch_type_at(window, index)
}

///|
pub fn gamepad_count() -> Int {
  moonbit_glfw_gamepad_count()
}

///|
pub fn gamepad_id_at(index : Int) -> Int {
  moonbit_glfw_gamepad_id_at(index)
}

///|
pub fn gamepad_axis_count(index : Int) -> Int {
  moonbit_glfw_gamepad_axis_count(index)
}

///|
pub fn gamepad_axis_at(gamepad_index : Int, axis_index : Int) -> Double {
  moonbit_glfw_gamepad_axis_at(gamepad_index, axis_index)
}

///|
pub fn gamepad_pressed_button_count(index : Int) -> Int {
  moonbit_glfw_gamepad_pressed_button_count(index)
}

///|
pub fn gamepad_pressed_button_at(
  gamepad_index : Int,
  button_index : Int,
) -> Int {
  moonbit_glfw_gamepad_pressed_button_at(gamepad_index, button_index)
}

///|
pub fn get_window_content_scale(window : GLFWwindow) -> Double {
  let scale = moonbit_glfw_get_window_content_scale(window)
  if scale <= 0.0 {
    1.0
  } else {
    scale
  }
}

///|
pub fn request_window_attention(window : GLFWwindow) -> Unit {
  moonbit_glfw_request_window_attention_safe(window)
}

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
