///|
pub fn run(
  update~ : (@core.InputSnapshot) -> Unit,
  draw~ : (EngineContext) -> Array[@gfx.DrawTrianglesCommand],
  audio_ctx? : @audio.MixerAudioContext,
  audio_frames_per_tick~ : Int = 735,
  width~ : Int = 320,
  height~ : Int = 240,
  title~ : String = "kagura",
  canvas~ : String = "",
) -> Unit {
  let _ = canvas
  invoke_on_start(canvas, title)
  let platform = @platform.create_desktop_glfw_platform()
  let surface = platform.current_surface() catch {
    _ => @platform.create_offscreen_surface_token(width, height)
  }
  let graphics = @gfx.create_wgpu_native_graphics(
    surface,
    @gfx.default_graphics_backend_options(),
  )
  let window_options = @platform.new_window_options(
    title, width, height, false, true,
  )
  platform.initialize(window_options) catch {
    _ => ()
  }
  graphics.initialize() catch {
    _ => ()
  }
  let dst = graphics.new_image(width, height) catch {
    _ => @gfx.new_image_handle(1, width, height)
  }
  let shader = graphics.new_shader(title) catch {
    _ => @gfx.new_shader_handle(1, title)
  }
  let ctx = { dst, shader, screen_w: width, screen_h: height }
  let mut tick = 0
  match audio_ctx {
    Some(_) => {
      let _ = @audio.audio_try_initialize(@audio.default_audio_format())

    }
    None => ()
  }
  while not(platform.should_close()) {
    platform.poll_events()
    let input = platform.capture_input(tick)
    tick = tick + 1
    update(input)
    let cmds = draw(ctx)
    @debugutil.render_commands(graphics, cmds) catch {
      _ => ()
    }
    match audio_ctx {
      Some(actx) => {
        let _ = @audio.audio_render_and_write(actx, audio_frames_per_tick)
        actx.tick_bgm(audio_frames_per_tick)
      }
      None => ()
    }
  }
  invoke_on_stop()
}
