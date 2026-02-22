pub fn render_scene(
  node : SceneNode,
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  screen_w : Double,
  screen_h : Double,
) -> Array[@gfx.DrawTrianglesCommand] {
  let cmds : Array[@gfx.DrawTrianglesCommand] = []
  render_node(cmds, node, dst, shader, screen_w, screen_h, 0.0, 0.0)
  cmds
}

fn render_node(
  cmds : Array[@gfx.DrawTrianglesCommand],
  node : SceneNode,
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  screen_w : Double,
  screen_h : Double,
  offset_x : Double,
  offset_y : Double,
) -> Unit {
  match node {
    Element(el) => render_element(cmds, el, dst, shader, screen_w, screen_h, offset_x, offset_y)
    Fragment(children) =>
      for child in children {
        render_node(cmds, child, dst, shader, screen_w, screen_h, offset_x, offset_y)
      }
    Show(condition~, child~) =>
      if condition() {
        render_node(cmds, child(), dst, shader, screen_w, screen_h, offset_x, offset_y)
      }
    For(render~) => {
      let items = render()
      for item in items {
        render_node(cmds, item, dst, shader, screen_w, screen_h, offset_x, offset_y)
      }
    }
    Component(render~) =>
      render_node(cmds, render(), dst, shader, screen_w, screen_h, offset_x, offset_y)
    Switch(sw) => {
      for c in sw.cases {
        if (c.when)() {
          render_node(cmds, (c.render)(), dst, shader, screen_w, screen_h, offset_x, offset_y)
          return
        }
      }
      match sw.fallback {
        Some(fb) =>
          render_node(cmds, fb(), dst, shader, screen_w, screen_h, offset_x, offset_y)
        None => ()
      }
    }
    Text(_) | DynamicText(_) | Async(_) | ErrorBoundary(_) | RawHtml(_) => ()
  }
}

fn render_element(
  cmds : Array[@gfx.DrawTrianglesCommand],
  el : @ui.VElement[Unit, String],
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  screen_w : Double,
  screen_h : Double,
  offset_x : Double,
  offset_y : Double,
) -> Unit {
  match el.tag {
    "rect" => render_rect(cmds, el, dst, shader, screen_w, screen_h, offset_x, offset_y)
    "label" => render_label(cmds, el, dst, shader, screen_w, screen_h, offset_x, offset_y)
    "group" => render_group(cmds, el, dst, shader, screen_w, screen_h, offset_x, offset_y)
    "line" => render_line(cmds, el, dst, shader, screen_w, screen_h, offset_x, offset_y)
    "rect_outline" => render_rect_outline(cmds, el, dst, shader, screen_w, screen_h, offset_x, offset_y)
    _ => ()
  }
}

fn render_rect(
  cmds : Array[@gfx.DrawTrianglesCommand],
  el : @ui.VElement[Unit, String],
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  screen_w : Double,
  screen_h : Double,
  offset_x : Double,
  offset_y : Double,
) -> Unit {
  let x = get_attr_double(el.attrs, "x", 0.0) + offset_x
  let y = get_attr_double(el.attrs, "y", 0.0) + offset_y
  let w = get_attr_double(el.attrs, "w", 0.0)
  let h = get_attr_double(el.attrs, "h", 0.0)
  let fill = get_attr_int(el.attrs, "fill", 0xFFFFFF)
  let alpha = get_attr_double(el.attrs, "alpha", 1.0)
  let color = @debugutil.color_from_hex_alpha(fill, alpha)
  cmds.push(
    @debugutil.new_ndc_rect_fill_command(
      dst, shader, x, y, w, h, screen_w, screen_h, color, 0,
    ),
  )
  for child in el.children {
    render_node(cmds, child, dst, shader, screen_w, screen_h, x, y)
  }
}

fn render_label(
  cmds : Array[@gfx.DrawTrianglesCommand],
  el : @ui.VElement[Unit, String],
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  screen_w : Double,
  screen_h : Double,
  offset_x : Double,
  offset_y : Double,
) -> Unit {
  let x = get_attr_double(el.attrs, "x", 0.0) + offset_x
  let y = get_attr_double(el.attrs, "y", 0.0) + offset_y
  let content = get_attr_string(el.attrs, "content", "")
  let color_hex = get_attr_int(el.attrs, "color", 0xFFFFFF)
  let scale = get_attr_double(el.attrs, "scale", 1.0)
  let color = @debugutil.color_from_hex(color_hex)
  let chars = string_to_char_codes(content)
  @debugutil.draw_dot_text(cmds, dst, shader, chars, x, y, screen_w, screen_h, color, scale)
}

fn render_group(
  cmds : Array[@gfx.DrawTrianglesCommand],
  el : @ui.VElement[Unit, String],
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  screen_w : Double,
  screen_h : Double,
  offset_x : Double,
  offset_y : Double,
) -> Unit {
  let x = get_attr_double(el.attrs, "x", 0.0) + offset_x
  let y = get_attr_double(el.attrs, "y", 0.0) + offset_y
  for child in el.children {
    render_node(cmds, child, dst, shader, screen_w, screen_h, x, y)
  }
}

fn pixel_to_ndc_vertices(
  vertices : Array[Double],
  screen_w : Double,
  screen_h : Double,
) -> Array[Double] {
  let out : Array[Double] = []
  let mut i = 0
  while i < vertices.length() {
    let px = vertices[i]
    let py = vertices[i + 1]
    let u = vertices[i + 2]
    let v = vertices[i + 3]
    out.push(px / screen_w * 2.0 - 1.0)
    out.push(1.0 - py / screen_h * 2.0)
    out.push(u)
    out.push(v)
    i = i + 4
  }
  out
}

fn render_line(
  cmds : Array[@gfx.DrawTrianglesCommand],
  el : @ui.VElement[Unit, String],
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  screen_w : Double,
  screen_h : Double,
  offset_x : Double,
  offset_y : Double,
) -> Unit {
  let x0 = get_attr_double(el.attrs, "x0", 0.0) + offset_x
  let y0 = get_attr_double(el.attrs, "y0", 0.0) + offset_y
  let x1 = get_attr_double(el.attrs, "x1", 0.0) + offset_x
  let y1 = get_attr_double(el.attrs, "y1", 0.0) + offset_y
  let width = get_attr_double(el.attrs, "width", 1.0)
  let color_hex = get_attr_int(el.attrs, "color", 0xFFFFFF)
  let color = @debugutil.color_from_hex(color_hex)
  let (vertices, indices) = @debugutil.line_vertices(x0, y0, x1, y1, width)
  let ndc_vertices = pixel_to_ndc_vertices(vertices, screen_w, screen_h)
  let uniform = @debugutil.color_to_uniform_dwords(color)
  cmds.push(
    @gfx.new_draw_triangles_command(
      dst,
      shader,
      [@gfx.new_dst_region(0, 0, screen_w.to_int(), screen_h.to_int(), indices.length())],
      0,
      0,
      0,
      @gfx.blend_mode_from_int(1),
      ndc_vertices,
      indices,
      [],
      uniform,
    ),
  )
}

fn render_rect_outline(
  cmds : Array[@gfx.DrawTrianglesCommand],
  el : @ui.VElement[Unit, String],
  dst : @gfx.ImageHandle,
  shader : @gfx.ShaderHandle,
  screen_w : Double,
  screen_h : Double,
  offset_x : Double,
  offset_y : Double,
) -> Unit {
  let x = get_attr_double(el.attrs, "x", 0.0) + offset_x
  let y = get_attr_double(el.attrs, "y", 0.0) + offset_y
  let w = get_attr_double(el.attrs, "w", 0.0)
  let h = get_attr_double(el.attrs, "h", 0.0)
  let line_width = get_attr_double(el.attrs, "line_width", 1.0)
  let color_hex = get_attr_int(el.attrs, "color", 0xFFFFFF)
  let color = @debugutil.color_from_hex(color_hex)
  let (vertices, indices) = @debugutil.rect_outline_vertices(x, y, w, h, line_width)
  let ndc_vertices = pixel_to_ndc_vertices(vertices, screen_w, screen_h)
  let uniform = @debugutil.color_to_uniform_dwords(color)
  cmds.push(
    @gfx.new_draw_triangles_command(
      dst,
      shader,
      [@gfx.new_dst_region(0, 0, screen_w.to_int(), screen_h.to_int(), indices.length())],
      0,
      0,
      0,
      @gfx.blend_mode_from_int(1),
      ndc_vertices,
      indices,
      [],
      uniform,
    ),
  )
}

fn get_attr_string(
  attrs : Array[(String, @ui.Attr[Unit, String])],
  key : String,
  default_ : String,
) -> String {
  for pair in attrs {
    let (k, v) = pair
    if k == key {
      match v {
        VStatic(s) => return s
        VDynamic(f) => return f()
        VHandler(_) => continue
      }
    }
  }
  default_
}

fn get_attr_double(
  attrs : Array[(String, @ui.Attr[Unit, String])],
  key : String,
  default_ : Double,
) -> Double {
  let s = get_attr_string(attrs, key, "")
  if s == "" {
    return default_
  }
  parse_double(s, default_)
}

fn get_attr_int(
  attrs : Array[(String, @ui.Attr[Unit, String])],
  key : String,
  default_ : Int,
) -> Int {
  let s = get_attr_string(attrs, key, "")
  if s == "" {
    return default_
  }
  parse_int(s, default_)
}

fn parse_double(s : String, default_ : Double) -> Double {
  let mut result = 0.0
  let mut frac = 0.0
  let mut frac_div = 1.0
  let mut in_frac = false
  let mut negative = false
  let mut started = false
  for ch in s {
    if ch == '-' && !started {
      negative = true
      started = true
      continue
    }
    if ch == '.' {
      in_frac = true
      started = true
      continue
    }
    let digit = ch.to_int() - 48
    if digit >= 0 && digit <= 9 {
      started = true
      if in_frac {
        frac_div = frac_div * 10.0
        frac = frac + digit.to_double() / frac_div
      } else {
        result = result * 10.0 + digit.to_double()
      }
    } else {
      if started {
        break
      }
      return default_
    }
  }
  if !started {
    return default_
  }
  let v = result + frac
  if negative { -v } else { v }
}

fn parse_int(s : String, default_ : Int) -> Int {
  let mut result = 0
  let mut negative = false
  let mut started = false
  for ch in s {
    if ch == '-' && !started {
      negative = true
      started = true
      continue
    }
    let digit = ch.to_int() - 48
    if digit >= 0 && digit <= 9 {
      started = true
      result = result * 10 + digit
    } else {
      if started {
        break
      }
      return default_
    }
  }
  if !started {
    return default_
  }
  if negative { -result } else { result }
}

fn string_to_char_codes(s : String) -> Array[Int] {
  let codes : Array[Int] = []
  for ch in s {
    let code = ch.to_int()
    // glyph_pattern uses 0-9 for digits, but ASCII for letters
    if code >= 48 && code <= 57 {
      codes.push(code - 48)
    } else {
      codes.push(code)
    }
  }
  codes
}
