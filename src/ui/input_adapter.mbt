///|
/// SimpleUIInputAdapter converts InputSnapshot to UIEvents.

///|
pub struct SimpleUIInputAdapter {
  mut prev_pressed_mouse : Array[Int]
  mut prev_cursor_x : Double
  mut prev_cursor_y : Double
  mut prev_pressed_keys : Array[Int]
}

///|
pub fn SimpleUIInputAdapter::new() -> SimpleUIInputAdapter {
  {
    prev_pressed_mouse: [],
    prev_cursor_x: 0.0,
    prev_cursor_y: 0.0,
    prev_pressed_keys: [],
  }
}

///|
fn contains_int(arr : Array[Int], value : Int) -> Bool {
  for item in arr {
    if item == value {
      return true
    }
  }
  false
}

///|
pub impl UIInputAdapter for SimpleUIInputAdapter with from_input_snapshot(
  self,
  snapshot,
) {
  let events : Array[UIEvent] = []
  // Pointer move
  if snapshot.cursor_x != self.prev_cursor_x ||
    snapshot.cursor_y != self.prev_cursor_y {
    events.push(UIEvent::PointerMove(snapshot.cursor_x, snapshot.cursor_y))
  }
  // Mouse button down (newly pressed)
  for btn in snapshot.pressed_mouse_buttons {
    if not(contains_int(self.prev_pressed_mouse, btn)) {
      events.push(UIEvent::PointerDown(snapshot.cursor_x, snapshot.cursor_y))
    }
  }
  // Mouse button up (newly released)
  for btn in self.prev_pressed_mouse {
    if not(contains_int(snapshot.pressed_mouse_buttons, btn)) {
      events.push(UIEvent::PointerUp(snapshot.cursor_x, snapshot.cursor_y))
    }
  }
  // Scroll
  if snapshot.wheel_x != 0.0 || snapshot.wheel_y != 0.0 {
    events.push(UIEvent::Scroll(snapshot.wheel_x, snapshot.wheel_y))
  }
  // Key down (newly pressed)
  for key in snapshot.pressed_keys {
    if not(contains_int(self.prev_pressed_keys, key)) {
      events.push(UIEvent::KeyDown(key))
    }
  }
  // Key up (newly released)
  for key in self.prev_pressed_keys {
    if not(contains_int(snapshot.pressed_keys, key)) {
      events.push(UIEvent::KeyUp(key))
    }
  }
  // Update state
  self.prev_pressed_mouse = snapshot.pressed_mouse_buttons
  self.prev_cursor_x = snapshot.cursor_x
  self.prev_cursor_y = snapshot.cursor_y
  self.prev_pressed_keys = snapshot.pressed_keys
  events
}
