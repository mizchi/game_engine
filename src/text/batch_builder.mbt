///|
/// SimpleTextBatchBuilder creates draw commands from positioned glyph quads.

///|
pub struct SimpleTextBatchBuilder {
  cache : GlyphCache
  pipeline_id : Int
}

///|
pub fn SimpleTextBatchBuilder::new(
  cache : GlyphCache,
  pipeline_id : Int,
) -> SimpleTextBatchBuilder {
  { cache, pipeline_id }
}

///|
pub impl TextBatchBuilder for SimpleTextBatchBuilder with build_draw_commands(
  self,
  target,
  glyphs,
  shader,
) {
  let commands : Array[@gfx.DrawTrianglesCommand] = []
  for glyph in glyphs {
    let entry = match self.cache.get(glyph.glyph_id) {
      Some(e) => e
      None =>
        match self.cache.allocate(glyph.glyph_id, glyph.dst_w, glyph.dst_h) {
          Some(e) => e
          None => continue
        }
    }
    // Compute UV coordinates in atlas
    let atlas_w = self.cache.atlas_width
    let atlas_h = self.cache.atlas_height
    let u0 = entry.atlas_x / atlas_w
    let v0 = entry.atlas_y / atlas_h
    let u1 = (entry.atlas_x + entry.atlas_w) / atlas_w
    let v1 = (entry.atlas_y + entry.atlas_h) / atlas_h
    // Quad vertices: position (x, y) + UV (u, v)
    let left = glyph.dst_x
    let top = glyph.dst_y
    let right = glyph.dst_x + glyph.dst_w
    let bottom = glyph.dst_y + glyph.dst_h
    let vertex_data = [
      left, top, u0, v0, right, top, u1, v0, right, bottom, u1, v1, left, bottom,
      u0, v1,
    ]
    let indices = [0, 1, 2, 2, 3, 0]
    let region = @gfx.new_dst_region(
      left.to_int(),
      top.to_int(),
      glyph.dst_w.to_int(),
      glyph.dst_h.to_int(),
      6,
    )
    commands.push(
      @gfx.new_draw_triangles_command(
        target,
        shader,
        [region],
        0,
        self.pipeline_id,
        0,
        @gfx.blend_mode_from_int(1),
        vertex_data,
        indices,
        [entry.atlas_page_id],
        [],
      ),
    )
  }
  commands
}
