///|
fn main {
  @native_hooks.install("scene_demo")
  let game = Game::new()
  @scene.run(
    view=fn() { game.view() },
    update=fn(input) { game.update(input) },
    width=screen_w,
    height=screen_h,
    title="scene_demo",
  )
  @native_hooks.shutdown()
  @native_hooks.uninstall()
}
