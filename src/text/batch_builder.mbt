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
  if glyphs.length() == 0 {
    return []
  }
  let vertex_data : Array[Double] = Array::make(glyphs.length() * 16, 0.0)
  let indices : Array[Int] = Array::make(glyphs.length() * 6, 0)
  let inv_atlas_w = 1.0 / self.cache.atlas_width
  let inv_atlas_h = 1.0 / self.cache.atlas_height
  let mut vertex_offset = 0
  let mut index_offset = 0
  let mut vertex_base = 0
  let mut has_region = false
  let mut min_x = 0
  let mut min_y = 0
  let mut max_x = 0
  let mut max_y = 0
  let mut src_image_id = -1
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
    let u0 = entry.atlas_x * inv_atlas_w
    let v0 = entry.atlas_y * inv_atlas_h
    let u1 = (entry.atlas_x + entry.atlas_w) * inv_atlas_w
    let v1 = (entry.atlas_y + entry.atlas_h) * inv_atlas_h
    // Quad vertices: position (x, y) + UV (u, v)
    let left = glyph.dst_x
    let top = glyph.dst_y
    let right = glyph.dst_x + glyph.dst_w
    let bottom = glyph.dst_y + glyph.dst_h
    let left_i = left.to_int()
    let top_i = top.to_int()
    let right_i = right.to_int()
    let bottom_i = bottom.to_int()
    if !has_region {
      min_x = left_i
      min_y = top_i
      max_x = right_i
      max_y = bottom_i
      has_region = true
    } else {
      if left_i < min_x {
        min_x = left_i
      }
      if top_i < min_y {
        min_y = top_i
      }
      if right_i > max_x {
        max_x = right_i
      }
      if bottom_i > max_y {
        max_y = bottom_i
      }
    }
    vertex_data[vertex_offset] = left
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = top
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = u0
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = v0
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = right
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = top
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = u1
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = v0
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = right
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = bottom
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = u1
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = v1
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = left
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = bottom
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = u0
    vertex_offset = vertex_offset + 1
    vertex_data[vertex_offset] = v1
    vertex_offset = vertex_offset + 1
    indices[index_offset] = vertex_base
    index_offset = index_offset + 1
    indices[index_offset] = vertex_base + 1
    index_offset = index_offset + 1
    indices[index_offset] = vertex_base + 2
    index_offset = index_offset + 1
    indices[index_offset] = vertex_base + 2
    index_offset = index_offset + 1
    indices[index_offset] = vertex_base + 3
    index_offset = index_offset + 1
    indices[index_offset] = vertex_base
    index_offset = index_offset + 1
    if src_image_id < 0 {
      src_image_id = entry.atlas_page_id
    }
    vertex_base = vertex_base + 4
  }
  if !has_region {
    []
  } else {
    let command_vertex_data : Array[Double] = if vertex_offset == vertex_data.length() {
      vertex_data
    } else {
      let out : Array[Double] = []
      for i in 0..<vertex_offset {
        out.push(vertex_data[i])
      }
      out
    }
    let command_indices : Array[Int] = if index_offset == indices.length() {
      indices
    } else {
      let out : Array[Int] = []
      for i in 0..<index_offset {
        out.push(indices[i])
      }
      out
    }
    let src_image_ids : Array[Int] = if src_image_id < 0 {
      []
    } else {
      [src_image_id]
    }
    let region_width = max_x - min_x
    let region_height = max_y - min_y
    let merged_region = @gfx.new_dst_region(
      min_x,
      min_y,
      region_width,
      region_height,
      index_offset,
    )
    [
      @gfx.new_draw_triangles_command(
        target,
        shader,
        [merged_region],
        0,
        self.pipeline_id,
        0,
        @gfx.blend_mode_from_int(1),
        command_vertex_data,
        command_indices,
        src_image_ids,
        [],
      ),
    ]
  }
}
