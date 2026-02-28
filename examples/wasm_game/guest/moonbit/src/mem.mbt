///| Load a 32-bit integer from linear memory at byte offset.
extern "wasm" fn mem_load32(offset : Int) -> Int =
  #|(func (param i32) (result i32) (i32.load (local.get 0)))

///| Store a 32-bit integer to linear memory at byte offset.
extern "wasm" fn mem_store32(offset : Int, value : Int) =
  #|(func (param i32 i32) (i32.store (local.get 0) (local.get 1)))

///| Load a 64-bit float from linear memory at byte offset.
extern "wasm" fn mem_load_f64(offset : Int) -> Double =
  #|(func (param i32) (result f64) (f64.load (local.get 0)))

///| Store a 32-bit float to linear memory at byte offset.
extern "wasm" fn mem_store_f32(offset : Int, value : Float) =
  #|(func (param i32 f32) (f32.store (local.get 0) (local.get 1)))

///| Store a byte to linear memory.
extern "wasm" fn mem_store8(offset : Int, value : Int) =
  #|(func (param i32 i32) (i32.store8 (local.get 0) (local.get 1)))

// Bump allocator
// Allocator state at address 0. Heap starts at 4096 (within first 64KB page).
let heap_base : Int = 4096

///| Initialize the bump allocator.
fn bump_init() -> Unit {
  mem_store32(0, heap_base)
}

///| Allocate `size` bytes contiguously (no alignment padding).
fn bump_alloc(size : Int) -> Int {
  let current = mem_load32(0)
  mem_store32(0, current + size)
  current
}

///| Reset the bump allocator (call at start of each frame).
fn bump_reset() -> Unit {
  mem_store32(0, heap_base)
}
