///|
/// Particle-like benchmark fixtures for sprite command build and dispatch.
fn bench_particle_repo(
  atlas_id : Int,
  key_name : String,
) -> (@asset.SimpleAtlasImageRepository, @asset.AssetKey) {
  let repo = @asset.new_simple_atlas_image_repository(8, 8, atlas_id)
  let key = @asset.new_asset_key(key_name)
  let _ = @asset.create_atlas_image(repo, key, @asset.default_image_spec(2, 2))
  (repo, key)
}

///|
fn particle_dispatch_checksum(dispatch : @gfx.DrawCommandDispatch) -> Int {
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
fn particle_pipeline_checksum(
  commands : Array[@gfx.DrawTrianglesCommand],
) -> Int {
  let queue = @gfx.new_simple_command_queue()
  for command in commands {
    queue.enqueue_draw_triangles(command)
  }
  let flushed = queue.flush()
  let mut checksum = flushed.length()
  for command in flushed {
    checksum = checksum +
      particle_dispatch_checksum(@gfx.build_draw_command_dispatch(command))
  }
  checksum
}

///|
fn append_particle_command(
  commands : Array[@gfx.DrawTrianglesCommand],
  repo : @asset.SimpleAtlasImageRepository,
  key : @asset.AssetKey,
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  dst_region : @gfx.DstRegion,
  pipeline_id : Int,
  uniform_hash : Int,
  blend : @gfx.BlendMode,
  i : Int,
  uniform_dwords : Array[Int],
) -> Unit {
  let left = (i % 256).to_double() * 2.0
  let top = (i / 256).to_double() * 2.0
  let appended = append_atlas_sprite_draw_command(
    commands,
    repo,
    key,
    dst,
    shader,
    dst_region,
    0,
    pipeline_id,
    uniform_hash,
    blend,
    left,
    top,
    left + 2.0,
    top + 2.0,
    uniform_dwords,
  )
  if !appended {
    panic()
  }
}

///|
test "bench particle pipeline same state 10000" (b : @bench.T) {
  let (repo, key) = bench_particle_repo(700, "particle/a")
  let dst = @gfx.new_image_handle(1, 1920, 1080)
  let shader = @gfx.new_shader_handle(2, "particle_shader")
  let dst_region = @gfx.new_dst_region(0, 0, 1920, 1080, 6)
  let blend = @gfx.blend_mode_from_int(1)
  let uniform_dwords = [1, 2, 3, 4]
  b.bench(name="particles/pipeline_same_state_10000", fn() {
    let commands : Array[@gfx.DrawTrianglesCommand] = []
    for i in 0..<10000 {
      append_particle_command(
        commands, repo, key, dst, shader, dst_region, 7, 11, blend, i,
        uniform_dwords,
      )
    }
    b.keep(particle_pipeline_checksum(commands))
  })
}

///|
test "bench particle pipeline varying uniform 10000" (b : @bench.T) {
  let (repo, key) = bench_particle_repo(701, "particle/a")
  let dst = @gfx.new_image_handle(1, 1920, 1080)
  let shader = @gfx.new_shader_handle(2, "particle_shader")
  let dst_region = @gfx.new_dst_region(0, 0, 1920, 1080, 6)
  let blend = @gfx.blend_mode_from_int(1)
  b.bench(name="particles/pipeline_varying_uniform_10000", fn() {
    let commands : Array[@gfx.DrawTrianglesCommand] = []
    for i in 0..<10000 {
      append_particle_command(
        commands,
        repo,
        key,
        dst,
        shader,
        dst_region,
        7,
        11,
        blend,
        i,
        [i % 64],
      )
    }
    b.keep(particle_pipeline_checksum(commands))
  })
}

///|
test "bench particle pipeline alternating texture pages 10000" (b : @bench.T) {
  let (repo_a, key_a) = bench_particle_repo(710, "particle/a")
  let (repo_b, key_b) = bench_particle_repo(711, "particle/b")
  let dst = @gfx.new_image_handle(1, 1920, 1080)
  let shader = @gfx.new_shader_handle(2, "particle_shader")
  let dst_region = @gfx.new_dst_region(0, 0, 1920, 1080, 6)
  let blend = @gfx.blend_mode_from_int(1)
  let uniform_dwords = [1, 2, 3, 4]
  b.bench(name="particles/pipeline_alternating_texture_pages_10000", fn() {
    let commands : Array[@gfx.DrawTrianglesCommand] = []
    for i in 0..<10000 {
      if i % 2 == 0 {
        append_particle_command(
          commands, repo_a, key_a, dst, shader, dst_region, 7, 11, blend, i,
          uniform_dwords,
        )
      } else {
        append_particle_command(
          commands, repo_b, key_b, dst, shader, dst_region, 7, 11, blend, i,
          uniform_dwords,
        )
      }
    }
    b.keep(particle_pipeline_checksum(commands))
  })
}
