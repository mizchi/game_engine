///|
priv struct SyncedSourceGeneration {
  image_id : Int
  generation : Int
}

///|
priv struct SourceImageCacheEntry {
  image_id : Int
  width : Int
  height : Int
  pixels_rgba8 : Array[Int]
}

///|
let synced_source_generations : Ref[Array[SyncedSourceGeneration]] = Ref::new([])

///|
let source_image_cache : Ref[Array[SourceImageCacheEntry]] = Ref::new([])

///|
fn normalized_size(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
fn normalized_source_generation(generation : Int) -> Int {
  if generation <= 0 {
    1
  } else {
    generation
  }
}

///|
fn synced_source_generation_at(image_id : Int) -> Int {
  let mut generation = 0
  for entry in synced_source_generations.val {
    if entry.image_id == image_id {
      generation = entry.generation
    }
  }
  generation
}

///|
fn set_synced_source_generation(image_id : Int, generation : Int) -> Unit {
  let next : Array[SyncedSourceGeneration] = []
  let mut replaced = false
  let safe_generation = normalized_source_generation(generation)
  for entry in synced_source_generations.val {
    if entry.image_id == image_id {
      next.push({ image_id, generation: safe_generation })
      replaced = true
    } else {
      next.push(entry)
    }
  }
  if !replaced {
    next.push({ image_id, generation: safe_generation })
  }
  synced_source_generations.val = next
}

///|
fn clear_synced_source_generations() -> Unit {
  synced_source_generations.val = []
}

///|
fn drop_synced_source_generation(image_id : Int) -> Unit {
  let next : Array[SyncedSourceGeneration] = []
  for entry in synced_source_generations.val {
    if entry.image_id != image_id {
      next.push(entry)
    }
  }
  synced_source_generations.val = next
}

///|
fn expected_rgba8_channel_count(width : Int, height : Int) -> Int {
  normalized_size(width) * normalized_size(height) * 4
}

///|
fn has_valid_rgba8_payload(
  rgba8_channels : Array[Int],
  width : Int,
  height : Int,
) -> Bool {
  let expected = expected_rgba8_channel_count(width, height)
  expected > 0 && rgba8_channels.length() >= expected
}

///|
fn clamp_u8_channel(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn normalized_rgba8_channels(
  rgba8_channels : Array[Int],
  width : Int,
  height : Int,
) -> Array[Int] {
  let expected = expected_rgba8_channel_count(width, height)
  let out : Array[Int] = []
  if expected <= 0 || rgba8_channels.length() < expected {
    out
  } else {
    for i in 0..<expected {
      out.push(clamp_u8_channel(rgba8_channels[i]))
    }
    out
  }
}

///|
fn source_image_cache_entry_at(image_id : Int) -> SourceImageCacheEntry? {
  let mut out : SourceImageCacheEntry? = None
  for entry in source_image_cache.val {
    if entry.image_id == image_id {
      out = Some(entry)
    }
  }
  out
}

///|
fn set_source_image_cache_entry(next_entry : SourceImageCacheEntry) -> Unit {
  let next : Array[SourceImageCacheEntry] = []
  let mut replaced = false
  for entry in source_image_cache.val {
    if entry.image_id == next_entry.image_id {
      next.push(next_entry)
      replaced = true
    } else {
      next.push(entry)
    }
  }
  if !replaced {
    next.push(next_entry)
  }
  source_image_cache.val = next
}

///|
fn clear_source_image_cache() -> Unit {
  source_image_cache.val = []
}

///|
pub fn install(_canvas_selector : String) -> Unit {
  ()
}

///|
pub fn uninstall() -> Unit {
  ()
}

///|
pub fn is_ready() -> Bool {
  false
}

///|
pub fn shutdown() -> Unit {
  ()
}

///|
pub fn register_source_image_palette(
  source_image_id : Int,
  _palette : @image_palette.ImagePalette2x2,
) -> Unit {
  if source_image_id < 0 {
    return
  }
  let mut width = 1
  let mut height = 1
  let mut pixels_rgba8 : Array[Int] = []
  match source_image_cache_entry_at(source_image_id) {
    Some(entry) => {
      width = entry.width
      height = entry.height
      pixels_rgba8 = entry.pixels_rgba8
    }
    None => ()
  }
  set_source_image_cache_entry({
    image_id: source_image_id,
    width,
    height,
    pixels_rgba8,
  })
  drop_synced_source_generation(source_image_id)
}

///|
pub fn register_source_image_solid_color(
  source_image_id : Int,
  color : @image_palette.Rgba,
) -> Unit {
  register_source_image_palette(
    source_image_id,
    @image_palette.new_solid_palette(color),
  )
}

///|
pub fn register_source_image_rgba8(
  source_image_id : Int,
  width : Int,
  height : Int,
  rgba8_channels : Array[Int],
) -> Unit {
  if source_image_id < 0 {
    return
  }
  let safe_width = normalized_size(width)
  let safe_height = normalized_size(height)
  let pixels_rgba8 = normalized_rgba8_channels(
    rgba8_channels, safe_width, safe_height,
  )
  if pixels_rgba8.length() == 0 {
    return
  }
  set_source_image_cache_entry({
    image_id: source_image_id,
    width: safe_width,
    height: safe_height,
    pixels_rgba8,
  })
  drop_synced_source_generation(source_image_id)
}

///|
pub fn patch_source_image_rgba8(
  source_image_id : Int,
  width : Int,
  height : Int,
  dirty_x : Int,
  dirty_y : Int,
  dirty_width : Int,
  dirty_height : Int,
  rgba8_channels : Array[Int],
) -> Bool {
  if source_image_id < 0 {
    return false
  }
  let safe_width = normalized_size(width)
  let safe_height = normalized_size(height)
  if !has_valid_rgba8_payload(rgba8_channels, safe_width, safe_height) {
    return false
  }
  match source_image_cache_entry_at(source_image_id) {
    Some(entry) =>
      if entry.width != safe_width ||
        entry.height != safe_height ||
        !has_valid_rgba8_payload(entry.pixels_rgba8, safe_width, safe_height) {
        false
      } else {
        let x0 = if dirty_x < 0 {
          0
        } else if dirty_x > safe_width {
          safe_width
        } else {
          dirty_x
        }
        let y0 = if dirty_y < 0 {
          0
        } else if dirty_y > safe_height {
          safe_height
        } else {
          dirty_y
        }
        let x1_raw = dirty_x + dirty_width
        let y1_raw = dirty_y + dirty_height
        let x1 = if x1_raw < 0 {
          0
        } else if x1_raw > safe_width {
          safe_width
        } else {
          x1_raw
        }
        let y1 = if y1_raw < 0 {
          0
        } else if y1_raw > safe_height {
          safe_height
        } else {
          y1_raw
        }
        if x1 <= x0 || y1 <= y0 {
          false
        } else {
          let next_pixels = entry.pixels_rgba8
          for y in y0..<y1 {
            for x in x0..<x1 {
              let base = (y * safe_width + x) * 4
              next_pixels[base] = clamp_u8_channel(rgba8_channels[base])
              next_pixels[base + 1] = clamp_u8_channel(rgba8_channels[base + 1])
              next_pixels[base + 2] = clamp_u8_channel(rgba8_channels[base + 2])
              next_pixels[base + 3] = clamp_u8_channel(rgba8_channels[base + 3])
            }
          }
          set_source_image_cache_entry({
            image_id: source_image_id,
            width: safe_width,
            height: safe_height,
            pixels_rgba8: next_pixels,
          })
          drop_synced_source_generation(source_image_id)
          true
        }
      }
    None => false
  }
}

///|
pub fn clear_source_image_palettes() -> Unit {
  clear_source_image_cache()
  clear_synced_source_generations()
}

///|
pub fn sync_source_image_palettes(
  bindings : Array[@asset.ImagePaletteBinding],
) -> Int {
  let mut count = 0
  for binding in bindings {
    if binding.image_id >= 0 {
      register_source_image_palette(binding.image_id, binding.palette)
      count = count + 1
    }
  }
  count
}

///|
pub fn sync_source_image_palettes_from_repository(
  repository : @asset.SimpleImageRepository,
) -> Int {
  sync_source_image_palettes(@asset.list_image_palette_bindings(repository))
}

///|
pub fn sync_source_images(bindings : Array[@asset.SourceImageBinding]) -> Int {
  let mut count = 0
  for binding in bindings {
    if binding.image_id < 0 {
      continue
    }
    let generation = normalized_source_generation(binding.generation)
    if synced_source_generation_at(binding.image_id) == generation {
      continue
    }
    let required_channels = expected_rgba8_channel_count(
      binding.width,
      binding.height,
    )
    if required_channels > 0 &&
      binding.pixels_rgba8.length() >= required_channels {
      let mut patched = false
      match binding.dirty_rect {
        Some(rect) => {
          let full_rect = rect.x <= 0 &&
            rect.y <= 0 &&
            rect.width >= normalized_size(binding.width) &&
            rect.height >= normalized_size(binding.height)
          if !full_rect {
            patched = patch_source_image_rgba8(
              binding.image_id,
              binding.width,
              binding.height,
              rect.x,
              rect.y,
              rect.width,
              rect.height,
              binding.pixels_rgba8,
            )
          }
        }
        None => ()
      }
      if !patched {
        register_source_image_rgba8(
          binding.image_id,
          binding.width,
          binding.height,
          binding.pixels_rgba8,
        )
      }
    } else {
      register_source_image_palette(binding.image_id, binding.palette)
    }
    set_synced_source_generation(binding.image_id, generation)
    count = count + 1
  }
  count
}

///|
pub fn sync_source_images_from_repository(
  repository : @asset.SimpleImageRepository,
) -> Int {
  sync_source_images(@asset.list_source_image_bindings(repository))
}

///|
pub fn sync_dirty_source_images_from_repository(
  repository : @asset.SimpleImageRepository,
) -> Int {
  let count = sync_source_images(
    @asset.list_dirty_source_image_bindings(repository),
  )
  let _ = @asset.clear_source_image_dirty_flags(repository)
  count
}

///|
pub fn sync_dirty_atlas_pages_from_repository(
  repository : @asset.SimpleAtlasImageRepository,
) -> Int {
  let count = sync_source_images(
    @asset.list_dirty_atlas_page_bindings(repository),
  )
  let _ = @asset.clear_dirty_atlas_page_flags(repository)
  count
}

///|
pub fn source_image_cache_count() -> Int {
  source_image_cache.val.length()
}

///|
pub fn source_image_generation(image_id : Int) -> Int {
  synced_source_generation_at(image_id)
}

///|
pub fn source_image_width(image_id : Int) -> Int {
  match source_image_cache_entry_at(image_id) {
    Some(entry) => entry.width
    None => 0
  }
}

///|
pub fn source_image_height(image_id : Int) -> Int {
  match source_image_cache_entry_at(image_id) {
    Some(entry) => entry.height
    None => 0
  }
}

///|
pub fn source_image_pixel_channel(
  image_id : Int,
  x : Int,
  y : Int,
  channel_index : Int,
) -> Int {
  if channel_index < 0 || channel_index > 3 {
    return -1
  }
  match source_image_cache_entry_at(image_id) {
    Some(entry) =>
      if x < 0 || y < 0 || x >= entry.width || y >= entry.height {
        -1
      } else {
        let base = (y * entry.width + x) * 4
        let offset = base + channel_index
        if offset < 0 || offset >= entry.pixels_rgba8.length() {
          -1
        } else {
          entry.pixels_rgba8[offset]
        }
      }
    None => -1
  }
}
