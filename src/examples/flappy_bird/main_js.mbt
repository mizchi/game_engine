///|
fn[T : @gfx.GraphicsDriver] render_frame(
  state : FlappyState,
  graphics : T,
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
) -> Unit raise {
  let pass = @gfx.new_render_pass_desc(
    @gfx.new_color(0.0, 0.0, 0.0, 1.0),
    true,
  )
  graphics.begin(pass)
  let cmds = state.build_draw_commands(dst, shader)
  for cmd in cmds {
    graphics.draw_triangles(cmd)
  }
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
  // Create render resources
  let dst = graphics.new_image(320, 240) catch {
    _ => @gfx.new_image_handle(1, 320, 240)
  }
  let shader = graphics.new_shader("flappy_bird") catch {
    _ => @gfx.new_shader_handle(1, "flappy_bird")
  }
  // Game state
  let state = FlappyState::new()
  // RAF game loop
  fn frame() {
    platform.poll_events()
    let input = platform.capture_input(state.frame_count)
    state.update(input)
    if state.frame_count % 120 == 0 {
      println(
        "frame=\{state.frame_count} mode=\{state.game_mode} bird_y=\{state.bird_y} pipes=\{state.pipes.length()} score=\{state.score}",
      )
    }
    render_frame(state, graphics, dst, shader) catch {
      _ => ()
    }
    @web_hooks.request_animation_frame(frame)
  }
  @web_hooks.request_animation_frame(frame)
}
