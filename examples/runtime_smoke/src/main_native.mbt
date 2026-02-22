///|
fn[T : @gfx.GraphicsDriver] run_draw_payload_probe(graphics : T) -> Unit raise {
  graphics.initialize()
  let pass = @gfx.new_render_pass_desc(@gfx.new_color(0.0, 0.0, 0.0, 1.0), true)
  let dst = graphics.new_image(64, 64)
  let shader = graphics.new_shader("runtime_smoke_payload_probe")
  let plan = build_runtime_smoke_tile_draw_plan(dst, shader)
  graphics.begin(pass)
  for i = plan.commands.length() - 1; i >= 0; i = i - 1 {
    graphics.draw_triangles(plan.commands[i])
  }
  graphics.end(true)
}

///|
fn main {
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
  run_draw_payload_probe(graphics) catch {
    _ => ()
  }
  println("runtime_smoke(native): ok")
}
