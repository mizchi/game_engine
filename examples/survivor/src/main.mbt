///|
fn main {
  let state = SurvivorState::new()
  @scene.run(
    view=fn() { state.view() },
    update=fn(input) { state.update(input) },
    width=320,
    height=240,
    title="Survivor",
    canvas="#app",
  )
}
