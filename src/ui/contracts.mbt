///|
/// UI contracts.
///
/// Reference:
/// - mizchi/layout

///|
pub struct UINodeId {
  value : Int
} derive(Show)

///|
pub struct LayoutConstraint {
  min_width : Double
  min_height : Double
  max_width : Double
  max_height : Double
} derive(Show)

///|
pub struct LayoutRect {
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Show)

///|
pub struct LayoutResult {
  node_id : UINodeId
  rect : LayoutRect
} derive(Show)

///|
pub enum UIEvent {
  PointerDown(Double, Double)
  PointerUp(Double, Double)
  PointerMove(Double, Double)
  Scroll(Double, Double)
  KeyDown(Int)
  KeyUp(Int)
} derive(Show)

///|
pub trait LayoutEngine {
  compute_layout(Self, root : UINodeId, constraint : LayoutConstraint) -> Array[
    LayoutResult,
  ] raise
}

///|
pub trait UIInputAdapter {
  from_input_snapshot(Self, snapshot : @core.InputSnapshot) -> Array[UIEvent]
}

///|
pub trait UIRenderAdapter {
  build_draw_commands(
    Self,
    frame : @core.FrameBudget,
    layouts : Array[LayoutResult],
    target : @gfx.ImageHandle,
  ) -> Array[@gfx.DrawTrianglesCommand] raise
}

///|
pub fn default_layout_constraint(
  width : Double,
  height : Double,
) -> LayoutConstraint {
  { min_width: 0.0, min_height: 0.0, max_width: width, max_height: height }
}

///|
pub fn point_in_rect(rect : LayoutRect, x : Double, y : Double) -> Bool {
  x >= rect.x && x < rect.x + rect.width && y >= rect.y &&
  y < rect.y + rect.height
}

///|
/// Find the last (topmost) node that contains the given point.
pub fn hit_test(
  layouts : Array[LayoutResult],
  x : Double,
  y : Double,
) -> UINodeId? {
  let mut result : UINodeId? = None
  for layout in layouts {
    if point_in_rect(layout.rect, x, y) {
      result = Some(layout.node_id)
    }
  }
  result
}

///|
/// Find all nodes that contain the given point (bottom-to-top order).
pub fn hit_test_all(
  layouts : Array[LayoutResult],
  x : Double,
  y : Double,
) -> Array[UINodeId] {
  let result : Array[UINodeId] = []
  for layout in layouts {
    if point_in_rect(layout.rect, x, y) {
      result.push(layout.node_id)
    }
  }
  result
}

///|
pub(all) enum UIFocusEvent {
  FocusGained(UINodeId)
  FocusLost(UINodeId)
} derive(Show)

///|
pub struct UIFocusManager {
  mut focused : UINodeId?
  mut focusable_ids : Array[UINodeId]
}

///|
pub fn UIFocusManager::new() -> UIFocusManager {
  { focused: None, focusable_ids: [] }
}

///|
pub fn UIFocusManager::set_focusable(
  self : UIFocusManager,
  ids : Array[UINodeId],
) -> Unit {
  self.focusable_ids = ids
}

///|
pub fn UIFocusManager::current_focus(self : UIFocusManager) -> UINodeId? {
  self.focused
}

///|
/// Focus a specific node. Returns focus/blur events.
pub fn UIFocusManager::focus(
  self : UIFocusManager,
  id : UINodeId,
) -> Array[UIFocusEvent] {
  let events : Array[UIFocusEvent] = []
  match self.focused {
    Some(prev) =>
      if prev.value != id.value {
        events.push(UIFocusEvent::FocusLost(prev))
        events.push(UIFocusEvent::FocusGained(id))
        self.focused = Some(id)
      }
    None => {
      events.push(UIFocusEvent::FocusGained(id))
      self.focused = Some(id)
    }
  }
  events
}

///|
/// Remove focus. Returns blur event if something was focused.
pub fn UIFocusManager::blur(self : UIFocusManager) -> Array[UIFocusEvent] {
  let events : Array[UIFocusEvent] = []
  match self.focused {
    Some(prev) => {
      events.push(UIFocusEvent::FocusLost(prev))
      self.focused = None
    }
    None => ()
  }
  events
}

///|
fn UIFocusManager::find_focus_index(self : UIFocusManager) -> Int {
  match self.focused {
    None => -1
    Some(id) => {
      for i, fid in self.focusable_ids {
        if fid.value == id.value {
          return i
        }
      }
      -1
    }
  }
}

///|
/// Move focus to the next focusable node (tab order).
pub fn UIFocusManager::focus_next(
  self : UIFocusManager,
) -> Array[UIFocusEvent] {
  let n = self.focusable_ids.length()
  if n == 0 {
    return []
  }
  let current = self.find_focus_index()
  let next_idx = (current + 1) % n
  self.focus(self.focusable_ids[next_idx])
}

///|
/// Move focus to the previous focusable node (shift-tab order).
pub fn UIFocusManager::focus_prev(
  self : UIFocusManager,
) -> Array[UIFocusEvent] {
  let n = self.focusable_ids.length()
  if n == 0 {
    return []
  }
  let current = self.find_focus_index()
  let prev_idx = if current <= 0 { n - 1 } else { current - 1 }
  self.focus(self.focusable_ids[prev_idx])
}

///|
/// Handle a pointer down event: focus the hit node, or blur if no hit.
pub fn UIFocusManager::handle_pointer_down(
  self : UIFocusManager,
  layouts : Array[LayoutResult],
  x : Double,
  y : Double,
) -> Array[UIFocusEvent] {
  match hit_test(layouts, x, y) {
    Some(id) => {
      for fid in self.focusable_ids {
        if fid.value == id.value {
          return self.focus(id)
        }
      }
      self.blur()
    }
    None => self.blur()
  }
}

///|
/// Convert inpututil edge state to UIEvents for the current frame.
/// Uses just-pressed/just-released from the edge detection to generate
/// PointerDown/Up and KeyDown/Up events.
pub fn ui_events_from_input_edge(
  key_state : @inpututil.KeyInputState,
  mouse_state : @inpututil.MouseButtonInputState,
  cursor_x : Double,
  cursor_y : Double,
) -> Array[UIEvent] {
  let events : Array[UIEvent] = []
  let just_pressed_keys = @inpututil.append_just_pressed_keys(key_state, [])
  for key in just_pressed_keys {
    events.push(UIEvent::KeyDown(key))
  }
  let just_released_keys = @inpututil.append_just_released_keys(key_state, [])
  for key in just_released_keys {
    events.push(UIEvent::KeyUp(key))
  }
  let just_pressed_buttons = @inpututil.append_just_pressed_mouse_buttons(
    mouse_state,
    [],
  )
  for _ in just_pressed_buttons {
    events.push(UIEvent::PointerDown(cursor_x, cursor_y))
  }
  let just_released_buttons = @inpututil.append_just_released_mouse_buttons(
    mouse_state,
    [],
  )
  for _ in just_released_buttons {
    events.push(UIEvent::PointerUp(cursor_x, cursor_y))
  }
  events
}
