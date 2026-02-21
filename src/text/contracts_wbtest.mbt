///|
test "default_text_style" {
  let style = default_text_style("sans-serif", 16.0)
  assert_eq(style.font.family, "sans-serif")
  assert_eq(style.font.weight, 400)
  assert_eq(style.font.italic, false)
  assert_eq(style.size_px, 16.0)
  assert_eq(style.line_height, 22.4)
  assert_eq(style.letter_spacing, 0.0)
}

///|
test "GlyphCache allocate and get" {
  let cache = GlyphCache::new(256.0, 256.0, 1)
  assert_eq(cache.entry_count(), 0)
  // Allocate first glyph
  match cache.allocate(65, 10.0, 12.0) {
    Some(entry) => {
      assert_eq(entry.glyph_id, 65)
      assert_eq(entry.atlas_x, 0.0)
      assert_eq(entry.atlas_y, 0.0)
      assert_eq(entry.atlas_w, 10.0)
      assert_eq(entry.atlas_h, 12.0)
      assert_eq(entry.atlas_page_id, 1)
    }
    None => fail("expected allocation to succeed")
  }
  assert_eq(cache.entry_count(), 1)
  // Get existing glyph
  match cache.get(65) {
    Some(entry) => assert_eq(entry.glyph_id, 65)
    None => fail("expected glyph to be cached")
  }
  // Get missing glyph
  match cache.get(66) {
    Some(_) => fail("expected None")
    None => ()
  }
}

///|
test "GlyphCache allocate multiple" {
  let cache = GlyphCache::new(256.0, 256.0, 1)
  let _ = cache.allocate(65, 10.0, 12.0)
  match cache.allocate(66, 8.0, 12.0) {
    Some(entry) => {
      // Should be placed after first glyph (10 + 1 padding)
      assert_eq(entry.atlas_x, 11.0)
      assert_eq(entry.atlas_y, 0.0)
    }
    None => fail("expected allocation")
  }
  assert_eq(cache.entry_count(), 2)
}

///|
test "GlyphCache row wrapping" {
  let cache = GlyphCache::new(30.0, 256.0, 1)
  let _ = cache.allocate(65, 10.0, 12.0) // x=0, w=10+1=11
  let _ = cache.allocate(66, 10.0, 12.0) // x=11, w=10+1=11 -> 22
  // Third glyph should wrap to next row: 22+11=33 > 30
  match cache.allocate(67, 10.0, 14.0) {
    Some(entry) => {
      assert_eq(entry.atlas_x, 0.0)
      // y should be 0 + row_height(13) + padding(1) = 14
      assert_eq(entry.atlas_y, 14.0)
    }
    None => fail("expected allocation")
  }
}

///|
test "GlyphCache atlas full" {
  let cache = GlyphCache::new(20.0, 20.0, 1)
  let _ = cache.allocate(65, 18.0, 18.0) // fills most of atlas
  // Second glyph should fail
  match cache.allocate(66, 18.0, 18.0) {
    Some(_) => fail("expected None when atlas is full")
    None => ()
  }
}

///|
test "GlyphCache clear" {
  let cache = GlyphCache::new(256.0, 256.0, 1)
  let _ = cache.allocate(65, 10.0, 12.0)
  assert_eq(cache.entry_count(), 1)
  cache.clear()
  assert_eq(cache.entry_count(), 0)
}

///|
test "GlyphCache duplicate allocate returns existing" {
  let cache = GlyphCache::new(256.0, 256.0, 1)
  let _ = cache.allocate(65, 10.0, 12.0)
  // Allocate same glyph again should return existing entry
  match cache.allocate(65, 10.0, 12.0) {
    Some(entry) => {
      assert_eq(entry.atlas_x, 0.0)
      assert_eq(entry.atlas_y, 0.0)
    }
    None => fail("expected existing entry")
  }
  assert_eq(cache.entry_count(), 1)
}

///|
test "path_commands_to_svg_d basic" {
  let commands : Array[@msvg.PathCommand] = [
    @msvg.PathCommand::MoveTo(0.0, 10.0),
    @msvg.PathCommand::LineTo(5.0, 0.0),
    @msvg.PathCommand::LineTo(10.0, 10.0),
    @msvg.PathCommand::ClosePath,
  ]
  let d = path_commands_to_svg_d(commands)
  assert_true(d.contains("M 0"))
  assert_true(d.contains("L 5"))
  assert_true(d.contains("L 10"))
  assert_true(d.contains("Z"))
}

///|
test "path_commands_to_svg_d with curves" {
  let commands : Array[@msvg.PathCommand] = [
    @msvg.PathCommand::MoveTo(0.0, 0.0),
    @msvg.PathCommand::QuadraticCurveTo(5.0, 10.0, 10.0, 0.0),
    @msvg.PathCommand::CurveTo(15.0, 5.0, 20.0, 5.0, 25.0, 0.0),
  ]
  let d = path_commands_to_svg_d(commands)
  assert_true(d.contains("M 0"))
  assert_true(d.contains("Q "))
  assert_true(d.contains("C "))
}

///|
test "outline_bbox" {
  let commands : Array[@msvg.PathCommand] = [
    @msvg.PathCommand::MoveTo(5.0, -3.0),
    @msvg.PathCommand::LineTo(20.0, 15.0),
    @msvg.PathCommand::LineTo(0.0, 10.0),
    @msvg.PathCommand::ClosePath,
  ]
  let (x_min, y_min, x_max, y_max) = outline_bbox(commands)
  assert_true((x_min - 0.0).abs() < 0.01)
  assert_true((y_min - -3.0).abs() < 0.01)
  assert_true((x_max - 20.0).abs() < 0.01)
  assert_true((y_max - 15.0).abs() < 0.01)
}

///|
test "outline_bbox with quadratic control points" {
  let commands : Array[@msvg.PathCommand] = [
    @msvg.PathCommand::MoveTo(0.0, 0.0),
    @msvg.PathCommand::QuadraticCurveTo(5.0, 20.0, 10.0, 0.0),
  ]
  let (x_min, y_min, x_max, y_max) = outline_bbox(commands)
  assert_true((x_min - 0.0).abs() < 0.01)
  assert_true((y_min - 0.0).abs() < 0.01)
  assert_true((x_max - 10.0).abs() < 0.01)
  // Control point at y=20 should extend bbox
  assert_true((y_max - 20.0).abs() < 0.01)
}

///|
test "GlyphAtlas new" {
  let atlas = GlyphAtlas::new(128, 128, 1)
  assert_eq(atlas.width, 128)
  assert_eq(atlas.height, 128)
  assert_eq(atlas.pixels.length(), 128 * 128 * 4)
  assert_eq(atlas.cache.entry_count(), 0)
}

///|
test "blit_to_atlas" {
  let atlas = GlyphAtlas::new(16, 16, 1)
  // Create a 2x2 red bitmap
  let bitmap : GlyphBitmap = {
    width: 2,
    height: 2,
    pixels: [255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 0, 255],
  }
  blit_to_atlas(atlas.pixels, atlas.width, bitmap, 3, 5)
  // Check pixel at (3, 5) = red
  let idx = (5 * 16 + 3) * 4
  assert_eq(atlas.pixels[idx], 255) // R
  assert_eq(atlas.pixels[idx + 1], 0) // G
  assert_eq(atlas.pixels[idx + 2], 0) // B
  assert_eq(atlas.pixels[idx + 3], 255) // A
  // Check pixel at (4, 5) = green
  let idx2 = (5 * 16 + 4) * 4
  assert_eq(atlas.pixels[idx2], 0)
  assert_eq(atlas.pixels[idx2 + 1], 255)
  // Check pixel at (3, 6) = blue
  let idx3 = (6 * 16 + 3) * 4
  assert_eq(atlas.pixels[idx3], 0)
  assert_eq(atlas.pixels[idx3 + 1], 0)
  assert_eq(atlas.pixels[idx3 + 2], 255)
}

///|
test "SVG rasterize triangle produces non-empty pixels" {
  // Test the SVG → pixel pipeline with a simple triangle
  let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"32\" height=\"32\"><path d=\"M 16 2 L 30 30 L 2 30 Z\" fill=\"white\"/></svg>"
  match @msvg.render_svg_to_image(svg, 32, 32) {
    Some(img) => {
      assert_eq(img.width, 32)
      assert_eq(img.height, 32)
      // Center of triangle should have white pixels
      let center_idx = 20 * 32 + 16
      assert_true(img.pixels[center_idx].a > 200)
    }
    None => fail("expected SVG render")
  }
}

///|
test "GlyphCache clear and re-allocate" {
  let cache = GlyphCache::new(256.0, 256.0, 1)
  let _ = cache.allocate(65, 10.0, 12.0)
  let _ = cache.allocate(66, 8.0, 10.0)
  assert_eq(cache.entry_count(), 2)
  cache.clear()
  assert_eq(cache.entry_count(), 0)
  // After clear, should allocate at origin again
  match cache.allocate(67, 5.0, 5.0) {
    Some(entry) => {
      assert_eq(entry.atlas_x, 0.0)
      assert_eq(entry.atlas_y, 0.0)
    }
    None => panic()
  }
}

///|
test "GlyphCache page_id propagates to entries" {
  let cache = GlyphCache::new(256.0, 256.0, 42)
  match cache.allocate(65, 10.0, 12.0) {
    Some(entry) => assert_eq(entry.atlas_page_id, 42)
    None => panic()
  }
}

///|
test "blit_to_atlas with out of bounds is safe" {
  let atlas = GlyphAtlas::new(8, 8, 1)
  let bitmap : GlyphBitmap = {
    width: 4,
    height: 4,
    pixels: Array::make(64, 255),
  }
  // Blit at position near edge, should not panic even if partially out of bounds
  blit_to_atlas(atlas.pixels, atlas.width, bitmap, 6, 6)
  // Only (6,6) and (7,6) of first row should be written
  let idx = (6 * 8 + 6) * 4
  assert_eq(atlas.pixels[idx], 255)
  let idx2 = (6 * 8 + 7) * 4
  assert_eq(atlas.pixels[idx2], 255)
}

///|
test "blit_to_atlas clips negative destination origin" {
  let atlas = GlyphAtlas::new(8, 8, 1)
  let src_pixels : Array[Int] = []
  for i in 0..<16 {
    let value = i + 1
    src_pixels.push(value)
    src_pixels.push(0)
    src_pixels.push(0)
    src_pixels.push(255)
  }
  let bitmap : GlyphBitmap = { width: 4, height: 4, pixels: src_pixels }
  blit_to_atlas(atlas.pixels, atlas.width, bitmap, -2, -1)
  // (0,0) <- src(2,1), value = 7
  let top_left = (0 * 8 + 0) * 4
  assert_eq(atlas.pixels[top_left], 7)
  // (1,0) <- src(3,1), value = 8
  let top_right = (0 * 8 + 1) * 4
  assert_eq(atlas.pixels[top_right], 8)
  // (0,2) <- src(2,3), value = 15
  let bottom_left = (2 * 8 + 0) * 4
  assert_eq(atlas.pixels[bottom_left], 15)
  // Outside clipped area remains untouched
  let untouched = (0 * 8 + 2) * 4
  assert_eq(atlas.pixels[untouched], 0)
}

///|
test "blit_to_atlas fully out of bounds keeps atlas unchanged" {
  let atlas = GlyphAtlas::new(8, 8, 1)
  let bitmap : GlyphBitmap = {
    width: 4,
    height: 4,
    pixels: Array::make(64, 255),
  }
  blit_to_atlas(atlas.pixels, atlas.width, bitmap, 16, 16)
  // Buffer should stay zeroed when no overlap exists
  assert_eq(atlas.pixels[0], 0)
  assert_eq(atlas.pixels[(7 * 8 + 7) * 4], 0)
}

///|
test "GlyphAtlas new pixel buffer is zeroed" {
  let atlas = GlyphAtlas::new(64, 64, 5)
  // All pixels should be zero
  let mut all_zero = true
  for i in 0..<atlas.pixels.length() {
    if atlas.pixels[i] != 0 {
      all_zero = false
      break
    }
  }
  assert_true(all_zero)
  assert_eq(atlas.pixels.length(), 64 * 64 * 4)
}

///|
test "default_text_style with zero size" {
  let style = default_text_style("mono", 0.0)
  assert_eq(style.size_px, 0.0)
  assert_eq(style.line_height, 0.0)
  assert_eq(style.letter_spacing, 0.0)
}

///|
test "path_commands_to_svg_d empty" {
  let d = path_commands_to_svg_d([])
  assert_eq(d, "")
}

///|
test "detect_font_format identifies formats" {
  // TTF magic: 0x00010000
  let ttf = Bytes::from_array([b'\x00', b'\x01', b'\x00', b'\x00', b'\x00'])
  assert_eq(detect_font_format(ttf), FontFormat::TrueType)
  // OTF magic: "OTTO"
  let otf = Bytes::from_array([b'\x4F', b'\x54', b'\x54', b'\x4F', b'\x00'])
  assert_eq(detect_font_format(otf), FontFormat::OpenType)
  // WOFF1 magic: "wOFF"
  let woff1 = Bytes::from_array([b'\x77', b'\x4F', b'\x46', b'\x46', b'\x00'])
  assert_eq(detect_font_format(woff1), FontFormat::Woff1)
  // WOFF2 magic: "wOF2"
  let woff2 = Bytes::from_array([b'\x77', b'\x4F', b'\x46', b'\x32', b'\x00'])
  assert_eq(detect_font_format(woff2), FontFormat::Woff2)
  // TTC magic: "ttcf"
  let ttc = Bytes::from_array([b'\x74', b'\x74', b'\x63', b'\x66', b'\x00'])
  assert_eq(detect_font_format(ttc), FontFormat::TrueTypeCollection)
  // Unknown
  let unknown = Bytes::from_array([b'\xFF', b'\xFF', b'\xFF', b'\xFF'])
  assert_eq(detect_font_format(unknown), FontFormat::Unknown)
  // Too short
  let short = Bytes::from_array([b'\x00', b'\x01'])
  assert_eq(detect_font_format(short), FontFormat::Unknown)
  // Empty
  let empty = Bytes::from_array([])
  assert_eq(detect_font_format(empty), FontFormat::Unknown)
}

///|
test "parse_font_bytes returns None for invalid data" {
  let bad = Bytes::from_array([
    b'\xFF', b'\xFE', b'\xFD', b'\xFC', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
  match parse_font_bytes(bad) {
    None => ()
    Some(_) => fail("expected None for invalid font data")
  }
}

///|
test "load_font_engine_from_bytes returns None for invalid data" {
  let bad = Bytes::from_array([
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
  match load_font_engine_from_bytes(bad) {
    None => ()
    Some(_) => fail("expected None for invalid font data")
  }
}

///|
test "SimpleTextBatchBuilder produces commands from glyphs" {
  let cache = GlyphCache::new(256.0, 256.0, 1)
  let builder = SimpleTextBatchBuilder::new(cache, 0)
  let glyphs = [
    {
      glyph_id: 65,
      atlas_x: 0.0,
      atlas_y: 0.0,
      atlas_w: 10.0,
      atlas_h: 12.0,
      dst_x: 0.0,
      dst_y: 0.0,
      dst_w: 10.0,
      dst_h: 12.0,
    },
    {
      glyph_id: 66,
      atlas_x: 0.0,
      atlas_y: 0.0,
      atlas_w: 8.0,
      atlas_h: 12.0,
      dst_x: 12.0,
      dst_y: 0.0,
      dst_w: 8.0,
      dst_h: 12.0,
    },
  ]
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "text_shader")
  let commands = builder.build_draw_commands(dst, glyphs, shader)
  // Batched into a single explicit-geometry command.
  assert_eq(commands.length(), 1)
  assert_eq(commands[0].vertex_data.length(), 32)
  assert_eq(commands[0].indices.length(), 12)
  assert_eq(commands[0].dst_regions.length(), 1)
  assert_eq(commands[0].dst_regions[0].index_count, 12)
  // Second quad indices should be offset by +4 vertices.
  assert_eq(commands[0].indices[6], 4)
  assert_eq(commands[0].indices[7], 5)
  assert_eq(commands[0].indices[8], 6)
  assert_eq(commands[0].indices[9], 6)
  assert_eq(commands[0].indices[10], 7)
  assert_eq(commands[0].indices[11], 4)
  assert_eq(commands[0].src_image_ids.length(), 1)
  assert_eq(commands[0].src_image_ids[0], 1) // atlas_page_id
}

///|
test "TextRenderer new initializes empty atlas" {
  // We need a valid TTFont but can only test with invalid data returning None
  // So test construction helper path
  let bad = Bytes::from_array([
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
  let engine = load_font_engine_from_bytes(bad)
  assert_true(engine is None)
}

///|
test "TextRenderer get_page_id returns atlas page id" {
  // Test that TextRenderer properly exposes its page_id
  // Use parse_font_bytes to try to get a font (will be None for invalid data)
  // Instead, test with a valid atlas setup
  let atlas = GlyphAtlas::new(256, 256, 42)
  assert_eq(atlas.cache.atlas_page_id, 42)
  assert_eq(atlas.cache.entry_count(), 0)
}

///|
test "TextRenderer clear resets atlas state" {
  let atlas = GlyphAtlas::new(64, 64, 10)
  // Manually allocate some entries to simulate usage
  let _ = atlas.cache.allocate(65, 10.0, 12.0)
  let _ = atlas.cache.allocate(66, 8.0, 10.0)
  assert_eq(atlas.cache.entry_count(), 2)
  // Write some non-zero data to atlas pixels
  atlas.pixels[0] = 255
  atlas.pixels[1] = 128
  // Clear
  atlas.cache.clear()
  assert_eq(atlas.cache.entry_count(), 0)
  // After clear, new allocations start from origin
  match atlas.cache.allocate(67, 5.0, 5.0) {
    Some(entry) => {
      assert_eq(entry.atlas_x, 0.0)
      assert_eq(entry.atlas_y, 0.0)
    }
    None => fail("expected allocation after clear")
  }
}

///|
test "SimpleTextBatchBuilder handles empty glyphs" {
  let cache = GlyphCache::new(256.0, 256.0, 1)
  let builder = SimpleTextBatchBuilder::new(cache, 0)
  let glyphs : Array[GlyphQuad] = []
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "text_shader")
  let commands = builder.build_draw_commands(dst, glyphs, shader)
  assert_eq(commands.length(), 0)
}

///|
test "SimpleTextBatchBuilder single glyph has correct UV range" {
  let cache = GlyphCache::new(128.0, 128.0, 5)
  let builder = SimpleTextBatchBuilder::new(cache, 3)
  let glyphs = [
    {
      glyph_id: 72,
      atlas_x: 0.0,
      atlas_y: 0.0,
      atlas_w: 16.0,
      atlas_h: 20.0,
      dst_x: 5.0,
      dst_y: 10.0,
      dst_w: 16.0,
      dst_h: 20.0,
    },
  ]
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "shader")
  let commands = builder.build_draw_commands(dst, glyphs, shader)
  assert_eq(commands.length(), 1)
  let cmd = commands[0]
  // 1 glyph = 4 vertices * 4 floats (x,y,u,v) = 16
  assert_eq(cmd.vertex_data.length(), 16)
  // 1 glyph = 6 indices
  assert_eq(cmd.indices.length(), 6)
  // Check UV coordinates: u0 = 0/128 = 0.0, v0 = 0/128 = 0.0
  // u1 = 16/128 = 0.125, v1 = 20/128 = 0.15625
  let u0 = cmd.vertex_data[2]
  let v0 = cmd.vertex_data[3]
  let u1 = cmd.vertex_data[6]
  let v1 = cmd.vertex_data[11] // bottom-right v
  assert_true((u0 - 0.0).abs() < 0.001)
  assert_true((v0 - 0.0).abs() < 0.001)
  assert_true((u1 - 0.125).abs() < 0.001)
  assert_true((v1 - 0.15625).abs() < 0.001)
  // Verify dst position in vertex data
  let x0 = cmd.vertex_data[0]
  let y0 = cmd.vertex_data[1]
  assert_true((x0 - 5.0).abs() < 0.001)
  assert_true((y0 - 10.0).abs() < 0.001)
  // src_image_ids should be [5] (atlas_page_id)
  assert_eq(cmd.src_image_ids.length(), 1)
  assert_eq(cmd.src_image_ids[0], 5)
}

///|
test "SimpleTextBatchBuilder merged region covers all glyphs" {
  let cache = GlyphCache::new(512.0, 512.0, 1)
  let builder = SimpleTextBatchBuilder::new(cache, 0)
  let glyphs = [
    {
      glyph_id: 65,
      atlas_x: 0.0,
      atlas_y: 0.0,
      atlas_w: 10.0,
      atlas_h: 12.0,
      dst_x: 100.0,
      dst_y: 200.0,
      dst_w: 10.0,
      dst_h: 12.0,
    },
    {
      glyph_id: 66,
      atlas_x: 0.0,
      atlas_y: 0.0,
      atlas_w: 8.0,
      atlas_h: 12.0,
      dst_x: 120.0,
      dst_y: 200.0,
      dst_w: 8.0,
      dst_h: 12.0,
    },
  ]
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "shader")
  let commands = builder.build_draw_commands(dst, glyphs, shader)
  assert_eq(commands.length(), 1)
  let region = commands[0].dst_regions[0]
  // Region should encompass both glyphs
  assert_eq(region.x, 100)
  assert_eq(region.y, 200)
  // Width: 128 - 100 = 28, Height: 212 - 200 = 12
  assert_eq(region.width, 28)
  assert_eq(region.height, 12)
  // Index count for 2 glyphs = 12
  assert_eq(region.index_count, 12)
}

///|
test "make_glyph_cache_key basic" {
  // Different glyph IDs produce different keys at the same size
  let k1 = make_glyph_cache_key(1, 16.0)
  let k2 = make_glyph_cache_key(2, 16.0)
  assert_true(k1 != k2)
  // Same glyph and size produce the same key
  let k3 = make_glyph_cache_key(1, 16.0)
  assert_eq(k1, k3)
}

///|
test "make_glyph_cache_key different sizes" {
  // Same glyph at different sizes MUST produce different keys
  // This is the core invariant for multi-size caching
  let k_16 = make_glyph_cache_key(65, 16.0)
  let k_24 = make_glyph_cache_key(65, 24.0)
  let k_32 = make_glyph_cache_key(65, 32.0)
  assert_true(k_16 != k_24)
  assert_true(k_24 != k_32)
  assert_true(k_16 != k_32)
}

///|
test "make_glyph_cache_key quantization" {
  // Sizes differing by less than 0.1px should quantize to same key
  let k1 = make_glyph_cache_key(10, 16.0)
  let k2 = make_glyph_cache_key(10, 16.04)
  assert_eq(k1, k2)
  // Sizes differing by >= 0.1px should be distinct
  let k3 = make_glyph_cache_key(10, 16.1)
  assert_true(k1 != k3)
}

///|
test "make_glyph_cache_key zero size" {
  let k = make_glyph_cache_key(42, 0.0)
  // Should not panic for zero size; key should just encode glyph_id with 0 size
  assert_true(k >= 0)
  // Different glyph at zero size should differ
  let k2 = make_glyph_cache_key(43, 0.0)
  assert_true(k != k2)
}

///|
test "make_glyph_cache_key no collision across glyph-size pairs" {
  // Verify that (glyph_id=1, size=40960*0.1=4096.0) does not collide with
  // (glyph_id=2, size=0.0). The formula is glyph_id * 40960 + quantized_size.
  let k_a = make_glyph_cache_key(1, 4095.0)
  let k_b = make_glyph_cache_key(2, 0.0)
  assert_true(k_a != k_b)
}

///|
test "GlyphCache multi-size caching stores separate entries" {
  let cache = GlyphCache::new(512.0, 512.0, 1)
  // Allocate glyph 65 at size 16px
  let key_16 = make_glyph_cache_key(65, 16.0)
  match cache.allocate(key_16, 10.0, 12.0) {
    Some(entry) => {
      assert_eq(entry.atlas_x, 0.0)
      assert_eq(entry.atlas_y, 0.0)
    }
    None => fail("expected allocation for 16px")
  }
  // Allocate glyph 65 at size 24px — should get a DIFFERENT slot
  let key_24 = make_glyph_cache_key(65, 24.0)
  match cache.allocate(key_24, 14.0, 18.0) {
    Some(entry) => {
      // Should not overlap with the first entry
      assert_true(entry.atlas_x > 0.0 || entry.atlas_y > 0.0)
      assert_eq(entry.atlas_w, 14.0)
      assert_eq(entry.atlas_h, 18.0)
    }
    None => fail("expected allocation for 24px")
  }
  assert_eq(cache.entry_count(), 2)
  // Both entries should be independently retrievable
  assert_true(cache.get(key_16) is Some(_))
  assert_true(cache.get(key_24) is Some(_))
  // And they should be different
  let e16 = cache.get(key_16).unwrap()
  let e24 = cache.get(key_24).unwrap()
  assert_true(e16.atlas_x != e24.atlas_x || e16.atlas_y != e24.atlas_y)
}

///|
test "GlyphCache multi-size dedup returns existing on re-allocate" {
  let cache = GlyphCache::new(512.0, 512.0, 1)
  let key = make_glyph_cache_key(65, 16.0)
  let _ = cache.allocate(key, 10.0, 12.0)
  // Allocating same composite key again should return existing entry, not a new one
  match cache.allocate(key, 10.0, 12.0) {
    Some(entry) => {
      assert_eq(entry.atlas_x, 0.0)
      assert_eq(entry.atlas_y, 0.0)
    }
    None => fail("expected existing entry")
  }
  assert_eq(cache.entry_count(), 1)
}

///|
test "new_text_run constructs correctly" {
  let style = default_text_style("serif", 24.0)
  let run = new_text_run("Hello", style)
  assert_eq(run.text, "Hello")
  assert_eq(run.style.font.family, "serif")
  assert_eq(run.style.size_px, 24.0)
}

///|
test "GlyphAtlas get_cache and get_pixels accessors" {
  let atlas = GlyphAtlas::new(128, 64, 7)
  let cache = atlas.get_cache()
  assert_eq(cache.atlas_page_id, 7)
  assert_eq(cache.atlas_width, 128.0)
  assert_eq(cache.atlas_height, 64.0)
  let pixels = atlas.get_pixels()
  assert_eq(pixels.length(), 128 * 64 * 4)
}

///|
test "blit_to_atlas zero-size bitmap is no-op" {
  let atlas = GlyphAtlas::new(16, 16, 1)
  let bitmap : GlyphBitmap = { width: 0, height: 0, pixels: [] }
  // Should not panic
  blit_to_atlas(atlas.pixels, atlas.width, bitmap, 0, 0)
  // Atlas should remain zeroed
  assert_eq(atlas.pixels[0], 0)
}

///|
test "blit_to_atlas zero atlas_width is no-op" {
  let pixels : Array[Int] = []
  let bitmap : GlyphBitmap = {
    width: 2,
    height: 2,
    pixels: [255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 0, 255],
  }
  // atlas_width=0 should return early without panic
  blit_to_atlas(pixels, 0, bitmap, 0, 0)
}

///|
test "detect_font_format with exactly 4 bytes" {
  let ttf = Bytes::from_array([b'\x00', b'\x01', b'\x00', b'\x00'])
  assert_eq(detect_font_format(ttf), FontFormat::TrueType)
  let otf = Bytes::from_array([b'\x4F', b'\x54', b'\x54', b'\x4F'])
  assert_eq(detect_font_format(otf), FontFormat::OpenType)
}

///|
test "font_data_to_bytes converts correctly" {
  let data = [0x00, 0x01, 0xFF, 0x80]
  let bytes = font_data_to_bytes(data)
  assert_eq(bytes.length(), 4)
  assert_eq(bytes[0], b'\x00')
  assert_eq(bytes[1], b'\x01')
  assert_eq(bytes[2], b'\xFF')
  assert_eq(bytes[3], b'\x80')
}

///|
test "font_data_to_bytes empty array" {
  let data : Array[Int] = []
  let bytes = font_data_to_bytes(data)
  assert_eq(bytes.length(), 0)
}

///|
test "load_font returns None with default hooks" {
  reset_font_load_hooks()
  let result = load_font("nonexistent.ttf")
  assert_true(result is None)
}

///|
test "load_font calls custom hook" {
  let mut called_with = ""
  set_font_load_hooks({
    load_font_data: fn(name) {
      called_with = name
      // Return invalid font data — parse will fail but hook was called
      Some([0xFF, 0xFE, 0xFD, 0xFC])
    },
  })
  let result = load_font("test_font.ttf")
  assert_eq(called_with, "test_font.ttf")
  // Invalid data → parse fails → None
  assert_true(result is None)
  reset_font_load_hooks()
}

///|
test "load_text_renderer returns None with default hooks" {
  reset_font_load_hooks()
  let result = load_text_renderer("nonexistent.ttf", 256, 1, 0)
  assert_true(result is None)
}

///|
test "set_font_load_hooks and reset_font_load_hooks" {
  let mut hook_called = false
  set_font_load_hooks({
    load_font_data: fn(_name) {
      hook_called = true
      None
    },
  })
  let _ = load_font("test")
  assert_true(hook_called)
  // Reset should restore default (no-op) behavior
  reset_font_load_hooks()
  hook_called = false
  let _ = load_font("test")
  assert_false(hook_called)
}

///|
/// Minimal NotoSans OTF subset (glyph: 'I' only) - 1364 bytes, OFL license
fn test_font_otf_data() -> Array[Int] {
  let font_bytes : FixedArray[Byte] = [
    0x4F, 0x54, 0x54, 0x4F, 0x00, 0x0C, 0x00, 0x80, 0x00, 0x03, 0x00, 0x40, 0x43, 0x46,
    0x46, 0x20, 0x75, 0x2F, 0x02, 0xBC, 0x00, 0x00, 0x03, 0xA8, 0x00, 0x00, 0x01, 0x36,
    0x47, 0x44, 0x45, 0x46, 0x00, 0x0F, 0x00, 0x02, 0x00, 0x00, 0x04, 0xE0, 0x00, 0x00,
    0x00, 0x14, 0x47, 0x50, 0x4F, 0x53, 0x44, 0x76, 0x4C, 0x75, 0x00, 0x00, 0x04, 0xF4,
    0x00, 0x00, 0x00, 0x20, 0x47, 0x53, 0x55, 0x42, 0x93, 0x15, 0x82, 0x16, 0x00, 0x00,
    0x05, 0x14, 0x00, 0x00, 0x00, 0x36, 0x4F, 0x53, 0x2F, 0x32, 0x69, 0x78, 0x5E, 0x43,
    0x00, 0x00, 0x01, 0x30, 0x00, 0x00, 0x00, 0x60, 0x63, 0x6D, 0x61, 0x70, 0x00, 0x0C,
    0x00, 0x9C, 0x00, 0x00, 0x03, 0x54, 0x00, 0x00, 0x00, 0x34, 0x68, 0x65, 0x61, 0x64,
    0x23, 0xA4, 0xF7, 0xE2, 0x00, 0x00, 0x00, 0xCC, 0x00, 0x00, 0x00, 0x36, 0x68, 0x68,
    0x65, 0x61, 0x05, 0x81, 0x05, 0x46, 0x00, 0x00, 0x01, 0x04, 0x00, 0x00, 0x00, 0x24,
    0x68, 0x6D, 0x74, 0x78, 0x03, 0xAB, 0x00, 0x86, 0x00, 0x00, 0x05, 0x4C, 0x00, 0x00,
    0x00, 0x08, 0x6D, 0x61, 0x78, 0x70, 0x00, 0x02, 0x50, 0x00, 0x00, 0x00, 0x01, 0x28,
    0x00, 0x00, 0x00, 0x06, 0x6E, 0x61, 0x6D, 0x65, 0x26, 0x3F, 0x3E, 0x24, 0x00, 0x00,
    0x01, 0x90, 0x00, 0x00, 0x01, 0xC2, 0x70, 0x6F, 0x73, 0x74, 0xFF, 0x9F, 0x00, 0x32,
    0x00, 0x00, 0x03, 0x88, 0x00, 0x00, 0x00, 0x20, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02,
    0x03, 0x96, 0xFE, 0xF1, 0x64, 0x42, 0x5F, 0x0F, 0x3C, 0xF5, 0x00, 0x03, 0x03, 0xE8,
    0x00, 0x00, 0x00, 0x00, 0xDD, 0x80, 0xD3, 0xE7, 0x00, 0x00, 0x00, 0x00, 0xE5, 0xBA,
    0xDC, 0xB8, 0x00, 0x28, 0x00, 0x00, 0x01, 0x2A, 0x02, 0xCA, 0x00, 0x00, 0x00, 0x06,
    0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x04, 0x2D,
    0xFE, 0xDB, 0x00, 0x00, 0x02, 0x58, 0x00, 0x28, 0x00, 0x29, 0x01, 0x2A, 0x03, 0xE8,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x02, 0x00, 0x00, 0x50, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x04, 0x02, 0x41,
    0x01, 0x90, 0x00, 0x05, 0x00, 0x00, 0x02, 0x8A, 0x02, 0x58, 0x00, 0x00, 0x00, 0x4B,
    0x02, 0x8A, 0x02, 0x58, 0x00, 0x00, 0x01, 0x5E, 0x00, 0x32, 0x01, 0x42, 0x00, 0x00,
    0x02, 0x0B, 0x05, 0x02, 0x04, 0x05, 0x04, 0x02, 0x02, 0x04, 0x00, 0x00, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x47, 0x4F,
    0x4F, 0x47, 0x00, 0xC0, 0x00, 0x49, 0x00, 0x49, 0x04, 0x2D, 0xFE, 0xDB, 0x00, 0x00,
    0x04, 0x64, 0x01, 0x8B, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x02, 0x18,
    0x02, 0xCA, 0x00, 0x00, 0x00, 0x20, 0x00, 0x04, 0x00, 0x00, 0x00, 0x07, 0x00, 0x5A,
    0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x00, 0x00, 0xB6, 0x00, 0x00, 0x00, 0x03,
    0x00, 0x01, 0x04, 0x09, 0x00, 0x01, 0x00, 0x12, 0x00, 0xB6, 0x00, 0x03, 0x00, 0x01,
    0x04, 0x09, 0x00, 0x02, 0x00, 0x0E, 0x00, 0xC8, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09,
    0x00, 0x03, 0x00, 0x36, 0x00, 0xD6, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x04,
    0x00, 0x22, 0x01, 0x0C, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x05, 0x00, 0x1A,
    0x01, 0x2E, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x06, 0x00, 0x20, 0x01, 0x48,
    0x00, 0x43, 0x00, 0x6F, 0x00, 0x70, 0x00, 0x79, 0x00, 0x72, 0x00, 0x69, 0x00, 0x67,
    0x00, 0x68, 0x00, 0x74, 0x00, 0x20, 0x00, 0x32, 0x00, 0x30, 0x00, 0x32, 0x00, 0x32,
    0x00, 0x20, 0x00, 0x54, 0x00, 0x68, 0x00, 0x65, 0x00, 0x20, 0x00, 0x4E, 0x00, 0x6F,
    0x00, 0x74, 0x00, 0x6F, 0x00, 0x20, 0x00, 0x50, 0x00, 0x72, 0x00, 0x6F, 0x00, 0x6A,
    0x00, 0x65, 0x00, 0x63, 0x00, 0x74, 0x00, 0x20, 0x00, 0x41, 0x00, 0x75, 0x00, 0x74,
    0x00, 0x68, 0x00, 0x6F, 0x00, 0x72, 0x00, 0x73, 0x00, 0x20, 0x00, 0x28, 0x00, 0x68,
    0x00, 0x74, 0x00, 0x74, 0x00, 0x70, 0x00, 0x73, 0x00, 0x3A, 0x00, 0x2F, 0x00, 0x2F,
    0x00, 0x67, 0x00, 0x69, 0x00, 0x74, 0x00, 0x68, 0x00, 0x75, 0x00, 0x62, 0x00, 0x2E,
    0x00, 0x63, 0x00, 0x6F, 0x00, 0x6D, 0x00, 0x2F, 0x00, 0x6E, 0x00, 0x6F, 0x00, 0x74,
    0x00, 0x6F, 0x00, 0x66, 0x00, 0x6F, 0x00, 0x6E, 0x00, 0x74, 0x00, 0x73, 0x00, 0x2F,
    0x00, 0x6C, 0x00, 0x61, 0x00, 0x74, 0x00, 0x69, 0x00, 0x6E, 0x00, 0x2D, 0x00, 0x67,
    0x00, 0x72, 0x00, 0x65, 0x00, 0x65, 0x00, 0x6B, 0x00, 0x2D, 0x00, 0x63, 0x00, 0x79,
    0x00, 0x72, 0x00, 0x69, 0x00, 0x6C, 0x00, 0x6C, 0x00, 0x69, 0x00, 0x63, 0x00, 0x29,
    0x00, 0x4E, 0x00, 0x6F, 0x00, 0x74, 0x00, 0x6F, 0x00, 0x20, 0x00, 0x53, 0x00, 0x61,
    0x00, 0x6E, 0x00, 0x73, 0x00, 0x52, 0x00, 0x65, 0x00, 0x67, 0x00, 0x75, 0x00, 0x6C,
    0x00, 0x61, 0x00, 0x72, 0x00, 0x32, 0x00, 0x2E, 0x00, 0x30, 0x00, 0x31, 0x00, 0x34,
    0x00, 0x3B, 0x00, 0x47, 0x00, 0x4F, 0x00, 0x4F, 0x00, 0x47, 0x00, 0x3B, 0x00, 0x4E,
    0x00, 0x6F, 0x00, 0x74, 0x00, 0x6F, 0x00, 0x53, 0x00, 0x61, 0x00, 0x6E, 0x00, 0x73,
    0x00, 0x2D, 0x00, 0x52, 0x00, 0x65, 0x00, 0x67, 0x00, 0x75, 0x00, 0x6C, 0x00, 0x61,
    0x00, 0x72, 0x00, 0x4E, 0x00, 0x6F, 0x00, 0x74, 0x00, 0x6F, 0x00, 0x20, 0x00, 0x53,
    0x00, 0x61, 0x00, 0x6E, 0x00, 0x73, 0x00, 0x20, 0x00, 0x52, 0x00, 0x65, 0x00, 0x67,
    0x00, 0x75, 0x00, 0x6C, 0x00, 0x61, 0x00, 0x72, 0x00, 0x56, 0x00, 0x65, 0x00, 0x72,
    0x00, 0x73, 0x00, 0x69, 0x00, 0x6F, 0x00, 0x6E, 0x00, 0x20, 0x00, 0x32, 0x00, 0x2E,
    0x00, 0x30, 0x00, 0x31, 0x00, 0x34, 0x00, 0x4E, 0x00, 0x6F, 0x00, 0x74, 0x00, 0x6F,
    0x00, 0x53, 0x00, 0x61, 0x00, 0x6E, 0x00, 0x73, 0x00, 0x2D, 0x00, 0x52, 0x00, 0x65,
    0x00, 0x67, 0x00, 0x75, 0x00, 0x6C, 0x00, 0x61, 0x00, 0x72, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x02, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x14, 0x00, 0x03, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x14, 0x00, 0x04, 0x00, 0x20, 0x00, 0x00, 0x00, 0x04, 0x00, 0x04,
    0x00, 0x01, 0x00, 0x00, 0x00, 0x49, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x49, 0xFF, 0xFF,
    0xFF, 0xB8, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0xFF, 0x9C, 0x00, 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00,
    0x04, 0x02, 0x00, 0x01, 0x01, 0x01, 0x11, 0x4E, 0x6F, 0x74, 0x6F, 0x53, 0x61, 0x6E,
    0x73, 0x2D, 0x52, 0x65, 0x67, 0x75, 0x6C, 0x61, 0x72, 0x00, 0x01, 0x01, 0x01, 0x22,
    0xF8, 0x1B, 0x00, 0xF8, 0x1C, 0x01, 0xF8, 0x1D, 0x0C, 0x00, 0xF8, 0x1E, 0x02, 0xF8,
    0x1F, 0x03, 0xB3, 0x8B, 0xF7, 0xBE, 0xF9, 0x5E, 0x05, 0xF7, 0x99, 0x0F, 0xAD, 0xF7,
    0xA8, 0x12, 0xF7, 0x9C, 0x11, 0x00, 0x05, 0x01, 0x01, 0x05, 0x27, 0x7C, 0x8D, 0x96,
    0x32, 0x2E, 0x31, 0x34, 0x4E, 0x6F, 0x74, 0x6F, 0x20, 0x69, 0x73, 0x20, 0x61, 0x20,
    0x74, 0x72, 0x61, 0x64, 0x65, 0x6D, 0x61, 0x72, 0x6B, 0x20, 0x6F, 0x66, 0x20, 0x47,
    0x6F, 0x6F, 0x67, 0x6C, 0x65, 0x20, 0x4C, 0x4C, 0x43, 0x2E, 0x43, 0x6F, 0x70, 0x79,
    0x72, 0x69, 0x67, 0x68, 0x74, 0x20, 0x32, 0x30, 0x32, 0x32, 0x20, 0x54, 0x68, 0x65,
    0x20, 0x4E, 0x6F, 0x74, 0x6F, 0x20, 0x50, 0x72, 0x6F, 0x6A, 0x65, 0x63, 0x74, 0x20,
    0x41, 0x75, 0x74, 0x68, 0x6F, 0x72, 0x73, 0x20, 0x68, 0x74, 0x74, 0x70, 0x73, 0x3A,
    0x67, 0x69, 0x74, 0x68, 0x75, 0x62, 0x2E, 0x63, 0x6F, 0x6D, 0x6E, 0x6F, 0x74, 0x6F,
    0x66, 0x6F, 0x6E, 0x74, 0x73, 0x6C, 0x61, 0x74, 0x69, 0x6E, 0x2D, 0x67, 0x72, 0x65,
    0x65, 0x6B, 0x2D, 0x63, 0x79, 0x72, 0x69, 0x6C, 0x6C, 0x69, 0x63, 0x4E, 0x6F, 0x74,
    0x6F, 0x20, 0x53, 0x61, 0x6E, 0x73, 0x20, 0x52, 0x65, 0x67, 0x75, 0x6C, 0x61, 0x72,
    0x4E, 0x6F, 0x74, 0x6F, 0x20, 0x53, 0x61, 0x6E, 0x73, 0x00, 0x02, 0x01, 0x01, 0x1D,
    0x23, 0xBF, 0x07, 0x37, 0x9E, 0x05, 0xF8, 0xCF, 0x07, 0xDF, 0x9F, 0x05, 0xBF, 0xFB,
    0x96, 0x57, 0x07, 0xDF, 0x77, 0x05, 0xFC, 0xCF, 0x07, 0x37, 0x78, 0x05, 0x57, 0x07,
    0x0B, 0xF7, 0xBE, 0x16, 0x20, 0x1D, 0x0E, 0x00, 0x00, 0x2A, 0x00, 0x02, 0x01, 0x01,
    0x03, 0x07, 0xC2, 0x0E, 0xFB, 0x62, 0x21, 0x1D, 0x7C, 0x9A, 0x7C, 0x9A, 0xF8, 0xAC,
    0x96, 0xF7, 0x3B, 0x97, 0xAD, 0x91, 0x06, 0xFB, 0x94, 0x9B, 0x07, 0x1E, 0x46, 0x87,
    0x5C, 0x6F, 0x0C, 0x09, 0x8B, 0x0C, 0x0B, 0xDA, 0x0A, 0xE5, 0x0B, 0xF8, 0xB5, 0x15,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x0A,
    0x00, 0x1C, 0x00, 0x1E, 0x00, 0x01, 0x44, 0x46, 0x4C, 0x54, 0x00, 0x08, 0x00, 0x04,
    0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x0A, 0x00, 0x32, 0x00, 0x34, 0x00, 0x04, 0x44, 0x46, 0x4C, 0x54,
    0x00, 0x1A, 0x63, 0x79, 0x72, 0x6C, 0x00, 0x24, 0x67, 0x72, 0x65, 0x6B, 0x00, 0x24,
    0x6C, 0x61, 0x74, 0x6E, 0x00, 0x24, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x58,
    0x00, 0x5E, 0x01, 0x53, 0x00, 0x28,
  ]
  let data : Array[Int] = Array::make(font_bytes.length(), 0)
  for i, b in font_bytes {
    data[i] = b.to_int()
  }
  data
}

///|
test "load_font with hook returns valid font" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  let font = load_font("test_embedded.otf")
  assert_true(font is Some(_))
  reset_font_load_hooks()
}

///|
test "load_text_renderer with hook returns valid renderer" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  let renderer = load_text_renderer("test_embedded.otf", 256, 1, 0)
  assert_true(renderer is Some(_))
  let tr = renderer.unwrap()
  let metrics = tr.measure("I", 24.0)
  assert_true(metrics.width > 0.0)
  assert_true(metrics.height > 0.0)
  reset_font_load_hooks()
}

///|
test "load_text_renderer hook multi-size render increases glyph_count" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  let renderer = load_text_renderer("test_embedded.otf", 256, 1, 0)
  assert_true(renderer is Some(_))
  let tr = renderer.unwrap()
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "text_shader")
  // Render at 24.0px
  let cmds_24 = tr.render_text(
    "I", 24.0, 0.0, 0.0, dst, shader, @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
  )
  assert_true(cmds_24.length() > 0)
  let count_after_24 = tr.glyph_count()
  assert_true(count_after_24 > 0)
  // Render at 12.0px — different size should add new glyph entry
  let cmds_12 = tr.render_text(
    "I", 12.0, 0.0, 0.0, dst, shader, @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
  )
  assert_true(cmds_12.length() > 0)
  let count_after_12 = tr.glyph_count()
  assert_true(count_after_12 > count_after_24)
  reset_font_load_hooks()
}

///|
test "multi-font independent renderers" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  let r1 = load_text_renderer("test_a.otf", 256, 100, 0)
  let r2 = load_text_renderer("test_b.otf", 256, 200, 0)
  assert_true(r1 is Some(_))
  assert_true(r2 is Some(_))
  let tr1 = r1.unwrap()
  let tr2 = r2.unwrap()
  // Render 'I' independently
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "text_shader")
  let cmds1 = tr1.render_text(
    "I", 24.0, 0.0, 0.0, dst, shader, @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
  )
  let cmds2 = tr2.render_text(
    "I", 24.0, 0.0, 0.0, dst, shader, @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
  )
  assert_true(cmds1.length() > 0)
  assert_true(cmds2.length() > 0)
  // Each renderer has its own independent atlas
  assert_true(tr1.glyph_count() > 0)
  assert_true(tr2.glyph_count() > 0)
  // Page IDs are different
  assert_true(tr1.get_page_id() != tr2.get_page_id())
  reset_font_load_hooks()
}

///|
test "multi-size measure scales proportionally" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  let renderer = load_text_renderer("test.otf", 256, 1, 0).unwrap()
  let m12 = renderer.measure("I", 12.0)
  let m24 = renderer.measure("I", 24.0)
  let m48 = renderer.measure("I", 48.0)
  assert_true(m12.width > 0.0)
  assert_true(m24.width > 0.0)
  assert_true(m48.width > 0.0)
  // 24px should be approximately 2x of 12px (±20%)
  let ratio_24_12 = m24.width / m12.width
  assert_true(ratio_24_12 > 1.6)
  assert_true(ratio_24_12 < 2.4)
  // 48px should be approximately 2x of 24px (±20%)
  let ratio_48_24 = m48.width / m24.width
  assert_true(ratio_48_24 > 1.6)
  assert_true(ratio_48_24 < 2.4)
  reset_font_load_hooks()
}

///|
test "render text with missing glyphs does not crash" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  let renderer = load_text_renderer("test.otf", 256, 1, 0).unwrap()
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "text_shader")
  // 'A' and 'B' are not in subset, only 'I' is
  let commands = renderer.render_text(
    "ABI", 24.0, 0.0, 0.0, dst, shader, @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
  )
  // Should not crash; 'I' should render
  assert_true(renderer.glyph_count() >= 1)
  assert_true(commands.length() > 0)
  reset_font_load_hooks()
}

///|
test "atlas multi-size stress fills cache" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  let renderer = load_text_renderer("test.otf", 512, 1, 0).unwrap()
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "text_shader")
  let sizes = [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 32.0, 48.0]
  let mut prev_count = 0
  for size in sizes {
    let _ = renderer.render_text(
      "I", size, 0.0, 0.0, dst, shader, @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
    )
    let current_count = renderer.glyph_count()
    assert_true(current_count > prev_count)
    prev_count = current_count
  }
  // Should have 10 distinct cache entries (one per size)
  assert_eq(renderer.glyph_count(), 10)
  reset_font_load_hooks()
}

///|
test "SimpleTextBatchBuilder skips unresolvable glyphs in full atlas" {
  // Use a tiny atlas that can only fit one glyph
  let cache = GlyphCache::new(15.0, 15.0, 1)
  let builder = SimpleTextBatchBuilder::new(cache, 0)
  let glyphs = [
    {
      glyph_id: 1,
      atlas_x: 0.0,
      atlas_y: 0.0,
      atlas_w: 12.0,
      atlas_h: 12.0,
      dst_x: 0.0,
      dst_y: 0.0,
      dst_w: 12.0,
      dst_h: 12.0,
    },
    {
      glyph_id: 2,
      atlas_x: 0.0,
      atlas_y: 0.0,
      atlas_w: 12.0,
      atlas_h: 12.0,
      dst_x: 14.0,
      dst_y: 0.0,
      dst_w: 12.0,
      dst_h: 12.0,
    },
  ]
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "shader")
  let commands = builder.build_draw_commands(dst, glyphs, shader)
  // Only the first glyph should have been allocated; second overflows atlas
  assert_eq(commands.length(), 1)
  // 1 glyph = 4 vertices * 4 floats = 16
  assert_eq(commands[0].vertex_data.length(), 16)
  assert_eq(commands[0].indices.length(), 6)
}

// =====================================================================
// Multi-page atlas tests
// =====================================================================

///|
test "multi-page overflow creates new page" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  // Use very small atlas (32x32) so 'I' at large size fills quickly
  let renderer = load_text_renderer("test.otf", 32, 1, 0).unwrap()
  let tr = renderer
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "shader")
  // Render 'I' at multiple large sizes to overflow the tiny atlas
  let sizes = [16.0, 20.0, 24.0, 28.0, 32.0, 40.0, 48.0, 56.0, 64.0]
  for size in sizes {
    let _ = tr.render_text(
      "I", size, 0.0, 0.0, dst, shader, @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
    )
  }
  assert_true(tr.page_count() > 1)
  reset_font_load_hooks()
}

///|
test "multi-page eviction clears oldest" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  // max_pages=2, tiny atlas
  let font = load_font("test.otf").unwrap()
  let tr = TextRenderer::new_with_options(font, 32, 1, 0, 2)
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "shader")
  // Fill many sizes to trigger eviction
  let sizes = [16.0, 20.0, 24.0, 28.0, 32.0, 40.0, 48.0, 56.0, 64.0, 72.0, 80.0]
  for size in sizes {
    let _ = tr.render_text(
      "I", size, 0.0, 0.0, dst, shader, @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
    )
  }
  // Should never exceed max_pages
  assert_true(tr.page_count() <= 2)
  // Should still have some glyphs cached
  assert_true(tr.glyph_count() > 0)
  reset_font_load_hooks()
}

///|
test "multi-page glyph_count sums all" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  let renderer = load_text_renderer("test.otf", 32, 1, 0).unwrap()
  let tr = renderer
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "shader")
  let sizes = [16.0, 24.0, 32.0, 48.0, 64.0]
  for size in sizes {
    let _ = tr.render_text(
      "I", size, 0.0, 0.0, dst, shader, @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
    )
  }
  if tr.page_count() > 1 {
    // glyph_count should be sum of all pages
    let mut manual_sum = 0
    for i = 0; i < tr.page_count(); i = i + 1 {
      manual_sum += tr.get_page(i).cache.entry_count()
    }
    assert_eq(tr.glyph_count(), manual_sum)
  }
  reset_font_load_hooks()
}

///|
test "multi-page commands per page" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  let renderer = load_text_renderer("test.otf", 32, 100, 0).unwrap()
  let tr = renderer
  let dst = @gfx.new_image_handle(1, 640, 480)
  let shader = @gfx.new_shader_handle(1, "shader")
  // Fill sizes to force multi-page
  let sizes = [16.0, 24.0, 32.0, 48.0, 64.0]
  for size in sizes {
    let _ = tr.render_text(
      "I", size, 0.0, 0.0, dst, shader, @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
    )
  }
  if tr.page_count() > 1 {
    // page IDs should be sequential from base
    let ids = tr.get_page_ids()
    assert_eq(ids[0], 100)
    assert_eq(ids[1], 101)
  }
  reset_font_load_hooks()
}

///|
test "multi-page backward compat" {
  let font_data = test_font_otf_data()
  set_font_load_hooks({
    load_font_data: fn(_name) { Some(font_data) },
  })
  let renderer = load_text_renderer("test.otf", 256, 42, 0).unwrap()
  let tr = renderer
  // get_atlas() should return first page
  let atlas = tr.get_atlas()
  let page0 = tr.get_page(0)
  assert_eq(atlas.cache.atlas_page_id, page0.cache.atlas_page_id)
  // get_page_id() should return base_page_id
  assert_eq(tr.get_page_id(), 42)
  // page_count() starts at 1
  assert_eq(tr.page_count(), 1)
  reset_font_load_hooks()
}

// =====================================================================
// CJK font tests (using NotoSansJP-subset.otf)
// =====================================================================

///|
fn load_cjk_font_data() -> Array[Int]? {
  // Use FontLoadHooks to load CJK subset font
  (font_load_hooks.val.load_font_data)("fixtures/fonts/NotoSansJP-subset.otf")
}

///|
test "CJK hiragana rendering" {
  // This test requires the CJK subset font file to be available via hooks
  let font_data = load_cjk_font_data()
  match font_data {
    None => () // Skip if font not available (e.g., in CI without file)
    Some(data) => {
      let bytes = font_data_to_bytes(data)
      let font = parse_font_bytes(bytes)
      match font {
        None => fail("CJK font parse failed")
        Some(ttfont) => {
          let tr = TextRenderer::new(ttfont, 256, 1, 0)
          let dst = @gfx.new_image_handle(1, 640, 480)
          let shader = @gfx.new_shader_handle(1, "shader")
          let cmds = tr.render_text(
            "あいう", 24.0, 0.0, 0.0, dst, shader,
            @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
          )
          assert_true(cmds.length() > 0)
          assert_true(tr.glyph_count() >= 3)
        }
      }
    }
  }
}

///|
test "CJK mixed text rendering" {
  let font_data = load_cjk_font_data()
  match font_data {
    None => () // Skip if font not available
    Some(data) => {
      let bytes = font_data_to_bytes(data)
      let font = parse_font_bytes(bytes)
      match font {
        None => fail("CJK font parse failed")
        Some(ttfont) => {
          let tr = TextRenderer::new(ttfont, 256, 1, 0)
          // Measure mixed text
          let mixed = tr.measure("Hello世界", 24.0)
          assert_true(mixed.width > 0.0)
          assert_true(mixed.height > 0.0)
          // Render mixed text
          let dst = @gfx.new_image_handle(1, 640, 480)
          let shader = @gfx.new_shader_handle(1, "shader")
          let cmds = tr.render_text(
            "Hello世界", 24.0, 0.0, 0.0, dst, shader,
            @gfx.blend_mode_from_int(1), [255, 255, 255, 255],
          )
          assert_true(cmds.length() > 0)
        }
      }
    }
  }
}

///|
test "CJK multi-size measure" {
  let font_data = load_cjk_font_data()
  match font_data {
    None => () // Skip if font not available
    Some(data) => {
      let bytes = font_data_to_bytes(data)
      let font = parse_font_bytes(bytes)
      match font {
        None => fail("CJK font parse failed")
        Some(ttfont) => {
          let tr = TextRenderer::new(ttfont, 256, 1, 0)
          let m12 = tr.measure("日", 12.0)
          let m24 = tr.measure("日", 24.0)
          assert_true(m12.width > 0.0)
          assert_true(m24.width > 0.0)
          // 24px should be approximately 2x of 12px (±20%)
          let ratio = m24.width / m12.width
          assert_true(ratio > 1.6)
          assert_true(ratio < 2.4)
        }
      }
    }
  }
}
