///|
fn main {
  @web_hooks.install("#app")
  let state = SurvivorState::new()
  @scene.run(
    view=fn() { state.view() },
    update=fn(input) { state.update(input) },
    width=320,
    height=240,
    title="survivor",
    canvas="#app",
  )
}
