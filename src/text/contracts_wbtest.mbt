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
  assert_eq!(commands.length(), 2)
  assert_eq!(commands[0].vertex_data.length(), 16)
  assert_eq!(commands[0].indices.length(), 6)
  assert_eq!(commands[0].src_image_ids.length(), 1)
  assert_eq!(commands[0].src_image_ids[0], 1) // atlas_page_id
}
