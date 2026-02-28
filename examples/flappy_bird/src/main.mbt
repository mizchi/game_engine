///|
fn main {
  let game = Game::new()
  @scene.run(
    view=fn() { game.view() },
    update=fn(input) { game.update(input) },
    width=screen_w,
    height=screen_h,
    title="Flappy Bird",
    canvas="#app",
  )
}
