///|
/// Baseline benchmark for atlas blitting hot path.
test "bench blit_to_atlas full copy" (b : @bench.T) {
  let atlas = GlyphAtlas::new(1024, 1024, 1)
  let bitmap : GlyphBitmap = {
    width: 64,
    height: 64,
    pixels: Array::make(64 * 64 * 4, 255),
  }
  b.bench(name="blit_to_atlas/full_copy_64x64", fn() {
    blit_to_atlas(atlas.pixels, atlas.width, bitmap, 128, 128)
    b.keep(atlas.pixels[(128 * atlas.width + 128) * 4])
  })
}

///|
/// Benchmark for partially clipped blits near atlas edge.
test "bench blit_to_atlas edge clip" (b : @bench.T) {
  let atlas = GlyphAtlas::new(1024, 1024, 1)
  let bitmap : GlyphBitmap = {
    width: 64,
    height: 64,
    pixels: Array::make(64 * 64 * 4, 255),
  }
  b.bench(name="blit_to_atlas/edge_clip_64x64", fn() {
    blit_to_atlas(atlas.pixels, atlas.width, bitmap, 1000, 1000)
    b.keep(atlas.pixels[(1000 * atlas.width + 1000) * 4])
  })
}

///|
fn make_bench_glyphs(count : Int) -> Array[GlyphQuad] {
  let glyphs : Array[GlyphQuad] = []
  for i in 0..<count {
    let x = (i % 64).to_double() * 12.0
    let y = (i / 64).to_double() * 12.0
    glyphs.push(
      {
        glyph_id: i + 1,
        atlas_x: 0.0,
        atlas_y: 0.0,
        atlas_w: 10.0,
        atlas_h: 10.0,
        dst_x: x,
        dst_y: y,
        dst_w: 10.0,
        dst_h: 10.0,
      },
    )
  }
  glyphs
}

///|
fn dispatch_checksum(dispatch : @gfx.DrawCommandDispatch) -> Int {
  dispatch.draw_calls +
  dispatch.pipeline_id +
  dispatch.uniform_hash +
  dispatch.blend_mode +
  dispatch.dst_image_id +
  dispatch.shader_id +
  dispatch.index_offset +
  dispatch.region_count +
  dispatch.total_index_count +
  dispatch.vertex_float_count +
  dispatch.index_count +
  dispatch.src_image_count +
  dispatch.uniform_dword_count
}

///|
fn pipeline_dispatch_checksum(
  commands : Array[@gfx.DrawTrianglesCommand],
) -> Int {
  let queue = @gfx.new_simple_command_queue()
  for command in commands {
    queue.enqueue_draw_triangles(command)
  }
  let flushed = queue.flush()
  let mut checksum = flushed.length()
  for command in flushed {
    let dispatch = @gfx.build_draw_command_dispatch(command)
    checksum = checksum + dispatch_checksum(dispatch)
  }
  checksum
}

///|
/// Benchmark text draw command build in warm-cache condition.
test "bench build_draw_commands warm cache 512" (b : @bench.T) {
  let cache = GlyphCache::new(4096.0, 4096.0, 1)
  let builder = SimpleTextBatchBuilder::new(cache, 0)
  let glyphs = make_bench_glyphs(512)
  let target = @gfx.new_image_handle(1, 1024, 1024)
  let shader = @gfx.new_shader_handle(1, "text_shader")
  // Warm up cache once.
  let _ = builder.build_draw_commands(target, glyphs, shader) catch {
    _ => []
  }
  b.bench(name="build_draw_commands/warm_cache_512", fn() {
    let commands = builder.build_draw_commands(target, glyphs, shader) catch {
      _ => []
    }
    b.keep(commands.length())
  })
}

///|
/// Benchmark text draw command build in cold-cache condition.
test "bench build_draw_commands cold cache 512" (b : @bench.T) {
  let glyphs = make_bench_glyphs(512)
  let target = @gfx.new_image_handle(1, 1024, 1024)
  let shader = @gfx.new_shader_handle(1, "text_shader")
  b.bench(name="build_draw_commands/cold_cache_512", fn() {
    let cache = GlyphCache::new(4096.0, 4096.0, 1)
    let builder = SimpleTextBatchBuilder::new(cache, 0)
    let commands = builder.build_draw_commands(target, glyphs, shader) catch {
      _ => []
    }
    b.keep(commands.length())
  })
}

///|
/// End-to-end benchmark: build commands + queue merge + dispatch build (warm cache).
test "bench draw pipeline warm cache 512" (b : @bench.T) {
  let cache = GlyphCache::new(4096.0, 4096.0, 1)
  let builder = SimpleTextBatchBuilder::new(cache, 0)
  let glyphs = make_bench_glyphs(512)
  let target = @gfx.new_image_handle(1, 1024, 1024)
  let shader = @gfx.new_shader_handle(1, "text_shader")
  let _ = builder.build_draw_commands(target, glyphs, shader) catch {
    _ => []
  }
  b.bench(name="draw_pipeline/warm_cache_512", fn() {
    let commands = builder.build_draw_commands(target, glyphs, shader) catch {
      _ => []
    }
    b.keep(pipeline_dispatch_checksum(commands))
  })
}

///|
/// End-to-end benchmark: build commands + queue merge + dispatch build (cold cache).
test "bench draw pipeline cold cache 512" (b : @bench.T) {
  let glyphs = make_bench_glyphs(512)
  let target = @gfx.new_image_handle(1, 1024, 1024)
  let shader = @gfx.new_shader_handle(1, "text_shader")
  b.bench(name="draw_pipeline/cold_cache_512", fn() {
    let cache = GlyphCache::new(4096.0, 4096.0, 1)
    let builder = SimpleTextBatchBuilder::new(cache, 0)
    let commands = builder.build_draw_commands(target, glyphs, shader) catch {
      _ => []
    }
    b.keep(pipeline_dispatch_checksum(commands))
  })
}
