///|
extern "js" fn js_request_animation_frame(f : () -> Unit) -> Unit =
  #| (f) => { requestAnimationFrame(() => f()); }

///|
pub fn run(
  view~ : () -> SceneNode,
  update~ : (@core.InputSnapshot) -> Unit,
  on_frame? : (
    Array[@gfx.DrawTrianglesCommand],
    @gfx.ImageHandle,
    @gfx.ShaderHandle,
    Double,
    Double,
  ) -> Unit = fn(_c, _d, _s, _w, _h) {  },
  width? : Int = 320,
  height? : Int = 240,
  title? : String = "kagura",
  canvas? : String = "#app",
) -> Unit {
  let platform = @platform.create_web_canvas_platform(canvas)
  let surface = platform.current_surface() catch {
    _ => @platform.create_offscreen_surface_token(width, height)
  }
  let graphics = @gfx.create_webgpu_graphics(
    surface,
    @gfx.default_graphics_backend_options(),
  )
  // NOTE: run_loop is NOT called on JS — it contains a blocking while-loop
  // for native targets. JS uses requestAnimationFrame below instead.
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
  let tick : Ref[Int] = Ref::new(0)
  let screen_w = width.to_double()
  let screen_h = height.to_double()
  fn frame() {
    platform.poll_events()
    let input = platform.capture_input(tick.val)
    tick.val = tick.val + 1
    update(input)
    let scene = view()
    let cmds = render_scene(scene, dst, shader, screen_w, screen_h)
    on_frame(cmds, dst, shader, screen_w, screen_h)
    @debugutil.render_commands(graphics, cmds) catch {
      _ => ()
    }
    js_request_animation_frame(frame)
  }
  js_request_animation_frame(frame)
}
