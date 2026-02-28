///| Input state read from shared memory.
struct InputState {
  cursor_x : Double
  cursor_y : Double
  wheel_x : Double
  wheel_y : Double
  keys : Array[Int]
  mouse_btns : Array[Int]
}

///| Read InputSnapshot from linear memory at (ptr, len).
fn read_input(ptr : Int) -> InputState {
  let cursor_x = mem_load_f64(ptr)
  let cursor_y = mem_load_f64(ptr + 8)
  let wheel_x = mem_load_f64(ptr + 16)
  let wheel_y = mem_load_f64(ptr + 24)
  let key_count = mem_load32(ptr + 32)
  let keys : Array[Int] = []
  for i = 0; i < key_count; i = i + 1 {
    keys.push(mem_load32(ptr + 36 + i * 4))
  }
  let mouse_offset = ptr + 36 + key_count * 4
  let mouse_btn_count = mem_load32(mouse_offset)
  let mouse_btns : Array[Int] = []
  for i = 0; i < mouse_btn_count; i = i + 1 {
    mouse_btns.push(mem_load32(mouse_offset + 4 + i * 4))
  }
  { cursor_x, cursor_y, wheel_x, wheel_y, keys, mouse_btns }
}

///| Check if a key code is currently pressed.
fn is_key_pressed(input : InputState, key_code : Int) -> Bool {
  for k in input.keys {
    if k == key_code {
      return true
    }
  }
  false
}

///| Check if any mouse button is pressed.
fn is_mouse_pressed(input : InputState) -> Bool {
  input.mouse_btns.length() > 0
}

///| A single draw command to be sent to the host.
struct DrawCmd {
  vertex_count : Int
  index_count : Int
  src_image_id : Int
  uniform_r : Int
  uniform_g : Int
  uniform_b : Int
  uniform_a : Int
  vertices : Array[Float]
  indices : Array[Int]
}

///| Write an array of DrawCmds to linear memory and return the pointer.
fn write_draw_commands(cmds : Array[DrawCmd]) -> Int {
  let ptr = bump_alloc(4)
  mem_store32(ptr, cmds.length())
  for cmd in cmds {
    let header_size = 28
    let verts_size = cmd.vertex_count * 4 * 4 // V * 4 floats * 4 bytes
    let indices_size = cmd.index_count * 4
    let cmd_ptr = bump_alloc(header_size + verts_size + indices_size)
    mem_store32(cmd_ptr, cmd.vertex_count)
    mem_store32(cmd_ptr + 4, cmd.index_count)
    mem_store32(cmd_ptr + 8, cmd.src_image_id)
    mem_store32(cmd_ptr + 12, cmd.uniform_r)
    mem_store32(cmd_ptr + 16, cmd.uniform_g)
    mem_store32(cmd_ptr + 20, cmd.uniform_b)
    mem_store32(cmd_ptr + 24, cmd.uniform_a)
    for i = 0; i < cmd.vertices.length(); i = i + 1 {
      mem_store_f32(cmd_ptr + 28 + i * 4, cmd.vertices[i])
    }
    let idx_base = cmd_ptr + 28 + verts_size
    for i = 0; i < cmd.indices.length(); i = i + 1 {
      mem_store32(idx_base + i * 4, cmd.indices[i])
    }
  }
  ptr
}
