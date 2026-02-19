///|
fn approx(a : Double, b : Double) -> Bool {
  (a - b).abs() < 0.01
}

///|
test "UITree add and get node" {
  let tree = UITree::new()
  let style = default_node_style()
  let id = tree.add_node(style, [])
  assert_eq!(tree.node_count(), 1)
  match tree.get_node(id) {
    Some(node) => {
      assert_eq!(node.id.value, id.value)
      assert_eq!(node.children.length(), 0)
    }
    None => fail!("expected node")
  }
}

///|
test "UITree parent-child" {
  let tree = UITree::new()
  let style = default_node_style()
  let child1 = tree.add_node(style, [])
  let child2 = tree.add_node(style, [])
  let parent = tree.add_node(style, [child1, child2])
  assert_eq!(tree.node_count(), 3)
  match tree.get_node(parent) {
    Some(node) => assert_eq!(node.children.length(), 2)
    None => fail!("expected parent")
  }
}

///|
test "default_layout_constraint" {
  let c = default_layout_constraint(800.0, 600.0)
  assert_eq!(c.min_width, 0.0)
  assert_eq!(c.min_height, 0.0)
  assert_eq!(c.max_width, 800.0)
  assert_eq!(c.max_height, 600.0)
}

///|
test "SimpleLayoutEngine single node fixed size" {
  let tree = UITree::new()
  let style : UINodeStyle = {
    ..default_node_style(),
    width: UISizing::Fixed(100.0),
    height: UISizing::Fixed(50.0),
  }
  let root = tree.add_node(style, [])
  let engine = SimpleLayoutEngine::new(tree)
  let results = engine.compute_layout(root, default_layout_constraint(800.0, 600.0))
  assert_eq!(results.length(), 1)
  assert_true!(approx(results[0].rect.x, 0.0))
  assert_true!(approx(results[0].rect.y, 0.0))
  assert_true!(approx(results[0].rect.width, 100.0))
  assert_true!(approx(results[0].rect.height, 50.0))
}

///|
test "SimpleLayoutEngine row layout" {
  let tree = UITree::new()
  let child_style : UINodeStyle = {
    ..default_node_style(),
    width: UISizing::Fixed(40.0),
    height: UISizing::Fixed(30.0),
  }
  let c1 = tree.add_node(child_style, [])
  let c2 = tree.add_node(child_style, [])
  let parent_style : UINodeStyle = {
    ..default_node_style(),
    direction: UIDirection::Row,
    gap: 10.0,
  }
  let root = tree.add_node(parent_style, [c1, c2])
  let engine = SimpleLayoutEngine::new(tree)
  let results = engine.compute_layout(root, default_layout_constraint(800.0, 600.0))
  // Should have 3 results: c1, c2, root
  assert_eq!(results.length(), 3)
  // c1 at x=0
  assert_true!(approx(results[0].rect.x, 0.0))
  assert_true!(approx(results[0].rect.width, 40.0))
  // c2 at x=40+10=50
  assert_true!(approx(results[1].rect.x, 50.0))
  assert_true!(approx(results[1].rect.width, 40.0))
  // root auto-sized: 40+10+40 = 90 wide, 30 tall
  assert_true!(approx(results[2].rect.width, 90.0))
  assert_true!(approx(results[2].rect.height, 30.0))
}

///|
test "SimpleLayoutEngine column layout" {
  let tree = UITree::new()
  let child_style : UINodeStyle = {
    ..default_node_style(),
    width: UISizing::Fixed(40.0),
    height: UISizing::Fixed(30.0),
  }
  let c1 = tree.add_node(child_style, [])
  let c2 = tree.add_node(child_style, [])
  let parent_style : UINodeStyle = {
    ..default_node_style(),
    direction: UIDirection::Column,
    gap: 5.0,
  }
  let root = tree.add_node(parent_style, [c1, c2])
  let engine = SimpleLayoutEngine::new(tree)
  let results = engine.compute_layout(root, default_layout_constraint(800.0, 600.0))
  assert_eq!(results.length(), 3)
  // c1 at y=0
  assert_true!(approx(results[0].rect.y, 0.0))
  // c2 at y=30+5=35
  assert_true!(approx(results[1].rect.y, 35.0))
  // root: 40 wide, 30+5+30 = 65 tall
  assert_true!(approx(results[2].rect.width, 40.0))
  assert_true!(approx(results[2].rect.height, 65.0))
}

///|
test "SimpleLayoutEngine with padding" {
  let tree = UITree::new()
  let child_style : UINodeStyle = {
    ..default_node_style(),
    width: UISizing::Fixed(40.0),
    height: UISizing::Fixed(30.0),
  }
  let c1 = tree.add_node(child_style, [])
  let parent_style : UINodeStyle = {
    ..default_node_style(),
    padding_left: 10.0,
    padding_top: 5.0,
    padding_right: 10.0,
    padding_bottom: 5.0,
  }
  let root = tree.add_node(parent_style, [c1])
  let engine = SimpleLayoutEngine::new(tree)
  let results = engine.compute_layout(root, default_layout_constraint(800.0, 600.0))
  // Child should be offset by padding
  assert_true!(approx(results[0].rect.x, 10.0))
  assert_true!(approx(results[0].rect.y, 5.0))
  // Parent auto-size: 10+40+10=60 wide, 5+30+5=40 tall
  assert_true!(approx(results[1].rect.width, 60.0))
  assert_true!(approx(results[1].rect.height, 40.0))
}

///|
test "SimpleUIInputAdapter pointer events" {
  let adapter = SimpleUIInputAdapter::new()
  // First frame: cursor at (100, 200), no buttons
  let snap1 = @core.new_input_snapshot_full(100.0, 200.0, 0.0, 0.0, [], [], [], [])
  let events1 = adapter.from_input_snapshot(snap1)
  // Should have PointerMove since position changed from (0,0)
  assert_eq!(events1.length(), 1)
  // Second frame: mouse button pressed
  let snap2 = @core.new_input_snapshot_full(100.0, 200.0, 0.0, 0.0, [], [0], [], [])
  let events2 = adapter.from_input_snapshot(snap2)
  assert_eq!(events2.length(), 1) // PointerDown
  // Third frame: mouse button released
  let snap3 = @core.new_input_snapshot_full(100.0, 200.0, 0.0, 0.0, [], [], [], [])
  let events3 = adapter.from_input_snapshot(snap3)
  assert_eq!(events3.length(), 1) // PointerUp
}

///|
test "SimpleUIInputAdapter key events" {
  let adapter = SimpleUIInputAdapter::new()
  let snap1 = @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [65], [], [], [])
  let events1 = adapter.from_input_snapshot(snap1)
  // KeyDown(65)
  let mut has_key_down = false
  for event in events1 {
    match event {
      UIEvent::KeyDown(65) => has_key_down = true
      _ => ()
    }
  }
  assert_true!(has_key_down)
  // Release key
  let snap2 = @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [], [], [], [])
  let events2 = adapter.from_input_snapshot(snap2)
  let mut has_key_up = false
  for event in events2 {
    match event {
      UIEvent::KeyUp(65) => has_key_up = true
      _ => ()
    }
  }
  assert_true!(has_key_up)
}

///|
test "SimpleUIInputAdapter scroll events" {
  let adapter = SimpleUIInputAdapter::new()
  let snap = @core.new_input_snapshot_full(0.0, 0.0, 1.0, -2.0, [], [], [], [])
  let events = adapter.from_input_snapshot(snap)
  let mut has_scroll = false
  for event in events {
    match event {
      UIEvent::Scroll(_, _) => has_scroll = true
      _ => ()
    }
  }
  assert_true!(has_scroll)
}

///|
test "SimpleUIRenderAdapter produces commands" {
  let shader = @gfx.new_shader_handle(1, "ui_shader")
  let adapter = SimpleUIRenderAdapter::new(shader, 0)
  let frame = @core.new_frame_budget(1, 1.0, 0)
  let target = @gfx.new_image_handle(1, 640, 480)
  let layouts = [
    {
      node_id: { value: 1 },
      rect: { x: 10.0, y: 20.0, width: 100.0, height: 50.0 },
    },
  ]
  let commands = adapter.build_draw_commands(frame, layouts, target)
  assert_eq!(commands.length(), 1)
  assert_eq!(commands[0].vertex_data.length(), 16)
  assert_eq!(commands[0].indices.length(), 6)
}

///|
test "point_in_rect" {
  let rect : LayoutRect = { x: 10.0, y: 20.0, width: 100.0, height: 50.0 }
  assert_true!(point_in_rect(rect, 10.0, 20.0))
  assert_true!(point_in_rect(rect, 50.0, 40.0))
  assert_true!(not(point_in_rect(rect, 9.0, 20.0)))
  assert_true!(not(point_in_rect(rect, 110.0, 20.0)))
  assert_true!(not(point_in_rect(rect, 50.0, 70.0)))
}

///|
test "hit_test finds topmost node" {
  let layouts : Array[LayoutResult] = [
    {
      node_id: { value: 1 },
      rect: { x: 0.0, y: 0.0, width: 200.0, height: 200.0 },
    },
    {
      node_id: { value: 2 },
      rect: { x: 50.0, y: 50.0, width: 100.0, height: 100.0 },
    },
  ]
  // Point inside both -> topmost (node 2)
  match hit_test(layouts, 75.0, 75.0) {
    Some(id) => assert_eq!(id.value, 2)
    None => fail!("expected hit")
  }
  // Point inside only node 1
  match hit_test(layouts, 10.0, 10.0) {
    Some(id) => assert_eq!(id.value, 1)
    None => fail!("expected hit")
  }
  // Point outside all
  match hit_test(layouts, 300.0, 300.0) {
    Some(_) => fail!("expected no hit")
    None => ()
  }
}

///|
test "hit_test_all" {
  let layouts : Array[LayoutResult] = [
    {
      node_id: { value: 1 },
      rect: { x: 0.0, y: 0.0, width: 200.0, height: 200.0 },
    },
    {
      node_id: { value: 2 },
      rect: { x: 50.0, y: 50.0, width: 100.0, height: 100.0 },
    },
  ]
  let all = hit_test_all(layouts, 75.0, 75.0)
  assert_eq!(all.length(), 2)
  assert_eq!(all[0].value, 1)
  assert_eq!(all[1].value, 2)
}

///|
test "UIFocusManager focus and blur" {
  let mgr = UIFocusManager::new()
  mgr.set_focusable([{ value: 1 }, { value: 2 }, { value: 3 }])
  // Initially no focus
  match mgr.current_focus() {
    None => ()
    Some(_) => fail!("expected no focus")
  }
  // Focus node 1
  let events = mgr.focus({ value: 1 })
  assert_eq!(events.length(), 1)
  match events[0] {
    FocusGained(id) => assert_eq!(id.value, 1)
    _ => fail!("expected FocusGained")
  }
  // Focus node 2 (should blur node 1)
  let events2 = mgr.focus({ value: 2 })
  assert_eq!(events2.length(), 2)
  match events2[0] {
    FocusLost(id) => assert_eq!(id.value, 1)
    _ => fail!("expected FocusLost")
  }
  match events2[1] {
    FocusGained(id) => assert_eq!(id.value, 2)
    _ => fail!("expected FocusGained")
  }
  // Focus same node (no events)
  let events3 = mgr.focus({ value: 2 })
  assert_eq!(events3.length(), 0)
  // Blur
  let events4 = mgr.blur()
  assert_eq!(events4.length(), 1)
  match events4[0] {
    FocusLost(id) => assert_eq!(id.value, 2)
    _ => fail!("expected FocusLost")
  }
  // Blur again (no events)
  let events5 = mgr.blur()
  assert_eq!(events5.length(), 0)
}

///|
test "UIFocusManager focus_next and focus_prev" {
  let mgr = UIFocusManager::new()
  let ids : Array[UINodeId] = [{ value: 10 }, { value: 20 }, { value: 30 }]
  mgr.set_focusable(ids)
  // focus_next from no focus -> first
  let e1 = mgr.focus_next()
  assert_eq!(e1.length(), 1)
  match mgr.current_focus() {
    Some(id) => assert_eq!(id.value, 10)
    None => fail!("expected focus")
  }
  // focus_next -> second
  let _ = mgr.focus_next()
  match mgr.current_focus() {
    Some(id) => assert_eq!(id.value, 20)
    None => fail!("expected focus")
  }
  // focus_next -> third
  let _ = mgr.focus_next()
  match mgr.current_focus() {
    Some(id) => assert_eq!(id.value, 30)
    None => fail!("expected focus")
  }
  // focus_next wraps to first
  let _ = mgr.focus_next()
  match mgr.current_focus() {
    Some(id) => assert_eq!(id.value, 10)
    None => fail!("expected focus")
  }
  // focus_prev wraps to last
  let _ = mgr.focus_prev()
  match mgr.current_focus() {
    Some(id) => assert_eq!(id.value, 30)
    None => fail!("expected focus")
  }
}

///|
test "UIFocusManager handle_pointer_down" {
  let mgr = UIFocusManager::new()
  mgr.set_focusable([{ value: 1 }, { value: 2 }])
  let layouts : Array[LayoutResult] = [
    {
      node_id: { value: 1 },
      rect: { x: 0.0, y: 0.0, width: 100.0, height: 100.0 },
    },
    {
      node_id: { value: 2 },
      rect: { x: 100.0, y: 0.0, width: 100.0, height: 100.0 },
    },
  ]
  // Click on node 1
  let e1 = mgr.handle_pointer_down(layouts, 50.0, 50.0)
  assert_eq!(e1.length(), 1)
  match mgr.current_focus() {
    Some(id) => assert_eq!(id.value, 1)
    None => fail!("expected focus")
  }
  // Click on node 2 (blurs 1, focuses 2)
  let e2 = mgr.handle_pointer_down(layouts, 150.0, 50.0)
  assert_eq!(e2.length(), 2)
  match mgr.current_focus() {
    Some(id) => assert_eq!(id.value, 2)
    None => fail!("expected focus")
  }
  // Click outside (blurs)
  let e3 = mgr.handle_pointer_down(layouts, 300.0, 300.0)
  assert_eq!(e3.length(), 1)
  match mgr.current_focus() {
    None => ()
    Some(_) => fail!("expected no focus")
  }
}

///|
test "ui_events_from_input_edge" {
  let key_state = @inpututil.new_key_input_state()
  let mouse_state = @inpututil.new_mouse_input_state()
  // Frame 1: press key 65 and mouse button 0
  let snap1 = @core.new_input_snapshot_full(
    100.0, 200.0, 0.0, 0.0, [65], [0], [], [],
  )
  @inpututil.update_key_input_state(key_state, snap1)
  @inpututil.update_mouse_input_state(mouse_state, snap1)
  let events1 = ui_events_from_input_edge(
    key_state, mouse_state, 100.0, 200.0,
  )
  // Should have KeyDown(65) + PointerDown
  let mut has_key_down = false
  let mut has_pointer_down = false
  for event in events1 {
    match event {
      UIEvent::KeyDown(65) => has_key_down = true
      UIEvent::PointerDown(_, _) => has_pointer_down = true
      _ => ()
    }
  }
  assert_true!(has_key_down)
  assert_true!(has_pointer_down)
  // Frame 2: release both
  let snap2 = @core.new_input_snapshot_full(100.0, 200.0, 0.0, 0.0, [], [], [], [])
  @inpututil.update_key_input_state(key_state, snap2)
  @inpututil.update_mouse_input_state(mouse_state, snap2)
  let events2 = ui_events_from_input_edge(
    key_state, mouse_state, 100.0, 200.0,
  )
  let mut has_key_up = false
  let mut has_pointer_up = false
  for event in events2 {
    match event {
      UIEvent::KeyUp(65) => has_key_up = true
      UIEvent::PointerUp(_, _) => has_pointer_up = true
      _ => ()
    }
  }
  assert_true!(has_key_up)
  assert_true!(has_pointer_up)
  // Frame 3: no changes -> no events
  let snap3 = @core.new_input_snapshot_full(100.0, 200.0, 0.0, 0.0, [], [], [], [])
  @inpututil.update_key_input_state(key_state, snap3)
  @inpututil.update_mouse_input_state(mouse_state, snap3)
  let events3 = ui_events_from_input_edge(
    key_state, mouse_state, 100.0, 200.0,
  )
  assert_eq!(events3.length(), 0)
}
