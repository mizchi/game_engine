///|
fn main {
  let state = ShowcaseState::new()
  @scene.run(
    view=fn() { state.view() },
    update=fn(input) { state.update(input) },
    on_frame=fn(cmds, dst, shader, sw, sh) {
      state.render_text_hud(cmds, dst, shader, sw, sh)
    },
    width=screen_w.to_int(),
    height=screen_h.to_int(),
    title="Action RPG",
    canvas="#app",
  )
}
