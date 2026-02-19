///|
/// Shared runtime context between platform and gfx native hooks.
///
/// Ebiten refs:
/// - internal/ui/ui_glfw.go (window/event lifecycle)
/// - internal/graphicsdriver/* (backend initialization and frame present)

///|
let runtime_context : Ref[TriangleContext?] = Ref::new(None)

///|
let planned_clear_r : Ref[Double] = Ref::new(0.1)

///|
let planned_clear_g : Ref[Double] = Ref::new(0.2)

///|
let planned_clear_b : Ref[Double] = Ref::new(0.3)

///|
let planned_clear_a : Ref[Double] = Ref::new(1.0)

///|
let planned_draw_calls : Ref[Int] = Ref::new(0)

///|
let planned_command_count : Ref[Int] = Ref::new(0)

///|
let planned_last_pipeline_id : Ref[Int] = Ref::new(0)

///|
let planned_last_uniform_hash : Ref[Int] = Ref::new(0)

///|
let planned_last_blend_mode : Ref[Int] = Ref::new(1)

///|
let planned_last_dst_image_id : Ref[Int] = Ref::new(0)

///|
let planned_last_shader_id : Ref[Int] = Ref::new(0)

///|
let planned_last_index_offset : Ref[Int] = Ref::new(0)

///|
let planned_last_region_count : Ref[Int] = Ref::new(0)

///|
let planned_last_total_index_count : Ref[Int] = Ref::new(0)

///|
let planned_last_vertex_float_count : Ref[Int] = Ref::new(0)

///|
let planned_last_index_count : Ref[Int] = Ref::new(0)

///|
let planned_last_src_image_count : Ref[Int] = Ref::new(0)

///|
let planned_last_uniform_dword_count : Ref[Int] = Ref::new(0)

///|
let planned_has_triangle_payload : Ref[Bool] = Ref::new(false)

///|
let planned_triangle_ax : Ref[Double] = Ref::new(0.0)

///|
let planned_triangle_ay : Ref[Double] = Ref::new(0.5)

///|
let planned_triangle_bx : Ref[Double] = Ref::new(-0.5)

///|
let planned_triangle_by : Ref[Double] = Ref::new(-0.5)

///|
let planned_triangle_cx : Ref[Double] = Ref::new(0.5)

///|
let planned_triangle_cy : Ref[Double] = Ref::new(-0.5)

///|
let planned_uv_au : Ref[Double] = Ref::new(0.0)

///|
let planned_uv_av : Ref[Double] = Ref::new(0.0)

///|
let planned_uv_bu : Ref[Double] = Ref::new(1.0)

///|
let planned_uv_bv : Ref[Double] = Ref::new(0.0)

///|
let planned_uv_cu : Ref[Double] = Ref::new(1.0)

///|
let planned_uv_cv : Ref[Double] = Ref::new(1.0)

///|
let planned_uniform_r : Ref[Double] = Ref::new(1.0)

///|
let planned_uniform_g : Ref[Double] = Ref::new(1.0)

///|
let planned_uniform_b : Ref[Double] = Ref::new(1.0)

///|
let planned_uniform_a : Ref[Double] = Ref::new(1.0)

///|
let planned_texture_seed : Ref[Int] = Ref::new(0)

///|
let configured_surface_width : Ref[Int] = Ref::new(0)

///|
let configured_surface_height : Ref[Int] = Ref::new(0)

///|
let runtime_vsync_enabled : Ref[Bool] = Ref::new(true)

///|
let runtime_device_scale_override : Ref[Double] = Ref::new(0.0)

///|
pub fn clamp_runtime_render_size(width : Int, height : Int) -> WindowSize {
  {
    width: if width <= 0 {
      1
    } else {
      width
    },
    height: if height <= 0 {
      1
    } else {
      height
    },
  }
}

///|
fn ensure_runtime_surface_size(
  ctx : TriangleContext,
  requested_width : Int,
  requested_height : Int,
) -> WindowSize {
  let size = clamp_runtime_render_size(requested_width, requested_height)
  if configured_surface_width.val != size.width ||
    configured_surface_height.val != size.height {
    reconfigure_triangle_surface(ctx, size.width, size.height)
    configured_surface_width.val = size.width
    configured_surface_height.val = size.height
  }
  size
}

///|
pub fn has_runtime_context() -> Bool {
  match runtime_context.val {
    Some(_) => true
    None => false
  }
}

///|
pub fn ensure_runtime_context(
  width : Int,
  height : Int,
  title : String,
) -> Bool {
  if has_runtime_context() {
    true
  } else {
    match try_init_triangle_context(width, height, title) {
      Some(ctx) => {
        let size = clamp_runtime_render_size(width, height)
        configured_surface_width.val = size.width
        configured_surface_height.val = size.height
        set_swap_interval(runtime_vsync_enabled.val)
        runtime_context.val = Some(ctx)
        true
      }
      None => false
    }
  }
}

///|
pub fn runtime_poll_events() -> Unit {
  match runtime_context.val {
    Some(ctx) => poll(ctx)
    None => ()
  }
}

///|
pub fn runtime_should_close() -> Bool {
  match runtime_context.val {
    Some(ctx) => !should_continue(ctx)
    None => false
  }
}

///|
pub fn runtime_window_size(
  fallback_width : Int,
  fallback_height : Int,
) -> WindowSize {
  match runtime_context.val {
    Some(ctx) => get_window_size(ctx.window)
    None => { width: fallback_width, height: fallback_height }
  }
}

///|
pub fn runtime_set_fullscreen(enabled : Bool) -> Bool {
  match runtime_context.val {
    Some(ctx) => set_fullscreen(ctx.window, enabled)
    None => enabled
  }
}

///|
pub fn runtime_is_fullscreen() -> Bool {
  match runtime_context.val {
    Some(ctx) => is_fullscreen(ctx.window)
    None => false
  }
}

///|
pub fn runtime_set_cursor_mode(mode : Int) -> Int {
  let safe_mode = if mode < 0 || mode > 2 { 0 } else { mode }
  match runtime_context.val {
    Some(ctx) => set_cursor_mode(ctx.window, safe_mode)
    None => safe_mode
  }
}

///|
pub fn runtime_cursor_mode() -> Int {
  match runtime_context.val {
    Some(ctx) => get_cursor_mode(ctx.window)
    None => 0
  }
}

///|
pub fn runtime_cursor_x() -> Double {
  match runtime_context.val {
    Some(ctx) => get_cursor_x(ctx.window)
    None => 0.0
  }
}

///|
pub fn runtime_cursor_y() -> Double {
  match runtime_context.val {
    Some(ctx) => get_cursor_y(ctx.window)
    None => 0.0
  }
}

///|
pub fn runtime_take_wheel_x() -> Double {
  match runtime_context.val {
    Some(ctx) => take_scroll_x(ctx.window)
    None => 0.0
  }
}

///|
pub fn runtime_take_wheel_y() -> Double {
  match runtime_context.val {
    Some(ctx) => take_scroll_y(ctx.window)
    None => 0.0
  }
}

///|
pub fn runtime_pressed_key_count() -> Int {
  match runtime_context.val {
    Some(ctx) => pressed_key_count(ctx.window)
    None => 0
  }
}

///|
pub fn runtime_pressed_key_at(index : Int) -> Int {
  if index < 0 {
    -1
  } else {
    match runtime_context.val {
      Some(ctx) => pressed_key_at(ctx.window, index)
      None => -1
    }
  }
}

///|
pub fn runtime_pressed_mouse_button_count() -> Int {
  match runtime_context.val {
    Some(ctx) => pressed_mouse_button_count(ctx.window)
    None => 0
  }
}

///|
pub fn runtime_pressed_mouse_button_at(index : Int) -> Int {
  if index < 0 {
    -1
  } else {
    match runtime_context.val {
      Some(ctx) => pressed_mouse_button_at(ctx.window, index)
      None => -1
    }
  }
}

///|
pub fn runtime_touch_count() -> Int {
  match runtime_context.val {
    Some(ctx) => touch_count(ctx.window)
    None => 0
  }
}

///|
pub fn runtime_touch_id_at(index : Int) -> Int {
  if index < 0 {
    -1
  } else {
    match runtime_context.val {
      Some(ctx) => touch_id_at(ctx.window, index)
      None => -1
    }
  }
}

///|
pub fn runtime_touch_x_at(index : Int) -> Double {
  if index < 0 {
    0.0
  } else {
    match runtime_context.val {
      Some(ctx) => touch_x_at(ctx.window, index)
      None => 0.0
    }
  }
}

///|
pub fn runtime_touch_y_at(index : Int) -> Double {
  if index < 0 {
    0.0
  } else {
    match runtime_context.val {
      Some(ctx) => touch_y_at(ctx.window, index)
      None => 0.0
    }
  }
}

///|
pub fn runtime_gamepad_count() -> Int {
  match runtime_context.val {
    Some(_) => gamepad_count()
    None => 0
  }
}

///|
pub fn runtime_gamepad_id_at(index : Int) -> Int {
  if index < 0 {
    -1
  } else {
    match runtime_context.val {
      Some(_) => gamepad_id_at(index)
      None => -1
    }
  }
}

///|
pub fn runtime_gamepad_axis_count(index : Int) -> Int {
  if index < 0 {
    0
  } else {
    match runtime_context.val {
      Some(_) =>
        if gamepad_id_at(index) < 0 {
          0
        } else {
          gamepad_axis_count(index)
        }
      None => 0
    }
  }
}

///|
pub fn runtime_gamepad_axis_at(gamepad_index : Int, axis_index : Int) -> Double {
  if gamepad_index < 0 || axis_index < 0 {
    0.0
  } else {
    match runtime_context.val {
      Some(_) =>
        if gamepad_id_at(gamepad_index) < 0 {
          0.0
        } else {
          gamepad_axis_at(gamepad_index, axis_index)
        }
      None => 0.0
    }
  }
}

///|
pub fn runtime_gamepad_pressed_button_count(index : Int) -> Int {
  if index < 0 {
    0
  } else {
    match runtime_context.val {
      Some(_) =>
        if gamepad_id_at(index) < 0 {
          0
        } else {
          gamepad_pressed_button_count(index)
        }
      None => 0
    }
  }
}

///|
pub fn runtime_gamepad_pressed_button_at(
  gamepad_index : Int,
  button_index : Int,
) -> Int {
  if gamepad_index < 0 || button_index < 0 {
    -1
  } else {
    match runtime_context.val {
      Some(_) =>
        if gamepad_id_at(gamepad_index) < 0 {
          -1
        } else {
          gamepad_pressed_button_at(gamepad_index, button_index)
        }
      None => -1
    }
  }
}

///|
pub fn runtime_set_device_scale_factor(scale : Double) -> Double {
  runtime_device_scale_override.val = if scale <= 0.0 { 1.0 } else { scale }
  runtime_device_scale_override.val
}

///|
pub fn runtime_device_scale_factor(fallback : Double) -> Double {
  if runtime_device_scale_override.val > 0.0 {
    runtime_device_scale_override.val
  } else {
    match runtime_context.val {
      Some(ctx) => get_window_content_scale(ctx.window)
      None => if fallback <= 0.0 { 1.0 } else { fallback }
    }
  }
}

///|
pub fn runtime_set_vsync_enabled(enabled : Bool) -> Bool {
  runtime_vsync_enabled.val = enabled
  match runtime_context.val {
    Some(_) => set_swap_interval(enabled)
    None => ()
  }
  runtime_vsync_enabled.val
}

///|
pub fn runtime_is_vsync_enabled() -> Bool {
  runtime_vsync_enabled.val
}

///|
pub fn runtime_request_close() -> Unit {
  match runtime_context.val {
    Some(ctx) => set_window_should_close(ctx.window, true)
    None => ()
  }
}

///|
pub fn runtime_request_attention() -> Unit {
  match runtime_context.val {
    Some(ctx) => request_window_attention(ctx.window)
    None => ()
  }
}

///|
pub fn runtime_begin_frame(
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
) -> Unit {
  planned_clear_r.val = clear_r
  planned_clear_g.val = clear_g
  planned_clear_b.val = clear_b
  planned_clear_a.val = clear_a
  planned_draw_calls.val = 0
  planned_command_count.val = 0
  planned_last_pipeline_id.val = 0
  planned_last_uniform_hash.val = 0
  planned_last_blend_mode.val = 1
  planned_last_dst_image_id.val = 0
  planned_last_shader_id.val = 0
  planned_last_index_offset.val = 0
  planned_last_region_count.val = 0
  planned_last_total_index_count.val = 0
  planned_last_vertex_float_count.val = 0
  planned_last_index_count.val = 0
  planned_last_src_image_count.val = 0
  planned_last_uniform_dword_count.val = 0
  planned_has_triangle_payload.val = false
  planned_triangle_ax.val = 0.0
  planned_triangle_ay.val = 0.5
  planned_triangle_bx.val = -0.5
  planned_triangle_by.val = -0.5
  planned_triangle_cx.val = 0.5
  planned_triangle_cy.val = -0.5
  planned_uv_au.val = 0.0
  planned_uv_av.val = 0.0
  planned_uv_bu.val = 1.0
  planned_uv_bv.val = 0.0
  planned_uv_cu.val = 1.0
  planned_uv_cv.val = 1.0
  planned_uniform_r.val = 1.0
  planned_uniform_g.val = 1.0
  planned_uniform_b.val = 1.0
  planned_uniform_a.val = 1.0
  planned_texture_seed.val = 0
}

///|
pub fn runtime_record_draw_command(
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
) -> Unit {
  let count = if draw_calls <= 0 { 1 } else { draw_calls }
  let safe_blend_mode = if blend_mode < 0 || blend_mode > 3 {
    1
  } else {
    blend_mode
  }
  let safe_region_count = if region_count < 0 { 0 } else { region_count }
  let safe_total_index_count = if total_index_count < 0 {
    0
  } else {
    total_index_count
  }
  let safe_vertex_float_count = if vertex_float_count < 0 {
    0
  } else {
    vertex_float_count
  }
  let safe_index_count = if index_count <= 0 {
    safe_total_index_count
  } else {
    index_count
  }
  let safe_src_image_count = if src_image_count < 0 {
    0
  } else {
    src_image_count
  }
  let safe_uniform_dword_count = if uniform_dword_count < 0 {
    0
  } else {
    uniform_dword_count
  }
  planned_draw_calls.val = planned_draw_calls.val + count
  planned_command_count.val = planned_command_count.val + 1
  planned_last_pipeline_id.val = pipeline_id
  planned_last_uniform_hash.val = uniform_hash
  planned_last_blend_mode.val = safe_blend_mode
  planned_last_dst_image_id.val = dst_image_id
  planned_last_shader_id.val = shader_id
  planned_last_index_offset.val = index_offset
  planned_last_region_count.val = safe_region_count
  planned_last_total_index_count.val = safe_total_index_count
  planned_last_vertex_float_count.val = safe_vertex_float_count
  planned_last_index_count.val = safe_index_count
  planned_last_src_image_count.val = safe_src_image_count
  planned_last_uniform_dword_count.val = safe_uniform_dword_count
}

///|
pub fn runtime_record_draw_region_count(region_count : Int) -> Unit {
  let safe_region_count = if region_count <= 0 { 1 } else { region_count }
  runtime_record_draw_command(
    region_count,
    0,
    0,
    1,
    0,
    0,
    0,
    safe_region_count,
    safe_region_count * 3,
    0,
    safe_region_count * 3,
    0,
    0,
  )
}

///|
pub fn runtime_record_draw_triangle_payload(
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
  planned_has_triangle_payload.val = true
  planned_triangle_ax.val = ax
  planned_triangle_ay.val = ay
  planned_triangle_bx.val = bx
  planned_triangle_by.val = by
  planned_triangle_cx.val = cx
  planned_triangle_cy.val = cy
  planned_uv_au.val = au
  planned_uv_av.val = av
  planned_uv_bu.val = bu
  planned_uv_bv.val = bv
  planned_uv_cu.val = cu
  planned_uv_cv.val = cv
  planned_uniform_r.val = uniform_r
  planned_uniform_g.val = uniform_g
  planned_uniform_b.val = uniform_b
  planned_uniform_a.val = uniform_a
  planned_texture_seed.val = if texture_seed < 0 { 0 } else { texture_seed }
}

///|
pub fn runtime_has_triangle_payload() -> Bool {
  planned_has_triangle_payload.val
}

///|
pub fn runtime_payload_triangle_ax() -> Double {
  planned_triangle_ax.val
}

///|
pub fn runtime_payload_triangle_ay() -> Double {
  planned_triangle_ay.val
}

///|
pub fn runtime_payload_triangle_bx() -> Double {
  planned_triangle_bx.val
}

///|
pub fn runtime_payload_triangle_by() -> Double {
  planned_triangle_by.val
}

///|
pub fn runtime_payload_triangle_cx() -> Double {
  planned_triangle_cx.val
}

///|
pub fn runtime_payload_triangle_cy() -> Double {
  planned_triangle_cy.val
}

///|
pub fn runtime_payload_uv_au() -> Double {
  planned_uv_au.val
}

///|
pub fn runtime_payload_uv_av() -> Double {
  planned_uv_av.val
}

///|
pub fn runtime_payload_uv_bu() -> Double {
  planned_uv_bu.val
}

///|
pub fn runtime_payload_uv_bv() -> Double {
  planned_uv_bv.val
}

///|
pub fn runtime_payload_uv_cu() -> Double {
  planned_uv_cu.val
}

///|
pub fn runtime_payload_uv_cv() -> Double {
  planned_uv_cv.val
}

///|
pub fn runtime_payload_uniform_r() -> Double {
  planned_uniform_r.val
}

///|
pub fn runtime_payload_uniform_g() -> Double {
  planned_uniform_g.val
}

///|
pub fn runtime_payload_uniform_b() -> Double {
  planned_uniform_b.val
}

///|
pub fn runtime_payload_uniform_a() -> Double {
  planned_uniform_a.val
}

///|
pub fn runtime_payload_texture_seed() -> Int {
  planned_texture_seed.val
}

///|
pub fn runtime_pending_draw_calls() -> Int {
  planned_draw_calls.val
}

///|
pub fn runtime_pending_command_count() -> Int {
  planned_command_count.val
}

///|
pub fn runtime_last_pipeline_id() -> Int {
  planned_last_pipeline_id.val
}

///|
pub fn runtime_last_uniform_hash() -> Int {
  planned_last_uniform_hash.val
}

///|
pub fn runtime_last_blend_mode() -> Int {
  planned_last_blend_mode.val
}

///|
pub fn runtime_last_dst_image_id() -> Int {
  planned_last_dst_image_id.val
}

///|
pub fn runtime_last_shader_id() -> Int {
  planned_last_shader_id.val
}

///|
pub fn runtime_last_index_offset() -> Int {
  planned_last_index_offset.val
}

///|
pub fn runtime_last_region_count() -> Int {
  planned_last_region_count.val
}

///|
pub fn runtime_last_total_index_count() -> Int {
  planned_last_total_index_count.val
}

///|
pub fn runtime_last_vertex_float_count() -> Int {
  planned_last_vertex_float_count.val
}

///|
pub fn runtime_last_index_count() -> Int {
  planned_last_index_count.val
}

///|
pub fn runtime_last_src_image_count() -> Int {
  planned_last_src_image_count.val
}

///|
pub fn runtime_last_uniform_dword_count() -> Int {
  planned_last_uniform_dword_count.val
}

///|
pub fn runtime_render_frame() -> Bool {
  match runtime_context.val {
    Some(ctx) => {
      let size = get_window_size(ctx.window)
      let _ = ensure_runtime_surface_size(ctx, size.width, size.height)
      render_triangle_frame(ctx)
      true
    }
    None => false
  }
}

///|
pub fn runtime_present_planned_frame() -> Bool {
  match runtime_context.val {
    Some(ctx) => {
      let size = get_window_size(ctx.window)
      let _ = ensure_runtime_surface_size(ctx, size.width, size.height)
      render_triangle_frame_with_plan_payload(
        ctx,
        planned_clear_r.val,
        planned_clear_g.val,
        planned_clear_b.val,
        planned_clear_a.val,
        planned_draw_calls.val,
        planned_has_triangle_payload.val,
        planned_triangle_ax.val,
        planned_triangle_ay.val,
        planned_triangle_bx.val,
        planned_triangle_by.val,
        planned_triangle_cx.val,
        planned_triangle_cy.val,
        planned_uv_au.val,
        planned_uv_av.val,
        planned_uv_bu.val,
        planned_uv_bv.val,
        planned_uv_cu.val,
        planned_uv_cv.val,
        planned_uniform_r.val,
        planned_uniform_g.val,
        planned_uniform_b.val,
        planned_uniform_a.val,
        planned_texture_seed.val,
      )
      planned_draw_calls.val = 0
      true
    }
    None => false
  }
}

///|
pub fn shutdown_runtime_context() -> Unit {
  match runtime_context.val {
    Some(ctx) => {
      shutdown_triangle_context(ctx)
      runtime_context.val = None
      configured_surface_width.val = 0
      configured_surface_height.val = 0
      runtime_device_scale_override.val = 0.0
    }
    None => ()
  }
}
