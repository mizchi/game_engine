///|
fn main {
  @web_hooks.install("#app")
  let _audio_ok = @audio.audio_try_initialize(@audio.default_audio_format())
  let platform = @platform.create_web_canvas_platform("#app")
  let surface = platform.current_surface() catch {
    _ => @platform.create_offscreen_surface_token(screen_w, screen_h)
  }
  let graphics = @gfx.create_webgpu_graphics(
    surface,
    @gfx.default_graphics_backend_options(),
  )
  platform.initialize(
    @platform.new_window_options("arena3d", screen_w, screen_h, false, true),
  ) catch {
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
  fn frame() {
    platform.poll_events()
    let input = platform.capture_input(state.frame_count)
    state.update(input)
    let cmds = state.build_draw_commands(dst, shader)
    @debugutil.render_commands(graphics, cmds) catch {
      _ => ()
    }
    @audio.audio_resume()
    let _ = @audio.audio_render_and_write(state.audio_ctx, 735)
    @web_hooks.request_animation_frame(frame)
  }

  @web_hooks.request_animation_frame(frame)
}
