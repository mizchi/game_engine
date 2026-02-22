///|
fn main {
  @web_hooks.install("#app")
  let state = ShowcaseState::new()
  @scene.run(
    view=fn() { state.view() },
    update=fn(input) { state.update(input) },
    width=screen_w.to_int(),
    height=screen_h.to_int(),
    title="action_rpg",
    canvas="#app",
  )
}
