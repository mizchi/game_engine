///|
let runtime_title : Ref[String] = Ref::new("game_engine")

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
        touches.push(
          @core.new_touch_point(
            touch_id,
            @wgpu_native.runtime_touch_x_at(i),
            @wgpu_native.runtime_touch_y_at(i),
          ),
        )
      }
    }
    if touches.length() == 0 {
      let mut left_button_pressed = false
      for button in pressed_mouse_buttons {
        if button == 0 {
          left_button_pressed = true
        }
      }
      if left_button_pressed {
        touches.push(@core.new_touch_point(0, cursor_x, cursor_y))
      }
    }

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
      cursor_x, cursor_y, wheel_x, wheel_y, pressed_keys, pressed_mouse_buttons,
      touches, gamepads,
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
    @wgpu_native.runtime_record_draw_command(
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
    )
    let payload = @payload2d.decode_triangle_payload(
      command.vertex_data,
      command.indices,
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

///|
pub fn install(title : String) -> Unit {
  runtime_title.val = title
  @platform.set_desktop_native_hooks(
    @platform.new_desktop_native_hooks(
      bridge_desktop_try_initialize, bridge_desktop_poll, bridge_desktop_should_close,
      bridge_desktop_outside_size, bridge_desktop_capture_input, bridge_desktop_set_fullscreen,
      bridge_desktop_is_fullscreen, bridge_desktop_set_cursor_mode, bridge_desktop_cursor_mode,
      bridge_desktop_set_device_scale_factor, bridge_desktop_device_scale_factor,
      bridge_desktop_set_vsync_enabled, bridge_desktop_is_vsync_enabled, bridge_desktop_close_window,
      bridge_desktop_request_attention,
    ),
  )
  @gfx.set_native_graphics_hooks(
    @gfx.new_native_graphics_hooks(
      bridge_gfx_try_initialize, bridge_gfx_on_begin, bridge_gfx_on_end, bridge_gfx_on_draw,
    ),
  )
}

///|
pub fn uninstall() -> Unit {
  @gfx.reset_native_graphics_hooks()
  @platform.reset_desktop_native_hooks()
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
