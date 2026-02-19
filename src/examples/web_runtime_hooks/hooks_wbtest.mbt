///|
test "web runtime hooks install and uninstall" {
  uninstall()
  assert_true(!is_ready())

  install("#app")
  assert_true(is_ready())

  shutdown()
  assert_true(!is_ready())
}

///|
fn test_source_repository() -> @asset.SimpleImageRepository {
  let repo = @asset.new_simple_image_repository()
  let _ = repo.create_image(
    @asset.new_asset_key("web/sync"),
    @asset.image_spec_with_rgba8(2, 2, [
      10, 20, 30, 255, 40, 50, 60, 255, 70, 80, 90, 255, 100, 110, 120, 255,
    ]),
  ) catch {
    _ => panic()
  }
  repo
}

///|
test "sync_source_images_from_repository deduplicates by generation" {
  clear_source_image_palettes()
  let repo = test_source_repository()
  let key = @asset.new_asset_key("web/sync")

  let first = sync_source_images_from_repository(repo)
  let second = sync_source_images_from_repository(repo)
  assert_eq(first, 1)
  assert_eq(second, 0)

  let updated = @asset.update_image_spec(
    repo,
    key,
    @asset.image_spec_with_rgba8(2, 2, [
      11, 20, 30, 255, 40, 50, 60, 255, 70, 80, 90, 255, 100, 110, 120, 255,
    ]),
  )
  match updated {
    Some(_) => ()
    None => panic()
  }
  let third = sync_source_images_from_repository(repo)
  let fourth = sync_source_images_from_repository(repo)
  assert_eq(third, 1)
  assert_eq(fourth, 0)
}

///|
test "sync dirty source/atlas bindings only once per dirty generation" {
  clear_source_image_palettes()
  let source_repo = test_source_repository()
  let key = @asset.new_asset_key("web/sync")

  let source_first = sync_dirty_source_images_from_repository(source_repo)
  let source_second = sync_dirty_source_images_from_repository(source_repo)
  assert_eq(source_first, 1)
  assert_eq(source_second, 0)

  let updated = @asset.update_image_spec(
    source_repo,
    key,
    @asset.image_spec_with_rgba8(2, 2, [
      10, 20, 30, 255, 41, 51, 61, 255, 70, 80, 90, 255, 100, 110, 120, 255,
    ]),
  )
  match updated {
    Some(_) => ()
    None => panic()
  }
  let source_third = sync_dirty_source_images_from_repository(source_repo)
  let source_fourth = sync_dirty_source_images_from_repository(source_repo)
  assert_eq(source_third, 1)
  assert_eq(source_fourth, 0)

  let atlas_repo = @asset.new_simple_atlas_image_repository(4, 4, 901)
  let atlas_key = @asset.new_asset_key("web/atlas")
  let atlas_created = @asset.create_atlas_image(
    atlas_repo,
    atlas_key,
    @asset.image_spec_with_rgba8(2, 2, [
      1, 2, 3, 255, 4, 5, 6, 255, 7, 8, 9, 255, 10, 11, 12, 255,
    ]),
  )
  match atlas_created {
    Some(_) => ()
    None => panic()
  }
  let atlas_first = sync_dirty_atlas_pages_from_repository(atlas_repo)
  let atlas_second = sync_dirty_atlas_pages_from_repository(atlas_repo)
  assert_eq(atlas_first, 1)
  assert_eq(atlas_second, 0)

  let atlas_updated = @asset.update_atlas_image_spec(
    atlas_repo,
    atlas_key,
    @asset.image_spec_with_rgba8(2, 2, [
      1, 2, 3, 255, 44, 45, 46, 255, 7, 8, 9, 255, 10, 11, 12, 255,
    ]),
  )
  match atlas_updated {
    Some(_) => ()
    None => panic()
  }
  let atlas_third = sync_dirty_atlas_pages_from_repository(atlas_repo)
  let atlas_fourth = sync_dirty_atlas_pages_from_repository(atlas_repo)
  assert_eq(atlas_third, 1)
  assert_eq(atlas_fourth, 0)
}
