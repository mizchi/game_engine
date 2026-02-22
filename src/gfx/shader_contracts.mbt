///|
/// Shader pipeline contracts (outline only).
///
/// Ebiten refs:
/// - shader.go
/// - internal/graphics/shader.go
/// - internal/shader/shader.go
/// - internal/ui/shader.go
/// - internal/shaderir/program.go
/// - internal/graphicscommand/commandqueue.go
/// - internal/builtinshader/shader.go

///|
pub enum ShaderUnit {
  Pixels
  Texels
} derive(Show)

///|
pub struct ShaderEntrypoints {
  vertex : String
  fragment : String
} derive(Show)

///|
pub struct ShaderCompileRequest {
  source : String
  unit_hint : ShaderUnit?
  src_image_count : Int
  entrypoints : ShaderEntrypoints
  debug_name : String
} derive(Show)

///|
pub struct ShaderIR {
  source : String
  unit : ShaderUnit
  noperspective : Bool
  src_image_count : Int
  entrypoints : ShaderEntrypoints
  debug_name : String
  source_hash : ShaderSourceHash
} derive(Show)

///|
pub struct ShaderSourceHash {
  value : String
} derive(Show)

///|
pub enum UniformValue {
  Bool(Bool)
  Int(Int)
  Float(Double)
  Bools(Array[Bool])
  Ints(Array[Int])
  Floats(Array[Double])
} derive(Show)

///|
pub struct NamedUniform {
  name : String
  value : UniformValue
} derive(Show)

///|
pub struct UniformLayout {
  names : Array[String]
  dword_counts : Array[Int]
  preserved_prefix_dwords : Int
} derive(Show)

///|
pub struct IntSize {
  width : Int
  height : Int
} derive(Show)

///|
pub struct FloatRect {
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Show)

///|
pub struct PreservedUniformContext {
  dst_texture_size : IntSize
  dst_region : FloatRect
  src_texture_sizes : Array[IntSize]
  src_regions : Array[FloatRect]
} derive(Show)

///|
pub struct PackedUniforms {
  dwords : Array[Int]
} derive(Show)

///|
pub enum BuiltinShaderFilter {
  Nearest
  Linear
  Pixelated
} derive(Show)

///|
pub enum BuiltinShaderAddress {
  Unsafe
  ClampToZero
  ClampToEdge
  Repeat
  MirrorRepeat
} derive(Show)

///|
/// Per-axis sampler specification for texture sampling.
pub struct SamplerSpec {
  filter : BuiltinShaderFilter
  address_u : BuiltinShaderAddress
  address_v : BuiltinShaderAddress
} derive(Show)

///|
pub fn default_sampler_spec() -> SamplerSpec {
  {
    filter: BuiltinShaderFilter::Nearest,
    address_u: BuiltinShaderAddress::Unsafe,
    address_v: BuiltinShaderAddress::Unsafe,
  }
}

///|
/// Convenience: create SamplerSpec with same address on both axes.
pub fn sampler_spec(
  filter : BuiltinShaderFilter,
  address : BuiltinShaderAddress,
) -> SamplerSpec {
  { filter, address_u: address, address_v: address }
}

///|
pub struct BuiltinShaderKey {
  filter : BuiltinShaderFilter
  address : BuiltinShaderAddress
  use_color_m : Bool
} derive(Show)

///|
/// Extended shader key that supports per-axis address modes.
pub struct BuiltinShaderKeyEx {
  sampler : SamplerSpec
  use_color_m : Bool
} derive(Show)

///|
/// Convert a classic BuiltinShaderKey to extended form.
pub fn builtin_key_to_ex(key : BuiltinShaderKey) -> BuiltinShaderKeyEx {
  {
    sampler: {
      filter: key.filter,
      address_u: key.address,
      address_v: key.address,
    },
    use_color_m: key.use_color_m,
  }
}

///|
pub trait ShaderFrontend {
  /// Ebiten ref: internal/graphics/shader.go (CompileShader)
  compile_ir(Self, request : ShaderCompileRequest) -> ShaderIR raise

  /// Ebiten ref: internal/graphics/shader.go (CalcSourceHash)
  calc_source_hash(Self, request : ShaderCompileRequest) -> ShaderSourceHash raise
}

///|
pub trait UniformCanonicalizer {
  /// Ebiten ref: internal/ui/shader.go (AppendUniforms)
  append_user_uniforms(
    Self,
    layout : UniformLayout,
    uniforms : Array[NamedUniform],
  ) -> PackedUniforms raise

  /// Ebiten ref: internal/graphicscommand/commandqueue.go (prependPreservedUniforms)
  prepend_preserved_uniforms(
    Self,
    uniforms : PackedUniforms,
    context : PreservedUniformContext,
  ) -> PackedUniforms

  /// Ebiten ref: internal/shaderir/program.go (FilterUniformVariables)
  filter_unused_uniforms(
    Self,
    ir : ShaderIR,
    layout : UniformLayout,
    uniforms : PackedUniforms,
  ) -> PackedUniforms
}

///|
pub trait BuiltinShaderSourceRepo {
  /// Ebiten ref: internal/builtinshader/shader.go (ShaderSource/ClearShaderSource)
  shader_source(Self, key : BuiltinShaderKey) -> String
  /// Extended: cache shader source by per-axis sampler key.
  shader_source_ex(Self, key : BuiltinShaderKeyEx) -> String
}

///|
pub fn[T : ShaderFrontend] compile_shader_ir(
  frontend : T,
  request : ShaderCompileRequest,
) -> ShaderIR raise {
  frontend.compile_ir(request)
}

///|
pub fn[T : ShaderFrontend] calc_shader_source_hash(
  frontend : T,
  request : ShaderCompileRequest,
) -> ShaderSourceHash raise {
  frontend.calc_source_hash(request)
}

///|
pub fn[T : UniformCanonicalizer] build_canonical_uniforms(
  canonicalizer : T,
  layout : UniformLayout,
  user_uniforms : Array[NamedUniform],
  context : PreservedUniformContext,
  ir : ShaderIR,
) -> PackedUniforms raise {
  let user = canonicalizer.append_user_uniforms(layout, user_uniforms)
  let preserved = canonicalizer.prepend_preserved_uniforms(user, context)
  let filtered = canonicalizer.filter_unused_uniforms(ir, layout, preserved)
  normalize_uniform_length(layout, filtered)
}

///|
pub struct BasicShaderFrontend {}

///|
pub struct BasicUniformCanonicalizer {}

///|
struct BuiltinShaderSourceCacheEntry {
  key : BuiltinShaderKey
  source : String
  last_used_tick : Int
}

///|
struct BuiltinShaderSourceCacheEntryEx {
  key : BuiltinShaderKeyEx
  source : String
  last_used_tick : Int
}

///|
pub struct BuiltinShaderCacheStats {
  hit_count : Int
  miss_count : Int
} derive(Show)

///|
pub struct BasicBuiltinShaderSourceRepo {
  mut cache : Array[BuiltinShaderSourceCacheEntry]
  mut cache_ex : Array[BuiltinShaderSourceCacheEntryEx]
  mut tick : Int
  max_cache_entries : Int
  mut hit_count : Int
  mut miss_count : Int
}

///|
/// Validate a shader compile request before compilation.
/// Returns None if valid, Some(error_message) if invalid.
pub fn validate_shader_compile_request(
  request : ShaderCompileRequest,
) -> String? {
  if request.source.length() == 0 {
    return Some("shader source must not be empty")
  }
  if request.entrypoints.vertex.length() == 0 {
    return Some("vertex entrypoint must not be empty")
  }
  if request.entrypoints.fragment.length() == 0 {
    return Some("fragment entrypoint must not be empty")
  }
  if request.src_image_count < 0 {
    return Some("src_image_count must not be negative")
  }
  None
}

///|
pub fn shader_unit_eq(lhs : ShaderUnit, rhs : ShaderUnit) -> Bool {
  match lhs {
    ShaderUnit::Pixels =>
      match rhs {
        ShaderUnit::Pixels => true
        _ => false
      }
    ShaderUnit::Texels =>
      match rhs {
        ShaderUnit::Texels => true
        _ => false
      }
  }
}

///|
pub fn shader_hash_eq(lhs : ShaderSourceHash, rhs : ShaderSourceHash) -> Bool {
  lhs.value == rhs.value
}

///|
pub fn new_basic_shader_frontend() -> BasicShaderFrontend {
  BasicShaderFrontend::{  }
}

///|
pub fn new_basic_uniform_canonicalizer() -> BasicUniformCanonicalizer {
  BasicUniformCanonicalizer::{  }
}

///|
pub fn new_basic_builtin_shader_source_repo() -> BasicBuiltinShaderSourceRepo {
  {
    cache: [],
    cache_ex: [],
    tick: 0,
    max_cache_entries: 8,
    hit_count: 0,
    miss_count: 0,
  }
}

///|
pub fn builtin_shader_source_cache_size(
  repo : BasicBuiltinShaderSourceRepo,
) -> Int {
  repo.cache.length() + repo.cache_ex.length()
}

///|
pub fn builtin_shader_source_cache_limit(
  repo : BasicBuiltinShaderSourceRepo,
) -> Int {
  repo.max_cache_entries
}

///|
pub fn clear_builtin_shader_source_cache(
  repo : BasicBuiltinShaderSourceRepo,
) -> Unit {
  repo.cache = []
  repo.cache_ex = []
  repo.hit_count = 0
  repo.miss_count = 0
}

///|
pub fn builtin_shader_cache_stats(
  repo : BasicBuiltinShaderSourceRepo,
) -> BuiltinShaderCacheStats {
  { hit_count: repo.hit_count, miss_count: repo.miss_count }
}

///|
/// Validate a uniform layout for common errors.
/// Returns None if valid, Some(error_message) if invalid.
pub fn validate_uniform_layout(layout : UniformLayout) -> String? {
  if layout.names.length() != layout.dword_counts.length() {
    return Some(
      "names length (\{layout.names.length()}) must match dword_counts length (\{layout.dword_counts.length()})",
    )
  }
  for i in 0..<layout.names.length() {
    if layout.dword_counts[i] < 0 {
      return Some(
        "dword_counts[\{i}] must not be negative (got \{layout.dword_counts[i]})",
      )
    }
    for j in (i + 1)..<layout.names.length() {
      if layout.names[i] == layout.names[j] {
        return Some(
          "duplicate uniform name '\{layout.names[i]}' at indices \{i} and \{j}",
        )
      }
    }
  }
  if layout.preserved_prefix_dwords < 0 {
    return Some(
      "preserved_prefix_dwords must not be negative (got \{layout.preserved_prefix_dwords})",
    )
  }
  None
}

///|
/// Compute the expected preserved prefix dword count from a context.
/// Ebiten layout: dst_size(2) + dst_region(4) + per_src(size(2) + region(4)).
pub fn compute_expected_preserved_dwords(
  context : PreservedUniformContext,
) -> Int {
  let src_count = if context.src_texture_sizes.length() <=
    context.src_regions.length() {
    context.src_texture_sizes.length()
  } else {
    context.src_regions.length()
  }
  2 + 4 + src_count * (2 + 4)
}

///|
/// Validate that preserved uniform context is internally consistent.
/// Returns None if valid, Some(error_message) if invalid.
pub fn validate_preserved_uniform_context(
  context : PreservedUniformContext,
) -> String? {
  if context.src_texture_sizes.length() != context.src_regions.length() {
    return Some(
      "src_texture_sizes length (\{context.src_texture_sizes.length()}) must match src_regions length (\{context.src_regions.length()})",
    )
  }
  if context.dst_texture_size.width <= 0 || context.dst_texture_size.height <= 0 {
    return Some("dst_texture_size must have positive dimensions")
  }
  None
}

///|
/// Convert a Double to IEEE 754 f32 bit representation as Int.
pub fn double_to_f32_bits(v : Double) -> Int {
  let bits = v.reinterpret_as_int64()
  let sign = bits.lsr(63).land(1L).to_int()
  let exp = bits.lsr(52).land(0x7FFL).to_int()
  let mantissa = bits & 0xFFFFFFFFFFFFFL
  if exp == 0x7FF {
    // Infinity or NaN
    if mantissa != 0L {
      sign.lsl(31) | 0x7FC00000
    } else {
      sign.lsl(31) | 0x7F800000
    }
  } else if exp == 0 {
    sign.lsl(31) // zero/denormal → zero
  } else {
    let f32_exp = exp - 1023 + 127
    if f32_exp >= 255 {
      sign.lsl(31) | 0x7F800000
    } else if f32_exp <= 0 {
      sign.lsl(31)
    } else {
      let f32_mantissa = mantissa.lsr(29).to_int()
      sign.lsl(31) | f32_exp.lsl(23) | f32_mantissa
    }
  }
}

///|
/// Convert IEEE 754 f32 bits (as Int) back to Double.
pub fn f32_bits_to_double(bits : Int) -> Double {
  let sign = bits.lsr(31) & 1
  let exp = bits.lsr(23) & 0xFF
  let mantissa = bits & 0x7FFFFF
  if exp == 0xFF {
    if mantissa != 0 {
      // NaN
      0.0 / 0.0
    } else if sign != 0 {
      -1.0 / 0.0
    } else {
      1.0 / 0.0
    }
  } else if exp == 0 {
    if sign != 0 {
      -0.0
    } else {
      0.0
    }
  } else {
    let f64_exp = (exp - 127 + 1023).to_int64()
    let f64_mantissa = mantissa.to_int64().lsl(29)
    let f64_bits = sign.to_int64().lsl(63) | f64_exp.lsl(52) | f64_mantissa
    f64_bits.reinterpret_as_double()
  }
}

///|
fn uniform_to_dwords(value : UniformValue) -> Array[Int] {
  match value {
    Bool(v) => [if v { 1 } else { 0 }]
    Int(v) => [v]
    Float(v) => [double_to_f32_bits(v)]
    Bools(vs) => vs.map(fn(v) { if v { 1 } else { 0 } })
    Ints(vs) => vs
    Floats(vs) => vs.map(fn(v) { double_to_f32_bits(v) })
  }
}

///|
fn find_named_uniform(
  uniforms : Array[NamedUniform],
  name : String,
) -> UniformValue? {
  for uniform in uniforms {
    if uniform.name == name {
      return Some(uniform.value)
    }
  }
  None
}

///|
fn normalized_src_image_count(src_image_count : Int) -> Int {
  if src_image_count < 0 {
    0
  } else {
    src_image_count
  }
}

///|
fn shader_unit_tag(unit : ShaderUnit) -> String {
  match unit {
    ShaderUnit::Pixels => "pixels"
    ShaderUnit::Texels => "texels"
  }
}

///|
fn is_space_like(ch : Char) -> Bool {
  ch == ' ' || ch == '\t'
}

///|
fn char_array_starts_with(
  chars : Array[Char],
  offset : Int,
  prefix : Array[Char],
) -> Bool {
  if offset < 0 || offset + prefix.length() > chars.length() {
    false
  } else {
    for i in 0..<prefix.length() {
      if chars[offset + i] != prefix[i] {
        return false
      }
    }
    true
  }
}

///|
fn parse_kage_unit_directive(source : String) -> ShaderUnit? {
  let chars = source.to_array()
  let directive = "//kage:unit".to_array()
  let pixels = "pixels".to_array()
  let texels = "texels".to_array()
  let chars_len = chars.length()
  let directive_len = directive.length()
  if chars_len < directive_len {
    None
  } else {
    for i in 0..<(chars_len - directive_len + 1) {
      if !char_array_starts_with(chars, i, directive) {
        continue
      }
      let mut cursor = i + directive_len
      while cursor < chars_len && is_space_like(chars[cursor]) {
        cursor = cursor + 1
      }
      if char_array_starts_with(chars, cursor, texels) {
        let right = cursor + texels.length()
        if right >= chars_len || !is_identifier_char(chars[right]) {
          return Some(ShaderUnit::Texels)
        }
      }
      if char_array_starts_with(chars, cursor, pixels) {
        let right = cursor + pixels.length()
        if right >= chars_len || !is_identifier_char(chars[right]) {
          return Some(ShaderUnit::Pixels)
        }
      }
    }
    None
  }
}

///|
fn resolve_shader_unit(request : ShaderCompileRequest) -> ShaderUnit {
  match parse_kage_unit_directive(request.source) {
    Some(unit) => unit
    None =>
      match request.unit_hint {
        Some(unit) => unit
        None => ShaderUnit::Pixels
      }
  }
}

///|
fn preprocess_shader_source(
  source : String,
  unit : ShaderUnit,
  entrypoints : ShaderEntrypoints,
  debug_name : String,
) -> String {
  let normalized = source
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\r", new="\n")
  "// kagura:shader\n// debug:\{debug_name}\n// unit:\{shader_unit_tag(unit)}\n// vertex:\{entrypoints.vertex}\n// fragment:\{entrypoints.fragment}\n\{normalized}"
}

///|
fn mix_hash(seed : Int, value : Int) -> Int {
  seed * 16777619 + value + 31
}

///|
fn calc_request_hash_value(
  preprocessed_source : String,
  debug_name : String,
  src_image_count : Int,
  entrypoints : ShaderEntrypoints,
  unit : ShaderUnit,
) -> String {
  let mut seed = 146959810
  seed = mix_hash(seed, preprocessed_source.hash())
  seed = mix_hash(seed, debug_name.hash())
  seed = mix_hash(seed, entrypoints.vertex.hash())
  seed = mix_hash(seed, entrypoints.fragment.hash())
  seed = mix_hash(seed, src_image_count)
  seed = mix_hash(
    seed,
    match unit {
      ShaderUnit::Pixels => 1
      ShaderUnit::Texels => 2
    },
  )
  seed.to_string()
}

///|
fn normalized_dword_count(value : Int) -> Int {
  if value <= 0 {
    0
  } else {
    value
  }
}

///|
fn layout_entry_count(layout : UniformLayout) -> Int {
  let names_len = layout.names.length()
  let counts_len = layout.dword_counts.length()
  if names_len <= counts_len {
    names_len
  } else {
    counts_len
  }
}

///|
fn normalized_preserved_prefix_dwords(layout : UniformLayout) -> Int {
  if layout.preserved_prefix_dwords <= 0 {
    0
  } else {
    layout.preserved_prefix_dwords
  }
}

///|
fn expected_user_uniform_dwords(layout : UniformLayout) -> Int {
  let mut total = 0
  let entry_count = layout_entry_count(layout)
  for i in 0..<entry_count {
    total = total + normalized_dword_count(layout.dword_counts[i])
  }
  total
}

///|
fn normalize_uniform_length(
  layout : UniformLayout,
  uniforms : PackedUniforms,
) -> PackedUniforms {
  let expected_preserved = normalized_preserved_prefix_dwords(layout)
  let expected_user = expected_user_uniform_dwords(layout)
  let dwords : Array[Int] = []
  for i in 0..<expected_preserved {
    if i < uniforms.dwords.length() {
      dwords.push(uniforms.dwords[i])
    } else {
      dwords.push(0)
    }
  }
  let user_start = if uniforms.dwords.length() > expected_user {
    uniforms.dwords.length() - expected_user
  } else {
    0
  }
  for i in 0..<expected_user {
    let index = user_start + i
    if index < uniforms.dwords.length() {
      dwords.push(uniforms.dwords[index])
    } else {
      dwords.push(0)
    }
  }
  { dwords, }
}

///|
fn is_identifier_char(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') ||
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '_'
}

///|
fn contains_uniform_identifier(source : String, name : String) -> Bool {
  let source_chars = source.to_array()
  let name_chars = name.to_array()
  let source_len = source_chars.length()
  let name_len = name_chars.length()
  if name_len == 0 || source_len < name_len {
    false
  } else {
    for i in 0..<(source_len - name_len + 1) {
      let mut matched = true
      for j in 0..<name_len {
        if source_chars[i + j] != name_chars[j] {
          matched = false
          break
        }
      }
      if matched {
        let left_ok = if i == 0 {
          true
        } else {
          !is_identifier_char(source_chars[i - 1])
        }
        let right_index = i + name_len
        let right_ok = if right_index >= source_len {
          true
        } else {
          !is_identifier_char(source_chars[right_index])
        }
        if left_ok && right_ok {
          return true
        }
      }
    }
    false
  }
}

///|
pub impl ShaderFrontend for BasicShaderFrontend with compile_ir(_self, request) {
  let src_image_count = normalized_src_image_count(request.src_image_count)
  let unit = resolve_shader_unit(request)
  let noperspective = parse_kage_noperspective_directive(request.source)
  let source = preprocess_shader_source(
    request.source,
    unit,
    request.entrypoints,
    request.debug_name,
  )
  let hash = {
    value: calc_request_hash_value(
      source,
      request.debug_name,
      src_image_count,
      request.entrypoints,
      unit,
    ),
  }
  {
    source,
    unit,
    noperspective,
    src_image_count,
    entrypoints: request.entrypoints,
    debug_name: request.debug_name,
    source_hash: hash,
  }
}

///|
pub impl ShaderFrontend for BasicShaderFrontend with calc_source_hash(
  _self,
  request,
) {
  let src_image_count = normalized_src_image_count(request.src_image_count)
  let unit = resolve_shader_unit(request)
  let source = preprocess_shader_source(
    request.source,
    unit,
    request.entrypoints,
    request.debug_name,
  )
  {
    value: calc_request_hash_value(
      source,
      request.debug_name,
      src_image_count,
      request.entrypoints,
      unit,
    ),
  }
}

///|
pub impl UniformCanonicalizer for BasicUniformCanonicalizer with append_user_uniforms(
  _self,
  layout,
  uniforms,
) {
  let dwords : Array[Int] = []
  let entry_count = layout_entry_count(layout)
  for i in 0..<entry_count {
    let name = layout.names[i]
    let expected = normalized_dword_count(layout.dword_counts[i])
    match find_named_uniform(uniforms, name) {
      Some(value) => {
        let encoded = uniform_to_dwords(value)
        let mut written = 0
        for v in encoded {
          if written >= expected {
            break
          }
          dwords.push(v)
          written = written + 1
        }
        while written < expected {
          dwords.push(0)
          written = written + 1
        }
      }
      None =>
        for _ in 0..<expected {
          dwords.push(0)
        }
    }
  }
  { dwords, }
}

///|
pub impl UniformCanonicalizer for BasicUniformCanonicalizer with prepend_preserved_uniforms(
  _self,
  uniforms,
  context,
) {
  let prefix : Array[Int] = [
    context.dst_texture_size.width,
    context.dst_texture_size.height,
  ]
  prefix.push(context.dst_region.x.to_int())
  prefix.push(context.dst_region.y.to_int())
  prefix.push(context.dst_region.width.to_int())
  prefix.push(context.dst_region.height.to_int())
  for size in context.src_texture_sizes {
    prefix.push(size.width)
    prefix.push(size.height)
  }
  for region in context.src_regions {
    prefix.push(region.x.to_int())
    prefix.push(region.y.to_int())
    prefix.push(region.width.to_int())
    prefix.push(region.height.to_int())
  }
  let out = prefix
  for value in uniforms.dwords {
    out.push(value)
  }
  { dwords: out }
}

///|
pub impl UniformCanonicalizer for BasicUniformCanonicalizer with filter_unused_uniforms(
  _self,
  ir,
  layout,
  uniforms,
) {
  let expected_user = expected_user_uniform_dwords(layout)
  let entry_count = layout_entry_count(layout)
  let user_start = if uniforms.dwords.length() > expected_user {
    uniforms.dwords.length() - expected_user
  } else {
    0
  }
  let out : Array[Int] = []
  for value in uniforms.dwords {
    out.push(value)
  }
  let mut cursor = 0
  for i in 0..<entry_count {
    let dword_count = normalized_dword_count(layout.dword_counts[i])
    let name = layout.names[i]
    if !contains_uniform_identifier(ir.source, name) {
      for j in 0..<dword_count {
        let index = user_start + cursor + j
        if index < out.length() {
          out[index] = 0
        }
      }
    }
    cursor = cursor + dword_count
  }
  { dwords: out }
}

///|
fn builtin_filter_eq(
  lhs : BuiltinShaderFilter,
  rhs : BuiltinShaderFilter,
) -> Bool {
  match lhs {
    BuiltinShaderFilter::Nearest =>
      match rhs {
        BuiltinShaderFilter::Nearest => true
        _ => false
      }
    BuiltinShaderFilter::Linear =>
      match rhs {
        BuiltinShaderFilter::Linear => true
        _ => false
      }
    BuiltinShaderFilter::Pixelated =>
      match rhs {
        BuiltinShaderFilter::Pixelated => true
        _ => false
      }
  }
}

///|
fn builtin_address_eq(
  lhs : BuiltinShaderAddress,
  rhs : BuiltinShaderAddress,
) -> Bool {
  match lhs {
    BuiltinShaderAddress::Unsafe =>
      match rhs {
        BuiltinShaderAddress::Unsafe => true
        _ => false
      }
    BuiltinShaderAddress::ClampToZero =>
      match rhs {
        BuiltinShaderAddress::ClampToZero => true
        _ => false
      }
    BuiltinShaderAddress::ClampToEdge =>
      match rhs {
        BuiltinShaderAddress::ClampToEdge => true
        _ => false
      }
    BuiltinShaderAddress::Repeat =>
      match rhs {
        BuiltinShaderAddress::Repeat => true
        _ => false
      }
    BuiltinShaderAddress::MirrorRepeat =>
      match rhs {
        BuiltinShaderAddress::MirrorRepeat => true
        _ => false
      }
  }
}

///|
fn builtin_shader_key_eq(
  lhs : BuiltinShaderKey,
  rhs : BuiltinShaderKey,
) -> Bool {
  builtin_filter_eq(lhs.filter, rhs.filter) &&
  builtin_address_eq(lhs.address, rhs.address) &&
  lhs.use_color_m == rhs.use_color_m
}

///|
fn sampler_spec_eq(lhs : SamplerSpec, rhs : SamplerSpec) -> Bool {
  builtin_filter_eq(lhs.filter, rhs.filter) &&
  builtin_address_eq(lhs.address_u, rhs.address_u) &&
  builtin_address_eq(lhs.address_v, rhs.address_v)
}

///|
fn builtin_shader_key_ex_eq(
  lhs : BuiltinShaderKeyEx,
  rhs : BuiltinShaderKeyEx,
) -> Bool {
  sampler_spec_eq(lhs.sampler, rhs.sampler) &&
  lhs.use_color_m == rhs.use_color_m
}

///|
fn find_builtin_shader_cache_index(
  cache : Array[BuiltinShaderSourceCacheEntry],
  key : BuiltinShaderKey,
) -> Int? {
  for i in 0..<cache.length() {
    if builtin_shader_key_eq(cache[i].key, key) {
      return Some(i)
    }
  }
  None
}

///|
fn find_builtin_shader_cache_ex_index(
  cache : Array[BuiltinShaderSourceCacheEntryEx],
  key : BuiltinShaderKeyEx,
) -> Int? {
  for i in 0..<cache.length() {
    if builtin_shader_key_ex_eq(cache[i].key, key) {
      return Some(i)
    }
  }
  None
}

///|
fn trim_builtin_shader_cache_ex(repo : BasicBuiltinShaderSourceRepo) -> Unit {
  if repo.max_cache_entries <= 0 {
    repo.cache_ex = []
  } else {
    let total = repo.cache.length() + repo.cache_ex.length()
    let mut remaining = total
    while remaining > repo.max_cache_entries {
      // Find oldest across both caches
      let mut oldest_tick = 2147483647
      let mut evict_classic = true
      let mut evict_index = -1
      for i in 0..<repo.cache.length() {
        if repo.cache[i].last_used_tick < oldest_tick {
          oldest_tick = repo.cache[i].last_used_tick
          evict_classic = true
          evict_index = i
        }
      }
      for i in 0..<repo.cache_ex.length() {
        if repo.cache_ex[i].last_used_tick < oldest_tick {
          oldest_tick = repo.cache_ex[i].last_used_tick
          evict_classic = false
          evict_index = i
        }
      }
      if evict_index < 0 {
        break
      }
      if evict_classic {
        let next : Array[BuiltinShaderSourceCacheEntry] = []
        for i in 0..<repo.cache.length() {
          if i != evict_index {
            next.push(repo.cache[i])
          }
        }
        repo.cache = next
      } else {
        let next : Array[BuiltinShaderSourceCacheEntryEx] = []
        for i in 0..<repo.cache_ex.length() {
          if i != evict_index {
            next.push(repo.cache_ex[i])
          }
        }
        repo.cache_ex = next
      }
      remaining = remaining - 1
    }
  }
}

///|
fn trim_builtin_shader_cache(repo : BasicBuiltinShaderSourceRepo) -> Unit {
  if repo.max_cache_entries <= 0 {
    repo.cache = []
  } else {
    while repo.cache.length() > repo.max_cache_entries {
      let mut oldest_index = 0
      let mut oldest_tick = repo.cache[0].last_used_tick
      for i in 1..<repo.cache.length() {
        if repo.cache[i].last_used_tick < oldest_tick {
          oldest_tick = repo.cache[i].last_used_tick
          oldest_index = i
        }
      }
      let next : Array[BuiltinShaderSourceCacheEntry] = []
      for i in 0..<repo.cache.length() {
        if i != oldest_index {
          next.push(repo.cache[i])
        }
      }
      repo.cache = next
    }
  }
}

///|
fn builtin_filter_tag(filter : BuiltinShaderFilter) -> String {
  match filter {
    BuiltinShaderFilter::Nearest => "nearest"
    BuiltinShaderFilter::Linear => "linear"
    BuiltinShaderFilter::Pixelated => "pixelated"
  }
}

///|
fn builtin_address_tag(address : BuiltinShaderAddress) -> String {
  match address {
    BuiltinShaderAddress::Unsafe => "unsafe"
    BuiltinShaderAddress::ClampToZero => "clamp_to_zero"
    BuiltinShaderAddress::ClampToEdge => "clamp_to_edge"
    BuiltinShaderAddress::Repeat => "repeat"
    BuiltinShaderAddress::MirrorRepeat => "mirror_repeat"
  }
}

///|
fn builtin_address_snippet(address : BuiltinShaderAddress) -> String {
  match address {
    BuiltinShaderAddress::Unsafe => "// address: unsafe\n  let sample_uv = uv;"
    BuiltinShaderAddress::ClampToZero =>
      "if uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 {\n    return vec4f(0.0, 0.0, 0.0, 0.0);\n  }\n  let sample_uv = uv;"
    BuiltinShaderAddress::ClampToEdge =>
      "let sample_uv = clamp(uv, vec2f(0.0), vec2f(1.0));"
    BuiltinShaderAddress::Repeat =>
      "// address: repeat\n  let sample_uv = fract(uv);"
    BuiltinShaderAddress::MirrorRepeat =>
      "// address: mirror_repeat\n  let sample_uv = abs(fract(uv * 0.5) * 2.0 - 1.0);"
  }
}

///|
/// Generate per-axis address snippet for SamplerSpec.
fn builtin_address_snippet_per_axis(spec : SamplerSpec) -> String {
  if builtin_address_eq(spec.address_u, spec.address_v) {
    builtin_address_snippet(spec.address_u)
  } else {
    let u_snippet = single_axis_address_expr(spec.address_u, "uv.x")
    let v_snippet = single_axis_address_expr(spec.address_v, "uv.y")
    "let sample_uv = vec2f(\{u_snippet}, \{v_snippet});"
  }
}

///|
fn single_axis_address_expr(
  address : BuiltinShaderAddress,
  coord : String,
) -> String {
  match address {
    BuiltinShaderAddress::Unsafe => coord
    BuiltinShaderAddress::ClampToZero =>
      "select(0.0, \{coord}, \{coord} >= 0.0 && \{coord} <= 1.0)"
    BuiltinShaderAddress::ClampToEdge => "clamp(\{coord}, 0.0, 1.0)"
    BuiltinShaderAddress::Repeat => "fract(\{coord})"
    BuiltinShaderAddress::MirrorRepeat =>
      "abs(fract(\{coord} * 0.5) * 2.0 - 1.0)"
  }
}

///|
fn builtin_sample_snippet(filter : BuiltinShaderFilter) -> String {
  match filter {
    BuiltinShaderFilter::Nearest =>
      "textureSampleLevel(tex, nearest_sampler, sample_uv, 0.0)"
    BuiltinShaderFilter::Linear =>
      "textureSample(tex, linear_sampler, sample_uv)"
    BuiltinShaderFilter::Pixelated =>
      "textureSampleLevel(tex, nearest_sampler, floor(sample_uv * vec2f(256.0, 256.0)) / vec2f(256.0, 256.0), 0.0)"
  }
}

///|
fn builtin_color_m_snippet(use_color_m : Bool) -> String {
  if use_color_m {
    "let color_m = mat4x4f(\n" +
    "    vec4f(1.0, 0.0, 0.0, 0.0),\n" +
    "    vec4f(0.0, 1.0, 0.0, 0.0),\n" +
    "    vec4f(0.0, 0.0, 1.0, 0.0),\n" +
    "    vec4f(0.0, 0.0, 0.0, 1.0),\n" +
    "  );\n" +
    "  color = color_m * color;"
  } else {
    "// color matrix disabled"
  }
}

///|
fn build_builtin_shader_source(key : BuiltinShaderKey) -> String {
  let address_snippet = builtin_address_snippet(key.address)
  let sample_snippet = builtin_sample_snippet(key.filter)
  let color_m_snippet = builtin_color_m_snippet(key.use_color_m)
  let color_m_tag = if key.use_color_m { "on" } else { "off" }
  let header = "// kagura builtin shader\n" +
    "// filter:\{builtin_filter_tag(key.filter)}\n" +
    "// address:\{builtin_address_tag(key.address)}\n" +
    "// color_m:\{color_m_tag}\n"
  let bindings = "@group(0) @binding(0) var tex: texture_2d<f32>;\n" +
    "@group(0) @binding(1) var nearest_sampler: sampler;\n" +
    "@group(0) @binding(2) var linear_sampler: sampler;\n\n"
  let structs = "struct VertexOutput {\n" +
    "  @builtin(position) pos: vec4f,\n" +
    "  @location(0) uv: vec2f,\n" +
    "};\n\n"
  let body = "@fragment\n" +
    "fn fs_main(in: VertexOutput) -> @location(0) vec4f {\n" +
    "  let uv = in.uv;\n" +
    "  \{address_snippet}\n" +
    "  var color = \{sample_snippet};\n" +
    "  \{color_m_snippet}\n" +
    "  return color;\n" +
    "}\n"
  header + bindings + structs + body
}

///|
/// Build shader source from extended key with per-axis address support.
pub fn build_builtin_shader_source_ex(key : BuiltinShaderKeyEx) -> String {
  let address_snippet = builtin_address_snippet_per_axis(key.sampler)
  let sample_snippet = builtin_sample_snippet(key.sampler.filter)
  let color_m_snippet = builtin_color_m_snippet(key.use_color_m)
  let color_m_tag = if key.use_color_m { "on" } else { "off" }
  let header = "// kagura builtin shader\n" +
    "// filter:\{builtin_filter_tag(key.sampler.filter)}\n" +
    "// address_u:\{builtin_address_tag(key.sampler.address_u)}\n" +
    "// address_v:\{builtin_address_tag(key.sampler.address_v)}\n" +
    "// color_m:\{color_m_tag}\n"
  let bindings = "@group(0) @binding(0) var tex: texture_2d<f32>;\n" +
    "@group(0) @binding(1) var nearest_sampler: sampler;\n" +
    "@group(0) @binding(2) var linear_sampler: sampler;\n\n"
  let structs = "struct VertexOutput {\n" +
    "  @builtin(position) pos: vec4f,\n" +
    "  @location(0) uv: vec2f,\n" +
    "};\n\n"
  let body = "@fragment\n" +
    "fn fs_main(in: VertexOutput) -> @location(0) vec4f {\n" +
    "  let uv = in.uv;\n" +
    "  \{address_snippet}\n" +
    "  var color = \{sample_snippet};\n" +
    "  \{color_m_snippet}\n" +
    "  return color;\n" +
    "}\n"
  header + bindings + structs + body
}

///|
pub impl BuiltinShaderSourceRepo for BasicBuiltinShaderSourceRepo with shader_source(
  self,
  key,
) {
  self.tick = self.tick + 1
  match find_builtin_shader_cache_index(self.cache, key) {
    Some(index) => {
      let entry = self.cache[index]
      self.cache[index] = {
        key: entry.key,
        source: entry.source,
        last_used_tick: self.tick,
      }
      self.hit_count = self.hit_count + 1
      entry.source
    }
    None => {
      let source = build_builtin_shader_source(key)
      self.cache.push({ key, source, last_used_tick: self.tick })
      self.miss_count = self.miss_count + 1
      trim_builtin_shader_cache(self)
      source
    }
  }
}

///|
pub impl BuiltinShaderSourceRepo for BasicBuiltinShaderSourceRepo with shader_source_ex(
  self,
  key,
) {
  self.tick = self.tick + 1
  match find_builtin_shader_cache_ex_index(self.cache_ex, key) {
    Some(index) => {
      let entry = self.cache_ex[index]
      self.cache_ex[index] = {
        key: entry.key,
        source: entry.source,
        last_used_tick: self.tick,
      }
      self.hit_count = self.hit_count + 1
      entry.source
    }
    None => {
      let source = build_builtin_shader_source_ex(key)
      self.cache_ex.push({ key, source, last_used_tick: self.tick })
      self.miss_count = self.miss_count + 1
      trim_builtin_shader_cache_ex(self)
      source
    }
  }
}

///|
pub fn builtin_filter_to_int(filter : BuiltinShaderFilter) -> Int {
  match filter {
    BuiltinShaderFilter::Nearest => 0
    BuiltinShaderFilter::Linear => 1
    BuiltinShaderFilter::Pixelated => 2
  }
}

///|
pub fn builtin_filter_from_int(value : Int) -> BuiltinShaderFilter {
  match value {
    1 => BuiltinShaderFilter::Linear
    2 => BuiltinShaderFilter::Pixelated
    _ => BuiltinShaderFilter::Nearest
  }
}

///|
pub fn builtin_address_to_int(address : BuiltinShaderAddress) -> Int {
  match address {
    BuiltinShaderAddress::Unsafe => 0
    BuiltinShaderAddress::ClampToZero => 1
    BuiltinShaderAddress::ClampToEdge => 2
    BuiltinShaderAddress::Repeat => 3
    BuiltinShaderAddress::MirrorRepeat => 4
  }
}

///|
pub fn builtin_address_from_int(value : Int) -> BuiltinShaderAddress {
  match value {
    1 => BuiltinShaderAddress::ClampToZero
    2 => BuiltinShaderAddress::ClampToEdge
    3 => BuiltinShaderAddress::Repeat
    4 => BuiltinShaderAddress::MirrorRepeat
    _ => BuiltinShaderAddress::Unsafe
  }
}

///|
pub fn default_shader_entrypoints() -> ShaderEntrypoints {
  { vertex: "vs_main", fragment: "fs_main" }
}

///|
pub fn parse_kage_noperspective_directive(source : String) -> Bool {
  let chars = source.to_array()
  let directive = "//kage:noperspective".to_array()
  let chars_len = chars.length()
  let directive_len = directive.length()
  if chars_len < directive_len {
    false
  } else {
    for i in 0..<(chars_len - directive_len + 1) {
      if char_array_starts_with(chars, i, directive) {
        // Check that it's at line start or preceded by newline
        let at_start = i == 0 || chars[i - 1] == '\n'
        if at_start {
          return true
        }
      }
    }
    false
  }
}
