import type { InputSnapshot } from "./input-collector";

/**
 * Serialize InputSnapshot into WASM linear memory at the given pointer.
 * Returns the total byte length written.
 *
 * Layout:
 *   0:  f64 cursor_x
 *   8:  f64 cursor_y
 *  16:  f64 wheel_x
 *  24:  f64 wheel_y
 *  32:  i32 key_count (K)
 *  36:  i32[K] keys
 *  36+K*4: i32 mouse_btn_count (M)
 *  +4: i32[M] mouse_btns
 *  ...: i32 touch_count (0)
 *  ...: i32 gamepad_count (0)
 */
export function serializeInput(
  memory: WebAssembly.Memory,
  ptr: number,
  input: InputSnapshot,
): number {
  const dv = new DataView(memory.buffer);
  dv.setFloat64(ptr, input.cursorX, true);
  dv.setFloat64(ptr + 8, input.cursorY, true);
  dv.setFloat64(ptr + 16, input.wheelX, true);
  dv.setFloat64(ptr + 24, input.wheelY, true);

  const keyCount = input.keys.length;
  dv.setInt32(ptr + 32, keyCount, true);
  for (let i = 0; i < keyCount; i++) {
    dv.setInt32(ptr + 36 + i * 4, input.keys[i], true);
  }

  let offset = ptr + 36 + keyCount * 4;
  const mouseCount = input.mouseButtons.length;
  dv.setInt32(offset, mouseCount, true);
  offset += 4;
  for (let i = 0; i < mouseCount; i++) {
    dv.setInt32(offset + i * 4, input.mouseButtons[i], true);
  }
  offset += mouseCount * 4;

  // touch_count = 0, gamepad_count = 0
  dv.setInt32(offset, 0, true);
  offset += 4;
  dv.setInt32(offset, 0, true);
  offset += 4;

  return offset - ptr;
}

/**
 * A draw command deserialized from WASM memory.
 * Compatible with kagura-gfx.js renderGpu() format.
 */
export interface DrawCommand {
  vertexData: Float32Array;
  indices: Uint32Array;
  srcImageId: number;
  uniformR: number;
  uniformG: number;
  uniformB: number;
  uniformA: number;
}

/**
 * Deserialize DrawCommands from WASM linear memory.
 *
 * Layout at ptr:
 *   0: i32 command_count
 *   Then N variable-length commands:
 *     0:  i32 vertex_count (V)
 *     4:  i32 index_count (I)
 *     8:  i32 src_image_id
 *    12:  i32 uniform_r (0-255)
 *    16:  i32 uniform_g
 *    20:  i32 uniform_b
 *    24:  i32 uniform_a
 *    28:  f32[V*4] vertices (x,y,u,v)
 *    28+V*16: i32[I] indices
 */
export function deserializeDrawCommands(
  memory: WebAssembly.Memory,
  ptr: number,
): DrawCommand[] {
  const dv = new DataView(memory.buffer);
  const cmdCount = dv.getInt32(ptr, true);
  const commands: DrawCommand[] = [];
  let offset = ptr + 4;

  for (let i = 0; i < cmdCount; i++) {
    const vertexCount = dv.getInt32(offset, true);
    const indexCount = dv.getInt32(offset + 4, true);
    const srcImageId = dv.getInt32(offset + 8, true);
    const uniformR = dv.getInt32(offset + 12, true) / 255;
    const uniformG = dv.getInt32(offset + 16, true) / 255;
    const uniformB = dv.getInt32(offset + 20, true) / 255;
    const uniformA = dv.getInt32(offset + 24, true) / 255;

    const vertFloatCount = vertexCount * 4;
    const vertByteOffset = offset + 28;
    const vertexData = new Float32Array(
      memory.buffer,
      vertByteOffset,
      vertFloatCount,
    );

    const idxByteOffset = vertByteOffset + vertFloatCount * 4;
    const indices = new Uint32Array(memory.buffer, idxByteOffset, indexCount);

    commands.push({
      vertexData: new Float32Array(vertexData),
      indices: new Uint32Array(indices),
      srcImageId,
      uniformR,
      uniformG,
      uniformB,
      uniformA,
    });

    offset = idxByteOffset + indexCount * 4;
  }

  return commands;
}

/**
 * Calculate the byte size needed for an InputSnapshot.
 */
export function inputByteSize(input: InputSnapshot): number {
  return (
    32 + // cursor_x, cursor_y, wheel_x, wheel_y (4 x f64)
    4 + // key_count
    input.keys.length * 4 +
    4 + // mouse_btn_count
    input.mouseButtons.length * 4 +
    4 + // touch_count
    4 // gamepad_count
  );
}
