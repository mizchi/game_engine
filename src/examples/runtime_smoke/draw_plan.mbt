///|
let runtime_smoke_atlas_page_id : Int = 801

///|
pub struct RuntimeSmokeTileDrawPlan {
  atlas_repository : @asset.SimpleAtlasImageRepository
  commands : Array[@gfx.DrawTrianglesCommand]
}

///|
pub fn build_runtime_smoke_tile_draw_plan(
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
) -> RuntimeSmokeTileDrawPlan {
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
  { atlas_repository, commands }
}
