///|
/// Glyph cache for mapping glyph IDs to atlas regions.

///|
pub struct GlyphCacheEntry {
  glyph_id : Int
  atlas_x : Double
  atlas_y : Double
  atlas_w : Double
  atlas_h : Double
  atlas_page_id : Int
} derive(Show)

///|
pub struct GlyphCache {
  entries : Map[Int, GlyphCacheEntry]
  mut next_x : Double
  mut next_y : Double
  mut row_height : Double
  atlas_width : Double
  atlas_height : Double
  atlas_page_id : Int
}

///|
pub fn GlyphCache::new(
  atlas_width : Double,
  atlas_height : Double,
  atlas_page_id : Int,
) -> GlyphCache {
  {
    entries: {},
    next_x: 0.0,
    next_y: 0.0,
    row_height: 0.0,
    atlas_width,
    atlas_height,
    atlas_page_id,
  }
}

///|
pub fn GlyphCache::get(self : GlyphCache, glyph_id : Int) -> GlyphCacheEntry? {
  self.entries.get(glyph_id)
}

///|
/// Allocate space in the atlas for a glyph. Returns the cache entry, or None
/// if the atlas is full.
pub fn GlyphCache::allocate(
  self : GlyphCache,
  glyph_id : Int,
  width : Double,
  height : Double,
) -> GlyphCacheEntry? {
  match self.entries.get(glyph_id) {
    Some(entry) => Some(entry)
    None => {
      let padding = 1.0
      let padded_w = width + padding
      let padded_h = height + padding
      // Check if we need to move to next row
      if self.next_x + padded_w > self.atlas_width {
        self.next_x = 0.0
        self.next_y = self.next_y + self.row_height + padding
        self.row_height = 0.0
      }
      // Check if atlas is full
      if self.next_y + padded_h > self.atlas_height {
        return None
      }
      let entry : GlyphCacheEntry = {
        glyph_id,
        atlas_x: self.next_x,
        atlas_y: self.next_y,
        atlas_w: width,
        atlas_h: height,
        atlas_page_id: self.atlas_page_id,
      }
      self.entries.set(glyph_id, entry)
      self.next_x = self.next_x + padded_w
      if padded_h > self.row_height {
        self.row_height = padded_h
      }
      Some(entry)
    }
  }
}

///|
pub fn GlyphCache::entry_count(self : GlyphCache) -> Int {
  self.entries.size()
}

///|
pub fn GlyphCache::clear(self : GlyphCache) -> Unit {
  self.entries.clear()
  self.next_x = 0.0
  self.next_y = 0.0
  self.row_height = 0.0
}
