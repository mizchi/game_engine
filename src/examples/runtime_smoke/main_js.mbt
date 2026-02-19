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
  graphics.begin(pass)
  graphics.draw_triangles(command)
  graphics.end(true)
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
