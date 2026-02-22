pub fn run(
  view~ : () -> SceneNode,
  update~ : (@core.InputSnapshot) -> Unit,
  width~ : Int = 320,
  height~ : Int = 240,
  title~ : String = "kagura",
  canvas~ : String = "",
) -> Unit {
  let _ = canvas
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
  let screen_w = width.to_double()
  let screen_h = height.to_double()
  let mut tick = 0
  while not(platform.should_close()) {
    platform.poll_events()
    let input = platform.capture_input(tick)
    tick = tick + 1
    update(input)
    let scene = view()
    let cmds = render_scene(scene, dst, shader, screen_w, screen_h)
    @debugutil.render_commands(graphics, cmds) catch {
      _ => ()
    }
  }
}
