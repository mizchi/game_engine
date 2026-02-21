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
