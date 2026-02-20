///|
test "default_text_style" {
  let style = default_text_style("sans-serif", 16.0)
  assert_eq!(style.font.family, "sans-serif")
  assert_eq!(style.font.weight, 400)
  assert_eq!(style.font.italic, false)
  assert_eq!(style.size_px, 16.0)
  assert_eq!(style.line_height, 22.4)
  assert_eq!(style.letter_spacing, 0.0)
}

///|
test "GlyphCache allocate and get" {
  let cache = GlyphCache::new(256.0, 256.0, 1)
  assert_eq!(cache.entry_count(), 0)
  // Allocate first glyph
  match cache.allocate(65, 10.0, 12.0) {
    Some(entry) => {
      assert_eq!(entry.glyph_id, 65)
      assert_eq!(entry.atlas_x, 0.0)
      assert_eq!(entry.atlas_y, 0.0)
      assert_eq!(entry.atlas_w, 10.0)
      assert_eq!(entry.atlas_h, 12.0)
      assert_eq!(entry.atlas_page_id, 1)
    }
    None => fail!("expected allocation to succeed")
  }
  assert_eq!(cache.entry_count(), 1)
  // Get existing glyph
  match cache.get(65) {
    Some(entry) => assert_eq!(entry.glyph_id, 65)
    None => fail!("expected glyph to be cached")
  }
  // Get missing glyph
  match cache.get(66) {
    Some(_) => fail!("expected None")
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
      assert_eq!(entry.atlas_x, 11.0)
      assert_eq!(entry.atlas_y, 0.0)
    }
    None => fail!("expected allocation")
  }
  assert_eq!(cache.entry_count(), 2)
}

///|
test "GlyphCache row wrapping" {
  let cache = GlyphCache::new(30.0, 256.0, 1)
  let _ = cache.allocate(65, 10.0, 12.0) // x=0, w=10+1=11
  let _ = cache.allocate(66, 10.0, 12.0) // x=11, w=10+1=11 -> 22
  // Third glyph should wrap to next row: 22+11=33 > 30
  match cache.allocate(67, 10.0, 14.0) {
    Some(entry) => {
      assert_eq!(entry.atlas_x, 0.0)
      // y should be 0 + row_height(13) + padding(1) = 14
      assert_eq!(entry.atlas_y, 14.0)
    }
    None => fail!("expected allocation")
  }
}

///|
test "GlyphCache atlas full" {
  let cache = GlyphCache::new(20.0, 20.0, 1)
  let _ = cache.allocate(65, 18.0, 18.0) // fills most of atlas
  // Second glyph should fail
  match cache.allocate(66, 18.0, 18.0) {
    Some(_) => fail!("expected None when atlas is full")
    None => ()
  }
}

///|
test "GlyphCache clear" {
  let cache = GlyphCache::new(256.0, 256.0, 1)
  let _ = cache.allocate(65, 10.0, 12.0)
  assert_eq!(cache.entry_count(), 1)
  cache.clear()
  assert_eq!(cache.entry_count(), 0)
}

///|
test "GlyphCache duplicate allocate returns existing" {
  let cache = GlyphCache::new(256.0, 256.0, 1)
  let _ = cache.allocate(65, 10.0, 12.0)
  // Allocate same glyph again should return existing entry
  match cache.allocate(65, 10.0, 12.0) {
    Some(entry) => {
      assert_eq!(entry.atlas_x, 0.0)
      assert_eq!(entry.atlas_y, 0.0)
    }
    None => fail!("expected existing entry")
  }
  assert_eq!(cache.entry_count(), 1)
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
  assert_true!(d.contains("M 0"))
  assert_true!(d.contains("L 5"))
  assert_true!(d.contains("L 10"))
  assert_true!(d.contains("Z"))
}

///|
test "path_commands_to_svg_d with curves" {
  let commands : Array[@msvg.PathCommand] = [
    @msvg.PathCommand::MoveTo(0.0, 0.0),
    @msvg.PathCommand::QuadraticCurveTo(5.0, 10.0, 10.0, 0.0),
    @msvg.PathCommand::CurveTo(15.0, 5.0, 20.0, 5.0, 25.0, 0.0),
  ]
  let d = path_commands_to_svg_d(commands)
  assert_true!(d.contains("M 0"))
  assert_true!(d.contains("Q "))
  assert_true!(d.contains("C "))
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
  assert_true!((x_min - 0.0).abs() < 0.01)
  assert_true!((y_min - (-3.0)).abs() < 0.01)
  assert_true!((x_max - 20.0).abs() < 0.01)
  assert_true!((y_max - 15.0).abs() < 0.01)
}

///|
test "outline_bbox with quadratic control points" {
  let commands : Array[@msvg.PathCommand] = [
    @msvg.PathCommand::MoveTo(0.0, 0.0),
    @msvg.PathCommand::QuadraticCurveTo(5.0, 20.0, 10.0, 0.0),
  ]
  let (x_min, y_min, x_max, y_max) = outline_bbox(commands)
  assert_true!((x_min - 0.0).abs() < 0.01)
  assert_true!((y_min - 0.0).abs() < 0.01)
  assert_true!((x_max - 10.0).abs() < 0.01)
  // Control point at y=20 should extend bbox
  assert_true!((y_max - 20.0).abs() < 0.01)
}

///|
test "GlyphAtlas new" {
  let atlas = GlyphAtlas::new(128, 128, 1)
  assert_eq!(atlas.width, 128)
  assert_eq!(atlas.height, 128)
  assert_eq!(atlas.pixels.length(), 128 * 128 * 4)
  assert_eq!(atlas.cache.entry_count(), 0)
}

///|
test "blit_to_atlas" {
  let atlas = GlyphAtlas::new(16, 16, 1)
  // Create a 2x2 red bitmap
  let bitmap : GlyphBitmap = {
    width: 2,
    height: 2,
    pixels: [
      255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 0, 255,
    ],
  }
  blit_to_atlas(atlas.pixels, atlas.width, bitmap, 3, 5)
  // Check pixel at (3, 5) = red
  let idx = (5 * 16 + 3) * 4
  assert_eq!(atlas.pixels[idx], 255) // R
  assert_eq!(atlas.pixels[idx + 1], 0) // G
  assert_eq!(atlas.pixels[idx + 2], 0) // B
  assert_eq!(atlas.pixels[idx + 3], 255) // A
  // Check pixel at (4, 5) = green
  let idx2 = (5 * 16 + 4) * 4
  assert_eq!(atlas.pixels[idx2], 0)
  assert_eq!(atlas.pixels[idx2 + 1], 255)
  // Check pixel at (3, 6) = blue
  let idx3 = (6 * 16 + 3) * 4
  assert_eq!(atlas.pixels[idx3], 0)
  assert_eq!(atlas.pixels[idx3 + 1], 0)
  assert_eq!(atlas.pixels[idx3 + 2], 255)
}

///|
test "SVG rasterize triangle produces non-empty pixels" {
  // Test the SVG → pixel pipeline with a simple triangle
  let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"32\" height=\"32\"><path d=\"M 16 2 L 30 30 L 2 30 Z\" fill=\"white\"/></svg>"
  match @msvg.render_svg_to_image(svg, 32, 32) {
    Some(img) => {
      assert_eq!(img.width, 32)
      assert_eq!(img.height, 32)
      // Center of triangle should have white pixels
      let center_idx = 20 * 32 + 16
      assert_true!(img.pixels[center_idx].a > 200)
    }
    None => fail!("expected SVG render")
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
  let bitmap : GlyphBitmap = {
    width: 4,
    height: 4,
    pixels: src_pixels,
  }
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
  assert_eq!(detect_font_format(ttf), FontFormat::TrueType)
  // OTF magic: "OTTO"
  let otf = Bytes::from_array([b'\x4F', b'\x54', b'\x54', b'\x4F', b'\x00'])
  assert_eq!(detect_font_format(otf), FontFormat::OpenType)
  // WOFF1 magic: "wOFF"
  let woff1 = Bytes::from_array([b'\x77', b'\x4F', b'\x46', b'\x46', b'\x00'])
  assert_eq!(detect_font_format(woff1), FontFormat::Woff1)
  // WOFF2 magic: "wOF2"
  let woff2 = Bytes::from_array([b'\x77', b'\x4F', b'\x46', b'\x32', b'\x00'])
  assert_eq!(detect_font_format(woff2), FontFormat::Woff2)
  // TTC magic: "ttcf"
  let ttc = Bytes::from_array([b'\x74', b'\x74', b'\x63', b'\x66', b'\x00'])
  assert_eq!(detect_font_format(ttc), FontFormat::TrueTypeCollection)
  // Unknown
  let unknown = Bytes::from_array([b'\xFF', b'\xFF', b'\xFF', b'\xFF'])
  assert_eq!(detect_font_format(unknown), FontFormat::Unknown)
  // Too short
  let short = Bytes::from_array([b'\x00', b'\x01'])
  assert_eq!(detect_font_format(short), FontFormat::Unknown)
  // Empty
  let empty = Bytes::from_array([])
  assert_eq!(detect_font_format(empty), FontFormat::Unknown)
}

///|
test "parse_font_bytes returns None for invalid data" {
  let bad = Bytes::from_array([b'\xFF', b'\xFE', b'\xFD', b'\xFC', b'\x00', b'\x00', b'\x00', b'\x00'])
  match parse_font_bytes(bad) {
    None => ()
    Some(_) => fail!("expected None for invalid font data")
  }
}

///|
test "load_font_engine_from_bytes returns None for invalid data" {
  let bad = Bytes::from_array([b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00'])
  match load_font_engine_from_bytes(bad) {
    None => ()
    Some(_) => fail!("expected None for invalid font data")
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
  assert_eq!(commands.length(), 1)
  assert_eq!(commands[0].vertex_data.length(), 32)
  assert_eq!(commands[0].indices.length(), 12)
  assert_eq!(commands[0].dst_regions.length(), 1)
  assert_eq!(commands[0].dst_regions[0].index_count, 12)
  // Second quad indices should be offset by +4 vertices.
  assert_eq!(commands[0].indices[6], 4)
  assert_eq!(commands[0].indices[7], 5)
  assert_eq!(commands[0].indices[8], 6)
  assert_eq!(commands[0].indices[9], 6)
  assert_eq!(commands[0].indices[10], 7)
  assert_eq!(commands[0].indices[11], 4)
  assert_eq!(commands[0].src_image_ids.length(), 1)
  assert_eq!(commands[0].src_image_ids[0], 1) // atlas_page_id
}
