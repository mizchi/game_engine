///|
fn main {
  @web_hooks.install("#app")
  let game = Game::new()
  @scene.run(
    view=fn() { game.view() },
    update=fn(input) { game.update(input) },
    width=screen_w,
    height=screen_h,
    title="flappy_bird",
    canvas="#app",
  )
}
