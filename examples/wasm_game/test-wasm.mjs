// Smoke test for WASM guest modules
// Usage: node examples/wasm_game/test-wasm.mjs [moonbit|rust|all]
import { readFile, access } from "node:fs/promises";

const MOONBIT_WASM =
  "examples/wasm_game/guest/moonbit/_build/wasm/debug/build/wasm_game_guest.wasm";
const RUST_WASM =
  "examples/wasm_game/guest/rust/target/wasm32-unknown-unknown/release/kagura_wasm_guest_rust.wasm";

function writeEmptyInput(memory, ptr) {
  const dv = new DataView(memory.buffer);
  dv.setFloat64(ptr, 0, true);
  dv.setFloat64(ptr + 8, 0, true);
  dv.setFloat64(ptr + 16, 0, true);
  dv.setFloat64(ptr + 24, 0, true);
  dv.setInt32(ptr + 32, 0, true);
  dv.setInt32(ptr + 36, 0, true);
  dv.setInt32(ptr + 40, 0, true);
  dv.setInt32(ptr + 44, 0, true);
}

function assert(cond, msg) {
  if (!cond) throw new Error(`Assertion failed: ${msg}`);
}

async function testWasm(path, label) {
  console.log(`\n=== ${label} ===`);
  const buf = await readFile(path);
  const { instance } = await WebAssembly.instantiate(buf, {});
  const { kagura_init, kagura_alloc, kagura_update, kagura_draw, memory, _start } =
    instance.exports;

  if (_start) _start();

  // kagura_init: returns valid GameConfig
  const configPtr = kagura_init();
  const dv = new DataView(memory.buffer);
  const width = dv.getInt32(configPtr, true);
  const height = dv.getInt32(configPtr + 4, true);
  const titleLen = dv.getInt32(configPtr + 8, true);
  const title = new TextDecoder().decode(
    new Uint8Array(memory.buffer, configPtr + 12, titleLen),
  );
  assert(width === 320, `width=${width}`);
  assert(height === 240, `height=${height}`);
  assert(titleLen > 0, `titleLen=${titleLen}`);
  console.log(`  config: ${width}x${height} "${title}"`);

  // kagura_update + kagura_draw: initial state (sky+ground+bird)
  const inputSize = 48;
  const inputPtr = kagura_alloc(inputSize);
  writeEmptyInput(memory, inputPtr);
  kagura_update(inputPtr, inputSize);
  const drawPtr = kagura_draw();
  const cmdCount = dv.getInt32(drawPtr, true);
  assert(cmdCount === 3, `initial cmdCount=${cmdCount}, expected 3`);

  // Verify draw command structure
  let offset = drawPtr + 4;
  const expectedColors = [
    [135, 206, 235, 255], // sky (#87CEEB)
    [139, 69, 19, 255],   // ground (#8B4513)
    [255, 215, 0, 255],   // bird (#FFD700)
  ];
  for (let i = 0; i < cmdCount; i++) {
    const v = dv.getInt32(offset, true);
    const idx = dv.getInt32(offset + 4, true);
    assert(v === 4, `cmd[${i}] vertexCount=${v}`);
    assert(idx === 6, `cmd[${i}] indexCount=${idx}`);
    const r = dv.getInt32(offset + 12, true);
    const g = dv.getInt32(offset + 16, true);
    const b = dv.getInt32(offset + 20, true);
    const a = dv.getInt32(offset + 24, true);
    const [er, eg, eb, ea] = expectedColors[i];
    assert(
      r === er && g === eg && b === eb && a === ea,
      `cmd[${i}] color=(${r},${g},${b},${a}) expected (${er},${eg},${eb},${ea})`,
    );
    offset += 28 + v * 16 + idx * 4;
  }
  console.log("  draw commands: OK (3 cmds, correct colors)");

  // 60 frame cycles without crash
  for (let frame = 0; frame < 60; frame++) {
    const ptr = kagura_alloc(inputSize);
    writeEmptyInput(memory, ptr);
    kagura_update(ptr, inputSize);
    kagura_draw();
  }
  console.log("  60 frame cycles: OK");

  // Space key starts game (game_mode 0→1)
  const ptr3 = kagura_alloc(52);
  const dv3 = new DataView(memory.buffer);
  dv3.setFloat64(ptr3, 0, true);
  dv3.setFloat64(ptr3 + 8, 0, true);
  dv3.setFloat64(ptr3 + 16, 0, true);
  dv3.setFloat64(ptr3 + 24, 0, true);
  dv3.setInt32(ptr3 + 32, 1, true); // 1 key
  dv3.setInt32(ptr3 + 36, 32, true); // Space
  dv3.setInt32(ptr3 + 40, 0, true);
  dv3.setInt32(ptr3 + 44, 0, true);
  dv3.setInt32(ptr3 + 48, 0, true);
  kagura_update(ptr3, 52);
  const drawPtr2 = kagura_draw();
  const cmdCount2 = new DataView(memory.buffer).getInt32(drawPtr2, true);
  assert(cmdCount2 >= 3, `after space cmdCount=${cmdCount2}`);
  console.log("  space key input: OK");

  console.log(`  ${label}: PASS`);
}

async function fileExists(path) {
  try { await access(path); return true; } catch { return false; }
}

const arg = process.argv[2] || "all";
let failed = false;

const targets = [];
if (arg === "all" || arg === "moonbit") targets.push([MOONBIT_WASM, "MoonBit"]);
if (arg === "all" || arg === "rust") targets.push([RUST_WASM, "Rust"]);

for (const [path, label] of targets) {
  if (!(await fileExists(path))) {
    console.log(`\n=== ${label} === SKIP (not built)`);
    continue;
  }
  try {
    await testWasm(path, label);
  } catch (e) {
    console.error(`\n  ${label}: FAIL - ${e.message}`);
    failed = true;
  }
}

console.log(failed ? "\nSome tests FAILED" : "\nAll tests PASSED");
process.exit(failed ? 1 : 0);
