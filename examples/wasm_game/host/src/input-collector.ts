export interface InputSnapshot {
  cursorX: number;
  cursorY: number;
  wheelX: number;
  wheelY: number;
  keys: number[];
  mouseButtons: number[];
}

export function createInputCollector(canvas: HTMLCanvasElement) {
  const pressedKeys = new Set<number>();
  const pressedMouseButtons = new Set<number>();
  let cursorX = 0;
  let cursorY = 0;
  let wheelX = 0;
  let wheelY = 0;

  const onKeyDown = (e: KeyboardEvent) => {
    pressedKeys.add(e.keyCode);
    e.preventDefault();
  };
  const onKeyUp = (e: KeyboardEvent) => {
    pressedKeys.delete(e.keyCode);
  };
  const onMouseMove = (e: MouseEvent) => {
    const rect = canvas.getBoundingClientRect();
    cursorX = e.clientX - rect.left;
    cursorY = e.clientY - rect.top;
  };
  const onMouseDown = (e: MouseEvent) => {
    pressedMouseButtons.add(e.button);
  };
  const onMouseUp = (e: MouseEvent) => {
    pressedMouseButtons.delete(e.button);
  };
  const onWheel = (e: WheelEvent) => {
    wheelX += e.deltaX;
    wheelY += e.deltaY;
    e.preventDefault();
  };

  window.addEventListener("keydown", onKeyDown);
  window.addEventListener("keyup", onKeyUp);
  canvas.addEventListener("mousemove", onMouseMove);
  canvas.addEventListener("mousedown", onMouseDown);
  canvas.addEventListener("mouseup", onMouseUp);
  canvas.addEventListener("wheel", onWheel, { passive: false });

  return {
    snapshot(): InputSnapshot {
      const snap: InputSnapshot = {
        cursorX,
        cursorY,
        wheelX,
        wheelY,
        keys: Array.from(pressedKeys),
        mouseButtons: Array.from(pressedMouseButtons),
      };
      // Reset per-frame accumulators
      wheelX = 0;
      wheelY = 0;
      return snap;
    },
    destroy() {
      window.removeEventListener("keydown", onKeyDown);
      window.removeEventListener("keyup", onKeyUp);
      canvas.removeEventListener("mousemove", onMouseMove);
      canvas.removeEventListener("mousedown", onMouseDown);
      canvas.removeEventListener("mouseup", onMouseUp);
      canvas.removeEventListener("wheel", onWheel);
    },
  };
}
