///|
let runtime_smoke_atlas_page_id : Int = 801

///|
fn clamp_unit(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

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
  let mut r = clamp_unit(payload_uniform_r)
  let mut g = clamp_unit(payload_uniform_g)
  let mut b = clamp_unit(payload_uniform_b)
  let mut a = clamp_unit(payload_uniform_a)
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
fn[T : @gfx.GraphicsDriver] run_draw_payload_probe(graphics : T) -> Int raise {
  graphics.initialize()
  let pass = @gfx.new_render_pass_desc(@gfx.new_color(0.0, 0.0, 0.0, 1.0), true)
  let dst = graphics.new_image(64, 64)
  let repository = @asset.new_simple_image_repository()
  let source_key_0 = @asset.new_asset_key("runtime_smoke/source0")
  let source_key_1 = @asset.new_asset_key("runtime_smoke/source1")
  let source0_png = @asset.encode_png_image_spec(
    @asset.image_spec_with_rgba8(1, 1, [255, 255, 255, 255]),
  ) catch {
    _ => panic()
  }
  let source0 = @asset.create_image_from_raster_bytes(
    repository,
    source_key_0,
    source0_png,
  ) catch {
    _ => None
  }
  match source0 {
    Some(_) => ()
    None => panic()
  }
  let source1_png = @asset.encode_png_image_spec(
    @asset.image_spec_with_rgba8(2, 2, [
      32, 200, 255, 255, 64, 128, 255, 255, 96, 64, 255, 255, 255, 255, 255, 255,
    ]),
  ) catch {
    _ => panic()
  }
  let source_created = @asset.create_image_from_raster_bytes(
    repository,
    source_key_1,
    source1_png,
  ) catch {
    _ => None
  }
  let source = match source_created {
    Some(handle) => handle
    None => panic()
  }
  let initial_synced = @native_hooks.sync_dirty_source_images_from_repository(
    repository,
  )
  if initial_synced != 2 {
    panic()
  }
  let repeated_synced = @native_hooks.sync_dirty_source_images_from_repository(
    repository,
  )
  if repeated_synced != 0 {
    panic()
  }

  let source_updated_png = @asset.encode_png_image_spec(
    @asset.image_spec_with_rgba8(2, 2, [
      33, 200, 255, 255, 64, 128, 255, 255, 96, 64, 255, 255, 255, 255, 255, 255,
    ]),
  ) catch {
    _ => panic()
  }
  let updated = @asset.update_image_from_raster_bytes(
    repository,
    source_key_1,
    source_updated_png,
  ) catch {
    _ => None
  }
  match updated {
    Some(handle) => if handle.id != source.id { panic() }
    None => panic()
  }
  let dirty_synced = @native_hooks.sync_dirty_source_images_from_repository(
    repository,
  )
  if dirty_synced != 1 {
    panic()
  }
  if @asset.get_image_generation_by_id(repository, source.id) != 2 {
    panic()
  }
  let atlas_repository = @asset.new_simple_atlas_image_repository(
    4, 4, runtime_smoke_atlas_page_id,
  )
  let atlas_key = @asset.new_asset_key("runtime_smoke/atlas")
  let atlas_png = @asset.encode_png_image_spec(
    @asset.image_spec_with_rgba8(2, 2, [
      1, 2, 3, 255, 4, 5, 6, 255, 7, 8, 9, 255, 10, 11, 12, 255,
    ]),
  ) catch {
    _ => panic()
  }
  let atlas_image = @asset.create_atlas_image_from_raster_bytes(
    atlas_repository,
    atlas_key,
    atlas_png,
  ) catch {
    _ => None
  }
  match atlas_image {
    Some(_) => ()
    None => panic()
  }
  let atlas_initial_synced = @native_hooks.sync_dirty_atlas_pages_from_repository(
    atlas_repository,
  )
  if atlas_initial_synced != 1 {
    panic()
  }
  let atlas_repeated_synced = @native_hooks.sync_dirty_atlas_pages_from_repository(
    atlas_repository,
  )
  if atlas_repeated_synced != 0 {
    panic()
  }
  let atlas_updated_png = @asset.encode_png_image_spec(
    @asset.image_spec_with_rgba8(2, 2, [
      1, 2, 3, 255, 42, 43, 44, 255, 7, 8, 9, 255, 10, 11, 12, 255,
    ]),
  ) catch {
    _ => panic()
  }
  let atlas_updated = @asset.update_atlas_image_from_raster_bytes(
    atlas_repository,
    atlas_key,
    atlas_updated_png,
  ) catch {
    _ => None
  }
  match atlas_updated {
    Some(_) => ()
    None => panic()
  }
  let atlas_dirty_synced = @native_hooks.sync_dirty_atlas_pages_from_repository(
    atlas_repository,
  )
  if atlas_dirty_synced != 1 {
    panic()
  }
  let shader = graphics.new_shader("runtime_smoke_native_payload_probe")
  let tile_table = @tilemap2d.new_tile_atlas_table([
    @tilemap2d.new_tile_atlas_entry(1, atlas_key),
  ])
  let previous_tiles = [0, 0, 0, 0]
  let next_tiles = [0, 1, 0, 0]
  let visible_chunk = @tilemap2d.estimate_visible_tile_chunk(
    2, 2, -0.5, -0.5, 0.5, 0.5, -0.5, -0.5, 0.5, 0.5, 0,
  )
  let dirty_chunks = @tilemap2d.diff_visible_tile_index_chunks(
    previous_tiles, next_tiles, 2, 1, visible_chunk,
  )
  if dirty_chunks.length() != 1 {
    panic()
  }
  let tile_commands : Array[@gfx.DrawTrianglesCommand] = []
  let appended = @tilemap2d.append_tile_indexed_dirty_chunk_batched_draw_commands(
    tile_commands,
    dirty_chunks,
    tile_table,
    atlas_repository,
    dst,
    shader,
    7,
    11,
    @gfx.blend_mode_from_int(1),
    @gfx.new_dst_region(0, 0, 64, 64, 6),
    next_tiles,
    2,
    -0.5,
    -0.5,
    0.5,
    0.5,
    [1, 2, 3, 4],
  )
  if appended != 1 {
    panic()
  }
  if tile_commands.length() != 1 {
    panic()
  }
  let command = tile_commands[0]
  graphics.begin(pass)
  graphics.draw_triangles(command)
  graphics.end(true)
  source.id
}

///|
fn run_runtime_contract_smoke() -> Int raise {
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_desktop_glfw_platform()
  let surface = platform.current_surface() catch {
    _ => @platform.create_offscreen_surface_token(320, 240)
  }
  let graphics = @gfx.create_wgpu_native_graphics(
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
  run_draw_payload_probe(graphics)
}

///|
fn run_with_real_native_hooks() -> Bool {
  @native_hooks.install("runtime_smoke_native")
  @native_hooks.clear_source_image_palettes()
  let source_image_id = run_runtime_contract_smoke() catch { _ => -1 }
  let has_payload = @wgpu_native.runtime_last_index_count() > 0 &&
    @wgpu_native.runtime_last_vertex_float_count() > 0 &&
    @wgpu_native.runtime_last_uniform_dword_count() > 0
  let payload_ax = @wgpu_native.runtime_payload_triangle_ax()
  let payload_ay = @wgpu_native.runtime_payload_triangle_ay()
  let payload_bx = @wgpu_native.runtime_payload_triangle_bx()
  let payload_by = @wgpu_native.runtime_payload_triangle_by()
  let payload_cx = @wgpu_native.runtime_payload_triangle_cx()
  let payload_cy = @wgpu_native.runtime_payload_triangle_cy()
  let payload_area2 = (payload_bx - payload_ax) * (payload_cy - payload_ay) -
    (payload_by - payload_ay) * (payload_cx - payload_ax)
  let payload_abs_area2 = if payload_area2 < 0.0 {
    -payload_area2
  } else {
    payload_area2
  }
  let payload_geometry_valid = @wgpu_native.runtime_has_triangle_payload() &&
    payload_ax >= -1.1 &&
    payload_ax <= 1.1 &&
    payload_ay >= -1.1 &&
    payload_ay <= 1.1 &&
    payload_bx >= -1.1 &&
    payload_bx <= 1.1 &&
    payload_by >= -1.1 &&
    payload_by <= 1.1 &&
    payload_cx >= -1.1 &&
    payload_cx <= 1.1 &&
    payload_cy >= -1.1 &&
    payload_cy <= 1.1 &&
    payload_abs_area2 > 0.05
  let payload_uniform_r = @wgpu_native.runtime_payload_uniform_r()
  let payload_uniform_g = @wgpu_native.runtime_payload_uniform_g()
  let payload_uniform_b = @wgpu_native.runtime_payload_uniform_b()
  let payload_uniform_a = @wgpu_native.runtime_payload_uniform_a()
  let payload_uniform_valid = payload_uniform_r >= 0.0 &&
    payload_uniform_r <= 1.0 &&
    payload_uniform_g >= 0.0 &&
    payload_uniform_g <= 1.0 &&
    payload_uniform_b >= 0.0 &&
    payload_uniform_b <= 1.0 &&
    payload_uniform_a >= 0.0 &&
    payload_uniform_a <= 1.0 &&
    payload_uniform_a > 0.0 &&
    payload_uniform_r + payload_uniform_g + payload_uniform_b > 0.0
  let payload_texture_seed = @wgpu_native.runtime_payload_texture_seed()
  let atlas_draw_path_active = payload_texture_seed ==
    runtime_smoke_atlas_page_id
  let source_generation = if source_image_id >= 0 {
    @wgpu_native.runtime_source_image_generation(source_image_id)
  } else {
    -1
  }
  let source_image_synced = source_image_id >= 0 &&
    source_generation == 2 &&
    @wgpu_native.planned_source_image_width(source_image_id) == 2 &&
    @wgpu_native.planned_source_image_height(source_image_id) == 2 &&
    @wgpu_native.planned_source_image_pixel_channel(source_image_id, 0, 0, 0) ==
    33 &&
    @wgpu_native.planned_source_image_pixel_channel(source_image_id, 0, 0, 1) ==
    200 &&
    @wgpu_native.planned_source_image_pixel_channel(source_image_id, 0, 0, 2) ==
    255 &&
    @wgpu_native.planned_source_image_pixel_channel(source_image_id, 0, 0, 3) ==
    255
  let atlas_generation = @wgpu_native.runtime_source_image_generation(
    runtime_smoke_atlas_page_id,
  )
  let atlas_pixel_r = @wgpu_native.planned_source_image_pixel_channel(
    runtime_smoke_atlas_page_id, 1, 0, 0,
  )
  let atlas_pixel_g = @wgpu_native.planned_source_image_pixel_channel(
    runtime_smoke_atlas_page_id, 1, 0, 1,
  )
  let atlas_pixel_b = @wgpu_native.planned_source_image_pixel_channel(
    runtime_smoke_atlas_page_id, 1, 0, 2,
  )
  let atlas_page_synced = atlas_generation == 2 &&
    @wgpu_native.planned_source_image_width(runtime_smoke_atlas_page_id) == 4 &&
    @wgpu_native.planned_source_image_height(runtime_smoke_atlas_page_id) == 4 &&
    atlas_pixel_r == 42 &&
    atlas_pixel_g == 43 &&
    atlas_pixel_b == 44 &&
    @wgpu_native.planned_source_image_pixel_channel(
      runtime_smoke_atlas_page_id, 3, 3, 0,
    ) ==
    0
  let ready = @native_hooks.is_ready()
  @native_hooks.shutdown()
  @native_hooks.uninstall()
  if !ready {
    return false
  }
  if !has_payload {
    return false
  }
  if !payload_geometry_valid {
    return false
  }
  if !payload_uniform_valid {
    return false
  }
  if !atlas_draw_path_active {
    return false
  }
  if !source_image_synced {
    return false
  }
  if !atlas_page_synced {
    return false
  }
  let sample0_x_ndc = payload_ax * 0.34 + payload_bx * 0.33 + payload_cx * 0.33
  let sample0_y_ndc = payload_ay * 0.34 + payload_by * 0.33 + payload_cy * 0.33
  let sample0_x = sample_pixel_x_from_ndc(sample0_x_ndc)
  let sample0_y = sample_pixel_y_from_ndc(sample0_y_ndc)
  let sample0 = sample_predicted_web_pixel_rgba(
    payload_ax,
    payload_ay,
    payload_bx,
    payload_by,
    payload_cx,
    payload_cy,
    payload_uniform_r,
    payload_uniform_g,
    payload_uniform_b,
    payload_uniform_a,
    payload_texture_seed,
    sample0_x,
    sample0_y,
  )
  let sample1_x_ndc = payload_ax * 0.2 + payload_bx * 0.6 + payload_cx * 0.2
  let sample1_y_ndc = payload_ay * 0.2 + payload_by * 0.6 + payload_cy * 0.2
  let sample1_x = sample_pixel_x_from_ndc(sample1_x_ndc)
  let sample1_y = sample_pixel_y_from_ndc(sample1_y_ndc)
  let sample1 = sample_predicted_web_pixel_rgba(
    payload_ax,
    payload_ay,
    payload_bx,
    payload_by,
    payload_cx,
    payload_cy,
    payload_uniform_r,
    payload_uniform_g,
    payload_uniform_b,
    payload_uniform_a,
    payload_texture_seed,
    sample1_x,
    sample1_y,
  )
  let sample2_x_ndc = payload_ax * 0.2 + payload_bx * 0.2 + payload_cx * 0.6
  let sample2_y_ndc = payload_ay * 0.2 + payload_by * 0.2 + payload_cy * 0.6
  let sample2_x = sample_pixel_x_from_ndc(sample2_x_ndc)
  let sample2_y = sample_pixel_y_from_ndc(sample2_y_ndc)
  let sample2 = sample_predicted_web_pixel_rgba(
    payload_ax,
    payload_ay,
    payload_bx,
    payload_by,
    payload_cx,
    payload_cy,
    payload_uniform_r,
    payload_uniform_g,
    payload_uniform_b,
    payload_uniform_a,
    payload_texture_seed,
    sample2_x,
    sample2_y,
  )
  let read_pixels_result = @wgpu_native.runtime_read_pixels(0, 0, 4, 4)
  let read_pixels_len = match read_pixels_result {
    Some(pixels) => pixels.length()
    None => -1
  }
  println(
    "runtime_smoke_native_probe: tex_seed=\{payload_texture_seed} source_gen=\{source_generation} atlas_gen=\{atlas_generation} atlas_rgb=\{atlas_pixel_r},\{atlas_pixel_g},\{atlas_pixel_b} sample0=\{sample0_x},\{sample0_y},\{sample0[0]},\{sample0[1]},\{sample0[2]},\{sample0[3]} sample1=\{sample1_x},\{sample1_y},\{sample1[0]},\{sample1[1]},\{sample1[2]},\{sample1[3]} sample2=\{sample2_x},\{sample2_y},\{sample2[0]},\{sample2[1]},\{sample2[2]},\{sample2[3]} read_pixels_len=\{read_pixels_len}",
  )
  true
}

///|
fn main {
  let native_ready = run_with_real_native_hooks()
  if !native_ready {
    panic()
  }
  println("runtime_smoke_native: ok (real)")
}
