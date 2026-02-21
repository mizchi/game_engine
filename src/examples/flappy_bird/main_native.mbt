///|
fn main {
  @native_hooks.install("flappy_bird")
  let platform = @platform.create_desktop_glfw_platform()
  let surface = platform.current_surface() catch {
    _ => @platform.create_offscreen_surface_token(320, 240)
  }
  let graphics = @gfx.create_wgpu_native_graphics(
    surface,
    @gfx.default_graphics_backend_options(),
  )
  // Initialize with 320x240 window (not run_loop which hardcodes 800x600)
  let window_options = @platform.new_window_options(
    "Flappy Bird", 320, 240, false, true,
  )
  platform.initialize(window_options) catch { _ => () }
  graphics.initialize() catch { _ => () }
  let dst = graphics.new_image(320, 240) catch {
    _ => @gfx.new_image_handle(1, 320, 240)
  }
  let shader = graphics.new_shader("flappy_bird") catch {
    _ => @gfx.new_shader_handle(1, "flappy_bird")
  }
  let state = FlappyState::new()
  while not(@native_hooks.should_close()) {
    @native_hooks.poll_events()
    let input = platform.capture_input(state.frame_count)
    state.update(input)
    let cmds = state.build_draw_commands(dst, shader)
    @debugutil.render_commands(graphics, cmds) catch { _ => () }
  }
  @native_hooks.shutdown()
  @native_hooks.uninstall()
}
