///|
let runtime_smoke_atlas_page_id : Int = 801

///|
let runtime_smoke_text_page_id : Int = 900

///|
pub struct RuntimeSmokeDrawPlan {
  atlas_repository : @asset.SimpleAtlasImageRepository
  text_atlas : @text.GlyphAtlas
  commands : Array[@gfx.DrawTrianglesCommand]
  sprite_command_index : Int
  text_command_index : Int
}

///|
pub fn build_runtime_smoke_tile_draw_plan(
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
) -> RuntimeSmokeDrawPlan {
  let atlas_repository = @asset.new_simple_atlas_image_repository(
    4, 4, runtime_smoke_atlas_page_id,
  )
  let atlas_key = @asset.new_asset_key("runtime_smoke/atlas")
  let atlas_png = @asset.encode_png_image_spec(
    @asset.image_spec_with_rgba8(2, 2, [
      1, 2, 3, 255, 4, 5, 6, 255, 7, 8, 9, 255, 10, 11, 12, 255,
    ]),
  ) catch {
    _ => panic()
  }
  let atlas_image = @asset.create_atlas_image_from_raster_bytes(
    atlas_repository,
    atlas_key,
    atlas_png,
  ) catch {
    _ => None
  }
  match atlas_image {
    Some(_) => ()
    None => panic()
  }
  let sprite_key = @asset.new_asset_key("runtime_smoke/sprite")
  let sprite_png = @asset.encode_png_image_spec(
    @asset.image_spec_with_rgba8(2, 2, [
      100, 150, 200, 255, 50, 75, 100, 255, 25, 37, 50, 255, 200, 225, 250,
      255,
    ]),
  ) catch {
    _ => panic()
  }
  let sprite_atlas_image = @asset.create_atlas_image_from_raster_bytes(
    atlas_repository,
    sprite_key,
    sprite_png,
  ) catch {
    _ => None
  }
  match sprite_atlas_image {
    Some(_) => ()
    None => panic()
  }
  let atlas_updated_png = @asset.encode_png_image_spec(
    @asset.image_spec_with_rgba8(2, 2, [
      1, 2, 3, 255, 42, 43, 44, 255, 7, 8, 9, 255, 10, 11, 12, 255,
    ]),
  ) catch {
    _ => panic()
  }
  let atlas_updated = @asset.update_atlas_image_from_raster_bytes(
    atlas_repository,
    atlas_key,
    atlas_updated_png,
  ) catch {
    _ => None
  }
  match atlas_updated {
    Some(_) => ()
    None => panic()
  }
  let atlas_dirty_synced = @asset.list_dirty_atlas_page_bindings(atlas_repository)
  if atlas_dirty_synced.length() != 1 {
    panic()
  }
  let tile_table = @tilemap2d.new_tile_atlas_table([
    @tilemap2d.new_tile_atlas_entry(1, atlas_key),
  ])
  let previous_tiles = [0]
  let next_tiles = [1]
  let visible_chunk = @tilemap2d.estimate_visible_tile_chunk(
    1, 1, -0.5, -0.5, 1.0, 1.0, -0.5, -0.5, 0.5, 0.5, 0,
  )
  let dirty_chunks = @tilemap2d.diff_visible_tile_index_chunks(
    previous_tiles, next_tiles, 1, 1, visible_chunk,
  )
  if dirty_chunks.length() != 1 {
    panic()
  }
  let commands : Array[@gfx.DrawTrianglesCommand] = []
  let appended = @tilemap2d.append_tile_indexed_dirty_chunk_batched_draw_commands(
    commands,
    dirty_chunks,
    tile_table,
    atlas_repository,
    dst,
    shader,
    7,
    11,
    @gfx.blend_mode_from_int(1),
    @gfx.new_dst_region(0, 0, 64, 64, 6),
    next_tiles,
    1,
    -0.5,
    -0.5,
    1.0,
    1.0,
    [1, 2, 3, 4],
  )
  if appended != 1 || commands.length() != 1 {
    panic()
  }
  let sprite_appended = @sprite2d.append_atlas_sprite_draw_command(
    commands,
    atlas_repository,
    sprite_key,
    dst,
    shader,
    @gfx.new_dst_region(0, 0, 64, 64, 6),
    0,
    7,
    12,
    @gfx.blend_mode_from_int(1),
    0.0,
    -0.5,
    0.5,
    0.5,
    [200, 100, 50, 255],
  )
  if !sprite_appended || commands.length() != 2 {
    panic()
  }
  // Text atlas: real font rasterization on a 64x64 atlas page
  let text_atlas_size = 64
  let text_atlas = @text.GlyphAtlas::new(
    text_atlas_size, text_atlas_size, runtime_smoke_text_page_id,
  )
  let font_data = Bytes::from_array(smoke_test_font_otf[:])
  let font = @text.parse_font_bytes(font_data)
  match font {
    Some(ttfont) => {
      let quads = text_atlas.rasterize_text(ttfont, "I", 24.0)
      if quads.length() < 1 {
        panic()
      }
      let quad = quads[0]
      let aw = text_atlas_size.to_double()
      let u0 = quad.atlas_x / aw
      let v0 = quad.atlas_y / aw
      let u1 = (quad.atlas_x + quad.atlas_w) / aw
      let v1 = (quad.atlas_y + quad.atlas_h) / aw
      let text_command = @gfx.new_draw_triangles_command(
        dst,
        shader,
        [@gfx.new_dst_region(0, 0, 64, 64, 6)],
        0,
        7,
        13,
        @gfx.blend_mode_from_int(1),
        [
          -0.8, -0.8, u0, v0, -0.3, -0.8, u1, v0, -0.3, -0.3, u1, v1,
          -0.8, -0.3, u0, v1,
        ],
        [0, 1, 2, 0, 2, 3],
        [runtime_smoke_text_page_id],
        [255, 255, 255, 255],
      )
      commands.push(text_command)
    }
    None => panic()
  }
  if commands.length() != 3 {
    panic()
  }
  {
    atlas_repository,
    text_atlas,
    commands,
    sprite_command_index: 1,
    text_command_index: 2,
  }
}
