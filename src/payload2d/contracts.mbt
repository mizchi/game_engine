///|
/// Generic 2D triangle payload decoder.
///
/// This package is intentionally engine-agnostic so it can be extracted
/// into a standalone utility later.

///|
pub struct TrianglePayload {
  has_payload : Bool
  ax : Double
  ay : Double
  bx : Double
  by : Double
  cx : Double
  cy : Double
  au : Double
  av : Double
  bu : Double
  bv : Double
  cu : Double
  cv : Double
  uniform_r : Double
  uniform_g : Double
  uniform_b : Double
  uniform_a : Double
  texture_seed : Int
} derive(Show)

///|
pub fn clamp_unit(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn decode_uniform_channel(
  uniforms : Array[Int],
  index : Int,
  fallback : Double,
) -> Double {
  if index >= 0 && index < uniforms.length() {
    let value = uniforms[index]
    if value >= 0 && value <= 255 {
      value.to_double() / 255.0
    } else {
      fallback
    }
  } else {
    fallback
  }
}

///|
fn resolve_texture_seed(src_image_ids : Array[Int]) -> Int {
  if src_image_ids.length() > 0 {
    let seed = src_image_ids[0]
    if seed < 0 {
      0
    } else {
      seed
    }
  } else {
    0
  }
}

///|
fn resolve_index_or_default(
  indices : Array[Int],
  order : Int,
  vertex_count : Int,
) -> Int {
  if vertex_count <= 0 {
    0
  } else if order >= 0 && order < indices.length() {
    let index = indices[order]
    if index >= 0 && index < vertex_count {
      index
    } else if order < vertex_count {
      order
    } else {
      0
    }
  } else if order < vertex_count {
    order
  } else {
    0
  }
}

///|
pub fn default_triangle_payload() -> TrianglePayload {
  {
    has_payload: false,
    ax: 0.0,
    ay: 0.5,
    bx: -0.5,
    by: -0.5,
    cx: 0.5,
    cy: -0.5,
    au: 0.0,
    av: 0.0,
    bu: 1.0,
    bv: 0.0,
    cu: 1.0,
    cv: 1.0,
    uniform_r: 1.0,
    uniform_g: 1.0,
    uniform_b: 1.0,
    uniform_a: 1.0,
    texture_seed: 0,
  }
}

///|
pub fn decode_triangle_payload(
  vertex_data : Array[Double],
  indices : Array[Int],
  uniform_dwords : Array[Int],
  src_image_ids : Array[Int],
) -> TrianglePayload {
  let payload_len = vertex_data.length()
  if payload_len < 6 {
    default_triangle_payload()
  } else {
    let mut ax = 0.0
    let mut ay = 0.5
    let mut bx = -0.5
    let mut by = -0.5
    let mut cx = 0.5
    let mut cy = -0.5
    let mut au = 0.0
    let mut av = 0.0
    let mut bu = 1.0
    let mut bv = 0.0
    let mut cu = 1.0
    let mut cv = 1.0

    if payload_len >= 12 {
      let vertex_count = payload_len / 4
      let i0 = resolve_index_or_default(indices, 0, vertex_count)
      let i1 = resolve_index_or_default(indices, 1, vertex_count)
      let i2 = resolve_index_or_default(indices, 2, vertex_count)

      let i0_base = i0 * 4
      let i1_base = i1 * 4
      let i2_base = i2 * 4
      ax = vertex_data[i0_base]
      ay = vertex_data[i0_base + 1]
      bx = vertex_data[i1_base]
      by = vertex_data[i1_base + 1]
      cx = vertex_data[i2_base]
      cy = vertex_data[i2_base + 1]
      au = vertex_data[i0_base + 2]
      av = vertex_data[i0_base + 3]
      bu = vertex_data[i1_base + 2]
      bv = vertex_data[i1_base + 3]
      cu = vertex_data[i2_base + 2]
      cv = vertex_data[i2_base + 3]
    } else {
      let vertex_count = payload_len / 2
      let i0 = resolve_index_or_default(indices, 0, vertex_count)
      let i1 = resolve_index_or_default(indices, 1, vertex_count)
      let i2 = resolve_index_or_default(indices, 2, vertex_count)
      let i0_base = i0 * 2
      let i1_base = i1 * 2
      let i2_base = i2 * 2
      ax = vertex_data[i0_base]
      ay = vertex_data[i0_base + 1]
      bx = vertex_data[i1_base]
      by = vertex_data[i1_base + 1]
      cx = vertex_data[i2_base]
      cy = vertex_data[i2_base + 1]
    }

    {
      has_payload: true,
      ax,
      ay,
      bx,
      by,
      cx,
      cy,
      au,
      av,
      bu,
      bv,
      cu,
      cv,
      uniform_r: clamp_unit(decode_uniform_channel(uniform_dwords, 0, 1.0)),
      uniform_g: clamp_unit(decode_uniform_channel(uniform_dwords, 1, 1.0)),
      uniform_b: clamp_unit(decode_uniform_channel(uniform_dwords, 2, 1.0)),
      uniform_a: clamp_unit(decode_uniform_channel(uniform_dwords, 3, 1.0)),
      texture_seed: resolve_texture_seed(src_image_ids),
    }
  }
}
