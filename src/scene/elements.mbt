pub fn rect(
  x~ : Double = 0.0,
  y~ : Double = 0.0,
  w~ : Double,
  h~ : Double,
  fill~ : Int = 0xFFFFFF,
  alpha~ : Double = 1.0,
  children~ : Array[SceneNode] = [],
) -> SceneNode {
  @ui.h(
    "rect",
    [
      ("x", @ui.attr_static(x.to_string())),
      ("y", @ui.attr_static(y.to_string())),
      ("w", @ui.attr_static(w.to_string())),
      ("h", @ui.attr_static(h.to_string())),
      ("fill", @ui.attr_static(fill.to_string())),
      ("alpha", @ui.attr_static(alpha.to_string())),
    ],
    children,
  )
}

pub fn label(
  x~ : Double = 0.0,
  y~ : Double = 0.0,
  content~ : String,
  color~ : Int = 0xFFFFFF,
  scale~ : Double = 1.0,
) -> SceneNode {
  @ui.h(
    "label",
    [
      ("x", @ui.attr_static(x.to_string())),
      ("y", @ui.attr_static(y.to_string())),
      ("content", @ui.attr_static(content)),
      ("color", @ui.attr_static(color.to_string())),
      ("scale", @ui.attr_static(scale.to_string())),
    ],
    [],
  )
}

pub fn group(
  x~ : Double = 0.0,
  y~ : Double = 0.0,
  children~ : Array[SceneNode],
) -> SceneNode {
  @ui.h(
    "group",
    [
      ("x", @ui.attr_static(x.to_string())),
      ("y", @ui.attr_static(y.to_string())),
    ],
    children,
  )
}

pub fn line(
  x0~ : Double,
  y0~ : Double,
  x1~ : Double,
  y1~ : Double,
  width~ : Double = 1.0,
  color~ : Int = 0xFFFFFF,
) -> SceneNode {
  @ui.h(
    "line",
    [
      ("x0", @ui.attr_static(x0.to_string())),
      ("y0", @ui.attr_static(y0.to_string())),
      ("x1", @ui.attr_static(x1.to_string())),
      ("y1", @ui.attr_static(y1.to_string())),
      ("width", @ui.attr_static(width.to_string())),
      ("color", @ui.attr_static(color.to_string())),
    ],
    [],
  )
}

pub fn rect_outline(
  x~ : Double,
  y~ : Double,
  w~ : Double,
  h~ : Double,
  line_width~ : Double = 1.0,
  color~ : Int = 0xFFFFFF,
) -> SceneNode {
  @ui.h(
    "rect_outline",
    [
      ("x", @ui.attr_static(x.to_string())),
      ("y", @ui.attr_static(y.to_string())),
      ("w", @ui.attr_static(w.to_string())),
      ("h", @ui.attr_static(h.to_string())),
      ("line_width", @ui.attr_static(line_width.to_string())),
      ("color", @ui.attr_static(color.to_string())),
    ],
    [],
  )
}

pub fn show(when : () -> Bool, child : () -> SceneNode) -> SceneNode {
  @ui.show(when, child)
}

pub fn for_each(items : () -> Array[SceneNode]) -> SceneNode {
  @ui.for_each(items)
}

pub fn fragment(children : Array[SceneNode]) -> SceneNode {
  @ui.fragment(children)
}

pub fn switch_(
  cases~ : Array[@ui.MatchCase[Unit, String]],
  fallback? : (() -> SceneNode)?,
) -> SceneNode {
  @ui.switch_(cases~, fallback?)
}

pub fn match_case(
  when~ : () -> Bool,
  render~ : () -> SceneNode,
) -> @ui.MatchCase[Unit, String] {
  @ui.match_case(when~, render~)
}
