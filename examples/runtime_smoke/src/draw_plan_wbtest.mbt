///|
test "build_runtime_smoke_tile_draw_plan returns tile sprite and text commands" {
  let plan = build_runtime_smoke_tile_draw_plan(
    @gfx.new_image_handle(1, 64, 64),
    @gfx.new_shader_handle(2, "shader"),
  )
  assert_eq(plan.commands.length(), 3)
  let tile_command = plan.commands[0]
  assert_eq(tile_command.src_image_ids.length(), 1)
  assert_eq(tile_command.src_image_ids[0], runtime_smoke_atlas_page_id)
  assert_eq(tile_command.vertex_data[0], -0.5)
  assert_eq(tile_command.vertex_data[1], -0.5)
  assert_eq(tile_command.vertex_data[4], 0.5)
  assert_eq(tile_command.vertex_data[5], -0.5)
  assert_eq(tile_command.vertex_data[8], 0.5)
  assert_eq(tile_command.vertex_data[9], 0.5)
  assert_eq(tile_command.indices.length(), 6)
  assert_eq(plan.sprite_command_index, 1)
  let sprite_command = plan.commands[1]
  assert_eq(sprite_command.src_image_ids.length(), 1)
  assert_eq(sprite_command.src_image_ids[0], runtime_smoke_atlas_page_id)
  assert_eq(sprite_command.vertex_data.length(), 16)
  assert_eq(sprite_command.indices.length(), 6)
  assert_eq(plan.text_command_index, 2)
  let text_command = plan.commands[2]
  assert_eq(text_command.src_image_ids.length(), 1)
  assert_eq(text_command.src_image_ids[0], runtime_smoke_text_page_id)
  // TextRenderer generates 1 glyph for "I": 4 verts * 4 floats = 16
  assert_eq(text_command.vertex_data.length(), 16)
  // 1 glyph = 6 indices
  assert_eq(text_command.indices.length(), 6)
  // UV coords should be in [0,1] range
  assert_true(
    text_command.vertex_data[2] >= 0.0 && text_command.vertex_data[2] <= 1.0,
  )
  assert_true(
    text_command.vertex_data[3] >= 0.0 && text_command.vertex_data[3] <= 1.0,
  )
  // uniform_dwords should contain color data
  assert_eq(text_command.uniform_dwords.length(), 4)
  assert_eq(text_command.uniform_dwords[0], 255)
}

///|
test "rasterize_text I returns 1 quad with valid atlas coords" {
  let text_atlas = @text.GlyphAtlas::new(64, 64, 900)
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let quads = text_atlas.rasterize_text(ttfont, "I", 24.0)
      assert_eq(quads.length(), 1)
      let q = quads[0]
      assert_true(q.atlas_x >= 0.0)
      assert_true(q.atlas_w > 0.0)
      assert_true(q.atlas_x + q.atlas_w <= 64.0)
      assert_true(q.atlas_y >= 0.0)
      assert_true(q.atlas_h > 0.0)
      assert_true(q.atlas_y + q.atlas_h <= 64.0)
      assert_eq(q.dst_w, q.atlas_w)
      assert_eq(q.dst_h, q.atlas_h)
    }
    None => panic()
  }
}

///|
test "rasterize_text III returns 3 quads with advancing x" {
  let text_atlas = @text.GlyphAtlas::new(128, 128, 900)
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let quads = text_atlas.rasterize_text(ttfont, "III", 24.0)
      assert_eq(quads.length(), 3)
      // All same glyph_id
      assert_eq(quads[0].glyph_id, quads[1].glyph_id)
      assert_eq(quads[1].glyph_id, quads[2].glyph_id)
      // Advancing x positions
      assert_true(quads[0].dst_x < quads[1].dst_x)
      assert_true(quads[1].dst_x < quads[2].dst_x)
      // Same atlas coords (same glyph cached once)
      assert_eq(quads[0].atlas_x, quads[1].atlas_x)
      assert_eq(quads[0].atlas_y, quads[1].atlas_y)
      assert_eq(quads[0].atlas_w, quads[1].atlas_w)
      assert_eq(quads[0].atlas_h, quads[1].atlas_h)
      assert_eq(quads[1].atlas_x, quads[2].atlas_x)
      assert_eq(quads[1].atlas_y, quads[2].atlas_y)
    }
    None => panic()
  }
}

///|
test "rasterize_text at different sizes produces different glyph dimensions" {
  let atlas_small = @text.GlyphAtlas::new(128, 128, 901)
  let atlas_large = @text.GlyphAtlas::new(128, 128, 902)
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let quads_12 = atlas_small.rasterize_text(ttfont, "I", 12.0)
      let quads_24 = atlas_large.rasterize_text(ttfont, "I", 24.0)
      assert_eq(quads_12.length(), 1)
      assert_eq(quads_24.length(), 1)
      assert_true(quads_24[0].atlas_w > quads_12[0].atlas_w)
      assert_true(quads_24[0].atlas_h > quads_12[0].atlas_h)
    }
    None => panic()
  }
}

///|
test "SimpleFontEngine measure with embedded font" {
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let fe = @text.load_font_engine_from_bytes(font_data)
  match fe {
    Some(engine) => {
      let style = @text.default_text_style("test", 24.0)
      let run = @text.new_text_run("Hello", style)
      let metrics = engine.measure(run)
      assert_true(metrics.width > 0.0)
      assert_true(metrics.height > 0.0)
      assert_true(metrics.baseline > 0.0)
      assert_true(metrics.baseline <= metrics.height)
    }
    None => panic()
  }
}

///|
test "SimpleTextBatchBuilder with quads from rasterize_text" {
  let text_atlas = @text.GlyphAtlas::new(128, 128, 903)
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let quads = text_atlas.rasterize_text(ttfont, "III", 24.0)
      assert_eq(quads.length(), 3)
      let builder = @text.SimpleTextBatchBuilder::new(text_atlas.get_cache(), 7)
      let dst = @gfx.new_image_handle(1, 128, 128)
      let shader = @gfx.new_shader_handle(2, "shader")
      let commands = builder.build_draw_commands(dst, quads, shader)
      assert_eq(commands.length(), 1)
      let cmd = commands[0]
      assert_eq(cmd.vertex_data.length(), 48)
      assert_eq(cmd.indices.length(), 18)
      assert_eq(cmd.src_image_ids.length(), 1)
      assert_eq(cmd.src_image_ids[0], 903)
      // UV coords should be in [0, 1]
      // vertex_data layout: [x0,y0,u0,v0, x1,y1,u1,v1, ...]
      assert_true(cmd.vertex_data[2] >= 0.0 && cmd.vertex_data[2] <= 1.0)
      assert_true(cmd.vertex_data[3] >= 0.0 && cmd.vertex_data[3] <= 1.0)
      assert_true(cmd.vertex_data[6] >= 0.0 && cmd.vertex_data[6] <= 1.0)
      assert_true(cmd.vertex_data[7] >= 0.0 && cmd.vertex_data[7] <= 1.0)
      // Advancing x positions across glyph quads in one command.
      let first_x = cmd.vertex_data[0]
      let second_x = cmd.vertex_data[16]
      let third_x = cmd.vertex_data[32]
      assert_true(first_x < second_x)
      assert_true(second_x < third_x)
    }
    None => panic()
  }
}

///|
test "TextRenderer render_text produces valid draw commands" {
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let renderer = @text.TextRenderer::new(ttfont, 128, 950, 7)
      assert_eq(renderer.glyph_count(), 0)
      assert_eq(renderer.get_page_id(), 950)
      let dst = @gfx.new_image_handle(1, 640, 480)
      let shader = @gfx.new_shader_handle(2, "text_shader")
      let blend = @gfx.blend_mode_from_int(1)
      let commands = renderer.render_text(
        "III",
        24.0,
        10.0,
        50.0,
        dst,
        shader,
        blend,
        [255, 255, 255, 255],
      )
      assert_eq(commands.length(), 1)
      let cmd = commands[0]
      // 3 glyphs => 3*4=12 vertices, 3*16=48 floats
      assert_eq(cmd.vertex_data.length(), 48)
      // 3 glyphs => 3*6=18 indices
      assert_eq(cmd.indices.length(), 18)
      // Source image is the atlas page
      assert_eq(cmd.src_image_ids.length(), 1)
      assert_eq(cmd.src_image_ids[0], 950)
      // Uniform dwords should be passed through
      assert_eq(cmd.uniform_dwords.length(), 4)
      assert_eq(cmd.uniform_dwords[0], 255)
      // Glyph positions should be offset by (10, 50)
      let first_x = cmd.vertex_data[0]
      assert_true(first_x >= 10.0)
      let first_y = cmd.vertex_data[1]
      assert_true(first_y >= 0.0) // y offset applied (50.0 + negative dst_y from baseline)
      // Advancing x positions
      let second_x = cmd.vertex_data[16]
      let third_x = cmd.vertex_data[32]
      assert_true(first_x < second_x)
      assert_true(second_x < third_x)
      // UV coords in [0,1] range
      assert_true(cmd.vertex_data[2] >= 0.0 && cmd.vertex_data[2] <= 1.0)
      assert_true(cmd.vertex_data[3] >= 0.0 && cmd.vertex_data[3] <= 1.0)
      // Atlas should now have cached the glyph
      assert_true(renderer.glyph_count() > 0)
    }
    None => panic()
  }
}

///|
test "TextRenderer render_text empty string returns no commands" {
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let renderer = @text.TextRenderer::new(ttfont, 64, 960, 0)
      let dst = @gfx.new_image_handle(1, 640, 480)
      let shader = @gfx.new_shader_handle(1, "shader")
      let blend = @gfx.blend_mode_from_int(1)
      let commands = renderer.render_text(
        "",
        24.0,
        0.0,
        0.0,
        dst,
        shader,
        blend,
        [],
      )
      assert_eq(commands.length(), 0)
      assert_eq(renderer.glyph_count(), 0)
    }
    None => panic()
  }
}

///|
test "TextRenderer measure returns positive dimensions" {
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let renderer = @text.TextRenderer::new(ttfont, 64, 970, 0)
      let metrics = renderer.measure("Hello", 24.0)
      assert_true(metrics.width > 0.0)
      assert_true(metrics.height > 0.0)
      assert_true(metrics.baseline > 0.0)
      assert_true(metrics.baseline <= metrics.height)
    }
    None => panic()
  }
}

///|
test "TextRenderer render_text then clear resets glyph count" {
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let renderer = @text.TextRenderer::new(ttfont, 128, 980, 0)
      let dst = @gfx.new_image_handle(1, 640, 480)
      let shader = @gfx.new_shader_handle(1, "shader")
      let blend = @gfx.blend_mode_from_int(1)
      // Render text to populate atlas
      let _ = renderer.render_text("I", 24.0, 0.0, 0.0, dst, shader, blend, [])
      assert_true(renderer.glyph_count() > 0)
      // Clear should reset
      renderer.clear()
      assert_eq(renderer.glyph_count(), 0)
      // Atlas pixels should be zeroed
      let pixels = renderer.get_atlas().get_pixels()
      let mut all_zero = true
      let check_len = if 64 < pixels.length() { 64 } else { pixels.length() }
      for i in 0..<check_len {
        if pixels[i] != 0 {
          all_zero = false
          break
        }
      }
      assert_true(all_zero)
    }
    None => panic()
  }
}

///|
test "TextRenderer atlas has non-zero pixels after render" {
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let renderer = @text.TextRenderer::new(ttfont, 128, 990, 0)
      let dst = @gfx.new_image_handle(1, 640, 480)
      let shader = @gfx.new_shader_handle(1, "shader")
      let blend = @gfx.blend_mode_from_int(1)
      let _ = renderer.render_text("I", 24.0, 0.0, 0.0, dst, shader, blend, [])
      // Atlas should have non-zero pixels from rasterized glyph
      let pixels = renderer.get_atlas().get_pixels()
      let mut has_nonzero = false
      for i in 0..<pixels.length() {
        if pixels[i] != 0 {
          has_nonzero = true
          break
        }
      }
      assert_true(has_nonzero)
    }
    None => panic()
  }
}

///|
test "TextRenderer multiple render_text calls share glyph cache" {
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let renderer = @text.TextRenderer::new(ttfont, 128, 991, 0)
      let dst = @gfx.new_image_handle(1, 640, 480)
      let shader = @gfx.new_shader_handle(1, "shader")
      let blend = @gfx.blend_mode_from_int(1)
      // First render
      let _ = renderer.render_text("I", 24.0, 0.0, 0.0, dst, shader, blend, [])
      let count_after_first = renderer.glyph_count()
      assert_true(count_after_first > 0)
      // Second render with same text should not increase glyph count
      let _ = renderer.render_text("I", 24.0, 50.0, 0.0, dst, shader, blend, [])
      assert_eq(renderer.glyph_count(), count_after_first)
      // Render with different text should increase glyph count
      // (the "I" glyph is cached, rendering "II" should not add new entries)
      let _ = renderer.render_text("II", 24.0, 100.0, 0.0, dst, shader, blend, [])
      assert_eq(renderer.glyph_count(), count_after_first)
    }
    None => panic()
  }
}

///|
test "rasterize_text matches rasterize_glyph UV for single I" {
  let atlas_glyph = @text.GlyphAtlas::new(64, 64, 910)
  let atlas_text = @text.GlyphAtlas::new(64, 64, 911)
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let entry = atlas_glyph.rasterize_glyph(ttfont, 73, 24.0)
      let quads = atlas_text.rasterize_text(ttfont, "I", 24.0)
      match entry {
        Some(cache_entry) => {
          assert_eq(quads.length(), 1)
          let quad = quads[0]
          assert_eq(cache_entry.atlas_x, quad.atlas_x)
          assert_eq(cache_entry.atlas_y, quad.atlas_y)
          assert_eq(cache_entry.atlas_w, quad.atlas_w)
          assert_eq(cache_entry.atlas_h, quad.atlas_h)
        }
        None => panic()
      }
    }
    None => panic()
  }
}
