///|
/// SimpleFontEngine wraps a TTFont for text measurement and shaping.

///|
pub struct SimpleFontEngine {
  font : @font.TTFont
}

///|
pub fn SimpleFontEngine::new(font : @font.TTFont) -> SimpleFontEngine {
  { font }
}

///|
pub impl FontEngine for SimpleFontEngine with measure(self, run) {
  let size = run.style.size_px
  let width = self.font.measure_text(run.text, size)
  let scale = size / self.font.units_per_em.to_double()
  let ascent = self.font.ascent.to_double() * scale
  let descent = self.font.descent.to_double().abs() * scale
  let height = ascent + descent
  { width, height, baseline: ascent }
}

///|
pub impl FontEngine for SimpleFontEngine with shape(self, run) {
  let size = run.style.size_px
  let positions = self.font.layout_text(run.text, size)
  let scale = size / self.font.units_per_em.to_double()
  let quads : Array[GlyphQuad] = []
  for pos in positions {
    let glyph_id = pos.glyph_id
    if glyph_id == 0 {
      continue
    }
    let metrics = self.font.glyph_metrics(glyph_id)
    let bbox = metrics.bbox
    let gw = (bbox.x_max - bbox.x_min).to_double() * scale
    let gh = (bbox.y_max - bbox.y_min).to_double() * scale
    if gw <= 0.0 || gh <= 0.0 {
      continue
    }
    let dst_x = pos.x_offset + metrics.left_side_bearing.to_double() * scale
    let dst_y = -(bbox.y_max.to_double() * scale)
    quads.push(
      {
        glyph_id,
        atlas_x: 0.0,
        atlas_y: 0.0,
        atlas_w: gw,
        atlas_h: gh,
        dst_x,
        dst_y,
        dst_w: gw,
        dst_h: gh,
      },
    )
  }
  quads
}
