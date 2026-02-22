///|
fn main {
  @native_hooks.install("action_rpg")
  let state = ShowcaseState::new()
  @scene.run(
    view=fn() { state.view() },
    update=fn(input) { state.update(input) },
    width=screen_w.to_int(),
    height=screen_h.to_int(),
    title="Action RPG",
  )
  @native_hooks.shutdown()
  @native_hooks.uninstall()
}
