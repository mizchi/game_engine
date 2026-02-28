///|
fn main {
  let state = GameState::new()
  @engine.run(
    update=fn(input) { state.update(input) },
    draw=fn(ctx) { state.draw(ctx) },
    audio_ctx=state.audio_ctx,
    width=screen_w,
    height=screen_h,
    title="3D Arena Collector",
    canvas="#app",
  )
}
