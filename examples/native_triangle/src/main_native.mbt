///|
fn main {
  if !@native_hooks.initialize_context(800, 600, "kagura: triangle") {
    panic()
  }
  while !@native_hooks.should_close() {
    @native_hooks.poll_events()
    let _ = @native_hooks.render_frame()
  }
  @native_hooks.shutdown_context()
}
