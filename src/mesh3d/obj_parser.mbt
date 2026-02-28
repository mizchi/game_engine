///|
/// Parse a Double from chars[start..end], supporting scientific notation (e.g. -3.41e-003).
fn parse_obj_double(chars : Array[Int], start : Int, end : Int) -> Double {
  if start >= end {
    return 0.0
  }
  let mut i = start
  let mut negative = false
  if chars[i] == 45 {
    // '-'
    negative = true
    i = i + 1
  } else if chars[i] == 43 {
    // '+'
    i = i + 1
  }
  let mut result = 0.0
  // Integer part
  while i < end {
    let d = chars[i] - 48
    if d >= 0 && d <= 9 {
      result = result * 10.0 + d.to_double()
      i = i + 1
    } else {
      break
    }
  }
  // Fractional part
  if i < end && chars[i] == 46 {
    // '.'
    i = i + 1
    let mut frac_div = 1.0
    while i < end {
      let d = chars[i] - 48
      if d >= 0 && d <= 9 {
        frac_div = frac_div * 10.0
        result = result + d.to_double() / frac_div
        i = i + 1
      } else {
        break
      }
    }
  }
  // Exponent part (e/E)
  if i < end && (chars[i] == 101 || chars[i] == 69) {
    // 'e' or 'E'
    i = i + 1
    let mut exp_neg = false
    if i < end && chars[i] == 45 {
      exp_neg = true
      i = i + 1
    } else if i < end && chars[i] == 43 {
      i = i + 1
    }
    let mut exp = 0
    while i < end {
      let d = chars[i] - 48
      if d >= 0 && d <= 9 {
        exp = exp * 10 + d
        i = i + 1
      } else {
        break
      }
    }
    let mut multiplier = 1.0
    for _k in 0..<exp {
      multiplier = multiplier * 10.0
    }
    if exp_neg {
      result = result / multiplier
    } else {
      result = result * multiplier
    }
  }
  if negative {
    -result
  } else {
    result
  }
}

///|
/// Parse an Int from chars[start..end].
fn parse_obj_int(chars : Array[Int], start : Int, end : Int) -> Int {
  if start >= end {
    return 0
  }
  let mut i = start
  let mut negative = false
  if chars[i] == 45 {
    negative = true
    i = i + 1
  }
  let mut result = 0
  while i < end {
    let d = chars[i] - 48
    if d >= 0 && d <= 9 {
      result = result * 10 + d
      i = i + 1
    } else {
      break
    }
  }
  if negative {
    -result
  } else {
    result
  }
}

///|
/// Skip whitespace (space/tab) and return the new position.
fn skip_ws(chars : Array[Int], start : Int, end : Int) -> Int {
  let mut i = start
  while i < end && (chars[i] == 32 || chars[i] == 9) {
    i = i + 1
  }
  i
}

///|
/// Find the next whitespace or end.
fn find_ws(chars : Array[Int], start : Int, end : Int) -> Int {
  let mut i = start
  while i < end && chars[i] != 32 && chars[i] != 9 {
    i = i + 1
  }
  i
}

///|
/// Find the next occurrence of char code or end.
fn find_char(chars : Array[Int], ch : Int, start : Int, end : Int) -> Int {
  let mut i = start
  while i < end && chars[i] != ch {
    i = i + 1
  }
  i
}

///|
/// Parse an OBJ face vertex index component: "v", "v/vt", "v/vt/vn", or "v//vn".
/// Returns (vertex_index, texcoord_index, normal_index) as 1-based or 0 if absent.
fn parse_face_vertex(
  chars : Array[Int],
  start : Int,
  end : Int,
) -> (Int, Int, Int) {
  // Find first '/'
  let slash1 = find_char(chars, 47, start, end) // '/'
  if slash1 >= end {
    // Just vertex index: "v"
    return (parse_obj_int(chars, start, end), 0, 0)
  }
  let vi = parse_obj_int(chars, start, slash1)
  let after_slash1 = slash1 + 1
  // Find second '/'
  let slash2 = find_char(chars, 47, after_slash1, end)
  if slash2 >= end {
    // "v/vt"
    let vti = parse_obj_int(chars, after_slash1, end)
    return (vi, vti, 0)
  }
  if slash2 == after_slash1 {
    // "v//vn"
    let vni = parse_obj_int(chars, slash2 + 1, end)
    return (vi, 0, vni)
  }
  // "v/vt/vn"
  let vti = parse_obj_int(chars, after_slash1, slash2)
  let vni = parse_obj_int(chars, slash2 + 1, end)
  (vi, vti, vni)
}

///|
/// Parse a Wavefront OBJ string into a Mesh3D.
/// Supports v, vn, vt, f directives.
/// Handles scientific notation, N-gon triangulation, negative indices, and flat normal generation.
pub fn Mesh3D::from_obj(source : String) -> Mesh3D {
  let chars : Array[Int] = []
  for ch in source {
    chars.push(ch.to_int())
  }
  let len = chars.length()
  // Collected positions, normals, texcoords
  let positions : Array[Double] = [] // x,y,z triples
  let normals : Array[Double] = [] // nx,ny,nz triples
  let texcoords : Array[Double] = [] // u,v pairs
  // Output mesh data
  let vertex_data : Array[Double] = []
  let indices : Array[Int] = []
  let mut vertex_count = 0
  // Track whether any normals were provided
  let mut has_normals = false
  // For flat-normal post-processing: store face start indices
  let face_starts : Array[Int] = [] // index into indices array where each face's triangles start
  let face_tri_counts : Array[Int] = [] // number of triangles per face
  // Parse line by line
  let mut pos = 0
  while pos < len {
    // Find end of line
    let mut line_end = pos
    while line_end < len && chars[line_end] != 10 && chars[line_end] != 13 {
      line_end = line_end + 1
    }
    // Skip leading whitespace
    let line_start = skip_ws(chars, pos, line_end)
    if line_start < line_end {
      let first = chars[line_start]
      if first == 118 {
        // 'v'
        if line_start + 1 < line_end && chars[line_start + 1] == 110 {
          // "vn" - vertex normal
          let mut p = skip_ws(chars, line_start + 2, line_end)
          let e1 = find_ws(chars, p, line_end)
          let nx = parse_obj_double(chars, p, e1)
          p = skip_ws(chars, e1, line_end)
          let e2 = find_ws(chars, p, line_end)
          let ny = parse_obj_double(chars, p, e2)
          p = skip_ws(chars, e2, line_end)
          let e3 = find_ws(chars, p, line_end)
          let nz = parse_obj_double(chars, p, e3)
          normals.push(nx)
          normals.push(ny)
          normals.push(nz)
        } else if line_start + 1 < line_end && chars[line_start + 1] == 116 {
          // "vt" - texture coordinate
          let mut p = skip_ws(chars, line_start + 2, line_end)
          let e1 = find_ws(chars, p, line_end)
          let u = parse_obj_double(chars, p, e1)
          p = skip_ws(chars, e1, line_end)
          let e2 = find_ws(chars, p, line_end)
          let v = parse_obj_double(chars, p, e2)
          texcoords.push(u)
          texcoords.push(v)
        } else if line_start + 1 < line_end &&
          (chars[line_start + 1] == 32 || chars[line_start + 1] == 9) {
          // "v " - vertex position
          let mut p = skip_ws(chars, line_start + 1, line_end)
          let e1 = find_ws(chars, p, line_end)
          let x = parse_obj_double(chars, p, e1)
          p = skip_ws(chars, e1, line_end)
          let e2 = find_ws(chars, p, line_end)
          let y = parse_obj_double(chars, p, e2)
          p = skip_ws(chars, e2, line_end)
          let e3 = find_ws(chars, p, line_end)
          let z = parse_obj_double(chars, p, e3)
          positions.push(x)
          positions.push(y)
          positions.push(z)
        }
      } else if first == 102 &&
        line_start + 1 < line_end &&
        (chars[line_start + 1] == 32 || chars[line_start + 1] == 9) {
        // "f " - face
        let face_verts : Array[(Int, Int, Int)] = [] // (vi, vti, vni)
        let mut p = skip_ws(chars, line_start + 1, line_end)
        while p < line_end {
          let tok_end = find_ws(chars, p, line_end)
          if tok_end > p {
            face_verts.push(parse_face_vertex(chars, p, tok_end))
          }
          p = skip_ws(chars, tok_end, line_end)
        }
        let num_verts = positions.length() / 3
        let num_norms = normals.length() / 3
        let num_texs = texcoords.length() / 2
        // Check if this face has normals
        let mut face_has_normals = false
        for fv in face_verts {
          let (_, _, vni) = fv
          if vni != 0 {
            face_has_normals = true
            has_normals = true
            break
          }
        }
        // Emit vertices for this face
        let base_idx = vertex_count
        for fv in face_verts {
          let (vi_raw, vti_raw, vni_raw) = fv
          // Resolve vertex index (1-based, negative = relative)
          let vi = if vi_raw < 0 { num_verts + vi_raw + 1 } else { vi_raw }
          let pi = (vi - 1) * 3
          let px = if pi >= 0 && pi + 2 < positions.length() {
            positions[pi]
          } else {
            0.0
          }
          let py = if pi >= 0 && pi + 2 < positions.length() {
            positions[pi + 1]
          } else {
            0.0
          }
          let pz = if pi >= 0 && pi + 2 < positions.length() {
            positions[pi + 2]
          } else {
            0.0
          }
          // Resolve normal
          let mut nx = 0.0
          let mut ny = 0.0
          let mut nz = 0.0
          if face_has_normals && vni_raw != 0 {
            let vni = if vni_raw < 0 {
              num_norms + vni_raw + 1
            } else {
              vni_raw
            }
            let ni = (vni - 1) * 3
            if ni >= 0 && ni + 2 < normals.length() {
              nx = normals[ni]
              ny = normals[ni + 1]
              nz = normals[ni + 2]
            }
          }
          // Resolve texcoord
          let mut u = 0.0
          let mut v = 0.0
          if vti_raw != 0 {
            let vti = if vti_raw < 0 {
              num_texs + vti_raw + 1
            } else {
              vti_raw
            }
            let ti = (vti - 1) * 2
            if ti >= 0 && ti + 1 < texcoords.length() {
              u = texcoords[ti]
              v = texcoords[ti + 1]
            }
          }
          push_vertex(vertex_data, px, py, pz, nx, ny, nz, u, v)
          vertex_count = vertex_count + 1
        }
        // Triangulate (fan from first vertex)
        let n_face = face_verts.length()
        let face_idx_start = indices.length()
        let mut tri_count = 0
        for k in 1..<(n_face - 1) {
          indices.push(base_idx)
          indices.push(base_idx + k)
          indices.push(base_idx + k + 1)
          tri_count = tri_count + 1
        }
        if !face_has_normals {
          face_starts.push(face_idx_start)
          face_tri_counts.push(tri_count)
        }
      }
    }
    // Advance past newline
    pos = line_end
    if pos < len && chars[pos] == 13 {
      pos = pos + 1 // CR
    }
    if pos < len && chars[pos] == 10 {
      pos = pos + 1 // LF
    }
  }
  // Post-process: compute flat normals for faces without explicit normals
  if !has_normals || face_starts.length() > 0 {
    for fi in 0..<face_starts.length() {
      let idx_start = face_starts[fi]
      let tris = face_tri_counts[fi]
      // Use first triangle to compute face normal
      let i0 = indices[idx_start]
      let i1 = indices[idx_start + 1]
      let i2 = indices[idx_start + 2]
      // Get positions from vertex_data (stride 8)
      let p0x = vertex_data[i0 * 8]
      let p0y = vertex_data[i0 * 8 + 1]
      let p0z = vertex_data[i0 * 8 + 2]
      let p1x = vertex_data[i1 * 8]
      let p1y = vertex_data[i1 * 8 + 1]
      let p1z = vertex_data[i1 * 8 + 2]
      let p2x = vertex_data[i2 * 8]
      let p2y = vertex_data[i2 * 8 + 1]
      let p2z = vertex_data[i2 * 8 + 2]
      // edge1 = p1 - p0, edge2 = p2 - p0
      let e1x = p1x - p0x
      let e1y = p1y - p0y
      let e1z = p1z - p0z
      let e2x = p2x - p0x
      let e2y = p2y - p0y
      let e2z = p2z - p0z
      // cross product
      let mut nx = e1y * e2z - e1z * e2y
      let mut ny = e1z * e2x - e1x * e2z
      let mut nz = e1x * e2y - e1y * e2x
      // normalize
      let mag = (nx * nx + ny * ny + nz * nz).sqrt()
      if mag > 1.0e-10 {
        nx = nx / mag
        ny = ny / mag
        nz = nz / mag
      }
      // Write normal to all vertices in this face's triangles
      for ti in 0..<tris {
        let base = idx_start + ti * 3
        for vi in 0..<3 {
          let idx = indices[base + vi]
          vertex_data[idx * 8 + 3] = nx
          vertex_data[idx * 8 + 4] = ny
          vertex_data[idx * 8 + 5] = nz
        }
      }
    }
  }
  { vertex_data, indices }
}
