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
test "runtime stores triangle payload per command entry" {
  runtime_begin_frame(0.0, 0.0, 0.0, 1.0)
  runtime_record_draw_command(2, 1, 2, 1, 10, 20, 0, 1, 3, 12, 3, 1, 4)
  runtime_record_draw_triangle_payload(
    -0.8, 0.7, -0.2, -0.6, 0.9, -0.1, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.2, 0.4, 0.8,
    1.0, 4,
  )
  runtime_record_draw_command(1, 2, 3, 1, 11, 21, 3, 1, 3, 12, 3, 1, 4)
  runtime_record_draw_triangle_payload(
    -0.6, 0.5, -0.1, -0.7, 0.7, -0.2, 0.1, 0.2, 0.9, 0.1, 0.8, 0.9, 0.3, 0.6, 0.9,
    1.0, 9,
  )

  assert_eq(runtime_pending_command_count(), 2)
  assert_eq(runtime_pending_draw_calls(), 3)

  assert_true(runtime_command_has_triangle_payload_at(0))
  assert_eq(runtime_command_payload_texture_seed_at(0), 4)

  assert_true(runtime_command_has_triangle_payload_at(1))
  assert_eq(runtime_command_payload_texture_seed_at(1), 9)

  assert_true(!runtime_command_has_triangle_payload_at(2))
  assert_eq(runtime_command_payload_texture_seed_at(2), 0)
}

///|
test "runtime render size is clamped to positive values" {
  let (w, h) = clamp_runtime_render_size(0, -9)
  assert_eq(w, 1)
  assert_eq(h, 1)

  let (w2, h2) = clamp_runtime_render_size(640, 480)
  assert_eq(w2, 640)
  assert_eq(h2, 480)
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

///|
test "runtime source image palette registration clamps channels" {
  runtime_clear_source_image_palette_registry()
  assert_eq(runtime_source_image_palette_count(), 0)

  runtime_register_source_image_palette(
    12, -5, 500, 64, 255, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
  )

  assert_eq(runtime_source_image_palette_count(), 1)
  assert_eq(runtime_source_image_palette_generation(12), 1)
  assert_eq(planned_image_palette_channel(12, 0, 0), 0)
  assert_eq(planned_image_palette_channel(12, 0, 1), 255)
  assert_eq(planned_image_palette_channel(12, 0, 2), 64)
  assert_eq(planned_image_palette_channel(12, 0, 3), 255)
  assert_eq(planned_image_palette_channel(12, 3, 0), 9)
  assert_eq(planned_image_palette_channel(12, 3, 3), 12)
}

///|
test "runtime source image palette ignores negative id and can clear" {
  runtime_clear_source_image_palette_registry()
  runtime_register_source_image_solid_color(-1, 1, 2, 3, 4)
  assert_eq(runtime_source_image_palette_count(), 0)

  runtime_register_source_image_solid_color(3, 10, 20, 30, 40)
  assert_eq(runtime_source_image_palette_count(), 1)
  assert_eq(runtime_source_image_palette_generation(3), 1)
  assert_eq(planned_image_palette_channel(3, 2, 0), 10)
  assert_eq(planned_image_palette_channel(3, 2, 1), 20)
  assert_eq(planned_image_palette_channel(3, 2, 2), 30)
  assert_eq(planned_image_palette_channel(3, 2, 3), 40)

  runtime_clear_source_image_palette_registry()
  assert_eq(runtime_source_image_palette_count(), 0)
}

///|
test "runtime source image rgba8 upload stores size and channels" {
  runtime_clear_source_image_registry()
  assert_eq(runtime_source_image_upload_count(), 0)

  runtime_register_source_image_rgba8(21, 2, 2, [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
  ])
  assert_eq(runtime_source_image_upload_count(), 1)
  assert_eq(runtime_source_image_generation(21), 1)
  assert_eq(runtime_source_image_width(21), 2)
  assert_eq(runtime_source_image_height(21), 2)
  assert_eq(runtime_source_image_pixel_channel(21, 0, 0, 0), 1)
  assert_eq(runtime_source_image_pixel_channel(21, 1, 0, 1), 6)
  assert_eq(runtime_source_image_pixel_channel(21, 0, 1, 2), 11)
  assert_eq(runtime_source_image_pixel_channel(21, 1, 1, 3), 16)
}

///|
test "runtime source image rgba8 upload increments generation on overwrite" {
  runtime_clear_source_image_registry()
  runtime_register_source_image_rgba8(33, 1, 1, [1, 2, 3, 4])
  assert_eq(runtime_source_image_generation(33), 1)

  runtime_register_source_image_rgba8(33, 1, 1, [9, 8, 7, 6])
  assert_eq(runtime_source_image_generation(33), 2)
  assert_eq(runtime_source_image_pixel_channel(33, 0, 0, 0), 9)
  assert_eq(runtime_source_image_pixel_channel(33, 0, 0, 1), 8)
  assert_eq(runtime_source_image_pixel_channel(33, 0, 0, 2), 7)
  assert_eq(runtime_source_image_pixel_channel(33, 0, 0, 3), 6)
}

///|
test "runtime source image rgba8 patch updates sub-rect and generation" {
  runtime_clear_source_image_registry()
  runtime_register_source_image_rgba8(77, 2, 2, [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
  ])
  assert_eq(runtime_source_image_generation(77), 1)

  let patched = runtime_patch_source_image_rgba8(77, 2, 2, 1, 0, 1, 2, [
    1, 2, 3, 4, 101, 102, 103, 104, 9, 10, 11, 12, 105, 106, 107, 108,
  ])
  assert_true(patched)
  assert_eq(runtime_source_image_generation(77), 2)
  assert_eq(runtime_source_image_pixel_channel(77, 0, 0, 0), 1)
  assert_eq(runtime_source_image_pixel_channel(77, 1, 0, 0), 101)
  assert_eq(runtime_source_image_pixel_channel(77, 1, 0, 3), 104)
  assert_eq(runtime_source_image_pixel_channel(77, 0, 1, 0), 9)
  assert_eq(runtime_source_image_pixel_channel(77, 1, 1, 0), 105)
  assert_eq(runtime_source_image_pixel_channel(77, 1, 1, 3), 108)
}

///|
test "runtime source image rgba8 patch returns false when source missing" {
  runtime_clear_source_image_registry()
  let patched = runtime_patch_source_image_rgba8(100, 2, 2, 0, 0, 1, 1, [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
  ])
  assert_true(!patched)
}

///|
test "runtime source image rgba8 upload ignores invalid payload" {
  runtime_clear_source_image_registry()
  runtime_register_source_image_rgba8(8, 2, 2, [1, 2, 3, 4])
  assert_eq(runtime_source_image_upload_count(), 0)

  runtime_register_source_image_rgba8(-1, 2, 2, [1, 2, 3, 4, 5, 6, 7, 8])
  assert_eq(runtime_source_image_upload_count(), 0)
}
