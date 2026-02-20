///|
///|
fn clamp_u8(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn clamp_sample_coord(value : Int) -> Int {
  if value < 0 {
    0
  } else if value >= 64 {
    63
  } else {
    value
  }
}

///|
fn sample_pixel_x_from_ndc(x_ndc : Double) -> Int {
  let x = (((x_ndc + 1.0) * 0.5) * 64.0).to_int()
  clamp_sample_coord(x)
}

///|
fn sample_pixel_y_from_ndc(y_ndc : Double) -> Int {
  let y = (((1.0 - y_ndc) * 0.5) * 64.0).to_int()
  clamp_sample_coord(y)
}

///|
fn normalized_payload_color(
  payload_uniform_r : Double,
  payload_uniform_g : Double,
  payload_uniform_b : Double,
  payload_uniform_a : Double,
  payload_texture_seed : Int,
) -> Array[Double] {
  let mut r = @payload2d.clamp_unit(payload_uniform_r)
  let mut g = @payload2d.clamp_unit(payload_uniform_g)
  let mut b = @payload2d.clamp_unit(payload_uniform_b)
  let mut a = @payload2d.clamp_unit(payload_uniform_a)
  if r + g + b < 0.12 {
    let seed = if payload_texture_seed < 0 {
      -payload_texture_seed
    } else {
      payload_texture_seed
    }
    r = (seed % 256).to_double() / 255.0
    g = ((seed / 256) % 256).to_double() / 255.0
    b = ((seed / 65536) % 256).to_double() / 255.0
    if r + g + b < 0.3 {
      r = 0.92
      g = 0.26
      b = 0.18
    }
  }
  if a < 0.2 {
    a = 1.0
  }
  [r, g, b, a]
}

///|
fn edge(
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  px : Double,
  py : Double,
) -> Double {
  (px - ax) * (by - ay) - (py - ay) * (bx - ax)
}

///|
fn sample_predicted_web_pixel_rgba(
  payload_ax : Double,
  payload_ay : Double,
  payload_bx : Double,
  payload_by : Double,
  payload_cx : Double,
  payload_cy : Double,
  payload_uniform_r : Double,
  payload_uniform_g : Double,
  payload_uniform_b : Double,
  payload_uniform_a : Double,
  payload_texture_seed : Int,
  px : Int,
  py : Int,
) -> Array[Int] {
  let sample_w = 64
  let sample_h = 64
  let x_ndc = (px.to_double() + 0.5) / sample_w.to_double() * 2.0 - 1.0
  let y_ndc = 1.0 - (py.to_double() + 0.5) / sample_h.to_double() * 2.0
  let area = edge(
    payload_ax,
    payload_ay,
    payload_bx,
    payload_by,
    payload_cx,
    payload_cy,
  )
  if area.abs() < 0.000001 {
    return [0, 0, 0, 255]
  }
  let e0 = edge(
    payload_bx,
    payload_by,
    payload_cx,
    payload_cy,
    x_ndc,
    y_ndc,
  )
  let e1 = edge(
    payload_cx,
    payload_cy,
    payload_ax,
    payload_ay,
    x_ndc,
    y_ndc,
  )
  let e2 = edge(
    payload_ax,
    payload_ay,
    payload_bx,
    payload_by,
    x_ndc,
    y_ndc,
  )
  let inside = if area > 0.0 {
    e0 >= 0.0 && e1 >= 0.0 && e2 >= 0.0
  } else {
    e0 <= 0.0 && e1 <= 0.0 && e2 <= 0.0
  }
  if !inside {
    return [0, 0, 0, 255]
  }
  let color = normalized_payload_color(
    payload_uniform_r,
    payload_uniform_g,
    payload_uniform_b,
    payload_uniform_a,
    payload_texture_seed,
  )
  let r = clamp_u8((color[0] * 255.0).to_int())
  let g = clamp_u8((color[1] * 255.0).to_int())
  let b = clamp_u8((color[2] * 255.0).to_int())
  let a = clamp_u8((color[3] * 255.0).to_int())
  [r, g, b, a]
}

///|
fn[T : @gfx.GraphicsDriver] run_draw_payload_probe(graphics : T) -> Unit raise {
  graphics.initialize()
  let pass = @gfx.new_render_pass_desc(@gfx.new_color(0.0, 0.0, 0.0, 1.0), true)
  let dst = graphics.new_image(64, 64)
  let shader = graphics.new_shader("runtime_smoke_payload_probe")
  let plan = build_runtime_smoke_tile_draw_plan(dst, shader)
  let synced = @web_hooks.sync_dirty_atlas_pages_from_repository(
    plan.atlas_repository,
  )
  if synced != 1 {
    panic()
  }
  let resynced = @web_hooks.sync_dirty_atlas_pages_from_repository(
    plan.atlas_repository,
  )
  if resynced != 0 {
    panic()
  }
  let atlas_page_id = 801
  if @web_hooks.source_image_generation(atlas_page_id) != 2 {
    panic()
  }
  if @web_hooks.source_image_width(atlas_page_id) != 4 ||
    @web_hooks.source_image_height(atlas_page_id) != 4 {
    panic()
  }
  if @web_hooks.source_image_pixel_channel(atlas_page_id, 1, 0, 0) != 42 ||
    @web_hooks.source_image_pixel_channel(atlas_page_id, 1, 0, 1) != 43 ||
    @web_hooks.source_image_pixel_channel(atlas_page_id, 1, 0, 2) != 44 {
    panic()
  }
  let command = plan.commands[0]
  if command.src_image_ids.length() <= 0 {
    panic()
  }
  let payload = @payload2d.decode_triangle_payload(
    command.vertex_data,
    command.indices,
    command.uniform_dwords,
    command.src_image_ids,
  )
  let payload_texture_seed = command.src_image_ids[0]
  let sample0_x_ndc = payload.ax * 0.34 + payload.bx * 0.33 + payload.cx * 0.33
  let sample0_y_ndc = payload.ay * 0.34 + payload.by * 0.33 + payload.cy * 0.33
  let sample0_x = sample_pixel_x_from_ndc(sample0_x_ndc)
  let sample0_y = sample_pixel_y_from_ndc(sample0_y_ndc)
  let sample0 = sample_predicted_web_pixel_rgba(
    payload.ax,
    payload.ay,
    payload.bx,
    payload.by,
    payload.cx,
    payload.cy,
    payload.uniform_r,
    payload.uniform_g,
    payload.uniform_b,
    payload.uniform_a,
    payload.texture_seed,
    sample0_x,
    sample0_y,
  )
  let sample1_x_ndc = payload.ax * 0.2 + payload.bx * 0.6 + payload.cx * 0.2
  let sample1_y_ndc = payload.ay * 0.2 + payload.by * 0.6 + payload.cy * 0.2
  let sample1_x = sample_pixel_x_from_ndc(sample1_x_ndc)
  let sample1_y = sample_pixel_y_from_ndc(sample1_y_ndc)
  let sample1 = sample_predicted_web_pixel_rgba(
    payload.ax,
    payload.ay,
    payload.bx,
    payload.by,
    payload.cx,
    payload.cy,
    payload.uniform_r,
    payload.uniform_g,
    payload.uniform_b,
    payload.uniform_a,
    payload.texture_seed,
    sample1_x,
    sample1_y,
  )
  let sample2_x_ndc = payload.ax * 0.2 + payload.bx * 0.2 + payload.cx * 0.6
  let sample2_y_ndc = payload.ay * 0.2 + payload.by * 0.2 + payload.cy * 0.6
  let sample2_x = sample_pixel_x_from_ndc(sample2_x_ndc)
  let sample2_y = sample_pixel_y_from_ndc(sample2_y_ndc)
  let sample2 = sample_predicted_web_pixel_rgba(
    payload.ax,
    payload.ay,
    payload.bx,
    payload.by,
    payload.cx,
    payload.cy,
    payload.uniform_r,
    payload.uniform_g,
    payload.uniform_b,
    payload.uniform_a,
    payload.texture_seed,
    sample2_x,
    sample2_y,
  )
  let atlas_generation = @web_hooks.source_image_generation(atlas_page_id)
  let atlas_pixel_r = @web_hooks.source_image_pixel_channel(atlas_page_id, 1, 0, 0)
  let atlas_pixel_g = @web_hooks.source_image_pixel_channel(atlas_page_id, 1, 0, 1)
  let atlas_pixel_b = @web_hooks.source_image_pixel_channel(atlas_page_id, 1, 0, 2)
  graphics.begin(pass)
  graphics.draw_triangles(command)
  graphics.end(true)
  let read_pixels_result = graphics.read_pixels(0, 0, 4, 4)
  let read_pixels_len = match read_pixels_result {
    Some(pixels) => pixels.length()
    None => -1
  }
  println(
    "runtime_smoke_web_probe: tex_seed=\{payload_texture_seed} atlas_gen=\{atlas_generation} atlas_rgb=\{atlas_pixel_r},\{atlas_pixel_g},\{atlas_pixel_b} sample0=\{sample0_x},\{sample0_y},\{sample0[0]},\{sample0[1]},\{sample0[2]},\{sample0[3]} sample1=\{sample1_x},\{sample1_y},\{sample1[0]},\{sample1[1]},\{sample1[2]},\{sample1[3]} sample2=\{sample2_x},\{sample2_y},\{sample2[0]},\{sample2[1]},\{sample2[2]},\{sample2[3]} read_pixels_len=\{read_pixels_len}",
  )
}

///|
fn main {
  @web_hooks.install("#app")
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_web_canvas_platform("#app")
  let surface = platform.current_surface() catch {
    _ => @platform.create_offscreen_surface_token(320, 240)
  }
  let graphics = @gfx.create_webgpu_graphics(
    surface,
    @gfx.default_graphics_backend_options(),
  )
  @runtime.run_loop(
    game,
    platform,
    graphics,
    @core.default_run_options(),
    @runtime.default_runtime_config(),
  ) catch {
    _ => ()
  }
  run_draw_payload_probe(graphics) catch {
    _ => ()
  }
  let ready = @web_hooks.is_ready()
  @web_hooks.uninstall()
  if !ready {
    panic()
  }
  println("runtime_smoke(js): ok (hooked)")
}
