///|
/// UI node tree and style definitions.

///|
pub enum UIDirection {
  Row
  Column
} derive(Show)

///|
pub enum UISizing {
  Fixed(Double)
  Percent(Double)
  Auto
} derive(Show)

///|
pub struct UINodeStyle {
  direction : UIDirection
  width : UISizing
  height : UISizing
  padding_left : Double
  padding_right : Double
  padding_top : Double
  padding_bottom : Double
  gap : Double
  align : @layout_types.Alignment
} derive(Show)

///|
pub fn default_node_style() -> UINodeStyle {
  {
    direction: UIDirection::Row,
    width: UISizing::Auto,
    height: UISizing::Auto,
    padding_left: 0.0,
    padding_right: 0.0,
    padding_top: 0.0,
    padding_bottom: 0.0,
    gap: 0.0,
    align: @layout_types.Alignment::Start,
  }
}

///|
pub struct UINode {
  id : UINodeId
  style : UINodeStyle
  children : Array[UINodeId]
} derive(Show)

///|
pub struct UITree {
  nodes : Map[Int, UINode]
  mut next_id : Int
}

///|
pub fn UITree::new() -> UITree {
  { nodes: {}, next_id: 1 }
}

///|
pub fn UITree::add_node(
  self : UITree,
  style : UINodeStyle,
  children : Array[UINodeId],
) -> UINodeId {
  let id : UINodeId = { value: self.next_id }
  self.next_id = self.next_id + 1
  let node : UINode = { id, style, children }
  self.nodes.set(id.value, node)
  id
}

///|
pub fn UITree::get_node(self : UITree, id : UINodeId) -> UINode? {
  self.nodes.get(id.value)
}

///|
pub fn UITree::node_count(self : UITree) -> Int {
  self.nodes.size()
}
