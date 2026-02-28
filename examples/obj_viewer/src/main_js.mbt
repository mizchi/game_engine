///|
let screen_w : Int = 640

///|
let screen_h : Int = 480

///|
extern "js" fn js_fetch_text(url : String, cb : (String) -> Unit) -> Unit =
  #| (url, cb) => { fetch(url).then(r => r.text()).then(t => cb(t)); }

///|
fn main {
  @web_hooks.install("#app")
  js_fetch_text("./assets/bunny.obj", fn(obj_text) {
    let mesh = @mesh3d.Mesh3D::from_obj(obj_text)
    let mut camera = @camera3d.OrbitCamera::new(
      @math3d.Vec3::new(0.0, 0.1, 0.0),
      0.4,
      0.5,
      0.3,
      @math.PI / 4.0,
      screen_w.to_double() / screen_h.to_double(),
      0.01,
      10.0,
    )
    let lighting = @light3d.LightingEnvironment::new(
      @light3d.DirectionalLight::new(
        @math3d.Vec3::new(-0.5, 1.0, 0.8),
        @math3d.Vec3::new(1.0, 1.0, 1.0),
        0.8,
      ),
      @light3d.AmbientLight::new(@math3d.Vec3::new(1.0, 1.0, 1.0), 0.3),
    )
    let prev_x : Ref[Double] = Ref::new(0.0)
    let prev_y : Ref[Double] = Ref::new(0.0)
    @engine.run(
      update=fn(input) {
        let cx = input.cursor_x
        let cy = input.cursor_y
        let dx = cx - prev_x.val
        let dy = cy - prev_y.val
        prev_x.val = cx
        prev_y.val = cy
        // Left mouse button (0) drag → orbit
        let mut lmb = false
        for b in input.pressed_mouse_buttons {
          if b == 0 {
            lmb = true
            break
          }
        }
        if lmb {
          camera = camera.orbit(dx * -0.005, dy * -0.005)
        }
        // Scroll wheel → zoom
        if input.wheel_y != 0.0 {
          camera = camera.zoom(input.wheel_y * 0.02)
        }
      },
      draw=fn(ctx) {
        let objects = [
          @scene3d.object3d(
            mesh~,
            color=@math3d.Vec4::new(0.8, 0.6, 0.5, 1.0),
          ),
        ]
        let scene = @scene3d.scene3d(
          objects~,
          camera=camera.to_camera3d(),
          lighting~,
        )
        @scene3d.render_scene3d(
          scene, ctx.dst, ctx.shader, ctx.screen_w, ctx.screen_h,
        )
      },
      width=screen_w,
      height=screen_h,
      title="OBJ Viewer - Stanford Bunny",
      canvas="#app",
    )
  })
}
