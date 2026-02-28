///|
extern "js" fn js_request_animation_frame(f : () -> Unit) -> Unit =
  #| (f) => { requestAnimationFrame(() => f()); }

///|
extern "js" fn js_on_beforeunload(f : () -> Unit) -> Unit =
  #| (f) => { window.addEventListener("beforeunload", () => f()); }

///|
pub fn run(
  update~ : (@core.InputSnapshot) -> Unit,
  draw~ : (EngineContext) -> Array[@gfx.DrawTrianglesCommand],
  audio_ctx? : @audio.MixerAudioContext,
  audio_frames_per_tick~ : Int = 735,
  width~ : Int = 320,
  height~ : Int = 240,
  title~ : String = "kagura",
  canvas~ : String = "#app",
) -> Unit {
  invoke_on_start(canvas, title)
  let platform = @platform.create_web_canvas_platform(canvas)
  let surface = platform.current_surface() catch {
    _ => @platform.create_offscreen_surface_token(width, height)
  }
  let graphics = @gfx.create_webgpu_graphics(
    surface,
    @gfx.default_graphics_backend_options(),
  )
  platform.initialize(
    @platform.new_window_options(title, width, height, false, true),
  ) catch {
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
  let tick : Ref[Int] = Ref::new(0)
  match audio_ctx {
    Some(_) => {
      let _ = @audio.audio_try_initialize(@audio.default_audio_format())

    }
    None => ()
  }
  fn frame() {
    platform.poll_events()
    let input = platform.capture_input(tick.val)
    tick.val = tick.val + 1
    update(input)
    let cmds = draw(ctx)
    @debugutil.render_commands(graphics, cmds) catch {
      _ => ()
    }
    match audio_ctx {
      Some(actx) => {
        @audio.audio_resume()
        let _ = @audio.audio_render_and_write(actx, audio_frames_per_tick)
        actx.tick_bgm(audio_frames_per_tick)
      }
      None => ()
    }
    js_request_animation_frame(frame)
  }
  js_on_beforeunload(fn() { invoke_on_stop() })
  js_request_animation_frame(frame)
}
