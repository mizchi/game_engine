///|
/// SimpleLayoutEngine computes layout for UI node trees.

///|
pub struct SimpleLayoutEngine {
  tree : UITree
}

///|
pub fn SimpleLayoutEngine::new(tree : UITree) -> SimpleLayoutEngine {
  { tree }
}

///|
fn resolve_size(sizing : UISizing, available : Double) -> Double {
  match sizing {
    UISizing::Fixed(v) => v
    UISizing::Percent(p) => available * p / 100.0
    UISizing::Auto => available
  }
}

///|
fn layout_node(
  tree : UITree,
  node_id : UINodeId,
  constraint : LayoutConstraint,
  results : Array[LayoutResult],
  offset_x : Double,
  offset_y : Double,
) -> (Double, Double) {
  let node = match tree.get_node(node_id) {
    Some(n) => n
    None => return (0.0, 0.0)
  }
  let style = node.style
  let avail_w = constraint.max_width
  let avail_h = constraint.max_height
  let content_w = resolve_size(style.width, avail_w)
  let content_h = resolve_size(style.height, avail_h)
  let inner_w = content_w - style.padding_left - style.padding_right
  let inner_h = content_h - style.padding_top - style.padding_bottom
  let clamped_w = @layout.clamp_value(
    inner_w,
    0.0,
    avail_w - style.padding_left - style.padding_right,
  )
  let clamped_h = @layout.clamp_value(
    inner_h,
    0.0,
    avail_h - style.padding_top - style.padding_bottom,
  )
  // Layout children
  let is_row = match style.direction {
    UIDirection::Row => true
    UIDirection::Column => false
  }
  let mut child_offset_main = 0.0
  let mut max_cross = 0.0
  for child_id in node.children {
    let child_avail_w = if is_row {
      clamped_w - child_offset_main
    } else {
      clamped_w
    }
    let child_avail_h = if is_row {
      clamped_h
    } else {
      clamped_h - child_offset_main
    }
    let child_constraint : LayoutConstraint = {
      min_width: 0.0,
      min_height: 0.0,
      max_width: if child_avail_w > 0.0 { child_avail_w } else { 0.0 },
      max_height: if child_avail_h > 0.0 { child_avail_h } else { 0.0 },
    }
    let cx = if is_row {
      offset_x + style.padding_left + child_offset_main
    } else {
      offset_x + style.padding_left
    }
    let cy = if is_row {
      offset_y + style.padding_top
    } else {
      offset_y + style.padding_top + child_offset_main
    }
    let (cw, ch) = layout_node(tree, child_id, child_constraint, results, cx, cy)
    if is_row {
      child_offset_main = child_offset_main + cw + style.gap
      if ch > max_cross {
        max_cross = ch
      }
    } else {
      child_offset_main = child_offset_main + ch + style.gap
      if cw > max_cross {
        max_cross = cw
      }
    }
  }
  // Determine final size
  let final_w = match style.width {
    UISizing::Auto =>
      if is_row {
        style.padding_left +
          child_offset_main -
          (if node.children.length() > 0 { style.gap } else { 0.0 }) +
          style.padding_right
      } else {
        style.padding_left + max_cross + style.padding_right
      }
    _ => content_w
  }
  let final_h = match style.height {
    UISizing::Auto =>
      if is_row {
        style.padding_top + max_cross + style.padding_bottom
      } else {
        style.padding_top +
          child_offset_main -
          (if node.children.length() > 0 { style.gap } else { 0.0 }) +
          style.padding_bottom
      }
    _ => content_h
  }
  results.push(
    { node_id, rect: { x: offset_x, y: offset_y, width: final_w, height: final_h } },
  )
  (final_w, final_h)
}

///|
pub impl LayoutEngine for SimpleLayoutEngine with compute_layout(
  self,
  root,
  constraint,
) {
  let results : Array[LayoutResult] = []
  let _ = layout_node(self.tree, root, constraint, results, 0.0, 0.0)
  results
}
