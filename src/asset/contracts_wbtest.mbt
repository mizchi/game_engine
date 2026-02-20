///|
fn expect_some_image(
  value : @gfx.ImageHandle?,
  expected_id : Int,
  expected_width : Int,
  expected_height : Int,
) -> Unit raise {
  match value {
    Some(image) => {
      assert_eq(image.id, expected_id)
      assert_eq(image.width, expected_width)
      assert_eq(image.height, expected_height)
    }
    None => panic()
  }
}

///|
fn expect_some_shader(
  value : @gfx.ShaderHandle?,
  expected_id : Int,
  expected_source : String,
) -> Unit raise {
  match value {
    Some(shader) => {
      assert_eq(shader.id, expected_id)
      assert_eq(shader.source, expected_source)
    }
    None => panic()
  }
}

///|
test "new_source_image_binding factory constructs binding" {
  let palette = @image_palette.checker_palette_from_seed(42)
  let pixels = [10, 20, 30, 255]
  let dirty = new_source_image_dirty_rect(1, 2, 3, 4)
  let binding = new_source_image_binding(
    900, 32, 32, 1, Some(dirty), palette, pixels,
  )
  assert_eq(binding.image_id, 900)
  assert_eq(binding.width, 32)
  assert_eq(binding.height, 32)
  assert_eq(binding.generation, 1)
  assert_eq(binding.pixels_rgba8[0], 10)
  match binding.dirty_rect {
    Some(rect) => {
      assert_eq(rect.x, 1)
      assert_eq(rect.y, 2)
      assert_eq(rect.width, 3)
      assert_eq(rect.height, 4)
    }
    None => panic()
  }
}

///|
test "simple image repository can create get and remove images" {
  let repo = new_simple_image_repository()
  let key : AssetKey = { value: "player" }
  let spec = default_image_spec(32, 16)
  let handle = repo.create_image(key, spec)

  assert_eq(handle.id, 1)
  assert_eq(handle.width, 32)
  assert_eq(handle.height, 16)
  expect_some_image(repo.get_image(key), 1, 32, 16)

  repo.remove_image(key)
  match repo.get_image(key) {
    Some(_) => panic()
    None => ()
  }
}

///|
test "simple image repository reuses handle for duplicate keys" {
  let repo = new_simple_image_repository()
  let key : AssetKey = { value: "player" }
  let first = repo.create_image(key, default_image_spec(32, 16))
  let second = repo.create_image(key, default_image_spec(64, 64))

  assert_eq(first.id, second.id)
  expect_some_image(repo.get_image(key), first.id, 32, 16)
}

///|
test "image spec with palette is retained in simple image repository" {
  let repo = new_simple_image_repository()
  let key : AssetKey = { value: "ui/button" }
  let palette = @image_palette.new_solid_palette(
    @image_palette.new_rgba(12, 34, 56, 255),
  )
  let spec = image_spec_with_palette(8, 8, palette)
  let handle = repo.create_image(key, spec)

  let stored = match get_image_palette_by_id(repo, handle.id) {
    Some(value) => value
    None => panic()
  }
  for pixel_index in 0..<4 {
    assert_eq(@image_palette.palette_channel(stored, pixel_index, 0), 12)
    assert_eq(@image_palette.palette_channel(stored, pixel_index, 1), 34)
    assert_eq(@image_palette.palette_channel(stored, pixel_index, 2), 56)
    assert_eq(@image_palette.palette_channel(stored, pixel_index, 3), 255)
  }
}

///|
test "list_image_palette_bindings exports all current images" {
  let repo = new_simple_image_repository()
  let key_a : AssetKey = { value: "a" }
  let key_b : AssetKey = { value: "b" }
  let handle_a = repo.create_image(
    key_a,
    image_spec_with_palette(
      4,
      4,
      @image_palette.new_solid_palette(@image_palette.new_rgba(1, 2, 3, 4)),
    ),
  )
  let handle_b = repo.create_image(
    key_b,
    image_spec_with_palette(
      4,
      4,
      @image_palette.new_solid_palette(@image_palette.new_rgba(9, 8, 7, 6)),
    ),
  )

  let bindings = list_image_palette_bindings(repo)
  assert_eq(bindings.length(), 2)

  let mut found_a = false
  let mut found_b = false
  for binding in bindings {
    if binding.image_id == handle_a.id {
      found_a = true
      assert_eq(@image_palette.palette_channel(binding.palette, 0, 0), 1)
      assert_eq(@image_palette.palette_channel(binding.palette, 0, 1), 2)
      assert_eq(@image_palette.palette_channel(binding.palette, 0, 2), 3)
      assert_eq(@image_palette.palette_channel(binding.palette, 0, 3), 4)
    }
    if binding.image_id == handle_b.id {
      found_b = true
      assert_eq(@image_palette.palette_channel(binding.palette, 0, 0), 9)
      assert_eq(@image_palette.palette_channel(binding.palette, 0, 1), 8)
      assert_eq(@image_palette.palette_channel(binding.palette, 0, 2), 7)
      assert_eq(@image_palette.palette_channel(binding.palette, 0, 3), 6)
    }
  }
  assert_true(found_a)
  assert_true(found_b)
}

///|
test "image_spec_with_rgba8 keeps channels and derives corner palette" {
  let spec = image_spec_with_rgba8(2, 2, [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
  ])
  assert_eq(spec.pixels_rgba8.length(), 16)
  assert_eq(@image_palette.palette_channel(spec.palette, 0, 0), 1)
  assert_eq(@image_palette.palette_channel(spec.palette, 0, 1), 2)
  assert_eq(@image_palette.palette_channel(spec.palette, 0, 2), 3)
  assert_eq(@image_palette.palette_channel(spec.palette, 0, 3), 4)
  assert_eq(@image_palette.palette_channel(spec.palette, 3, 0), 13)
  assert_eq(@image_palette.palette_channel(spec.palette, 3, 1), 14)
  assert_eq(@image_palette.palette_channel(spec.palette, 3, 2), 15)
  assert_eq(@image_palette.palette_channel(spec.palette, 3, 3), 16)
}

///|
test "list_source_image_bindings exports rgba8 payload when available" {
  let repo = new_simple_image_repository()
  let key : AssetKey = { value: "tilemap" }
  let handle = repo.create_image(
    key,
    image_spec_with_rgba8(2, 2, [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    ]),
  )

  let bindings = list_source_image_bindings(repo)
  assert_eq(bindings.length(), 1)
  let binding = bindings[0]
  assert_eq(binding.image_id, handle.id)
  assert_eq(binding.width, 2)
  assert_eq(binding.height, 2)
  assert_eq(binding.generation, 1)
  assert_eq(binding.pixels_rgba8.length(), 16)
  assert_eq(binding.pixels_rgba8[0], 1)
  assert_eq(binding.pixels_rgba8[15], 16)

  let pixels = match get_image_pixels_by_id(repo, handle.id) {
    Some(value) => value
    None => panic()
  }
  assert_eq(pixels.length(), 16)
  assert_eq(pixels[0], 1)
  assert_eq(pixels[15], 16)
}

///|
test "update_image_spec increments generation while keeping handle id" {
  let repo = new_simple_image_repository()
  let key = new_asset_key("tilemap/update")
  let handle = repo.create_image(
    key,
    image_spec_with_rgba8(2, 2, [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    ]),
  )
  assert_eq(get_image_generation_by_id(repo, handle.id), 1)

  let updated = update_image_spec(
    repo,
    key,
    image_spec_with_rgba8(2, 2, [
      16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
    ]),
  )
  match updated {
    Some(handle2) => {
      assert_eq(handle2.id, handle.id)
      assert_eq(handle2.width, 2)
      assert_eq(handle2.height, 2)
    }
    None => panic()
  }

  let bindings = list_source_image_bindings(repo)
  assert_eq(bindings.length(), 1)
  assert_eq(bindings[0].generation, 2)
  assert_eq(bindings[0].pixels_rgba8[0], 16)
  assert_eq(bindings[0].pixels_rgba8[15], 1)
  assert_eq(get_image_generation_by_id(repo, handle.id), 2)
}

///|
test "update_image_spec rejects size mismatch and keeps generation" {
  let repo = new_simple_image_repository()
  let key = new_asset_key("tilemap/size_guard")
  let handle = repo.create_image(
    key,
    image_spec_with_rgba8(2, 2, [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    ]),
  )
  let updated = update_image_spec(
    repo,
    key,
    image_spec_with_rgba8(1, 1, [9, 8, 7, 6]),
  )
  match updated {
    Some(_) => panic()
    None => ()
  }
  assert_eq(get_image_generation_by_id(repo, handle.id), 1)
}

///|
test "new image starts dirty and clear_source_image_dirty_flags resets it" {
  let repo = new_simple_image_repository()
  let key = new_asset_key("dirty/new")
  let handle = repo.create_image(
    key,
    image_spec_with_rgba8(2, 2, [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    ]),
  )

  let dirty_bindings = list_dirty_source_image_bindings(repo)
  assert_eq(dirty_bindings.length(), 1)
  assert_eq(dirty_bindings[0].image_id, handle.id)
  match dirty_bindings[0].dirty_rect {
    Some(rect) => {
      assert_eq(rect.x, 0)
      assert_eq(rect.y, 0)
      assert_eq(rect.width, 2)
      assert_eq(rect.height, 2)
    }
    None => panic()
  }

  let cleared = clear_source_image_dirty_flags(repo)
  assert_eq(cleared, 1)
  assert_eq(list_dirty_source_image_bindings(repo).length(), 0)
}

///|
test "update_image_spec calculates minimal dirty rect from rgba8 diff" {
  let repo = new_simple_image_repository()
  let key = new_asset_key("dirty/update_rect")
  let _ = repo.create_image(
    key,
    image_spec_with_rgba8(3, 2, [
      1, 1, 1, 255, 2, 2, 2, 255, 3, 3, 3, 255, 4, 4, 4, 255, 5, 5, 5, 255, 6, 6,
      6, 255,
    ]),
  )
  let _ = clear_source_image_dirty_flags(repo)

  let _ = update_image_spec(
    repo,
    key,
    image_spec_with_rgba8(3, 2, [
      1, 1, 1, 255, 2, 2, 2, 255, 9, 9, 9, 255, 4, 4, 4, 255, 8, 8, 8, 255, 6, 6,
      6, 255,
    ]),
  )

  let dirty_bindings = list_dirty_source_image_bindings(repo)
  assert_eq(dirty_bindings.length(), 1)
  match dirty_bindings[0].dirty_rect {
    Some(rect) => {
      assert_eq(rect.x, 1)
      assert_eq(rect.y, 0)
      assert_eq(rect.width, 2)
      assert_eq(rect.height, 2)
    }
    None => panic()
  }
}

///|
test "update_image_spec with same pixels does not advance generation" {
  let repo = new_simple_image_repository()
  let key = new_asset_key("dirty/noop")
  let handle = repo.create_image(
    key,
    image_spec_with_rgba8(2, 1, [1, 2, 3, 4, 5, 6, 7, 8]),
  )
  let _ = clear_source_image_dirty_flags(repo)
  assert_eq(get_image_generation_by_id(repo, handle.id), 1)

  let updated = update_image_spec(
    repo,
    key,
    image_spec_with_rgba8(2, 1, [1, 2, 3, 4, 5, 6, 7, 8]),
  )
  match updated {
    Some(h) => assert_eq(h.id, handle.id)
    None => panic()
  }

  assert_eq(get_image_generation_by_id(repo, handle.id), 1)
  assert_eq(list_dirty_source_image_bindings(repo).length(), 0)
}

///|
test "simple atlas allocator places regions with row wrap" {
  let allocator = new_simple_atlas_allocator(8, 8, 1)

  let first = match allocator.allocate(4, 4) {
    Some(region) => region
    None => panic()
  }
  assert_eq(first.x, 0)
  assert_eq(first.y, 0)

  let second = match allocator.allocate(4, 4) {
    Some(region) => region
    None => panic()
  }
  assert_eq(second.x, 4)
  assert_eq(second.y, 0)

  let third = match allocator.allocate(4, 4) {
    Some(region) => region
    None => panic()
  }
  assert_eq(third.x, 0)
  assert_eq(third.y, 4)
}

///|
test "simple atlas allocator returns none when out of capacity" {
  let allocator = new_simple_atlas_allocator(8, 8, 1)

  match allocator.allocate(9, 1) {
    Some(_) => panic()
    None => ()
  }

  let whole = match allocator.allocate(8, 8) {
    Some(region) => region
    None => panic()
  }

  match allocator.allocate(1, 1) {
    Some(_) => panic()
    None => ()
  }

  allocator.release(whole)
  assert_eq(allocator.allocated.length(), 0)
}

///|
test "simple atlas image repository creates image and marks full page dirty" {
  let repo = new_simple_atlas_image_repository(8, 8, 100)
  let key = new_asset_key("atlas/player")
  let handle = match
    create_atlas_image(
      repo,
      key,
      image_spec_with_rgba8(2, 2, [
        1, 2, 3, 255, 4, 5, 6, 255, 7, 8, 9, 255, 10, 11, 12, 255,
      ]),
    ) {
    Some(value) => value
    None => panic()
  }
  assert_eq(handle.id, 1)
  let region = match get_atlas_image_region(repo, key) {
    Some(value) => value
    None => panic()
  }
  assert_eq(region.x, 0)
  assert_eq(region.y, 0)
  assert_eq(region.width, 2)
  assert_eq(region.height, 2)
  assert_eq(region.atlas_id, 100)

  let dirty_pages = list_dirty_atlas_page_bindings(repo)
  assert_eq(dirty_pages.length(), 1)
  assert_eq(dirty_pages[0].image_id, 100)
  assert_eq(dirty_pages[0].generation, 1)
  match dirty_pages[0].dirty_rect {
    Some(rect) => {
      assert_eq(rect.x, 0)
      assert_eq(rect.y, 0)
      assert_eq(rect.width, 2)
      assert_eq(rect.height, 2)
    }
    None => panic()
  }
}

///|
test "simple atlas image repository update computes atlas-space dirty rect" {
  let repo = new_simple_atlas_image_repository(8, 8, 200)
  let key = new_asset_key("atlas/tile")
  let _ = create_atlas_image(
    repo,
    key,
    image_spec_with_rgba8(2, 2, [
      1, 1, 1, 255, 2, 2, 2, 255, 3, 3, 3, 255, 4, 4, 4, 255,
    ]),
  )
  let _ = clear_dirty_atlas_page_flags(repo)

  let updated = update_atlas_image_spec(
    repo,
    key,
    image_spec_with_rgba8(2, 2, [
      1, 1, 1, 255, 99, 99, 99, 255, 3, 3, 3, 255, 4, 4, 4, 255,
    ]),
  )
  match updated {
    Some(_) => ()
    None => panic()
  }

  let dirty_pages = list_dirty_atlas_page_bindings(repo)
  assert_eq(dirty_pages.length(), 1)
  assert_eq(dirty_pages[0].generation, 2)
  match dirty_pages[0].dirty_rect {
    Some(rect) => {
      assert_eq(rect.x, 1)
      assert_eq(rect.y, 0)
      assert_eq(rect.width, 1)
      assert_eq(rect.height, 1)
    }
    None => panic()
  }
}

///|
test "simple atlas image repository clears page dirty flags" {
  let repo = new_simple_atlas_image_repository(8, 8, 300)
  let _ = create_atlas_image(
    repo,
    new_asset_key("atlas/a"),
    image_spec_with_rgba8(2, 2, [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    ]),
  )
  assert_eq(list_dirty_atlas_page_bindings(repo).length(), 1)
  assert_eq(clear_dirty_atlas_page_flags(repo), 1)
  assert_eq(list_dirty_atlas_page_bindings(repo).length(), 0)
}

///|
test "simple atlas image repository remove marks released area dirty" {
  let repo = new_simple_atlas_image_repository(8, 8, 400)
  let key = new_asset_key("atlas/remove")
  let _ = create_atlas_image(
    repo,
    key,
    image_spec_with_rgba8(2, 2, [
      10, 20, 30, 255, 11, 21, 31, 255, 12, 22, 32, 255, 13, 23, 33, 255,
    ]),
  )
  let _ = clear_dirty_atlas_page_flags(repo)
  remove_atlas_image(repo, key)
  let dirty_pages = list_dirty_atlas_page_bindings(repo)
  assert_eq(dirty_pages.length(), 1)
  match dirty_pages[0].dirty_rect {
    Some(rect) => {
      assert_eq(rect.x, 0)
      assert_eq(rect.y, 0)
      assert_eq(rect.width, 2)
      assert_eq(rect.height, 2)
    }
    None => panic()
  }
}

///|
test "simple atlas image repository dirty page binding includes composed rgba8" {
  let repo = new_simple_atlas_image_repository(4, 4, 500)
  let _ = create_atlas_image(
    repo,
    new_asset_key("atlas/rgba8"),
    image_spec_with_rgba8(2, 2, [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    ]),
  )
  let dirty_pages = list_dirty_atlas_page_bindings(repo)
  assert_eq(dirty_pages.length(), 1)
  assert_eq(dirty_pages[0].width, 4)
  assert_eq(dirty_pages[0].height, 4)
  assert_eq(dirty_pages[0].pixels_rgba8.length(), 4 * 4 * 4)
  assert_eq(dirty_pages[0].pixels_rgba8[0], 1)
  assert_eq(dirty_pages[0].pixels_rgba8[1], 2)
  assert_eq(dirty_pages[0].pixels_rgba8[2], 3)
  assert_eq(dirty_pages[0].pixels_rgba8[3], 4)
  let far = (3 * 4 + 3) * 4
  assert_eq(dirty_pages[0].pixels_rgba8[far], 0)
  assert_eq(dirty_pages[0].pixels_rgba8[far + 1], 0)
  assert_eq(dirty_pages[0].pixels_rgba8[far + 2], 0)
  assert_eq(dirty_pages[0].pixels_rgba8[far + 3], 0)
}

///|
test "atlas draw source resolves page image id and uv from key" {
  let repo = new_simple_atlas_image_repository(8, 8, 777)
  let key_a = new_asset_key("atlas/draw/a")
  let key_b = new_asset_key("atlas/draw/b")
  let _ = create_atlas_image(repo, key_a, default_image_spec(2, 2))
  let _ = create_atlas_image(repo, key_b, default_image_spec(2, 2))

  let binding_a = match get_atlas_draw_source(repo, key_a) {
    Some(value) => value
    None => panic()
  }
  assert_eq(binding_a.page_image_id, 777)
  assert_eq(binding_a.region.x, 0)
  assert_eq(binding_a.region.y, 0)
  assert_eq(binding_a.region.width, 2)
  assert_eq(binding_a.region.height, 2)
  assert_eq(binding_a.u0, 0.0)
  assert_eq(binding_a.v0, 0.0)
  assert_eq(binding_a.u1, 0.25)
  assert_eq(binding_a.v1, 0.25)

  let binding_b = match get_atlas_draw_source(repo, key_b) {
    Some(value) => value
    None => panic()
  }
  assert_eq(binding_b.page_image_id, 777)
  assert_eq(binding_b.region.x, 2)
  assert_eq(binding_b.region.y, 0)
  assert_eq(binding_b.u0, 0.25)
  assert_eq(binding_b.v0, 0.0)
  assert_eq(binding_b.u1, 0.5)
  assert_eq(binding_b.v1, 0.25)
}

///|
test "atlas draw source returns none for missing key" {
  let repo = new_simple_atlas_image_repository(8, 8, 123)
  match get_atlas_draw_source(repo, new_asset_key("atlas/missing")) {
    Some(_) => panic()
    None => ()
  }
}

///|
test "new_unmanaged_atlas_draw_source uses full uv and clamps id" {
  let source = new_unmanaged_atlas_draw_source(-5)
  assert_eq(source.page_image_id, 0)
  assert_eq(source.region.atlas_id, 0)
  assert_eq(source.u0, 0.0)
  assert_eq(source.v0, 0.0)
  assert_eq(source.u1, 1.0)
  assert_eq(source.v1, 1.0)
}

///|
test "simple shader repository can create get and remove shaders" {
  let repo = new_simple_shader_repository()
  let key : AssetKey = { value: "lighting" }
  let spec : ShaderSpec = {
    debug_name: "lighting",
    source: "@fragment fn fs_main() -> vec4f { return vec4f(1.0); }",
  }
  let handle = repo.create_shader(key, spec)
  assert_eq(handle.id, 1)
  assert_eq(handle.source, spec.source)
  expect_some_shader(repo.get_shader(key), 1, spec.source)

  repo.remove_shader(key)
  match repo.get_shader(key) {
    Some(_) => panic()
    None => ()
  }
}

///|
test "simple shader repository reuses handle for duplicate keys" {
  let repo = new_simple_shader_repository()
  let key : AssetKey = { value: "lighting" }
  let first = repo.create_shader(key, {
    debug_name: "lighting_a",
    source: "shader_a",
  })
  let second = repo.create_shader(key, {
    debug_name: "lighting_b",
    source: "shader_b",
  })
  assert_eq(first.id, second.id)
  expect_some_shader(repo.get_shader(key), first.id, "shader_a")
}

///|
test "simple material repository registers and overwrites material specs" {
  let repo = new_simple_material_repository()
  let key : AssetKey = { value: "sprite" }
  let shader_key : AssetKey = { value: "shader/sprite" }
  repo.register_material(key, {
    shader: shader_key,
    blend: @gfx.blend_mode_from_int(1),
    filter: @gfx.filter_mode_from_int(0),
    uniform_keys: ["u_color"],
  })
  match repo.get_material(key) {
    Some(spec) => {
      assert_eq(spec.shader.value, "shader/sprite")
      assert_eq(spec.uniform_keys.length(), 1)
      assert_eq(spec.uniform_keys[0], "u_color")
      assert_eq(@gfx.blend_mode_to_int(spec.blend), 1)
    }
    None => panic()
  }

  repo.register_material(key, {
    shader: shader_key,
    blend: @gfx.blend_mode_from_int(2),
    filter: @gfx.filter_mode_from_int(1),
    uniform_keys: ["u_color", "u_alpha"],
  })
  match repo.get_material(key) {
    Some(spec2) => {
      assert_eq(@gfx.blend_mode_to_int(spec2.blend), 2)
      assert_eq(spec2.uniform_keys.length(), 2)
      assert_eq(spec2.uniform_keys[1], "u_alpha")
    }
    None => panic()
  }
}

///|
test "multi page atlas creates first page on demand" {
  let repo = new_multi_page_atlas_repository(64, 64)
  assert_eq(multi_page_count(repo), 0)
  let key = new_asset_key("img1")
  let spec = default_image_spec(8, 8)
  let handle = multi_page_create_image(repo, key, spec)
  assert_true(handle is Some(_))
  assert_eq(multi_page_count(repo), 1)
  assert_eq(multi_page_image_count(repo), 1)
}

///|
test "multi page atlas overflow creates new page" {
  // 16x16 atlas with 8x8 images: fits 4 per page (2x2 rows)
  let repo = new_multi_page_atlas_repository(16, 16)
  let specs : Array[(String, ImageSpec)] = []
  for i in 0..<5 {
    specs.push(("img\{i}", default_image_spec(8, 8)))
  }
  for entry in specs {
    let _ = multi_page_create_image(repo, new_asset_key(entry.0), entry.1)
  }
  // 4 images fit on page 1, 5th should overflow to page 2
  assert_eq(multi_page_count(repo), 2)
  assert_eq(multi_page_image_count(repo), 5)
}

///|
test "multi page atlas deduplicates keys" {
  let repo = new_multi_page_atlas_repository(64, 64)
  let key = new_asset_key("dup")
  let spec = default_image_spec(4, 4)
  let h1 = multi_page_create_image(repo, key, spec)
  let h2 = multi_page_create_image(repo, key, spec)
  assert_true(h1 is Some(_))
  assert_true(h2 is Some(_))
  assert_eq(multi_page_image_count(repo), 1)
}

///|
test "multi page atlas get_draw_source resolves across pages" {
  let repo = new_multi_page_atlas_repository(8, 8)
  // First image fills page 1
  let key1 = new_asset_key("a")
  let _ = multi_page_create_image(repo, key1, default_image_spec(8, 8))
  // Second image must go to page 2
  let key2 = new_asset_key("b")
  let _ = multi_page_create_image(repo, key2, default_image_spec(8, 8))
  assert_eq(multi_page_count(repo), 2)
  let src1 = multi_page_get_draw_source(repo, key1)
  let src2 = multi_page_get_draw_source(repo, key2)
  assert_true(src1 is Some(_))
  assert_true(src2 is Some(_))
  // Different pages should have different page_image_ids
  match (src1, src2) {
    (Some(s1), Some(s2)) => assert_true(s1.page_image_id != s2.page_image_id)
    _ => panic()
  }
}

///|
test "multi page atlas get_region returns correct region" {
  let repo = new_multi_page_atlas_repository(64, 64)
  let key = new_asset_key("r1")
  let _ = multi_page_create_image(repo, key, default_image_spec(10, 12))
  match multi_page_get_region(repo, key) {
    Some(region) => {
      assert_eq(region.width, 10)
      assert_eq(region.height, 12)
    }
    None => panic()
  }
}

///|
test "multi page atlas missing key returns None" {
  let repo = new_multi_page_atlas_repository(64, 64)
  let missing = new_asset_key("missing")
  assert_true(multi_page_get_draw_source(repo, missing) is None)
  assert_true(multi_page_get_region(repo, missing) is None)
  assert_true(multi_page_update_image_spec(repo, missing, default_image_spec(1, 1)) is None)
}

///|
test "multi page atlas update forwards to correct page" {
  let repo = new_multi_page_atlas_repository(64, 64)
  let key = new_asset_key("upd")
  let pixels = [255, 0, 0, 255]
  let spec = image_spec_with_rgba8(1, 1, pixels)
  let _ = multi_page_create_image(repo, key, spec)
  let new_pixels = [0, 255, 0, 255]
  let new_spec = image_spec_with_rgba8(1, 1, new_pixels)
  let updated = multi_page_update_image_spec(repo, key, new_spec)
  assert_true(updated is Some(_))
}

///|
test "multi page atlas remove and dirty tracking" {
  let repo = new_multi_page_atlas_repository(64, 64)
  let key = new_asset_key("rm")
  let _ = multi_page_create_image(repo, key, default_image_spec(4, 4))
  // Clear initial dirty flags
  let _ = multi_page_clear_dirty_flags(repo)
  // Remove triggers dirty
  multi_page_remove_image(repo, key)
  assert_eq(multi_page_image_count(repo), 0)
  let dirty = multi_page_list_dirty_bindings(repo)
  assert_true(dirty.length() > 0)
}

///|
test "multi page atlas dirty bindings across pages" {
  let repo = new_multi_page_atlas_repository(8, 8)
  let _ = multi_page_create_image(repo, new_asset_key("p1"), default_image_spec(8, 8))
  let _ = multi_page_create_image(repo, new_asset_key("p2"), default_image_spec(8, 8))
  let dirty = multi_page_list_dirty_bindings(repo)
  // Both pages should be dirty
  assert_eq(dirty.length(), 2)
  let cleared = multi_page_clear_dirty_flags(repo)
  assert_eq(cleared, 2)
  // After clear, no dirty
  assert_eq(multi_page_list_dirty_bindings(repo).length(), 0)
}

///|
test "multi page atlas get_page_ids" {
  let repo = new_multi_page_atlas_repository(8, 8)
  let _ = multi_page_create_image(repo, new_asset_key("x"), default_image_spec(8, 8))
  let _ = multi_page_create_image(repo, new_asset_key("y"), default_image_spec(8, 8))
  let ids = multi_page_get_page_ids(repo)
  assert_eq(ids.length(), 2)
  assert_true(ids[0] != ids[1])
}

///|
test "multi page atlas image too large returns None" {
  let repo = new_multi_page_atlas_repository(8, 8)
  // Image larger than page
  let result = multi_page_create_image(
    repo, new_asset_key("big"), default_image_spec(16, 16),
  )
  assert_true(result is None)
}

///|
test "allocator reset after all releases resets cursor" {
  let allocator = new_simple_atlas_allocator(8, 8, 1)
  let r1 = match allocator.allocate(4, 4) {
    Some(r) => r
    None => panic()
  }
  let r2 = match allocator.allocate(4, 4) {
    Some(r) => r
    None => panic()
  }
  assert_eq(atlas_allocator_is_empty(allocator), false)
  allocator.release(r1)
  allocator.release(r2)
  assert_eq(atlas_allocator_is_empty(allocator), true)
  assert_eq(atlas_allocator_reset_if_empty(allocator), true)
  // Cursor should be (0,0) now, can re-allocate from start
  let r3 = match allocator.allocate(4, 4) {
    Some(r) => r
    None => panic()
  }
  assert_eq(r3.x, 0)
  assert_eq(r3.y, 0)
}

///|
test "allocator reset no-op when images remain" {
  let allocator = new_simple_atlas_allocator(8, 8, 1)
  let r1 = match allocator.allocate(4, 4) {
    Some(r) => r
    None => panic()
  }
  let _ = match allocator.allocate(4, 4) {
    Some(r) => r
    None => panic()
  }
  allocator.release(r1)
  assert_eq(atlas_allocator_reset_if_empty(allocator), false)
  // Cursor should NOT have been reset
  assert_eq(allocator.allocated.length(), 1)
}

///|
test "remove_atlas_image resets allocator on empty page" {
  let repo = new_simple_atlas_image_repository(8, 8, 900)
  let key_a = new_asset_key("atlas/reset/a")
  let key_b = new_asset_key("atlas/reset/b")
  let _ = create_atlas_image(repo, key_a, default_image_spec(2, 2))
  let _ = create_atlas_image(repo, key_b, default_image_spec(2, 2))
  let _ = clear_dirty_atlas_page_flags(repo)
  remove_atlas_image(repo, key_a)
  remove_atlas_image(repo, key_b)
  // After removing all images, allocator should be reset
  // so re-allocation starts at (0,0)
  let handle = match create_atlas_image(
    repo, new_asset_key("atlas/reset/c"), default_image_spec(2, 2),
  ) {
    Some(h) => h
    None => panic()
  }
  let _ = handle
  let region = match get_atlas_image_region(repo, new_asset_key("atlas/reset/c")) {
    Some(r) => r
    None => panic()
  }
  assert_eq(region.x, 0)
  assert_eq(region.y, 0)
}

///|
test "multi_page_compact removes empty pages" {
  let repo = new_multi_page_atlas_repository(8, 8)
  // Create 3 pages: each with one 8x8 image
  let _ = multi_page_create_image(repo, new_asset_key("p0"), default_image_spec(8, 8))
  let _ = multi_page_create_image(repo, new_asset_key("p1"), default_image_spec(8, 8))
  let _ = multi_page_create_image(repo, new_asset_key("p2"), default_image_spec(8, 8))
  assert_eq(multi_page_count(repo), 3)
  // Remove middle page's image
  multi_page_remove_image(repo, new_asset_key("p1"))
  let result = multi_page_compact(repo)
  assert_eq(result.removed_page_count, 1)
  assert_eq(result.remaining_page_count, 2)
  assert_eq(multi_page_count(repo), 2)
}

///|
test "multi_page_compact remaps key indices" {
  let repo = new_multi_page_atlas_repository(8, 8)
  let _ = multi_page_create_image(repo, new_asset_key("c0"), default_image_spec(8, 8))
  let _ = multi_page_create_image(repo, new_asset_key("c1"), default_image_spec(8, 8))
  let _ = multi_page_create_image(repo, new_asset_key("c2"), default_image_spec(8, 8))
  assert_eq(multi_page_count(repo), 3)
  // Remove pages 0 and 2, keep page 1
  multi_page_remove_image(repo, new_asset_key("c0"))
  multi_page_remove_image(repo, new_asset_key("c2"))
  let result = multi_page_compact(repo)
  assert_eq(result.removed_page_count, 2)
  assert_eq(result.remaining_page_count, 1)
  // draw source for remaining key should still resolve
  let src = multi_page_get_draw_source(repo, new_asset_key("c1"))
  assert_true(src is Some(_))
}

///|
test "multi_page_compact no-op with no empty pages" {
  let repo = new_multi_page_atlas_repository(8, 8)
  let _ = multi_page_create_image(repo, new_asset_key("n0"), default_image_spec(8, 8))
  let _ = multi_page_create_image(repo, new_asset_key("n1"), default_image_spec(8, 8))
  let result = multi_page_compact(repo)
  assert_eq(result.removed_page_count, 0)
  assert_eq(result.remaining_page_count, 2)
}

///|
test "atlas_page_stats returns correct info" {
  let repo = new_simple_atlas_image_repository(16, 16, 600)
  let _ = create_atlas_image(repo, new_asset_key("stats/a"), default_image_spec(4, 4))
  let stats = atlas_page_stats(repo)
  assert_eq(stats.atlas_id, 600)
  assert_eq(stats.image_count, 1)
  assert_eq(stats.allocated_region_count, 1)
  assert_eq(stats.atlas_width, 16)
  assert_eq(stats.atlas_height, 16)
  assert_eq(stats.is_empty, false)
}

///|
test "multi_page_stats per-page statistics" {
  let repo = new_multi_page_atlas_repository(8, 8)
  let _ = multi_page_create_image(repo, new_asset_key("ms0"), default_image_spec(4, 4))
  let _ = multi_page_create_image(repo, new_asset_key("ms1"), default_image_spec(4, 4))
  // Both fit on one page (4x4 images in 8x8 atlas)
  // Force second page
  let _ = multi_page_create_image(repo, new_asset_key("ms2"), default_image_spec(8, 8))
  let stats = multi_page_stats(repo)
  assert_eq(stats.length(), 2)
  assert_eq(stats[0].image_count, 2)
  assert_eq(stats[1].image_count, 1)
}
