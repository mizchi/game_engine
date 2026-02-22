///|
priv struct ResolvedTouchPoints {
  touches : Array[@core.TouchPoint]
  saw_native_touch : Bool
}

///|
fn has_left_mouse_button_pressed(pressed_mouse_buttons : Array[Int]) -> Bool {
  let mut found = false
  for button in pressed_mouse_buttons {
    if button == 0 {
      found = true
    }
  }
  found
}

///|
fn resolve_touch_points_with_mouse_fallback(
  touches : Array[@core.TouchPoint],
  pressed_mouse_buttons : Array[Int],
  cursor_x : Double,
  cursor_y : Double,
  saw_native_touch : Bool,
  fallback_enabled : Bool,
) -> ResolvedTouchPoints {
  // Filter out Indirect touches (macOS trackpad surface touches)
  let direct_touches : Array[@core.TouchPoint] = []
  for touch in touches {
    if @core.touch_source_to_int(touch.source) != 1 {
      direct_touches.push(touch)
    }
  }
  if direct_touches.length() > 0 {
    { touches: direct_touches, saw_native_touch: true }
  } else if saw_native_touch {
    { touches: direct_touches, saw_native_touch }
  } else if !fallback_enabled {
    { touches: direct_touches, saw_native_touch: false }
  } else {
    let resolved_touches = direct_touches
    if has_left_mouse_button_pressed(pressed_mouse_buttons) {
      resolved_touches.push(
        @core.new_touch_point_with_source(
          0,
          cursor_x,
          cursor_y,
          @core.touch_source_from_int(2),
        ),
      )
    }
    { touches: resolved_touches, saw_native_touch: false }
  }
}
