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
  let dst = graphics.new_image(320, 240) catch {
    _ => @gfx.new_image_handle(1, 320, 240)
  }
  let shader = graphics.new_shader("action_rpg") catch {
    _ => @gfx.new_shader_handle(1, "action_rpg")
  }
  let state = ShowcaseState::new()
  fn frame() {
    platform.poll_events()
    let input = platform.capture_input(state.frame_count)
    state.update(input)
    let cmds = state.build_draw_commands(dst, shader)
    @debugutil.render_commands(graphics, cmds) catch {
      _ => ()
    }
    @web_hooks.request_animation_frame(frame)
  }
  @web_hooks.request_animation_frame(frame)
}
