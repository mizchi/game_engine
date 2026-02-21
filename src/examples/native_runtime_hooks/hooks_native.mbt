///|
let runtime_title : Ref[String] = Ref::new("game_engine")

///|
priv struct SyncedSourceGeneration {
  image_id : Int
  generation : Int
}

///|
let synced_source_generations : Ref[Array[SyncedSourceGeneration]] = Ref::new([])

///|
let saw_native_touch_input : Ref[Bool] = Ref::new(false)

///|
let mouse_touch_fallback_enabled : Ref[Bool] = Ref::new(false)

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
fn reset_touch_capture_state() -> Unit {
  saw_native_touch_input.val = false
  mouse_touch_fallback_enabled.val = false
}

///|
fn bridge_desktop_set_mouse_touch_fallback(
  active : Bool,
  enabled : Bool,
) -> Unit {
  if active {
    mouse_touch_fallback_enabled.val = enabled
  }
}

///|
fn bridge_desktop_mouse_touch_fallback_enabled(active : Bool) -> Bool {
  if active {
    mouse_touch_fallback_enabled.val
  } else {
    false
  }
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
fn bridge_desktop_try_initialize(options : @platform.WindowOptions) -> Bool {
  @wgpu_native.ensure_runtime_context(
    options.width,
    options.height,
    options.title,
  )
}

///|
fn bridge_desktop_poll(active : Bool) -> Unit {
  if active {
    @wgpu_native.runtime_poll_events()
  }
}

///|
fn bridge_desktop_should_close() -> Bool {
  @wgpu_native.runtime_should_close()
}

///|
fn bridge_desktop_outside_size(width : Int, height : Int) -> @core.OutsideSize {
  let size = @wgpu_native.runtime_window_size(width, height)
  @core.new_outside_size(size.width.to_double(), size.height.to_double())
}

///|
fn bridge_desktop_capture_input(
  active : Bool,
  _tick : Int,
) -> @core.InputSnapshot {
  if active {
    let cursor_x = @wgpu_native.runtime_cursor_x()
    let cursor_y = @wgpu_native.runtime_cursor_y()
    let wheel_x = @wgpu_native.runtime_take_wheel_x()
    let wheel_y = @wgpu_native.runtime_take_wheel_y()

    let pressed_keys : Array[Int] = []
    let key_count = @wgpu_native.runtime_pressed_key_count()
    for i in 0..<key_count {
      let key = @wgpu_native.runtime_pressed_key_at(i)
      if key >= 0 {
        pressed_keys.push(key)
      }
    }
    let pressed_mouse_buttons : Array[Int] = []
    let mouse_button_count = @wgpu_native.runtime_pressed_mouse_button_count()
    for i in 0..<mouse_button_count {
      let button = @wgpu_native.runtime_pressed_mouse_button_at(i)
      if button >= 0 {
        pressed_mouse_buttons.push(button)
      }
    }

    let touches : Array[@core.TouchPoint] = []
    let touch_count = @wgpu_native.runtime_touch_count()
    for i in 0..<touch_count {
      let touch_id = @wgpu_native.runtime_touch_id_at(i)
      if touch_id >= 0 {
        let touch_type = @wgpu_native.runtime_touch_type_at(i)
        touches.push(
          @core.new_touch_point_with_source(
            touch_id,
            @wgpu_native.runtime_touch_x_at(i),
            @wgpu_native.runtime_touch_y_at(i),
            @core.touch_source_from_int(touch_type),
          ),
        )
      }
    }
    let resolved_touches = resolve_touch_points_with_mouse_fallback(
      touches,
      pressed_mouse_buttons,
      cursor_x,
      cursor_y,
      saw_native_touch_input.val,
      mouse_touch_fallback_enabled.val,
    )
    saw_native_touch_input.val = resolved_touches.saw_native_touch

    let gamepads : Array[@core.GamepadSnapshot] = []
    let gamepad_count = @wgpu_native.runtime_gamepad_count()
    for i in 0..<gamepad_count {
      let gamepad_id = @wgpu_native.runtime_gamepad_id_at(i)
      if gamepad_id >= 0 {
        let axes : Array[Double] = []
        let axis_count = @wgpu_native.runtime_gamepad_axis_count(i)
        for j in 0..<axis_count {
          axes.push(@wgpu_native.runtime_gamepad_axis_at(i, j))
        }
        let pressed_buttons : Array[Int] = []
        let button_count = @wgpu_native.runtime_gamepad_pressed_button_count(i)
        for j in 0..<button_count {
          let button = @wgpu_native.runtime_gamepad_pressed_button_at(i, j)
          if button >= 0 {
            pressed_buttons.push(button)
          }
        }
        gamepads.push(
          @core.new_gamepad_snapshot(gamepad_id, axes, pressed_buttons),
        )
      }
    }

    @core.new_input_snapshot_full(
      cursor_x,
      cursor_y,
      wheel_x,
      wheel_y,
      pressed_keys,
      pressed_mouse_buttons,
      resolved_touches.touches,
      gamepads,
    )
  } else {
    @core.empty_input_snapshot()
  }
}

///|
fn bridge_desktop_set_fullscreen(active : Bool, enabled : Bool) -> Bool {
  if active {
    @wgpu_native.runtime_set_fullscreen(enabled)
  } else {
    enabled
  }
}

///|
fn bridge_desktop_is_fullscreen(active : Bool, current : Bool) -> Bool {
  if active {
    @wgpu_native.runtime_is_fullscreen()
  } else {
    current
  }
}

///|
fn bridge_desktop_set_cursor_mode(
  active : Bool,
  mode : @platform.CursorMode,
) -> @platform.CursorMode {
  if active {
    @platform.cursor_mode_from_int(
      @wgpu_native.runtime_set_cursor_mode(@platform.cursor_mode_to_int(mode)),
    )
  } else {
    mode
  }
}

///|
fn bridge_desktop_cursor_mode(
  active : Bool,
  current : @platform.CursorMode,
) -> @platform.CursorMode {
  if active {
    @platform.cursor_mode_from_int(@wgpu_native.runtime_cursor_mode())
  } else {
    current
  }
}

///|
fn bridge_desktop_set_device_scale_factor(
  active : Bool,
  scale : Double,
) -> Double {
  if active {
    @wgpu_native.runtime_set_device_scale_factor(scale)
  } else if scale <= 0.0 {
    1.0
  } else {
    scale
  }
}

///|
fn bridge_desktop_device_scale_factor(
  active : Bool,
  current : Double,
) -> Double {
  if active {
    @wgpu_native.runtime_device_scale_factor(current)
  } else if current <= 0.0 {
    1.0
  } else {
    current
  }
}

///|
fn bridge_desktop_set_vsync_enabled(active : Bool, enabled : Bool) -> Bool {
  if active {
    @wgpu_native.runtime_set_vsync_enabled(enabled)
  } else {
    enabled
  }
}

///|
fn bridge_desktop_is_vsync_enabled(active : Bool, current : Bool) -> Bool {
  if active {
    @wgpu_native.runtime_is_vsync_enabled()
  } else {
    current
  }
}

///|
fn bridge_desktop_close_window(active : Bool) -> Unit {
  if active {
    @wgpu_native.runtime_request_close()
  }
}

///|
fn bridge_desktop_request_attention(active : Bool) -> Unit {
  if active {
    @wgpu_native.runtime_request_attention()
  }
}

///|
fn bridge_gfx_try_initialize(width : Int, height : Int) -> Bool {
  @wgpu_native.ensure_runtime_context(width, height, runtime_title.val)
}

///|
fn bridge_gfx_on_begin(active : Bool, pass : @gfx.RenderPassDesc) -> Unit {
  if active {
    @wgpu_native.runtime_begin_frame(
      pass.clear_color.r,
      pass.clear_color.g,
      pass.clear_color.b,
      pass.clear_color.a,
    )
  }
}

///|
fn bridge_gfx_on_end(active : Bool, present : Bool) -> Unit {
  if active && present {
    let _ = @wgpu_native.runtime_present_planned_frame()
  }
}

///|
fn bridge_gfx_on_draw(
  active : Bool,
  command : @gfx.DrawTrianglesCommand,
) -> Unit {
  if active {
    let dispatch = @gfx.build_draw_command_dispatch(command)
    // Split draw command into individual triangles (3 indices each).
    // Each triangle needs its own command entry paired with its payload,
    // because runtime_record_draw_triangle_payload overwrites the last
    // entry in planned_draw_commands. Without per-triangle command entries,
    // quads (4 vertices, 6 indices = 2 triangles) would lose their first
    // triangle's payload.
    let indices = command.indices
    let tri_count = indices.length() / 3
    for t = 0; t < tri_count; t = t + 1 {
      @wgpu_native.runtime_record_draw_command(
        1,
        dispatch.pipeline_id,
        dispatch.uniform_hash,
        dispatch.blend_mode,
        dispatch.dst_image_id,
        dispatch.shader_id,
        dispatch.index_offset,
        1,
        3,
        dispatch.vertex_float_count,
        3,
        dispatch.src_image_count,
        dispatch.uniform_dword_count,
      )
      let base = t * 3
      let sub_indices = [indices[base], indices[base + 1], indices[base + 2]]
      let payload = @payload2d.decode_triangle_payload(
        command.vertex_data,
        sub_indices,
        command.uniform_dwords,
        command.src_image_ids,
      )
      if payload.has_payload {
        @wgpu_native.runtime_record_draw_triangle_payload(
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
  }
}

///|
fn bridge_gfx_on_resize(active : Bool, width : Int, height : Int) -> Unit {
  if active {
    let _ = @wgpu_native.runtime_resize_surface(width, height)
  }
}

///|
fn bridge_gfx_on_read_pixels(
  active : Bool,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Array[Int]? {
  if active {
    @wgpu_native.runtime_read_pixels(x, y, width, height)
  } else {
    None
  }
}

///|
fn bridge_gfx_on_new_image(
  active : Bool,
  image_id : Int,
  width : Int,
  height : Int,
) -> Unit {
  if active {
    @wgpu_native.register_offscreen_target(image_id, width, height)
  }
}

///|
fn palette_channel_or_zero(
  palette : @image_palette.ImagePalette2x2,
  pixel_index : Int,
  channel_index : Int,
) -> Int {
  let value = @image_palette.palette_channel(
    palette, pixel_index, channel_index,
  )
  if value < 0 {
    0
  } else {
    value
  }
}

///|
pub fn register_source_image_palette(
  source_image_id : Int,
  palette : @image_palette.ImagePalette2x2,
) -> Unit {
  @wgpu_native.runtime_register_source_image_palette(
    source_image_id,
    palette_channel_or_zero(palette, 0, 0),
    palette_channel_or_zero(palette, 0, 1),
    palette_channel_or_zero(palette, 0, 2),
    palette_channel_or_zero(palette, 0, 3),
    palette_channel_or_zero(palette, 1, 0),
    palette_channel_or_zero(palette, 1, 1),
    palette_channel_or_zero(palette, 1, 2),
    palette_channel_or_zero(palette, 1, 3),
    palette_channel_or_zero(palette, 2, 0),
    palette_channel_or_zero(palette, 2, 1),
    palette_channel_or_zero(palette, 2, 2),
    palette_channel_or_zero(palette, 2, 3),
    palette_channel_or_zero(palette, 3, 0),
    palette_channel_or_zero(palette, 3, 1),
    palette_channel_or_zero(palette, 3, 2),
    palette_channel_or_zero(palette, 3, 3),
  )
  if source_image_id >= 0 {
    drop_synced_source_generation(source_image_id)
  }
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
  @wgpu_native.runtime_register_source_image_rgba8(
    source_image_id, width, height, rgba8_channels,
  )
  if source_image_id >= 0 {
    drop_synced_source_generation(source_image_id)
  }
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
  @wgpu_native.runtime_patch_source_image_rgba8(
    source_image_id, width, height, dirty_x, dirty_y, dirty_width, dirty_height,
    rgba8_channels,
  )
}

///|
pub fn clear_source_image_palettes() -> Unit {
  @wgpu_native.runtime_clear_source_image_registry()
  clear_synced_source_generations()
}

///|
pub fn sync_source_image_palettes(
  bindings : Array[@asset.ImagePaletteBinding],
) -> Int {
  let mut count = 0
  for binding in bindings {
    register_source_image_palette(binding.image_id, binding.palette)
    count = count + 1
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
    let required_channels = binding.width * binding.height * 4
    if required_channels > 0 &&
      binding.pixels_rgba8.length() >= required_channels {
      let mut patched = false
      match binding.dirty_rect {
        Some(rect) => {
          let full_rect = rect.x <= 0 &&
            rect.y <= 0 &&
            rect.width >= binding.width &&
            rect.height >= binding.height
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
  let synced = sync_source_images(
    @asset.list_dirty_source_image_bindings(repository),
  )
  let _ = @asset.clear_source_image_dirty_flags(repository)
  synced
}

///|
pub fn sync_dirty_atlas_pages_from_repository(
  repository : @asset.SimpleAtlasImageRepository,
) -> Int {
  let synced = sync_source_images(
    @asset.list_dirty_atlas_page_bindings(repository),
  )
  let _ = @asset.clear_dirty_atlas_page_flags(repository)
  synced
}

///|
pub fn install(title : String) -> Unit {
  runtime_title.val = title
  clear_synced_source_generations()
  reset_touch_capture_state()
  @platform.set_desktop_native_hooks(
    @platform.new_desktop_native_hooks(
      bridge_desktop_try_initialize, bridge_desktop_poll, bridge_desktop_should_close,
      bridge_desktop_outside_size, bridge_desktop_capture_input, bridge_desktop_set_fullscreen,
      bridge_desktop_is_fullscreen, bridge_desktop_set_cursor_mode, bridge_desktop_cursor_mode,
      bridge_desktop_set_device_scale_factor, bridge_desktop_device_scale_factor,
      bridge_desktop_set_vsync_enabled, bridge_desktop_is_vsync_enabled, bridge_desktop_close_window,
      bridge_desktop_request_attention,
      bridge_desktop_set_mouse_touch_fallback,
      bridge_desktop_mouse_touch_fallback_enabled,
    ),
  )
  @gfx.set_native_graphics_hooks(
    @gfx.new_native_graphics_hooks_full(
      bridge_gfx_try_initialize, bridge_gfx_on_begin, bridge_gfx_on_end, bridge_gfx_on_draw,
      bridge_gfx_on_resize, bridge_gfx_on_read_pixels, bridge_gfx_on_new_image,
    ),
  )
  @text.set_font_load_hooks(@text.new_font_load_hooks(bridge_load_font_data))
  @audio.set_audio_output_hooks(
    @audio.new_audio_output_hooks_full(
      bridge_audio_try_initialize,
      bridge_audio_write_frames,
      bridge_audio_suspend,
      bridge_audio_resume,
      bridge_audio_close,
      bridge_audio_output_latency,
    ),
  )
}

///|
fn bridge_load_font_data(name : String) -> Array[Int]? {
  @wgpu_native.runtime_load_font_data(name)
}

// ---------------------------------------------------------------------------
// Audio bridge (miniaudio native backend)
// ---------------------------------------------------------------------------

///|
fn bridge_audio_try_initialize(format : @audio.AudioFormat) -> Bool {
  @wgpu_native.runtime_audio_try_initialize(format.sample_rate, format.channels)
}

///|
fn bridge_audio_write_frames(
  output : FixedArray[Float],
  frames : Int,
) -> Int {
  @wgpu_native.runtime_audio_write_frames(output, frames)
}

///|
fn bridge_audio_suspend() -> Unit {
  @wgpu_native.runtime_audio_suspend()
}

///|
fn bridge_audio_resume() -> Unit {
  @wgpu_native.runtime_audio_resume()
}

///|
fn bridge_audio_close() -> Unit {
  @wgpu_native.runtime_audio_close()
}

///|
fn bridge_audio_output_latency() -> Double {
  @wgpu_native.runtime_audio_output_latency()
}

///|
pub fn uninstall() -> Unit {
  clear_synced_source_generations()
  reset_touch_capture_state()
  @gfx.reset_native_graphics_hooks()
  @platform.reset_desktop_native_hooks()
  @text.reset_font_load_hooks()
  @audio.reset_audio_output_hooks()
}

///|
pub fn is_ready() -> Bool {
  @wgpu_native.has_runtime_context()
}

///|
pub fn shutdown() -> Unit {
  @wgpu_native.shutdown_runtime_context()
}

///|
pub fn initialize_context(width : Int, height : Int, title : String) -> Bool {
  install(title)
  @wgpu_native.ensure_runtime_context(width, height, title)
}

///|
pub fn should_close() -> Bool {
  @wgpu_native.runtime_should_close()
}

///|
pub fn poll_events() -> Unit {
  @wgpu_native.runtime_poll_events()
}

///|
pub fn render_frame() -> Bool {
  @wgpu_native.runtime_render_frame()
}

///|
pub fn shutdown_context() -> Unit {
  shutdown()
  uninstall()
}
