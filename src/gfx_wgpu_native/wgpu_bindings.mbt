// WebGPU C API MoonBit バインディング

///|
// 不透明ポインタ型の定義（C FFIと連携）
#external
type WGPUInstance

///|
#external
type WGPUAdapter

///|
#external
type WGPUDevice

///|
#external
type WGPUSurface

///|
#external
type WGPUShaderModule

///|
#external
type WGPURenderPipeline

///|
#external
type WGPUQueue

///|
// Status/Result 型
pub enum WGPUStatus {
  Success // 0
  Error // 1
} derive(Show)

///|
// Backend 型（Metal, Vulkan, DX12 など）
pub enum WGPUBackendType {
  Undefined // 0
  Null // 1
  WebGPU // 2
  D3D11 // 3
  D3D12 // 4
  Metal // 5
  Vulkan // 6
  OpenGL // 7
  OpenGLES // 8
} derive(Show)

///|
// ===============================
// C関数の宣言（extern "C"）
// ===============================

// Instance API
extern "C" fn wgpuCreateInstance(descriptor : Int) -> WGPUInstance = "wgpuCreateInstance"

///|
extern "C" fn wgpuInstanceRelease(instance : WGPUInstance) -> Unit = "wgpuInstanceRelease"

///|
extern "C" fn wgpuInstanceAddRef(instance : WGPUInstance) -> Unit = "wgpuInstanceAddRef"

///|
// Surface API（GLFW統合用）
extern "C" fn moonbit_create_surface_from_glfw(
  instance : WGPUInstance,
  window : GLFWwindow,
) -> WGPUSurface = "moonbit_create_surface_from_glfw"

///|
extern "C" fn wgpuSurfaceRelease(surface : WGPUSurface) -> Unit = "wgpuSurfaceRelease"

///|
// ===============================
// 高レベルラッパー関数
// ===============================

// Instance作成（NULL descriptor で最もシンプルな初期化）
pub fn create_instance() -> WGPUInstance {
  wgpuCreateInstance(0)
}

///|
pub fn instance_release(instance : WGPUInstance) -> Unit {
  wgpuInstanceRelease(instance)
}

///|
pub fn instance_add_ref(instance : WGPUInstance) -> Unit {
  wgpuInstanceAddRef(instance)
}

///|
// GLFWwindowからSurfaceを作成
pub fn create_surface_from_glfw(
  instance : WGPUInstance,
  window : GLFWwindow,
) -> WGPUSurface {
  moonbit_create_surface_from_glfw(instance, window)
}

///|
pub fn surface_release(surface : WGPUSurface) -> Unit {
  wgpuSurfaceRelease(surface)
}

///|
// ===============================
// Adapter API
// ===============================

// Adapter を同期的にリクエスト（内部で非同期処理を待機）
extern "C" fn moonbit_request_adapter_sync(
  instance : WGPUInstance,
  surface : WGPUSurface,
) -> WGPUAdapter = "moonbit_request_adapter_sync"

///|
extern "C" fn wgpuAdapterRelease(adapter : WGPUAdapter) -> Unit = "wgpuAdapterRelease"

///|
pub fn request_adapter(
  instance : WGPUInstance,
  surface : WGPUSurface,
) -> WGPUAdapter {
  moonbit_request_adapter_sync(instance, surface)
}

///|
pub fn adapter_release(adapter : WGPUAdapter) -> Unit {
  wgpuAdapterRelease(adapter)
}

///|
// ===============================
// Device & Queue API
// ===============================

// Device を同期的にリクエスト
extern "C" fn moonbit_request_device_sync(adapter : WGPUAdapter) -> WGPUDevice = "moonbit_request_device_sync"

///|
extern "C" fn wgpuDeviceRelease(device : WGPUDevice) -> Unit = "wgpuDeviceRelease"

///|
// Queue を取得
extern "C" fn moonbit_device_get_queue(device : WGPUDevice) -> WGPUQueue = "moonbit_device_get_queue"

///|
extern "C" fn wgpuQueueRelease(queue : WGPUQueue) -> Unit = "wgpuQueueRelease"

///|
pub fn request_device(adapter : WGPUAdapter) -> WGPUDevice {
  moonbit_request_device_sync(adapter)
}

///|
pub fn device_release(device : WGPUDevice) -> Unit {
  wgpuDeviceRelease(device)
}

///|
pub fn device_get_queue(device : WGPUDevice) -> WGPUQueue {
  moonbit_device_get_queue(device)
}

///|
pub fn queue_release(queue : WGPUQueue) -> Unit {
  wgpuQueueRelease(queue)
}

///|
// ===============================
// Surface Configuration API
// ===============================

// Surface を設定（サイズとフォーマットを自動決定）
extern "C" fn moonbit_configure_surface(
  surface : WGPUSurface,
  device : WGPUDevice,
  adapter : WGPUAdapter,
  width : Int,
  height : Int,
) -> Unit = "moonbit_configure_surface"

///|
pub fn configure_surface(
  surface : WGPUSurface,
  device : WGPUDevice,
  adapter : WGPUAdapter,
  width : Int,
  height : Int,
) -> Unit {
  moonbit_configure_surface(surface, device, adapter, width, height)
}

///|
// ===============================
// Shader Module API
// ===============================

// ShaderModule を作成（WGSL シェーダーコードから）
#borrow(wgsl_code)
extern "C" fn moonbit_create_shader_module(
  device : WGPUDevice,
  wgsl_code : String,
) -> WGPUShaderModule = "moonbit_create_shader_module"

///|
extern "C" fn wgpuShaderModuleRelease(shaderModule : WGPUShaderModule) -> Unit = "wgpuShaderModuleRelease"

///|
pub fn create_shader_module(
  device : WGPUDevice,
  wgsl_code : String,
) -> WGPUShaderModule {
  moonbit_create_shader_module(device, wgsl_code)
}

///|
pub fn shader_module_release(shaderModule : WGPUShaderModule) -> Unit {
  wgpuShaderModuleRelease(shaderModule)
}

///|
// ===============================
// Render Pipeline API
// ===============================

// RenderPipeline を作成（三角形描画用、シンプル版）
extern "C" fn moonbit_create_render_pipeline(
  device : WGPUDevice,
  shaderModule : WGPUShaderModule,
  format : Int,
) -> WGPURenderPipeline = "moonbit_create_render_pipeline"

///|
extern "C" fn wgpuRenderPipelineRelease(pipeline : WGPURenderPipeline) -> Unit = "wgpuRenderPipelineRelease"

///|
pub fn create_render_pipeline(
  device : WGPUDevice,
  shaderModule : WGPUShaderModule,
  format : Int,
) -> WGPURenderPipeline {
  moonbit_create_render_pipeline(device, shaderModule, format)
}

///|
pub fn render_pipeline_release(pipeline : WGPURenderPipeline) -> Unit {
  wgpuRenderPipelineRelease(pipeline)
}

///|
// ===============================
// Rendering API
// ===============================

// 1フレーム描画
extern "C" fn moonbit_render_frame(
  surface : WGPUSurface,
  device : WGPUDevice,
  queue : WGPUQueue,
  pipeline : WGPURenderPipeline,
) -> Unit = "moonbit_render_frame"

///|
pub fn render_frame(
  surface : WGPUSurface,
  device : WGPUDevice,
  queue : WGPUQueue,
  pipeline : WGPURenderPipeline,
) -> Unit {
  moonbit_render_frame(surface, device, queue, pipeline)
}

///|
extern "C" fn moonbit_render_frame_with_plan(
  surface : WGPUSurface,
  device : WGPUDevice,
  queue : WGPUQueue,
  pipeline : WGPURenderPipeline,
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
  draw_calls : Int,
) -> Unit = "moonbit_render_frame_with_plan"

///|
pub fn render_frame_with_plan(
  surface : WGPUSurface,
  device : WGPUDevice,
  queue : WGPUQueue,
  pipeline : WGPURenderPipeline,
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
  draw_calls : Int,
) -> Unit {
  moonbit_render_frame_with_plan(
    surface, device, queue, pipeline, clear_r, clear_g, clear_b, clear_a, draw_calls,
  )
}

///|
extern "C" fn moonbit_reset_planned_draw_queue() -> Unit = "moonbit_reset_planned_draw_queue"

///|
pub fn reset_planned_draw_queue() -> Unit {
  moonbit_reset_planned_draw_queue()
}

///|
extern "C" fn moonbit_clear_planned_pipeline_cache() -> Unit = "moonbit_clear_planned_pipeline_cache"

///|
pub fn clear_planned_pipeline_cache() -> Unit {
  moonbit_clear_planned_pipeline_cache()
}

///|
extern "C" fn moonbit_clear_planned_texture_cache() -> Unit = "moonbit_clear_planned_texture_cache"

///|
pub fn clear_planned_texture_cache() -> Unit {
  moonbit_clear_planned_texture_cache()
}

///|
extern "C" fn moonbit_clear_planned_bind_group_cache() -> Unit = "moonbit_clear_planned_bind_group_cache"

///|
pub fn clear_planned_bind_group_cache() -> Unit {
  moonbit_clear_planned_bind_group_cache()
}

///|
extern "C" fn moonbit_clear_planned_image_palette_registry() -> Unit = "moonbit_clear_planned_image_palette_registry"

///|
pub fn clear_planned_image_palette_registry() -> Unit {
  moonbit_clear_planned_image_palette_registry()
}

///|
extern "C" fn moonbit_register_planned_image_palette(
  image_id : Int,
  p00_r : Int,
  p00_g : Int,
  p00_b : Int,
  p00_a : Int,
  p10_r : Int,
  p10_g : Int,
  p10_b : Int,
  p10_a : Int,
  p01_r : Int,
  p01_g : Int,
  p01_b : Int,
  p01_a : Int,
  p11_r : Int,
  p11_g : Int,
  p11_b : Int,
  p11_a : Int,
) -> Unit = "moonbit_register_planned_image_palette"

///|
pub fn register_planned_image_palette(
  image_id : Int,
  p00_r : Int,
  p00_g : Int,
  p00_b : Int,
  p00_a : Int,
  p10_r : Int,
  p10_g : Int,
  p10_b : Int,
  p10_a : Int,
  p01_r : Int,
  p01_g : Int,
  p01_b : Int,
  p01_a : Int,
  p11_r : Int,
  p11_g : Int,
  p11_b : Int,
  p11_a : Int,
) -> Unit {
  moonbit_register_planned_image_palette(
    image_id, p00_r, p00_g, p00_b, p00_a, p10_r, p10_g, p10_b, p10_a, p01_r, p01_g,
    p01_b, p01_a, p11_r, p11_g, p11_b, p11_a,
  )
}

///|
extern "C" fn moonbit_planned_image_palette_registry_count() -> Int = "moonbit_planned_image_palette_registry_count"

///|
pub fn planned_image_palette_registry_count() -> Int {
  moonbit_planned_image_palette_registry_count()
}

///|
extern "C" fn moonbit_planned_image_palette_channel(
  image_id : Int,
  pixel_index : Int,
  channel_index : Int,
) -> Int = "moonbit_planned_image_palette_channel"

///|
pub fn planned_image_palette_channel(
  image_id : Int,
  pixel_index : Int,
  channel_index : Int,
) -> Int {
  moonbit_planned_image_palette_channel(image_id, pixel_index, channel_index)
}

///|
extern "C" fn moonbit_planned_image_palette_generation(image_id : Int) -> Int = "moonbit_planned_image_palette_generation"

///|
pub fn planned_image_palette_generation(image_id : Int) -> Int {
  moonbit_planned_image_palette_generation(image_id)
}

///|
extern "C" fn moonbit_clear_planned_source_image_registry() -> Unit = "moonbit_clear_planned_source_image_registry"

///|
pub fn clear_planned_source_image_registry() -> Unit {
  moonbit_clear_planned_source_image_registry()
}

///|
extern "C" fn moonbit_begin_planned_source_image_upload(
  image_id : Int,
  width : Int,
  height : Int,
) -> Unit = "moonbit_begin_planned_source_image_upload"

///|
pub fn begin_planned_source_image_upload(
  image_id : Int,
  width : Int,
  height : Int,
) -> Unit {
  moonbit_begin_planned_source_image_upload(image_id, width, height)
}

///|
extern "C" fn moonbit_begin_planned_source_image_patch(image_id : Int) -> Int = "moonbit_begin_planned_source_image_patch"

///|
pub fn begin_planned_source_image_patch(image_id : Int) -> Bool {
  moonbit_begin_planned_source_image_patch(image_id) != 0
}

///|
extern "C" fn moonbit_set_planned_source_image_pixel(
  image_id : Int,
  x : Int,
  y : Int,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
) -> Unit = "moonbit_set_planned_source_image_pixel"

///|
pub fn set_planned_source_image_pixel(
  image_id : Int,
  x : Int,
  y : Int,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
) -> Unit {
  moonbit_set_planned_source_image_pixel(image_id, x, y, r, g, b, a)
}

///|
extern "C" fn moonbit_end_planned_source_image_upload(image_id : Int) -> Unit = "moonbit_end_planned_source_image_upload"

///|
pub fn end_planned_source_image_upload(image_id : Int) -> Unit {
  moonbit_end_planned_source_image_upload(image_id)
}

///|
extern "C" fn moonbit_end_planned_source_image_patch(image_id : Int) -> Int = "moonbit_end_planned_source_image_patch"

///|
pub fn end_planned_source_image_patch(image_id : Int) -> Bool {
  moonbit_end_planned_source_image_patch(image_id) != 0
}

///|
extern "C" fn moonbit_planned_source_image_registry_count() -> Int = "moonbit_planned_source_image_registry_count"

///|
pub fn planned_source_image_registry_count() -> Int {
  moonbit_planned_source_image_registry_count()
}

///|
extern "C" fn moonbit_planned_source_image_width(image_id : Int) -> Int = "moonbit_planned_source_image_width"

///|
pub fn planned_source_image_width(image_id : Int) -> Int {
  moonbit_planned_source_image_width(image_id)
}

///|
extern "C" fn moonbit_planned_source_image_height(image_id : Int) -> Int = "moonbit_planned_source_image_height"

///|
pub fn planned_source_image_height(image_id : Int) -> Int {
  moonbit_planned_source_image_height(image_id)
}

///|
extern "C" fn moonbit_planned_source_image_generation(image_id : Int) -> Int = "moonbit_planned_source_image_generation"

///|
pub fn planned_source_image_generation(image_id : Int) -> Int {
  moonbit_planned_source_image_generation(image_id)
}

///|
extern "C" fn moonbit_planned_source_image_pixel_channel(
  image_id : Int,
  x : Int,
  y : Int,
  channel_index : Int,
) -> Int = "moonbit_planned_source_image_pixel_channel"

///|
pub fn planned_source_image_pixel_channel(
  image_id : Int,
  x : Int,
  y : Int,
  channel_index : Int,
) -> Int {
  moonbit_planned_source_image_pixel_channel(image_id, x, y, channel_index)
}

///|
extern "C" fn moonbit_push_planned_draw_command(
  draw_calls : Int,
  has_triangle_payload : Int,
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  cx : Double,
  cy : Double,
  au : Double,
  av : Double,
  bu : Double,
  bv : Double,
  cu : Double,
  cv : Double,
  uniform_r : Double,
  uniform_g : Double,
  uniform_b : Double,
  uniform_a : Double,
  texture_seed : Int,
) -> Unit = "moonbit_push_planned_draw_command"

///|
pub fn push_planned_draw_command(
  draw_calls : Int,
  has_triangle_payload : Int,
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  cx : Double,
  cy : Double,
  au : Double,
  av : Double,
  bu : Double,
  bv : Double,
  cu : Double,
  cv : Double,
  uniform_r : Double,
  uniform_g : Double,
  uniform_b : Double,
  uniform_a : Double,
  texture_seed : Int,
) -> Unit {
  moonbit_push_planned_draw_command(
    draw_calls, has_triangle_payload, ax, ay, bx, by, cx, cy, au, av, bu, bv, cu,
    cv, uniform_r, uniform_g, uniform_b, uniform_a, texture_seed,
  )
}

///|
extern "C" fn moonbit_render_frame_with_staged_plan(
  surface : WGPUSurface,
  device : WGPUDevice,
  queue : WGPUQueue,
  pipeline : WGPURenderPipeline,
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
) -> Unit = "moonbit_render_frame_with_staged_plan"

///|
pub fn render_frame_with_staged_plan(
  surface : WGPUSurface,
  device : WGPUDevice,
  queue : WGPUQueue,
  pipeline : WGPURenderPipeline,
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
) -> Unit {
  moonbit_render_frame_with_staged_plan(
    surface, device, queue, pipeline, clear_r, clear_g, clear_b, clear_a,
  )
}

///|
extern "C" fn moonbit_render_frame_with_plan_payload(
  surface : WGPUSurface,
  device : WGPUDevice,
  queue : WGPUQueue,
  pipeline : WGPURenderPipeline,
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
  draw_calls : Int,
  has_triangle_payload : Int,
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  cx : Double,
  cy : Double,
  au : Double,
  av : Double,
  bu : Double,
  bv : Double,
  cu : Double,
  cv : Double,
  uniform_r : Double,
  uniform_g : Double,
  uniform_b : Double,
  uniform_a : Double,
  texture_seed : Int,
) -> Unit = "moonbit_render_frame_with_plan_payload"

///|
// ===============================
// Readback API
// ===============================

extern "C" fn moonbit_read_pixels_available() -> Int = "moonbit_read_pixels_available"

///|
extern "C" fn moonbit_read_pixels_width() -> Int = "moonbit_read_pixels_width"

///|
extern "C" fn moonbit_read_pixels_height() -> Int = "moonbit_read_pixels_height"

///|
extern "C" fn moonbit_read_pixels_channel(offset : Int) -> Int = "moonbit_read_pixels_channel"

///|
pub fn read_pixels_available() -> Bool {
  moonbit_read_pixels_available() != 0
}

///|
pub fn read_pixels_width() -> Int {
  moonbit_read_pixels_width()
}

///|
pub fn read_pixels_height() -> Int {
  moonbit_read_pixels_height()
}

///|
pub fn read_pixels_channel(offset : Int) -> Int {
  moonbit_read_pixels_channel(offset)
}

///|
pub fn render_frame_with_plan_payload(
  surface : WGPUSurface,
  device : WGPUDevice,
  queue : WGPUQueue,
  pipeline : WGPURenderPipeline,
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
  draw_calls : Int,
  has_triangle_payload : Int,
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  cx : Double,
  cy : Double,
  au : Double,
  av : Double,
  bu : Double,
  bv : Double,
  cu : Double,
  cv : Double,
  uniform_r : Double,
  uniform_g : Double,
  uniform_b : Double,
  uniform_a : Double,
  texture_seed : Int,
) -> Unit {
  moonbit_render_frame_with_plan_payload(
    surface, device, queue, pipeline, clear_r, clear_g, clear_b, clear_a, draw_calls,
    has_triangle_payload, ax, ay, bx, by, cx, cy, au, av, bu, bv, cu, cv, uniform_r,
    uniform_g, uniform_b, uniform_a, texture_seed,
  )
}
