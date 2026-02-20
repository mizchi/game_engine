///|
let web_canvas_selector : Ref[String] = Ref::new("#app")

///|
let web_hooks_installed : Ref[Bool] = Ref::new(false)

///|
let web_fullscreen_state : Ref[Bool] = Ref::new(false)

///|
let web_cursor_mode_state : Ref[Int] = Ref::new(0)

///|
let web_device_scale_state : Ref[Double] = Ref::new(1.0)

///|
let web_vsync_state : Ref[Bool] = Ref::new(true)

///|
let web_close_requested : Ref[Bool] = Ref::new(false)

///|
let web_attention_requests : Ref[Int] = Ref::new(0)

///|
priv struct SyncedSourceGeneration {
  image_id : Int
  generation : Int
}

///|
priv struct SourceImageCacheEntry {
  image_id : Int
  width : Int
  height : Int
  pixels_rgba8 : Array[Int]
}

///|
let synced_source_generations : Ref[Array[SyncedSourceGeneration]] = Ref::new([])

///|
let source_image_cache : Ref[Array[SourceImageCacheEntry]] = Ref::new([])

///|
fn normalized_size(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
fn normalized_source_generation(generation : Int) -> Int {
  if generation <= 0 {
    1
  } else {
    generation
  }
}

///|
fn synced_source_generation_at(image_id : Int) -> Int {
  let mut generation = 0
  for entry in synced_source_generations.val {
    if entry.image_id == image_id {
      generation = entry.generation
    }
  }
  generation
}

///|
fn set_synced_source_generation(image_id : Int, generation : Int) -> Unit {
  let next : Array[SyncedSourceGeneration] = []
  let mut replaced = false
  let safe_generation = normalized_source_generation(generation)
  for entry in synced_source_generations.val {
    if entry.image_id == image_id {
      next.push({ image_id, generation: safe_generation })
      replaced = true
    } else {
      next.push(entry)
    }
  }
  if !replaced {
    next.push({ image_id, generation: safe_generation })
  }
  synced_source_generations.val = next
}

///|
fn clear_synced_source_generations() -> Unit {
  synced_source_generations.val = []
}

///|
fn drop_synced_source_generation(image_id : Int) -> Unit {
  let next : Array[SyncedSourceGeneration] = []
  for entry in synced_source_generations.val {
    if entry.image_id != image_id {
      next.push(entry)
    }
  }
  synced_source_generations.val = next
}

///|
fn expected_rgba8_channel_count(width : Int, height : Int) -> Int {
  normalized_size(width) * normalized_size(height) * 4
}

///|
fn has_valid_rgba8_payload(
  rgba8_channels : Array[Int],
  width : Int,
  height : Int,
) -> Bool {
  let expected = expected_rgba8_channel_count(width, height)
  expected > 0 && rgba8_channels.length() >= expected
}

///|
fn clamp_u8_channel(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn normalized_rgba8_channels(
  rgba8_channels : Array[Int],
  width : Int,
  height : Int,
) -> Array[Int] {
  let expected = expected_rgba8_channel_count(width, height)
  let out : Array[Int] = []
  if expected <= 0 || rgba8_channels.length() < expected {
    out
  } else {
    for i in 0..<expected {
      out.push(clamp_u8_channel(rgba8_channels[i]))
    }
    out
  }
}

///|
fn source_image_cache_entry_at(image_id : Int) -> SourceImageCacheEntry? {
  let mut out : SourceImageCacheEntry? = None
  for entry in source_image_cache.val {
    if entry.image_id == image_id {
      out = Some(entry)
    }
  }
  out
}

///|
fn set_source_image_cache_entry(next_entry : SourceImageCacheEntry) -> Unit {
  let next : Array[SourceImageCacheEntry] = []
  let mut replaced = false
  for entry in source_image_cache.val {
    if entry.image_id == next_entry.image_id {
      next.push(next_entry)
      replaced = true
    } else {
      next.push(entry)
    }
  }
  if !replaced {
    next.push(next_entry)
  }
  source_image_cache.val = next
}

///|
fn clear_source_image_cache() -> Unit {
  source_image_cache.val = []
}

///|
fn bool_to_int(value : Bool) -> Int {
  if value {
    1
  } else {
    0
  }
}

///|
fn int_to_bool(value : Int) -> Bool {
  value != 0
}

///|
fn backend_kind_to_int(kind : @gfx.GraphicsBackendKind) -> Int {
  match kind {
    @gfx.GraphicsBackendKind::WgpuNative => 0
    @gfx.GraphicsBackendKind::WebGpu => 1
    @gfx.GraphicsBackendKind::WebGl2 => 2
    @gfx.GraphicsBackendKind::Null => 3
  }
}

///|
extern "wasm" fn host_prepare_surface(width : Int, height : Int) -> Int = "game_engine_web" "prepare_surface"

///|
extern "wasm" fn host_surface_kind() -> Int = "game_engine_web" "surface_kind"

///|
extern "wasm" fn host_surface_id() -> Int = "game_engine_web" "surface_id"

///|
extern "wasm" fn host_surface_width(fallback_width : Int) -> Int = "game_engine_web" "surface_width"

///|
extern "wasm" fn host_surface_height(fallback_height : Int) -> Int = "game_engine_web" "surface_height"

///|
extern "wasm" fn host_surface_dpr() -> Double = "game_engine_web" "surface_dpr"

///|
extern "wasm" fn host_should_close() -> Int = "game_engine_web" "should_close"

///|
extern "wasm" fn host_gfx_try_initialize(
  kind : Int,
  width : Int,
  height : Int,
) -> Int = "game_engine_web" "gfx_try_initialize"

///|
extern "wasm" fn host_gfx_begin(
  kind : Int,
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
) -> Unit = "game_engine_web" "gfx_begin"

///|
extern "wasm" fn host_gfx_draw(
  kind : Int,
  draw_calls : Int,
  pipeline_id : Int,
  uniform_hash : Int,
  blend_mode : Int,
  dst_image_id : Int,
  shader_id : Int,
  index_offset : Int,
  region_count : Int,
  total_index_count : Int,
  vertex_float_count : Int,
  index_count : Int,
  src_image_count : Int,
  uniform_dword_count : Int,
  payload_has_triangle : Int,
  payload_ax : Double,
  payload_ay : Double,
  payload_bx : Double,
  payload_by : Double,
  payload_cx : Double,
  payload_cy : Double,
  payload_au : Double,
  payload_av : Double,
  payload_bu : Double,
  payload_bv : Double,
  payload_cu : Double,
  payload_cv : Double,
  payload_uniform_r : Double,
  payload_uniform_g : Double,
  payload_uniform_b : Double,
  payload_uniform_a : Double,
  payload_texture_seed : Int,
) -> Unit = "game_engine_web" "gfx_draw"

///|
extern "wasm" fn host_gfx_end(kind : Int, present : Int) -> Unit = "game_engine_web" "gfx_end"

///|
extern "wasm" fn host_shutdown() -> Unit = "game_engine_web" "shutdown"

///|
extern "wasm" fn host_gfx_read_pixels_begin(
  kind : Int,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
) -> Int = "game_engine_web" "gfx_read_pixels_begin"

///|
extern "wasm" fn host_gfx_read_pixels_channel(offset : Int) -> Int = "game_engine_web" "gfx_read_pixels_channel"

///|
extern "wasm" fn host_gfx_read_pixels_end() -> Unit = "game_engine_web" "gfx_read_pixels_end"

///|
fn bridge_web_try_initialize(
  canvas_selector : String,
  options : @platform.WindowOptions,
) -> Bool {
  web_hooks_installed.val &&
  canvas_selector == web_canvas_selector.val &&
  int_to_bool(host_prepare_surface(options.width, options.height))
}

///|
fn bridge_web_poll(_active : Bool) -> Unit {
  ()
}

///|
fn bridge_web_should_close() -> Bool {
  web_close_requested.val || int_to_bool(host_should_close())
}

///|
fn bridge_web_outside_size(width : Int, height : Int) -> @core.OutsideSize {
  let _ = host_prepare_surface(width, height)
  @core.new_outside_size(width.to_double(), height.to_double())
}

///|
fn bridge_web_current_surface(
  _canvas_selector : String,
  options : @platform.WindowOptions,
) -> @platform.SurfaceToken {
  let _ = host_prepare_surface(options.width, options.height)
  let surface_id = host_surface_id()
  let surface_width = host_surface_width(options.width)
  let surface_height = host_surface_height(options.height)
  let surface_dpr = host_surface_dpr()
  match host_surface_kind() {
    1 =>
      @platform.create_webgl_surface_token(
        surface_id, surface_width, surface_height, surface_dpr,
      )
    _ =>
      @platform.create_webgpu_surface_token(
        surface_id, surface_width, surface_height, surface_dpr,
      )
  }
}

///|
fn bridge_web_capture_input(_active : Bool, _tick : Int) -> @core.InputSnapshot {
  @core.empty_input_snapshot()
}

///|
fn bridge_web_set_fullscreen(
  _canvas_selector : String,
  active : Bool,
  enabled : Bool,
) -> Bool {
  if active {
    web_fullscreen_state.val = enabled
  }
  web_fullscreen_state.val
}

///|
fn bridge_web_is_fullscreen(
  _canvas_selector : String,
  active : Bool,
  current : Bool,
) -> Bool {
  if active {
    web_fullscreen_state.val
  } else {
    current
  }
}

///|
fn bridge_web_set_cursor_mode(
  _canvas_selector : String,
  active : Bool,
  mode : @platform.CursorMode,
) -> @platform.CursorMode {
  if active {
    web_cursor_mode_state.val = @platform.cursor_mode_to_int(mode)
  }
  @platform.cursor_mode_from_int(web_cursor_mode_state.val)
}

///|
fn bridge_web_cursor_mode(
  _canvas_selector : String,
  active : Bool,
  current : @platform.CursorMode,
) -> @platform.CursorMode {
  if active {
    @platform.cursor_mode_from_int(web_cursor_mode_state.val)
  } else {
    current
  }
}

///|
fn bridge_web_set_device_scale_factor(
  _canvas_selector : String,
  active : Bool,
  scale : Double,
) -> Double {
  let normalized = if scale <= 0.0 { 1.0 } else { scale }
  if active {
    web_device_scale_state.val = normalized
  }
  web_device_scale_state.val
}

///|
fn bridge_web_device_scale_factor(
  _canvas_selector : String,
  active : Bool,
  current : Double,
) -> Double {
  if active {
    web_device_scale_state.val
  } else if current <= 0.0 {
    1.0
  } else {
    current
  }
}

///|
fn bridge_web_set_vsync_enabled(
  _canvas_selector : String,
  active : Bool,
  enabled : Bool,
) -> Bool {
  if active {
    web_vsync_state.val = enabled
  }
  web_vsync_state.val
}

///|
fn bridge_web_is_vsync_enabled(
  _canvas_selector : String,
  active : Bool,
  current : Bool,
) -> Bool {
  if active {
    web_vsync_state.val
  } else {
    current
  }
}

///|
fn bridge_web_close_window(_canvas_selector : String, active : Bool) -> Unit {
  if active {
    web_close_requested.val = true
  }
}

///|
fn bridge_web_request_attention(
  _canvas_selector : String,
  active : Bool,
) -> Unit {
  if active {
    web_attention_requests.val = web_attention_requests.val + 1
  }
}

///|
fn bridge_web_gfx_try_initialize(
  kind : @gfx.GraphicsBackendKind,
  width : Int,
  height : Int,
) -> Bool {
  if !web_hooks_installed.val {
    false
  } else {
    int_to_bool(
      host_gfx_try_initialize(backend_kind_to_int(kind), width, height),
    )
  }
}

///|
fn bridge_web_gfx_on_begin(
  active : Bool,
  kind : @gfx.GraphicsBackendKind,
  pass : @gfx.RenderPassDesc,
) -> Unit {
  if active {
    host_gfx_begin(
      backend_kind_to_int(kind),
      pass.clear_color.r,
      pass.clear_color.g,
      pass.clear_color.b,
      pass.clear_color.a,
    )
  }
}

///|
fn bridge_web_gfx_on_end(
  active : Bool,
  kind : @gfx.GraphicsBackendKind,
  present : Bool,
) -> Unit {
  if active {
    host_gfx_end(backend_kind_to_int(kind), bool_to_int(present))
  }
}

///|
fn bridge_web_gfx_on_draw(
  active : Bool,
  kind : @gfx.GraphicsBackendKind,
  command : @gfx.DrawTrianglesCommand,
) -> Unit {
  if active {
    let dispatch = @gfx.build_draw_command_dispatch(command)
    let payload = @payload2d.decode_triangle_payload(
      command.vertex_data,
      command.indices,
      command.uniform_dwords,
      command.src_image_ids,
    )
    let payload_has_triangle = if payload.has_payload { 1 } else { 0 }
    host_gfx_draw(
      backend_kind_to_int(kind),
      dispatch.draw_calls,
      dispatch.pipeline_id,
      dispatch.uniform_hash,
      dispatch.blend_mode,
      dispatch.dst_image_id,
      dispatch.shader_id,
      dispatch.index_offset,
      dispatch.region_count,
      dispatch.total_index_count,
      dispatch.vertex_float_count,
      dispatch.index_count,
      dispatch.src_image_count,
      dispatch.uniform_dword_count,
      payload_has_triangle,
      payload.ax,
      payload.ay,
      payload.bx,
      payload.by,
      payload.cx,
      payload.cy,
      payload.au,
      payload.av,
      payload.bu,
      payload.bv,
      payload.cu,
      payload.cv,
      payload.uniform_r,
      payload.uniform_g,
      payload.uniform_b,
      payload.uniform_a,
      payload.texture_seed,
    )
  }
}

///|
fn bridge_web_gfx_on_resize(
  active : Bool,
  kind : @gfx.GraphicsBackendKind,
  width : Int,
  height : Int,
) -> Unit {
  if active {
    let _ = kind
    let _ = host_prepare_surface(width, height)
  }
}

///|
fn bridge_web_gfx_on_read_pixels(
  active : Bool,
  kind : @gfx.GraphicsBackendKind,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Array[Int]? {
  if !active || !web_hooks_installed.val {
    return None
  }
  let pixel_count = host_gfx_read_pixels_begin(
    backend_kind_to_int(kind), x, y, width, height,
  )
  if pixel_count <= 0 {
    host_gfx_read_pixels_end()
    return None
  }
  let channel_count = pixel_count * 4
  let result : Array[Int] = []
  for i in 0..<channel_count {
    result.push(host_gfx_read_pixels_channel(i))
  }
  host_gfx_read_pixels_end()
  Some(result)
}

///|
pub fn install(canvas_selector : String) -> Unit {
  web_canvas_selector.val = canvas_selector
  web_hooks_installed.val = true
  web_fullscreen_state.val = false
  web_cursor_mode_state.val = 0
  web_device_scale_state.val = 1.0
  web_vsync_state.val = true
  web_close_requested.val = false
  web_attention_requests.val = 0
  clear_source_image_cache()
  clear_synced_source_generations()
  @platform.set_web_canvas_hooks(
    @platform.new_web_canvas_hooks(
      bridge_web_try_initialize, bridge_web_poll, bridge_web_should_close, bridge_web_outside_size,
      bridge_web_current_surface, bridge_web_capture_input, bridge_web_set_fullscreen,
      bridge_web_is_fullscreen, bridge_web_set_cursor_mode, bridge_web_cursor_mode,
      bridge_web_set_device_scale_factor, bridge_web_device_scale_factor, bridge_web_set_vsync_enabled,
      bridge_web_is_vsync_enabled, bridge_web_close_window, bridge_web_request_attention,
    ),
  )
  @gfx.set_web_graphics_hooks(
    @gfx.new_web_graphics_hooks_full(
      bridge_web_gfx_try_initialize, bridge_web_gfx_on_begin, bridge_web_gfx_on_end,
      bridge_web_gfx_on_draw, bridge_web_gfx_on_resize, bridge_web_gfx_on_read_pixels,
    ),
  )
}

///|
pub fn uninstall() -> Unit {
  web_hooks_installed.val = false
  web_close_requested.val = false
  clear_source_image_cache()
  clear_synced_source_generations()
  host_shutdown()
  @gfx.reset_web_graphics_hooks()
  @platform.reset_web_canvas_hooks()
}

///|
pub fn is_ready() -> Bool {
  web_hooks_installed.val
}

///|
pub fn shutdown() -> Unit {
  uninstall()
}

///|
pub fn register_source_image_palette(
  source_image_id : Int,
  _palette : @image_palette.ImagePalette2x2,
) -> Unit {
  if source_image_id < 0 {
    return
  }
  let mut width = 1
  let mut height = 1
  let mut pixels_rgba8 : Array[Int] = []
  match source_image_cache_entry_at(source_image_id) {
    Some(entry) => {
      width = entry.width
      height = entry.height
      pixels_rgba8 = entry.pixels_rgba8
    }
    None => ()
  }
  set_source_image_cache_entry({
    image_id: source_image_id,
    width,
    height,
    pixels_rgba8,
  })
  drop_synced_source_generation(source_image_id)
}

///|
pub fn register_source_image_solid_color(
  source_image_id : Int,
  color : @image_palette.Rgba,
) -> Unit {
  register_source_image_palette(
    source_image_id,
    @image_palette.new_solid_palette(color),
  )
}

///|
pub fn register_source_image_rgba8(
  source_image_id : Int,
  width : Int,
  height : Int,
  rgba8_channels : Array[Int],
) -> Unit {
  if source_image_id < 0 {
    return
  }
  let safe_width = normalized_size(width)
  let safe_height = normalized_size(height)
  let pixels_rgba8 = normalized_rgba8_channels(
    rgba8_channels, safe_width, safe_height,
  )
  if pixels_rgba8.length() == 0 {
    return
  }
  set_source_image_cache_entry({
    image_id: source_image_id,
    width: safe_width,
    height: safe_height,
    pixels_rgba8,
  })
  drop_synced_source_generation(source_image_id)
}

///|
pub fn patch_source_image_rgba8(
  source_image_id : Int,
  width : Int,
  height : Int,
  dirty_x : Int,
  dirty_y : Int,
  dirty_width : Int,
  dirty_height : Int,
  rgba8_channels : Array[Int],
) -> Bool {
  if source_image_id < 0 {
    return false
  }
  let safe_width = normalized_size(width)
  let safe_height = normalized_size(height)
  if !has_valid_rgba8_payload(rgba8_channels, safe_width, safe_height) {
    return false
  }
  match source_image_cache_entry_at(source_image_id) {
    Some(entry) =>
      if entry.width != safe_width ||
        entry.height != safe_height ||
        !has_valid_rgba8_payload(entry.pixels_rgba8, safe_width, safe_height) {
        false
      } else {
        let x0 = if dirty_x < 0 {
          0
        } else if dirty_x > safe_width {
          safe_width
        } else {
          dirty_x
        }
        let y0 = if dirty_y < 0 {
          0
        } else if dirty_y > safe_height {
          safe_height
        } else {
          dirty_y
        }
        let x1_raw = dirty_x + dirty_width
        let y1_raw = dirty_y + dirty_height
        let x1 = if x1_raw < 0 {
          0
        } else if x1_raw > safe_width {
          safe_width
        } else {
          x1_raw
        }
        let y1 = if y1_raw < 0 {
          0
        } else if y1_raw > safe_height {
          safe_height
        } else {
          y1_raw
        }
        if x1 <= x0 || y1 <= y0 {
          false
        } else {
          let next_pixels = entry.pixels_rgba8
          for y in y0..<y1 {
            for x in x0..<x1 {
              let base = (y * safe_width + x) * 4
              next_pixels[base] = clamp_u8_channel(rgba8_channels[base])
              next_pixels[base + 1] = clamp_u8_channel(rgba8_channels[base + 1])
              next_pixels[base + 2] = clamp_u8_channel(rgba8_channels[base + 2])
              next_pixels[base + 3] = clamp_u8_channel(rgba8_channels[base + 3])
            }
          }
          set_source_image_cache_entry({
            image_id: source_image_id,
            width: safe_width,
            height: safe_height,
            pixels_rgba8: next_pixels,
          })
          drop_synced_source_generation(source_image_id)
          true
        }
      }
    None => false
  }
}

///|
pub fn clear_source_image_palettes() -> Unit {
  clear_source_image_cache()
  clear_synced_source_generations()
}

///|
pub fn sync_source_image_palettes(
  bindings : Array[@asset.ImagePaletteBinding],
) -> Int {
  let mut count = 0
  for binding in bindings {
    if binding.image_id >= 0 {
      register_source_image_palette(binding.image_id, binding.palette)
      count = count + 1
    }
  }
  count
}

///|
pub fn sync_source_image_palettes_from_repository(
  repository : @asset.SimpleImageRepository,
) -> Int {
  sync_source_image_palettes(@asset.list_image_palette_bindings(repository))
}

///|
pub fn sync_source_images(bindings : Array[@asset.SourceImageBinding]) -> Int {
  let mut count = 0
  for binding in bindings {
    if binding.image_id < 0 {
      continue
    }
    let generation = normalized_source_generation(binding.generation)
    if synced_source_generation_at(binding.image_id) == generation {
      continue
    }
    let required_channels = expected_rgba8_channel_count(
      binding.width,
      binding.height,
    )
    if required_channels > 0 &&
      binding.pixels_rgba8.length() >= required_channels {
      let mut patched = false
      match binding.dirty_rect {
        Some(rect) => {
          let full_rect = rect.x <= 0 &&
            rect.y <= 0 &&
            rect.width >= normalized_size(binding.width) &&
            rect.height >= normalized_size(binding.height)
          if !full_rect {
            patched = patch_source_image_rgba8(
              binding.image_id,
              binding.width,
              binding.height,
              rect.x,
              rect.y,
              rect.width,
              rect.height,
              binding.pixels_rgba8,
            )
          }
        }
        None => ()
      }
      if !patched {
        register_source_image_rgba8(
          binding.image_id,
          binding.width,
          binding.height,
          binding.pixels_rgba8,
        )
      }
    } else {
      register_source_image_palette(binding.image_id, binding.palette)
    }
    set_synced_source_generation(binding.image_id, generation)
    count = count + 1
  }
  count
}

///|
pub fn sync_source_images_from_repository(
  repository : @asset.SimpleImageRepository,
) -> Int {
  sync_source_images(@asset.list_source_image_bindings(repository))
}

///|
pub fn sync_dirty_source_images_from_repository(
  repository : @asset.SimpleImageRepository,
) -> Int {
  let count = sync_source_images(
    @asset.list_dirty_source_image_bindings(repository),
  )
  let _ = @asset.clear_source_image_dirty_flags(repository)
  count
}

///|
pub fn sync_dirty_atlas_pages_from_repository(
  repository : @asset.SimpleAtlasImageRepository,
) -> Int {
  let count = sync_source_images(
    @asset.list_dirty_atlas_page_bindings(repository),
  )
  let _ = @asset.clear_dirty_atlas_page_flags(repository)
  count
}

///|
pub fn source_image_cache_count() -> Int {
  source_image_cache.val.length()
}

///|
pub fn source_image_generation(image_id : Int) -> Int {
  synced_source_generation_at(image_id)
}

///|
pub fn source_image_width(image_id : Int) -> Int {
  match source_image_cache_entry_at(image_id) {
    Some(entry) => entry.width
    None => 0
  }
}

///|
pub fn source_image_height(image_id : Int) -> Int {
  match source_image_cache_entry_at(image_id) {
    Some(entry) => entry.height
    None => 0
  }
}

///|
pub fn source_image_pixel_channel(
  image_id : Int,
  x : Int,
  y : Int,
  channel_index : Int,
) -> Int {
  if channel_index < 0 || channel_index > 3 {
    return -1
  }
  match source_image_cache_entry_at(image_id) {
    Some(entry) =>
      if x < 0 || y < 0 || x >= entry.width || y >= entry.height {
        -1
      } else {
        let base = (y * entry.width + x) * 4
        let offset = base + channel_index
        if offset < 0 || offset >= entry.pixels_rgba8.length() {
          -1
        } else {
          entry.pixels_rgba8[offset]
        }
      }
    None => -1
  }
}
