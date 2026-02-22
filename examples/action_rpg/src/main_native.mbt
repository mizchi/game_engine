///|
fn main {
  @native_hooks.install("action_rpg")
  let platform = @platform.create_desktop_glfw_platform()
  let surface = platform.current_surface() catch {
    _ => @platform.create_offscreen_surface_token(320, 240)
  }
  let graphics = @gfx.create_wgpu_native_graphics(
    surface,
    @gfx.default_graphics_backend_options(),
  )
  let window_options = @platform.new_window_options(
    "Action RPG", 960, 720, false, true,
  )
  platform.initialize(window_options) catch { _ => () }
  graphics.initialize() catch { _ => () }
  let dst = graphics.new_image(320, 240) catch {
    _ => @gfx.new_image_handle(1, 320, 240)
  }
  let shader = graphics.new_shader("action_rpg") catch {
    _ => @gfx.new_shader_handle(1, "action_rpg")
  }
  let state = ShowcaseState::new()
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
