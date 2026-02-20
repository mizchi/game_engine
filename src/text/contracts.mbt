///|
/// Text contracts.
///
/// Reference:
/// - mizchi/font

///|
pub struct FontKey {
  family : String
  weight : Int
  italic : Bool
} derive(Show)

///|
pub struct TextStyle {
  font : FontKey
  size_px : Double
  line_height : Double
  letter_spacing : Double
} derive(Show)

///|
pub struct TextMetrics {
  width : Double
  height : Double
  baseline : Double
} derive(Show)

///|
pub struct GlyphQuad {
  glyph_id : Int
  atlas_x : Double
  atlas_y : Double
  atlas_w : Double
  atlas_h : Double
  dst_x : Double
  dst_y : Double
  dst_w : Double
  dst_h : Double
} derive(Show)

///|
pub struct TextRun {
  text : String
  style : TextStyle
} derive(Show)

///|
pub trait FontEngine {
  measure(Self, run : TextRun) -> TextMetrics
  shape(Self, run : TextRun) -> Array[GlyphQuad] raise
}

///|
pub trait TextBatchBuilder {
  build_draw_commands(
    Self,
    target : @gfx.ImageHandle,
    glyphs : Array[GlyphQuad],
    shader : @gfx.ShaderHandle,
  ) -> Array[@gfx.DrawTrianglesCommand] raise
}

///|
pub fn new_text_run(text : String, style : TextStyle) -> TextRun {
  { text, style }
}

///|
pub fn default_text_style(family : String, size_px : Double) -> TextStyle {
  {
    font: { family, weight: 400, italic: false },
    size_px,
    line_height: size_px * 1.4,
    letter_spacing: 0.0,
  }
}

///|
/// Detect font format from raw bytes.
pub enum FontFormat {
  TrueType
  OpenType
  Woff1
  Woff2
  TrueTypeCollection
  Unknown
} derive(Show, Eq)

///|
pub fn detect_font_format(data : Bytes) -> FontFormat {
  if data.length() < 4 {
    return Unknown
  }
  let b0 = data[0]
  let b1 = data[1]
  let b2 = data[2]
  let b3 = data[3]
  if b0 == b'\x00' && b1 == b'\x01' && b2 == b'\x00' && b3 == b'\x00' {
    TrueType
  } else if b0 == b'\x4F' && b1 == b'\x54' && b2 == b'\x54' && b3 == b'\x4F' {
    OpenType // "OTTO"
  } else if b0 == b'\x77' && b1 == b'\x4F' && b2 == b'\x46' && b3 == b'\x46' {
    Woff1 // "wOFF"
  } else if b0 == b'\x77' && b1 == b'\x4F' && b2 == b'\x46' && b3 == b'\x32' {
    Woff2 // "wOF2"
  } else if b0 == b'\x74' && b1 == b'\x74' && b2 == b'\x63' && b3 == b'\x66' {
    TrueTypeCollection // "ttcf"
  } else {
    Unknown
  }
}

///|
/// Parse font from raw bytes (auto-detects TTF/OTF/WOFF1/WOFF2).
pub fn parse_font_bytes(data : Bytes) -> @font.TTFont? {
  @font.parse_font(data)
}

///|
/// Load font engine from raw bytes.
pub fn load_font_engine_from_bytes(data : Bytes) -> SimpleFontEngine? {
  match @font.parse_font(data) {
    Some(font) => Some(SimpleFontEngine::new(font))
    None => None
  }
}

///|
/// Rasterized glyph pixel data (RGBA8 flat array).
pub struct GlyphBitmap {
  width : Int
  height : Int
  pixels : Array[Int]
} derive(Show)

///|
/// Atlas that combines region tracking (GlyphCache) with pixel storage.
pub struct GlyphAtlas {
  cache : GlyphCache
  width : Int
  height : Int
  pixels : Array[Int]
}

///|
pub fn GlyphAtlas::new(width : Int, height : Int, page_id : Int) -> GlyphAtlas {
  let total = width * height * 4
  let pixels : Array[Int] = Array::make(total, 0)
  {
    cache: GlyphCache::new(width.to_double(), height.to_double(), page_id),
    width,
    height,
    pixels,
  }
}

///|
pub fn GlyphAtlas::get_cache(self : GlyphAtlas) -> GlyphCache {
  self.cache
}

///|
pub fn GlyphAtlas::get_pixels(self : GlyphAtlas) -> Array[Int] {
  self.pixels
}

///|
/// Convert font outline PathCommands to SVG path `d` attribute string.
fn path_commands_to_svg_d(commands : Array[@msvg.PathCommand]) -> String {
  let parts : Array[String] = []
  for cmd in commands {
    match cmd {
      @msvg.PathCommand::MoveTo(x, y) =>
        parts.push("M " + x.to_string() + " " + y.to_string())
      @msvg.PathCommand::LineTo(x, y) =>
        parts.push("L " + x.to_string() + " " + y.to_string())
      @msvg.PathCommand::QuadraticCurveTo(cx, cy, x, y) =>
        parts.push(
          "Q " +
          cx.to_string() +
          " " +
          cy.to_string() +
          " " +
          x.to_string() +
          " " +
          y.to_string(),
        )
      @msvg.PathCommand::CurveTo(cx1, cy1, cx2, cy2, x, y) =>
        parts.push(
          "C " +
          cx1.to_string() +
          " " +
          cy1.to_string() +
          " " +
          cx2.to_string() +
          " " +
          cy2.to_string() +
          " " +
          x.to_string() +
          " " +
          y.to_string(),
        )
      @msvg.PathCommand::ClosePath => parts.push("Z")
      _ => ()
    }
  }
  let mut result = ""
  for i, p in parts {
    if i > 0 {
      result = result + " "
    }
    result = result + p
  }
  result
}

///|
/// Compute bounding box from outline path commands.
fn outline_bbox(
  commands : Array[@msvg.PathCommand],
) -> (Double, Double, Double, Double) {
  let mut x_min = 1.0e10
  let mut y_min = 1.0e10
  let mut x_max = -1.0e10
  let mut y_max = -1.0e10
  for cmd in commands {
    let points : Array[(Double, Double)] = match cmd {
      @msvg.PathCommand::MoveTo(x, y) => [(x, y)]
      @msvg.PathCommand::LineTo(x, y) => [(x, y)]
      @msvg.PathCommand::QuadraticCurveTo(cx, cy, x, y) => [(cx, cy), (x, y)]
      @msvg.PathCommand::CurveTo(cx1, cy1, cx2, cy2, x, y) =>
        [(cx1, cy1), (cx2, cy2), (x, y)]
      _ => []
    }
    for pt in points {
      let (px, py) = pt
      if px < x_min {
        x_min = px
      }
      if py < y_min {
        y_min = py
      }
      if px > x_max {
        x_max = px
      }
      if py > y_max {
        y_max = py
      }
    }
  }
  (x_min, y_min, x_max, y_max)
}

///|
/// Rasterize a glyph outline to a pixel bitmap using SVG rendering.
pub fn rasterize_glyph(
  font : @font.TTFont,
  codepoint : Int,
  size_px : Double,
) -> GlyphBitmap? {
  let outline = font.scaled_outline(codepoint, size_px)
  if outline.length() == 0 {
    return None
  }
  let (x_min, _y_min, x_max, y_max) = outline_bbox(outline)
  if x_max <= x_min || y_max <= _y_min {
    return None
  }
  let pad = 1.0
  let w = (x_max - x_min + pad * 2.0).ceil().to_int()
  let h = (y_max - _y_min + pad * 2.0).ceil().to_int()
  if w <= 0 || h <= 0 {
    return None
  }
  let d = path_commands_to_svg_d(outline)
  // SVG with y-flip transform: font coords (y-up) → SVG coords (y-down)
  let tx = (-x_min + pad).to_string()
  let ty = (y_max + pad).to_string()
  let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" +
    w.to_string() +
    "\" height=\"" +
    h.to_string() +
    "\"><g transform=\"translate(" +
    tx +
    ", " +
    ty +
    ") scale(1, -1)\"><path d=\"" +
    d +
    "\" fill=\"white\"/></g></svg>"
  match @msvg.render_svg_to_image(svg, w, h) {
    Some(img) => {
      let pixels : Array[Int] = []
      for i = 0; i < img.pixels.length(); i = i + 1 {
        let color = img.pixels[i]
        pixels.push(color.r)
        pixels.push(color.g)
        pixels.push(color.b)
        pixels.push(color.a)
      }
      Some({ width: img.width, height: img.height, pixels })
    }
    None => None
  }
}

///|
/// Copy a glyph bitmap into the atlas pixel buffer at the given position.
fn blit_to_atlas(
  atlas_pixels : Array[Int],
  atlas_width : Int,
  src : GlyphBitmap,
  dst_x : Int,
  dst_y : Int,
) -> Unit {
  if atlas_width <= 0 || src.width <= 0 || src.height <= 0 {
    return
  }
  let atlas_height = atlas_pixels.length() / 4 / atlas_width
  if atlas_height <= 0 {
    return
  }
  if src.pixels.length() < src.width * src.height * 4 {
    return
  }
  let src_x_start = if dst_x < 0 { -dst_x } else { 0 }
  let src_y_start = if dst_y < 0 { -dst_y } else { 0 }
  let mut src_x_end = src.width
  let mut src_y_end = src.height
  if dst_x + src_x_end > atlas_width {
    src_x_end = atlas_width - dst_x
  }
  if dst_y + src_y_end > atlas_height {
    src_y_end = atlas_height - dst_y
  }
  if src_x_start >= src_x_end || src_y_start >= src_y_end {
    return
  }
  let copy_width = src_x_end - src_x_start
  let row_copy_len = copy_width * 4
  for row in src_y_start..<src_y_end {
    let src_offset = (row * src.width + src_x_start) * 4
    let dst_offset = ((dst_y + row) * atlas_width + (dst_x + src_x_start)) * 4
    src.pixels[src_offset:src_offset + row_copy_len].blit_to(
      atlas_pixels,
      dst_offset~,
    )
  }
}

///|
/// Rasterize a glyph and place it into the atlas.
/// Returns the cache entry with atlas coordinates, or None if failed.
pub fn GlyphAtlas::rasterize_glyph(
  self : GlyphAtlas,
  font : @font.TTFont,
  codepoint : Int,
  size_px : Double,
) -> GlyphCacheEntry? {
  let glyph_id = font.glyph_index(codepoint)
  let cache_key = make_glyph_cache_key(glyph_id, size_px)
  // Return existing if already cached
  match self.cache.get(cache_key) {
    Some(entry) => return Some(entry)
    None => ()
  }
  // Rasterize the glyph
  match rasterize_glyph(font, codepoint, size_px) {
    None => None
    Some(bitmap) =>
      // Allocate space in atlas
      match
        self.cache.allocate(
          cache_key,
          bitmap.width.to_double(),
          bitmap.height.to_double(),
        ) {
        None => None
        Some(entry) => {
          // Copy pixels into atlas
          blit_to_atlas(
            self.pixels,
            self.width,
            bitmap,
            entry.atlas_x.to_int(),
            entry.atlas_y.to_int(),
          )
          Some(entry)
        }
      }
  }
}

///|
/// Rasterize a string of text into the atlas and return glyph quads.
pub fn GlyphAtlas::rasterize_text(
  self : GlyphAtlas,
  font : @font.TTFont,
  text : String,
  size_px : Double,
) -> Array[GlyphQuad] {
  let quads : Array[GlyphQuad] = []
  let scale = size_px / font.units_per_em.to_double()
  let positions = font.layout_text(text, size_px)
  for pos in positions {
    if pos.glyph_id == 0 {
      continue
    }
    let codepoint = pos.codepoint
    match self.rasterize_glyph(font, codepoint, size_px) {
      None => continue
      Some(entry) => {
        let metrics = font.glyph_metrics(pos.glyph_id)
        let bbox = metrics.bbox
        let dst_x = pos.x_offset + metrics.left_side_bearing.to_double() * scale
        let dst_y = -(bbox.y_max.to_double() * scale)
        // Use composite cache key so batch builder can look up the
        // correct size-specific entry.
        let cache_key = make_glyph_cache_key(pos.glyph_id, size_px)
        quads.push({
          glyph_id: cache_key,
          atlas_x: entry.atlas_x,
          atlas_y: entry.atlas_y,
          atlas_w: entry.atlas_w,
          atlas_h: entry.atlas_h,
          dst_x,
          dst_y,
          dst_w: entry.atlas_w,
          dst_h: entry.atlas_h,
        })
      }
    }
  }
  quads
}

///|
/// High-level text renderer that ties together font, atlas, and batch builder
/// into a single easy-to-use API for rendering text as draw commands.
///
/// Usage:
///   let renderer = TextRenderer::new(font, 512, page_id, pipeline_id)
///   let commands = renderer.render_text("Hello", 24.0, 10.0, 50.0, dst, shader, blend, [255,255,255,255])
///   // Upload renderer.get_atlas().get_pixels() as source texture for page_id
///   // Submit commands to the graphics pipeline
pub struct TextRenderer {
  atlas : GlyphAtlas
  font : @font.TTFont
  pipeline_id : Int
}

///|
pub fn TextRenderer::new(
  font : @font.TTFont,
  atlas_size : Int,
  page_id : Int,
  pipeline_id : Int,
) -> TextRenderer {
  { atlas: GlyphAtlas::new(atlas_size, atlas_size, page_id), font, pipeline_id }
}

///|
/// Render text at the given position, returning draw commands ready
/// for the graphics pipeline. Also rasterizes any new glyphs into the atlas.
///
/// The caller must ensure the atlas pixel data (from `get_atlas().get_pixels()`)
/// is uploaded as a source texture bound to the atlas page_id.
pub fn TextRenderer::render_text(
  self : TextRenderer,
  text : String,
  size_px : Double,
  x : Double,
  y : Double,
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  blend : @gfx.BlendMode,
  uniform_dwords : Array[Int],
) -> Array[@gfx.DrawTrianglesCommand] {
  let quads = self.atlas.rasterize_text(self.font, text, size_px)
  if quads.length() == 0 {
    return []
  }
  // Offset quads by (x, y) for positioning
  let offset_quads : Array[GlyphQuad] = []
  for q in quads {
    offset_quads.push({
      glyph_id: q.glyph_id,
      atlas_x: q.atlas_x,
      atlas_y: q.atlas_y,
      atlas_w: q.atlas_w,
      atlas_h: q.atlas_h,
      dst_x: q.dst_x + x,
      dst_y: q.dst_y + y,
      dst_w: q.dst_w,
      dst_h: q.dst_h,
    })
  }
  let builder = SimpleTextBatchBuilder::new(
    self.atlas.get_cache(),
    self.pipeline_id,
  )
  let commands = builder.build_draw_commands(dst, offset_quads, shader) catch {
    _ => return []
  }
  // Patch uniform_dwords into each command if provided
  if uniform_dwords.length() > 0 {
    let patched : Array[@gfx.DrawTrianglesCommand] = []
    for cmd in commands {
      patched.push(
        @gfx.new_draw_triangles_command(
          cmd.dst,
          cmd.shader,
          cmd.dst_regions,
          cmd.index_offset,
          cmd.pipeline_id,
          cmd.uniform_hash,
          blend,
          cmd.vertex_data,
          cmd.indices,
          cmd.src_image_ids,
          uniform_dwords,
        ),
      )
    }
    patched
  } else {
    commands
  }
}

///|
/// Measure text dimensions without rasterizing.
pub fn TextRenderer::measure(
  self : TextRenderer,
  text : String,
  size_px : Double,
) -> TextMetrics {
  let engine = SimpleFontEngine::new(self.font)
  let style = default_text_style("", size_px)
  let run = new_text_run(text, style)
  engine.measure(run)
}

///|
/// Get the underlying atlas for pixel data access (GPU upload).
pub fn TextRenderer::get_atlas(self : TextRenderer) -> GlyphAtlas {
  self.atlas
}

///|
/// Get the atlas page ID used as the source image ID in draw commands.
pub fn TextRenderer::get_page_id(self : TextRenderer) -> Int {
  self.atlas.cache.atlas_page_id
}

///|
/// Check if the atlas has been modified (new glyphs rasterized) and needs
/// re-upload to the GPU. Returns the number of cached glyph entries.
pub fn TextRenderer::glyph_count(self : TextRenderer) -> Int {
  self.atlas.cache.entry_count()
}

///|
/// Clear all cached glyphs and atlas data. Use when switching fonts or sizes.
pub fn TextRenderer::clear(self : TextRenderer) -> Unit {
  self.atlas.cache.clear()
  // Zero out pixel buffer
  for i in 0..<self.atlas.pixels.length() {
    self.atlas.pixels[i] = 0
  }
}
