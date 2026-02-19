///|
let runtime_smoke_atlas_page_id : Int = 901

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
  let atlas_draw_path_active = @wgpu_native.runtime_payload_texture_seed() ==
    runtime_smoke_atlas_page_id
  let source_image_synced = source_image_id >= 0 &&
    @wgpu_native.runtime_source_image_generation(source_image_id) == 2 &&
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
  let atlas_page_synced = @wgpu_native.runtime_source_image_generation(
      runtime_smoke_atlas_page_id,
    ) ==
    2 &&
    @wgpu_native.planned_source_image_width(runtime_smoke_atlas_page_id) == 4 &&
    @wgpu_native.planned_source_image_height(runtime_smoke_atlas_page_id) == 4 &&
    @wgpu_native.planned_source_image_pixel_channel(
      runtime_smoke_atlas_page_id, 1, 0, 0,
    ) ==
    42 &&
    @wgpu_native.planned_source_image_pixel_channel(
      runtime_smoke_atlas_page_id, 1, 0, 1,
    ) ==
    43 &&
    @wgpu_native.planned_source_image_pixel_channel(
      runtime_smoke_atlas_page_id, 1, 0, 2,
    ) ==
    44 &&
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
