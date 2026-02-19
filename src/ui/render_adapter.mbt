///|
/// SimpleUIRenderAdapter creates draw commands for laid-out nodes.

///|
pub struct SimpleUIRenderAdapter {
  shader : @gfx.ShaderHandle
  pipeline_id : Int
}

///|
pub fn SimpleUIRenderAdapter::new(
  shader : @gfx.ShaderHandle,
  pipeline_id : Int,
) -> SimpleUIRenderAdapter {
  { shader, pipeline_id }
}

///|
pub impl UIRenderAdapter for SimpleUIRenderAdapter with build_draw_commands(
  self,
  _frame,
  layouts,
  target,
) {
  let commands : Array[@gfx.DrawTrianglesCommand] = []
  for layout in layouts {
    let r = layout.rect
    let vertices = [
      r.x, r.y, 0.0, 0.0,
      r.x + r.width, r.y, 1.0, 0.0,
      r.x + r.width, r.y + r.height, 1.0, 1.0,
      r.x, r.y + r.height, 0.0, 1.0,
    ]
    let indices = [0, 1, 2, 2, 3, 0]
    let region = @gfx.new_dst_region(
      r.x.to_int(),
      r.y.to_int(),
      r.width.to_int(),
      r.height.to_int(),
      6,
    )
    commands.push(
      @gfx.new_draw_triangles_command(
        target,
        self.shader,
        [region],
        0,
        self.pipeline_id,
        0,
        @gfx.blend_mode_from_int(1),
        vertices,
        indices,
        [],
        [layout.node_id.value],
      ),
    )
  }
  commands
}
