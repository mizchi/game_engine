///|
/// Runtime orchestration contracts.
/// Ebiten refs:
/// - internal/ui/run.go
/// - internal/ui/context.go
/// - gameforui.go

///|
pub struct RuntimeConfig {
  max_skip_frames : Int
  enable_vsync : Bool
  clear_screen_every_frame : Bool
} derive(Show)

///|
pub struct FramePlan {
  updates : Int
  should_draw : Bool
} derive(Show)

///|
pub struct RuntimeHooks {
  on_input_captured : (Int, @core.InputSnapshot) -> Unit
  on_post_update : (Int, @core.FrameBudget) -> Unit
}

///|
pub fn new_runtime_hooks(
  on_input_captured : (Int, @core.InputSnapshot) -> Unit,
) -> RuntimeHooks {
  { on_input_captured, on_post_update: fn(_tick, _frame) { () } }
}

///|
pub fn new_runtime_hooks_full(
  on_input_captured : (Int, @core.InputSnapshot) -> Unit,
  on_post_update : (Int, @core.FrameBudget) -> Unit,
) -> RuntimeHooks {
  { on_input_captured, on_post_update }
}

///|
fn default_on_input_captured(_tick : Int, _input : @core.InputSnapshot) -> Unit {
  ()
}

///|
pub fn default_runtime_hooks() -> RuntimeHooks {
  new_runtime_hooks(default_on_input_captured)
}

///|
pub fn default_runtime_config() -> RuntimeConfig {
  { max_skip_frames: 5, enable_vsync: true, clear_screen_every_frame: true }
}

///|
pub fn plan_frame(fixed : @core.StepResult, max_skip_frames : Int) -> FramePlan {
  let cap = if max_skip_frames <= 0 { 1 } else { max_skip_frames }
  let updates = if fixed.updates > cap { cap } else { fixed.updates }
  let should_draw = updates > 0 || fixed.alpha > 0.0
  { updates, should_draw }
}

///|
pub fn[G : @core.Game, P : @platform.PlatformDriver, R : @gfx.GraphicsDriver] run_loop_with_hooks(
  game : G,
  platform : P,
  graphics : R,
  run_options : @core.RunOptions,
  runtime_config : RuntimeConfig,
  runtime_hooks : RuntimeHooks,
) -> Unit raise {
  let _ = run_options.init_unfocused
  let _ = run_options.screen_cleared_every_frame
  let fixed_cfg = @core.default_fixed_step_config()
  let mut fixed_state = @core.initial_fixed_step_state()
  let mut should_stop = false
  let mut configured_width = 0
  let mut configured_height = 0

  let window_options = @platform.new_window_options(
    "kagura",
    800,
    600,
    run_options.screen_transparent,
    true,
  )
  platform.initialize(window_options)
  platform.set_vsync_enabled(runtime_config.enable_vsync)
  graphics.initialize()

  while !platform.should_close() && !should_stop {
    platform.poll_events()

    let outside = platform.outside_size()
    let _ = game.layout(outside)
    let next_width = if outside.width.to_int() <= 0 {
      1
    } else {
      outside.width.to_int()
    }
    let next_height = if outside.height.to_int() <= 0 {
      1
    } else {
      outside.height.to_int()
    }
    if configured_width != next_width || configured_height != next_height {
      graphics.resize(next_width, next_height)
      configured_width = next_width
      configured_height = next_height
    }

    let step = @core.step_fixed_timestep(fixed_state, 16.6667, fixed_cfg)
    fixed_state = step.next_state
    let frame_plan = plan_frame(step, runtime_config.max_skip_frames)

    for _ in 0..<frame_plan.updates {
      let input = platform.capture_input(fixed_state.tick)
      (runtime_hooks.on_input_captured)(fixed_state.tick, input)
      match game.update(input) {
        Some(@core.EngineTermination::RegularTermination) => should_stop = true
        Some(@core.EngineTermination::Fatal(_)) => should_stop = true
        None => ()
      }
      let frame_budget = @core.new_frame_budget(
        frame_plan.updates,
        step.alpha,
        fixed_state.tick,
      )
      (runtime_hooks.on_post_update)(fixed_state.tick, frame_budget)
    }

    if frame_plan.should_draw {
      let pass = @gfx.new_render_pass_desc(
        @gfx.new_color(0.0, 0.0, 0.0, 1.0),
        runtime_config.clear_screen_every_frame,
      )
      graphics.begin(pass)
      game.draw(
        @core.new_frame_budget(frame_plan.updates, step.alpha, fixed_state.tick),
      )
      graphics.end(true)
    }
  }
}

///|
pub fn[G : @core.Game, P : @platform.PlatformDriver, R : @gfx.GraphicsDriver] run_loop(
  game : G,
  platform : P,
  graphics : R,
  run_options : @core.RunOptions,
  runtime_config : RuntimeConfig,
) -> Unit raise {
  run_loop_with_hooks(
    game,
    platform,
    graphics,
    run_options,
    runtime_config,
    default_runtime_hooks(),
  )
}
