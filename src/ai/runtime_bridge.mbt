///|
/// Runtime integration helpers for AI tick execution.

///|
pub struct AIRuntimeState {
  mut blackboard : BlackboardSnapshot
  mut traces : Array[Array[DecisionTrace]]
  mut total_decisions : Int
}

///|
pub fn AIRuntimeState::new() -> AIRuntimeState {
  { blackboard: { entries: [] }, traces: [], total_decisions: 0 }
}

///|
pub fn AIRuntimeState::new_with_blackboard(
  blackboard : BlackboardSnapshot,
) -> AIRuntimeState {
  { blackboard, traces: [], total_decisions: 0 }
}

///|
pub fn AIRuntimeState::current_blackboard(
  self : AIRuntimeState,
) -> BlackboardSnapshot {
  self.blackboard
}

///|
pub fn AIRuntimeState::total_decisions(self : AIRuntimeState) -> Int {
  self.total_decisions
}

///|
pub fn AIRuntimeState::trace_count(self : AIRuntimeState) -> Int {
  self.traces.length()
}

///|
pub fn AIRuntimeState::clear_traces(self : AIRuntimeState) -> Unit {
  self.traces = []
}

///|
/// Create an on_post_update callback for RuntimeHooks that runs AI tick.
pub fn[P : AIPolicy, S : SensorBridge, A : ActuatorBridge, C : AIScheduler] create_ai_post_update_hook(
  policy : P,
  sensors : S,
  actuator : A,
  scheduler : C,
  state : AIRuntimeState,
) -> (Int, @core.FrameBudget) -> Unit {
  fn(tick : Int, frame : @core.FrameBudget) {
    let next_blackboard = try {
      run_ai_tick(
        policy,
        sensors,
        actuator,
        scheduler,
        frame,
        tick,
        state.blackboard,
      )
    } catch {
      _ => state.blackboard
    }
    state.blackboard = next_blackboard
    state.total_decisions = state.total_decisions + 1
  }
}
