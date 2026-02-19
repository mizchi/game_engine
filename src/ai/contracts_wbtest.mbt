///|
struct TestSensor {
  id : Int
}

///|
pub impl SensorBridge for TestSensor with capture(self, agent_id, tick) {
  let _ = self.id
  {
    self_x: agent_id.value.to_double(),
    self_y: tick.to_double(),
    health: 100.0,
    visible_entities: [agent_id.value + 1],
    tags: ["enemy"],
  }
}

///|
struct TestActuator {
  mut applied : Int
}

///|
pub impl ActuatorBridge for TestActuator with apply(self, _agent_id, actions) {
  self.applied = self.applied + actions.length()
}

///|
struct TestScheduler {
  id : Int
}

///|
pub impl AIScheduler for TestScheduler with select_agents(self, tick) {
  let _ = self.id
  if tick % 2 == 0 {
    [{ value: 1 }, { value: 2 }]
  } else {
    [{ value: 1 }]
  }
}

///|
pub impl AIScheduler for TestScheduler with budget_for(_self, _agent_id) {
  default_ai_budget()
}

///|
struct TestPolicy {
  id : Int
}

///|
pub impl AIPolicy for TestPolicy with decide(self, context) {
  let _ = self.id
  let entries = context.blackboard.entries
  entries.push({ key: "last_tick", value: context.tick.to_string() })
  {
    actions: [
      ActionIntent::Move(context.perception.self_x, context.perception.self_y),
    ],
    next_blackboard: { entries, },
    trace: [{ stage: "test", score: 1.0, note: "ok" }],
  }
}

///|
test "run_ai_tick updates blackboard and applies actions" {
  let sensor : TestSensor = { id: 0 }
  let actuator = { applied: 0 }
  let scheduler : TestScheduler = { id: 0 }
  let policy : TestPolicy = { id: 0 }

  let frame = @core.new_frame_budget(1, 0.0, 10)
  let blackboard : BlackboardSnapshot = { entries: [] }
  let next = run_ai_tick(
    policy, sensor, actuator, scheduler, frame, 10, blackboard,
  )

  assert_eq(next.entries.length(), 2)
  assert_eq(actuator.applied, 2)
}

///|
test "AIRuntimeState tracks decisions" {
  let state = AIRuntimeState::new()
  assert_eq!(state.total_decisions(), 0)
  assert_eq!(state.trace_count(), 0)

  let sensor : TestSensor = { id: 0 }
  let actuator : TestActuator = { applied: 0 }
  let scheduler : TestScheduler = { id: 0 }
  let policy : TestPolicy = { id: 0 }
  let hook = create_ai_post_update_hook(
    policy, sensor, actuator, scheduler, state,
  )

  // Simulate two ticks
  let frame = @core.new_frame_budget(1, 0.0, 10)
  hook(10, frame)
  assert_eq!(state.total_decisions(), 1)

  let frame2 = @core.new_frame_budget(1, 0.0, 11)
  hook(11, frame2)
  assert_eq!(state.total_decisions(), 2)
  // Blackboard should have accumulated entries
  assert_true!(state.current_blackboard().entries.length() > 0)
}

///|
test "AIRuntimeState with initial blackboard" {
  let initial : BlackboardSnapshot = {
    entries: [{ key: "init", value: "yes" }],
  }
  let state = AIRuntimeState::new_with_blackboard(initial)
  assert_eq!(state.current_blackboard().entries.length(), 1)
  assert_eq!(state.current_blackboard().entries[0].key, "init")
}

///|
test "AIRuntimeState clear_traces" {
  let state = AIRuntimeState::new()
  state.traces.push([{ stage: "test", score: 1.0, note: "ok" }])
  assert_eq!(state.trace_count(), 1)
  state.clear_traces()
  assert_eq!(state.trace_count(), 0)
}
