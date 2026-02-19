///|
test "planned frame draw count resets on begin" {
  runtime_begin_frame(0.0, 0.0, 0.0, 1.0)
  assert_eq(runtime_pending_draw_calls(), 0)
  assert_eq(runtime_pending_command_count(), 0)
  runtime_record_draw_region_count(2)
  assert_eq(runtime_pending_draw_calls(), 2)
  assert_eq(runtime_pending_command_count(), 1)
  assert_eq(runtime_last_pipeline_id(), 0)
  assert_eq(runtime_last_uniform_hash(), 0)
  assert_eq(runtime_last_blend_mode(), 1)
  assert_eq(runtime_last_dst_image_id(), 0)
  assert_eq(runtime_last_shader_id(), 0)
  assert_eq(runtime_last_index_offset(), 0)
  assert_eq(runtime_last_region_count(), 2)
  assert_eq(runtime_last_total_index_count(), 6)
  assert_eq(runtime_last_vertex_float_count(), 0)
  assert_eq(runtime_last_index_count(), 6)
  assert_eq(runtime_last_src_image_count(), 0)
  assert_eq(runtime_last_uniform_dword_count(), 0)

  runtime_begin_frame(1.0, 0.0, 0.0, 1.0)
  assert_eq(runtime_pending_draw_calls(), 0)
  assert_eq(runtime_pending_command_count(), 0)
  assert_eq(runtime_last_pipeline_id(), 0)
  assert_eq(runtime_last_uniform_hash(), 0)
  assert_eq(runtime_last_blend_mode(), 1)
  assert_eq(runtime_last_dst_image_id(), 0)
  assert_eq(runtime_last_shader_id(), 0)
  assert_eq(runtime_last_index_offset(), 0)
  assert_eq(runtime_last_region_count(), 0)
  assert_eq(runtime_last_total_index_count(), 0)
  assert_eq(runtime_last_vertex_float_count(), 0)
  assert_eq(runtime_last_index_count(), 0)
  assert_eq(runtime_last_src_image_count(), 0)
  assert_eq(runtime_last_uniform_dword_count(), 0)
}

///|
test "planned frame present returns false without context" {
  runtime_begin_frame(0.0, 0.0, 0.0, 1.0)
  runtime_record_draw_region_count(1)
  let rendered = runtime_present_planned_frame()
  assert_true(!rendered)
}

///|
test "runtime records draw command metadata for native backend bridge" {
  runtime_begin_frame(0.0, 0.0, 0.0, 1.0)
  runtime_record_draw_command(2, 7, 11, 3, 100, 200, 4, 2, 6, 16, 6, 2, 3)
  runtime_record_draw_command(1, 9, 13, 2, 101, 201, 8, 1, 3, 12, 3, 1, 4)

  assert_eq(runtime_pending_draw_calls(), 3)
  assert_eq(runtime_pending_command_count(), 2)
  assert_eq(runtime_last_pipeline_id(), 9)
  assert_eq(runtime_last_uniform_hash(), 13)
  assert_eq(runtime_last_blend_mode(), 2)
  assert_eq(runtime_last_dst_image_id(), 101)
  assert_eq(runtime_last_shader_id(), 201)
  assert_eq(runtime_last_index_offset(), 8)
  assert_eq(runtime_last_region_count(), 1)
  assert_eq(runtime_last_total_index_count(), 3)
  assert_eq(runtime_last_vertex_float_count(), 12)
  assert_eq(runtime_last_index_count(), 3)
  assert_eq(runtime_last_src_image_count(), 1)
  assert_eq(runtime_last_uniform_dword_count(), 4)
}

///|
test "runtime render size is clamped to positive values" {
  let size = clamp_runtime_render_size(0, -9)
  assert_eq(size.width, 1)
  assert_eq(size.height, 1)

  let size2 = clamp_runtime_render_size(640, 480)
  assert_eq(size2.width, 640)
  assert_eq(size2.height, 480)
}

///|
test "runtime input getters return neutral values without context" {
  assert_eq(runtime_cursor_x().to_int(), 0)
  assert_eq(runtime_cursor_y().to_int(), 0)
  assert_eq(runtime_take_wheel_x().to_int(), 0)
  assert_eq(runtime_take_wheel_y().to_int(), 0)
  assert_eq(runtime_pressed_key_count(), 0)
  assert_eq(runtime_pressed_key_at(0), -1)
  assert_eq(runtime_pressed_key_at(-1), -1)
  assert_eq(runtime_pressed_mouse_button_count(), 0)
  assert_eq(runtime_pressed_mouse_button_at(0), -1)
  assert_eq(runtime_pressed_mouse_button_at(-1), -1)
  assert_eq(runtime_touch_count(), 0)
  assert_eq(runtime_touch_id_at(0), -1)
  assert_eq(runtime_touch_id_at(-1), -1)
  assert_eq(runtime_touch_x_at(0).to_int(), 0)
  assert_eq(runtime_touch_x_at(-1).to_int(), 0)
  assert_eq(runtime_touch_y_at(0).to_int(), 0)
  assert_eq(runtime_touch_y_at(-1).to_int(), 0)
  assert_eq(runtime_gamepad_count(), 0)
  assert_eq(runtime_gamepad_id_at(0), -1)
  assert_eq(runtime_gamepad_id_at(-1), -1)
  assert_eq(runtime_gamepad_axis_count(0), 0)
  assert_eq(runtime_gamepad_axis_count(-1), 0)
  assert_eq(runtime_gamepad_axis_at(0, 0).to_int(), 0)
  assert_eq(runtime_gamepad_axis_at(-1, 0).to_int(), 0)
  assert_eq(runtime_gamepad_axis_at(0, -1).to_int(), 0)
  assert_eq(runtime_gamepad_pressed_button_count(0), 0)
  assert_eq(runtime_gamepad_pressed_button_count(-1), 0)
  assert_eq(runtime_gamepad_pressed_button_at(0, 0), -1)
  assert_eq(runtime_gamepad_pressed_button_at(-1, 0), -1)
  assert_eq(runtime_gamepad_pressed_button_at(0, -1), -1)
}

///|
test "runtime payload triangle state is set and reset by begin" {
  runtime_begin_frame(0.0, 0.0, 0.0, 1.0)
  assert_true(!runtime_has_triangle_payload())

  runtime_record_draw_triangle_payload(
    -0.9, 0.7, -0.4, -0.6, 0.8, -0.3, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.25, 0.5, 0.75,
    1.0, 4,
  )
  assert_true(runtime_has_triangle_payload())
  assert_true(runtime_payload_triangle_ax() < -0.8)
  assert_true(runtime_payload_triangle_ay() > 0.6)
  assert_true(runtime_payload_triangle_bx() < -0.3)
  assert_true(runtime_payload_triangle_by() < -0.5)
  assert_true(runtime_payload_triangle_cx() > 0.7)
  assert_true(runtime_payload_triangle_cy() < -0.2)
  assert_true(runtime_payload_uv_au() < 0.1)
  assert_true(runtime_payload_uv_av() < 0.1)
  assert_true(runtime_payload_uv_bu() > 0.9)
  assert_true(runtime_payload_uv_bv() < 0.1)
  assert_true(runtime_payload_uv_cu() > 0.9)
  assert_true(runtime_payload_uv_cv() > 0.9)
  assert_true(runtime_payload_uniform_r() > 0.2)
  assert_true(runtime_payload_uniform_g() > 0.4)
  assert_true(runtime_payload_uniform_b() > 0.7)
  assert_true(runtime_payload_uniform_a() > 0.9)
  assert_eq(runtime_payload_texture_seed(), 4)

  runtime_begin_frame(0.0, 0.0, 0.0, 1.0)
  assert_true(!runtime_has_triangle_payload())
  assert_true(runtime_payload_uv_au() < 0.1)
  assert_true(runtime_payload_uv_av() < 0.1)
  assert_true(runtime_payload_uniform_r() > 0.9)
  assert_eq(runtime_payload_texture_seed(), 0)
}
