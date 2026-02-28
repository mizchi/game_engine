///|
pub(all) struct LifecycleHooks {
  on_start : (String, String) -> Unit
  on_stop : () -> Unit
}

///|
let lifecycle_hooks : Ref[LifecycleHooks?] = Ref::new(None)

///|
pub fn set_lifecycle_hooks(hooks : LifecycleHooks) -> Unit {
  lifecycle_hooks.val = Some(hooks)
}

///|
pub fn reset_lifecycle_hooks() -> Unit {
  lifecycle_hooks.val = None
}

///|
fn invoke_on_start(canvas : String, title : String) -> Unit {
  match lifecycle_hooks.val {
    Some(hooks) => (hooks.on_start)(canvas, title)
    None => ()
  }
}

///|
fn invoke_on_stop() -> Unit {
  match lifecycle_hooks.val {
    Some(hooks) => (hooks.on_stop)()
    None => ()
  }
}
