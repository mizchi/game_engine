///|
fn main {
  @native_hooks.install("arena3d")
  let _audio_ok = @audio.audio_try_initialize(@audio.default_audio_format())
  let platform = @platform.create_desktop_glfw_platform()
  let surface = platform.current_surface() catch {
    _ => @platform.create_offscreen_surface_token(screen_w, screen_h)
  }
  let graphics = @gfx.create_wgpu_native_graphics(
    surface,
    @gfx.default_graphics_backend_options(),
  )
  let window_options = @platform.new_window_options(
    "3D Arena Collector",
    screen_w * 2,
    screen_h * 2,
    false,
    true,
  )
  platform.initialize(window_options) catch {
    _ => ()
  }
  graphics.initialize() catch {
    _ => ()
  }
  let dst = graphics.new_image(screen_w, screen_h) catch {
    _ => @gfx.new_image_handle(1, screen_w, screen_h)
  }
  let shader = graphics.new_shader("arena3d") catch {
    _ => @gfx.new_shader_handle(1, "arena3d")
  }
  let state = GameState::new()
  while not(@native_hooks.should_close()) {
    @native_hooks.poll_events()
    let input = platform.capture_input(state.frame_count)
    state.update(input)
    let cmds = state.build_draw_commands(dst, shader)
    @debugutil.render_commands(graphics, cmds) catch {
      _ => ()
    }
    let _ = @audio.audio_render_and_write(state.audio_ctx, 735)
  }
  @native_hooks.shutdown()
  @native_hooks.uninstall()
}
