///|
let web_canvas_selector : Ref[String] = Ref::new("#app")

///|
let web_hooks_installed : Ref[Bool] = Ref::new(false)

///|
let web_fallback_to_webgl : Ref[Bool] = Ref::new(false)

///|
extern "js" fn js_prepare_surface(
  selector : String,
  fallback_width : Int,
  fallback_height : Int,
) -> Bool =
  #| (selector, fallbackWidth, fallbackHeight) => {
  #|   const root = globalThis;
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {
  #|     nextSurfaceId: 100,
  #|     selector: "#app",
  #|     canvas: null,
  #|     surfaceId: 0,
  #|     width: fallbackWidth,
  #|     height: fallbackHeight,
  #|     dpr: 1,
  #|     webgpu: {
  #|       context: null,
  #|       device: null,
  #|       format: "bgra8unorm",
  #|       pending: null,
  #|       pipeline: null,
  #|       pipelineFormat: "",
  #|       presentScheduled: false,
  #|       clear: [0, 0, 0, 1],
  #|       drawCalls: 0,
  #|       lastError: "",
  #|     },
  #|     webgl2: {
  #|       context: null,
  #|       program: null,
  #|       vao: null,
  #|       presentScheduled: false,
  #|       clear: [0, 0, 0, 1],
  #|       drawCalls: 0,
  #|     },
  #|   });
  #|   state.selector = selector;
  #|   const doc = typeof document === "undefined" ? null : document;
  #|   if (doc == null || typeof doc.querySelector !== "function") {
  #|     state.canvas = null;
  #|     state.width = fallbackWidth;
  #|     state.height = fallbackHeight;
  #|     state.dpr = 1;
  #|     state.surfaceId = 1;
  #|     return true;
  #|   }
  #|   const canvas = doc.querySelector(selector);
  #|   if (canvas == null || typeof canvas.getContext !== "function") {
  #|     return false;
  #|   }
  #|   const CanvasType = typeof HTMLCanvasElement === "undefined" ? null : HTMLCanvasElement;
  #|   if (CanvasType != null && !(canvas instanceof CanvasType)) {
  #|     return false;
  #|   }
  #|   const dpr = Number(root.devicePixelRatio ?? 1) || 1;
  #|   const rect = typeof canvas.getBoundingClientRect === "function"
  #|     ? canvas.getBoundingClientRect()
  #|     : { width: fallbackWidth, height: fallbackHeight };
  #|   const cssWidth = rect.width > 0 ? rect.width : fallbackWidth;
  #|   const cssHeight = rect.height > 0 ? rect.height : fallbackHeight;
  #|   const pixelWidth = Math.max(1, Math.round(cssWidth * dpr));
  #|   const pixelHeight = Math.max(1, Math.round(cssHeight * dpr));
  #|   if (canvas.width !== pixelWidth) {
  #|     canvas.width = pixelWidth;
  #|   }
  #|   if (canvas.height !== pixelHeight) {
  #|     canvas.height = pixelHeight;
  #|   }
  #|   if (canvas.__gameEngineSurfaceId == null) {
  #|     canvas.__gameEngineSurfaceId = state.nextSurfaceId++;
  #|   }
  #|   state.canvas = canvas;
  #|   state.surfaceId = Number(canvas.__gameEngineSurfaceId) | 0;
  #|   state.width = pixelWidth;
  #|   state.height = pixelHeight;
  #|   state.dpr = dpr;
  #|   return true;
  #| }

///|
extern "js" fn js_surface_id() -> Int =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   return state == null ? 1 : (Number(state.surfaceId ?? 1) | 0);
  #| }

///|
extern "js" fn js_surface_width(fallback_width : Int) -> Int =
  #| (fallbackWidth) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return fallbackWidth;
  #|   return Math.max(1, Number(state.width ?? fallbackWidth) | 0);
  #| }

///|
extern "js" fn js_surface_height(fallback_height : Int) -> Int =
  #| (fallbackHeight) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return fallbackHeight;
  #|   return Math.max(1, Number(state.height ?? fallbackHeight) | 0);
  #| }

///|
extern "js" fn js_surface_dpr() -> Double =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 1;
  #|   return Number(state.dpr ?? 1) || 1;
  #| }

///|
extern "js" fn js_ensure_window_state(selector : String) -> Unit =
  #| (selector) => {
  #|   const root = globalThis;
  #|   const ensureState = root.__gameEngineEnsureWindowState ?? (root.__gameEngineEnsureWindowState = (nextSelector) => {
  #|     const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {
  #|       nextSurfaceId: 100,
  #|       selector: "#app",
  #|       canvas: null,
  #|       surfaceId: 0,
  #|       width: 1,
  #|       height: 1,
  #|       dpr: 1,
  #|       shouldClose: false,
  #|       fullscreen: false,
  #|       cursorMode: 0,
  #|       deviceScaleOverride: 0,
  #|       vsyncEnabled: true,
  #|       attentionRequests: 0,
  #|       interactionHooksInstalled: false,
  #|       webgpu: { context: null, device: null, format: "bgra8unorm", pending: null, pipeline: null, pipelineFormat: "", presentScheduled: false, clear: [0, 0, 0, 1], drawCalls: 0, lastError: "" },
  #|       webgl2: { context: null, program: null, vao: null, presentScheduled: false, clear: [0, 0, 0, 1], drawCalls: 0 },
  #|     });
  #|     if (typeof nextSelector === "string" && nextSelector.length > 0) {
  #|       state.selector = nextSelector;
  #|     }
  #|     if (state.shouldClose == null) state.shouldClose = false;
  #|     if (state.fullscreen == null) state.fullscreen = false;
  #|     if (state.cursorMode == null) state.cursorMode = 0;
  #|     if (state.deviceScaleOverride == null) state.deviceScaleOverride = 0;
  #|     if (state.vsyncEnabled == null) state.vsyncEnabled = true;
  #|     if (state.attentionRequests == null) state.attentionRequests = 0;
  #|     if (typeof state.cursorX !== "number") state.cursorX = 0;
  #|     if (typeof state.cursorY !== "number") state.cursorY = 0;
  #|     if (typeof state.wheelX !== "number") state.wheelX = 0;
  #|     if (typeof state.wheelY !== "number") state.wheelY = 0;
  #|     if (!Array.isArray(state.pressedKeys)) state.pressedKeys = [];
  #|     if (!Array.isArray(state.pressedMouseButtons)) state.pressedMouseButtons = [];
  #|     if (!Array.isArray(state.touches)) state.touches = [];
  #|     if (!Array.isArray(state.testGamepads)) state.testGamepads = [];
  #|     if (state.inputHooksInstalled == null) state.inputHooksInstalled = false;
  #|     if (state.webgpu == null) {
  #|       state.webgpu = { context: null, device: null, format: "bgra8unorm", pending: null, pipeline: null, pipelineFormat: "", presentScheduled: false, clear: [0, 0, 0, 1], drawCalls: 0, commandCount: 0, lastPipelineId: 0, lastUniformHash: 0, lastBlendMode: 1, lastDstImageId: 0, lastShaderId: 0, lastIndexOffset: 0, lastRegionCount: 0, lastTotalIndexCount: 0, lastVertexFloatCount: 0, lastIndexCount: 0, lastSrcImageCount: 0, lastUniformDwordCount: 0, lastError: "" };
  #|     } else {
  #|       if (!Array.isArray(state.webgpu.clear)) state.webgpu.clear = [0, 0, 0, 1];
  #|       if (state.webgpu.drawCalls == null) state.webgpu.drawCalls = 0;
  #|       if (state.webgpu.commandCount == null) state.webgpu.commandCount = 0;
  #|       if (state.webgpu.lastPipelineId == null) state.webgpu.lastPipelineId = 0;
  #|       if (state.webgpu.lastUniformHash == null) state.webgpu.lastUniformHash = 0;
  #|       if (state.webgpu.lastBlendMode == null) state.webgpu.lastBlendMode = 1;
  #|       if (state.webgpu.lastDstImageId == null) state.webgpu.lastDstImageId = 0;
  #|       if (state.webgpu.lastShaderId == null) state.webgpu.lastShaderId = 0;
  #|       if (state.webgpu.lastIndexOffset == null) state.webgpu.lastIndexOffset = 0;
  #|       if (state.webgpu.lastRegionCount == null) state.webgpu.lastRegionCount = 0;
  #|       if (state.webgpu.lastTotalIndexCount == null) state.webgpu.lastTotalIndexCount = 0;
  #|       if (state.webgpu.lastVertexFloatCount == null) state.webgpu.lastVertexFloatCount = 0;
  #|       if (state.webgpu.lastIndexCount == null) state.webgpu.lastIndexCount = 0;
  #|       if (state.webgpu.lastSrcImageCount == null) state.webgpu.lastSrcImageCount = 0;
  #|       if (state.webgpu.lastUniformDwordCount == null) state.webgpu.lastUniformDwordCount = 0;
  #|       if (state.webgpu.pipeline == null) state.webgpu.pipeline = null;
  #|       if (typeof state.webgpu.pipelineFormat !== "string") state.webgpu.pipelineFormat = "";
  #|       if (state.webgpu.presentScheduled == null) state.webgpu.presentScheduled = false;
  #|       if (state.webgpu.lastError == null) state.webgpu.lastError = "";
  #|     }
  #|     if (state.webgl2 == null) {
  #|       state.webgl2 = { context: null, program: null, vao: null, presentScheduled: false, clear: [0, 0, 0, 1], drawCalls: 0, commandCount: 0, lastPipelineId: 0, lastUniformHash: 0, lastBlendMode: 1, lastDstImageId: 0, lastShaderId: 0, lastIndexOffset: 0, lastRegionCount: 0, lastTotalIndexCount: 0, lastVertexFloatCount: 0, lastIndexCount: 0, lastSrcImageCount: 0, lastUniformDwordCount: 0 };
  #|     } else {
  #|       if (!Array.isArray(state.webgl2.clear)) state.webgl2.clear = [0, 0, 0, 1];
  #|       if (state.webgl2.drawCalls == null) state.webgl2.drawCalls = 0;
  #|       if (state.webgl2.commandCount == null) state.webgl2.commandCount = 0;
  #|       if (state.webgl2.lastPipelineId == null) state.webgl2.lastPipelineId = 0;
  #|       if (state.webgl2.lastUniformHash == null) state.webgl2.lastUniformHash = 0;
  #|       if (state.webgl2.lastBlendMode == null) state.webgl2.lastBlendMode = 1;
  #|       if (state.webgl2.lastDstImageId == null) state.webgl2.lastDstImageId = 0;
  #|       if (state.webgl2.lastShaderId == null) state.webgl2.lastShaderId = 0;
  #|       if (state.webgl2.lastIndexOffset == null) state.webgl2.lastIndexOffset = 0;
  #|       if (state.webgl2.lastRegionCount == null) state.webgl2.lastRegionCount = 0;
  #|       if (state.webgl2.lastTotalIndexCount == null) state.webgl2.lastTotalIndexCount = 0;
  #|       if (state.webgl2.lastVertexFloatCount == null) state.webgl2.lastVertexFloatCount = 0;
  #|       if (state.webgl2.lastIndexCount == null) state.webgl2.lastIndexCount = 0;
  #|       if (state.webgl2.lastSrcImageCount == null) state.webgl2.lastSrcImageCount = 0;
  #|       if (state.webgl2.lastUniformDwordCount == null) state.webgl2.lastUniformDwordCount = 0;
  #|       if (state.webgl2.program == null) state.webgl2.program = null;
  #|       if (state.webgl2.vao == null) state.webgl2.vao = null;
  #|       if (state.webgl2.presentScheduled == null) state.webgl2.presentScheduled = false;
  #|     }
  #|     const doc = typeof document === "undefined" ? null : document;
  #|     if (doc != null && typeof doc.querySelector === "function") {
  #|       const canvas = doc.querySelector(state.selector);
  #|       if (canvas != null) {
  #|         state.canvas = canvas;
  #|         const dpr = Number(root.devicePixelRatio ?? state.dpr ?? 1) || 1;
  #|         state.dpr = dpr > 0 ? dpr : 1;
  #|         state.fullscreen = doc.fullscreenElement === canvas;
  #|         let mode = Number(state.cursorMode ?? 0) | 0;
  #|         if (doc.pointerLockElement === canvas) {
  #|           mode = 2;
  #|         } else if (mode === 2) {
  #|           mode = canvas.style != null && canvas.style.cursor === "none" ? 1 : 0;
  #|         }
  #|         if (mode !== 1 && mode !== 2) mode = 0;
  #|         state.cursorMode = mode;
  #|         if (canvas.style != null) {
  #|           canvas.style.cursor = mode === 0 ? "" : "none";
  #|         }
  #|       }
  #|       if (!state.interactionHooksInstalled && typeof doc.addEventListener === "function") {
  #|         doc.addEventListener("fullscreenchange", () => {
  #|           const current = root.__gameEngineWebRuntime;
  #|           if (current == null || current.canvas == null) return;
  #|           current.fullscreen = doc.fullscreenElement === current.canvas;
  #|         });
  #|         doc.addEventListener("pointerlockchange", () => {
  #|           const current = root.__gameEngineWebRuntime;
  #|           if (current == null) return;
  #|           const canvas = current.canvas;
  #|           let mode = Number(current.cursorMode ?? 0) | 0;
  #|           if (canvas != null && doc.pointerLockElement === canvas) {
  #|             mode = 2;
  #|           } else if (mode === 2) {
  #|             mode = canvas != null && canvas.style != null && canvas.style.cursor === "none" ? 1 : 0;
  #|           }
  #|           if (mode !== 1 && mode !== 2) mode = 0;
  #|           current.cursorMode = mode;
  #|           if (canvas != null && canvas.style != null) {
  #|             canvas.style.cursor = mode === 0 ? "" : "none";
  #|           }
  #|         });
  #|         const normalizeKeyCode = (event) => {
  #|           if (event == null) return 0;
  #|           const raw = Number(event.keyCode ?? event.which ?? 0) | 0;
  #|           return raw > 0 ? raw : 0;
  #|         };
  #|         const addPressedKey = (current, key) => {
  #|           if (key <= 0) return;
  #|           if (!Array.isArray(current.pressedKeys)) current.pressedKeys = [];
  #|           for (let i = 0; i < current.pressedKeys.length; i++) {
  #|             if ((Number(current.pressedKeys[i]) | 0) === key) return;
  #|           }
  #|           current.pressedKeys.push(key);
  #|         };
  #|         const removePressedKey = (current, key) => {
  #|           if (key <= 0) return;
  #|           if (!Array.isArray(current.pressedKeys)) {
  #|             current.pressedKeys = [];
  #|             return;
  #|           }
  #|           const next = [];
  #|           for (let i = 0; i < current.pressedKeys.length; i++) {
  #|             const value = Number(current.pressedKeys[i]) | 0;
  #|             if (value !== key) next.push(value);
  #|           }
  #|           current.pressedKeys = next;
  #|         };
  #|         const normalizeMouseButton = (event) => {
  #|           if (event == null) return -1;
  #|           const raw = Number(event.button ?? -1) | 0;
  #|           return raw >= 0 ? raw : -1;
  #|         };
  #|         const addPressedMouseButton = (current, button) => {
  #|           if (button < 0) return;
  #|           if (!Array.isArray(current.pressedMouseButtons)) current.pressedMouseButtons = [];
  #|           for (let i = 0; i < current.pressedMouseButtons.length; i++) {
  #|             if ((Number(current.pressedMouseButtons[i]) | 0) === button) return;
  #|           }
  #|           current.pressedMouseButtons.push(button);
  #|         };
  #|         const removePressedMouseButton = (current, button) => {
  #|           if (button < 0) return;
  #|           if (!Array.isArray(current.pressedMouseButtons)) {
  #|             current.pressedMouseButtons = [];
  #|             return;
  #|           }
  #|           const next = [];
  #|           for (let i = 0; i < current.pressedMouseButtons.length; i++) {
  #|             const value = Number(current.pressedMouseButtons[i]) | 0;
  #|             if (value !== button) next.push(value);
  #|           }
  #|           current.pressedMouseButtons = next;
  #|         };
  #|         const syncTouches = (current, event) => {
  #|           if (current == null) return;
  #|           const list = event?.touches;
  #|           if (list == null || typeof list.length !== "number") {
  #|             current.touches = [];
  #|             return;
  #|           }
  #|           const next = [];
  #|           for (let i = 0; i < list.length; i++) {
  #|             const touch = list[i];
  #|             if (touch == null) continue;
  #|             let x = Number(touch.clientX ?? 0);
  #|             let y = Number(touch.clientY ?? 0);
  #|             if (current.canvas != null && typeof current.canvas.getBoundingClientRect === "function") {
  #|               const rect = current.canvas.getBoundingClientRect();
  #|               x = x - Number(rect.left ?? 0);
  #|               y = y - Number(rect.top ?? 0);
  #|             }
  #|             next.push({
  #|               id: Number(touch.identifier ?? 0) | 0,
  #|               x: Number.isFinite(x) ? x : 0,
  #|               y: Number.isFinite(y) ? y : 0,
  #|             });
  #|           }
  #|           current.touches = next;
  #|         };
  #|         const updateCursor = (current, event) => {
  #|           if (current == null || event == null) return;
  #|           let x = Number(event.clientX ?? 0);
  #|           let y = Number(event.clientY ?? 0);
  #|           if (current.canvas != null && typeof current.canvas.getBoundingClientRect === "function") {
  #|             const rect = current.canvas.getBoundingClientRect();
  #|             x = x - Number(rect.left ?? 0);
  #|             y = y - Number(rect.top ?? 0);
  #|           }
  #|           current.cursorX = Number.isFinite(x) ? x : 0;
  #|           current.cursorY = Number.isFinite(y) ? y : 0;
  #|         };
  #|         doc.addEventListener("mousemove", (event) => {
  #|           const current = root.__gameEngineWebRuntime;
  #|           if (current == null) return;
  #|           updateCursor(current, event);
  #|         });
  #|         doc.addEventListener("mousedown", (event) => {
  #|           const current = root.__gameEngineWebRuntime;
  #|           if (current == null) return;
  #|           updateCursor(current, event);
  #|           addPressedMouseButton(current, normalizeMouseButton(event));
  #|         });
  #|         doc.addEventListener("mouseup", (event) => {
  #|           const current = root.__gameEngineWebRuntime;
  #|           if (current == null) return;
  #|           updateCursor(current, event);
  #|           removePressedMouseButton(current, normalizeMouseButton(event));
  #|         });
  #|         doc.addEventListener("wheel", (event) => {
  #|           const current = root.__gameEngineWebRuntime;
  #|           if (current == null) return;
  #|           const dx = Number(event?.deltaX ?? 0);
  #|           const dy = Number(event?.deltaY ?? 0);
  #|           current.wheelX = Number(current.wheelX ?? 0) + (Number.isFinite(dx) ? dx : 0);
  #|           current.wheelY = Number(current.wheelY ?? 0) + (Number.isFinite(dy) ? dy : 0);
  #|         }, { passive: true });
  #|         doc.addEventListener("touchstart", (event) => {
  #|           const current = root.__gameEngineWebRuntime;
  #|           if (current == null) return;
  #|           syncTouches(current, event);
  #|         }, { passive: true });
  #|         doc.addEventListener("touchmove", (event) => {
  #|           const current = root.__gameEngineWebRuntime;
  #|           if (current == null) return;
  #|           syncTouches(current, event);
  #|         }, { passive: true });
  #|         doc.addEventListener("touchend", (event) => {
  #|           const current = root.__gameEngineWebRuntime;
  #|           if (current == null) return;
  #|           syncTouches(current, event);
  #|         }, { passive: true });
  #|         doc.addEventListener("touchcancel", (event) => {
  #|           const current = root.__gameEngineWebRuntime;
  #|           if (current == null) return;
  #|           syncTouches(current, event);
  #|         }, { passive: true });
  #|         const targetWindow = typeof window === "undefined" ? null : window;
  #|         if (targetWindow != null && typeof targetWindow.addEventListener === "function") {
  #|           targetWindow.addEventListener("keydown", (event) => {
  #|             const current = root.__gameEngineWebRuntime;
  #|             if (current == null) return;
  #|             addPressedKey(current, normalizeKeyCode(event));
  #|           });
  #|           targetWindow.addEventListener("keyup", (event) => {
  #|             const current = root.__gameEngineWebRuntime;
  #|             if (current == null) return;
  #|             removePressedKey(current, normalizeKeyCode(event));
  #|           });
  #|           targetWindow.addEventListener("blur", () => {
  #|             const current = root.__gameEngineWebRuntime;
  #|             if (current == null) return;
  #|             current.pressedKeys = [];
  #|             current.pressedMouseButtons = [];
  #|             current.touches = [];
  #|             current.wheelX = 0;
  #|             current.wheelY = 0;
  #|           });
  #|         }
  #|         state.interactionHooksInstalled = true;
  #|         state.inputHooksInstalled = true;
  #|       }
  #|     }
  #|     return state;
  #|   });
  #|   ensureState(selector);
  #| }

///|
extern "js" fn js_set_should_close(value : Bool) -> Unit =
  #| (value) => {
  #|   const root = globalThis;
  #|   if (typeof root.__gameEngineEnsureWindowState === "function") {
  #|     root.__gameEngineEnsureWindowState("#app");
  #|   }
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {});
  #|   state.shouldClose = !!value;
  #| }

///|
extern "js" fn js_should_close_state() -> Bool =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return false;
  #|   return !!state.shouldClose;
  #| }

///|
extern "js" fn js_set_fullscreen(selector : String, enabled : Bool) -> Bool =
  #| (selector, enabled) => {
  #|   const root = globalThis;
  #|   if (typeof root.__gameEngineEnsureWindowState === "function") {
  #|     root.__gameEngineEnsureWindowState(selector);
  #|   }
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {});
  #|   const doc = typeof document === "undefined" ? null : document;
  #|   if (doc == null || typeof doc.querySelector !== "function") {
  #|     state.fullscreen = !!enabled;
  #|     return !!state.fullscreen;
  #|   }
  #|   const target = doc.querySelector(selector);
  #|   if (target == null) {
  #|     state.fullscreen = !!enabled;
  #|     return !!state.fullscreen;
  #|   }
  #|   if (enabled) {
  #|     if (doc.fullscreenElement === target) {
  #|       state.fullscreen = true;
  #|       return true;
  #|     }
  #|     if (typeof target.requestFullscreen === "function") {
  #|       Promise.resolve(target.requestFullscreen()).catch(() => {
  #|         const current = root.__gameEngineWebRuntime;
  #|         if (current != null) current.fullscreen = doc.fullscreenElement === target;
  #|       });
  #|       state.fullscreen = true;
  #|       return true;
  #|     }
  #|     state.fullscreen = doc.fullscreenElement === target;
  #|     return !!state.fullscreen;
  #|   }
  #|   if (doc.fullscreenElement != null && typeof doc.exitFullscreen === "function") {
  #|     Promise.resolve(doc.exitFullscreen()).catch(() => {
  #|       const current = root.__gameEngineWebRuntime;
  #|       if (current != null) current.fullscreen = doc.fullscreenElement === target;
  #|     });
  #|   }
  #|   state.fullscreen = false;
  #|   return false;
  #| }

///|
extern "js" fn js_is_fullscreen(selector : String, fallback : Bool) -> Bool =
  #| (selector, fallback) => {
  #|   const root = globalThis;
  #|   if (typeof root.__gameEngineEnsureWindowState === "function") {
  #|     root.__gameEngineEnsureWindowState(selector);
  #|   }
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {});
  #|   const doc = typeof document === "undefined" ? null : document;
  #|   if (doc == null || typeof doc.querySelector !== "function") {
  #|     if (state.fullscreen == null) state.fullscreen = !!fallback;
  #|     return !!state.fullscreen;
  #|   }
  #|   const target = doc.querySelector(selector);
  #|   if (target == null) {
  #|     if (state.fullscreen == null) state.fullscreen = !!fallback;
  #|     return !!state.fullscreen;
  #|   }
  #|   state.fullscreen = doc.fullscreenElement === target;
  #|   return !!state.fullscreen;
  #| }

///|
extern "js" fn js_set_cursor_mode(selector : String, mode : Int) -> Int =
  #| (selector, mode) => {
  #|   const root = globalThis;
  #|   if (typeof root.__gameEngineEnsureWindowState === "function") {
  #|     root.__gameEngineEnsureWindowState(selector);
  #|   }
  #|   const doc = typeof document === "undefined" ? null : document;
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {});
  #|   let nextMode = Number(mode) | 0;
  #|   if (nextMode !== 1 && nextMode !== 2) nextMode = 0;
  #|   if (doc != null && typeof doc.querySelector === "function") {
  #|     const canvas = doc.querySelector(selector);
  #|     if (canvas != null) {
  #|       if (nextMode === 0) {
  #|         if (canvas.style != null) canvas.style.cursor = "";
  #|         if (doc.pointerLockElement === canvas && typeof doc.exitPointerLock === "function") {
  #|           doc.exitPointerLock();
  #|         }
  #|       } else if (nextMode === 1) {
  #|         if (canvas.style != null) canvas.style.cursor = "none";
  #|       } else {
  #|         if (canvas.style != null) canvas.style.cursor = "none";
  #|         if (doc.pointerLockElement !== canvas && typeof canvas.requestPointerLock === "function") {
  #|           try {
  #|             canvas.requestPointerLock();
  #|           } catch (_) {}
  #|         }
  #|       }
  #|     }
  #|   }
  #|   state.cursorMode = nextMode;
  #|   return nextMode;
  #| }

///|
extern "js" fn js_cursor_mode(selector : String, fallback : Int) -> Int =
  #| (selector, fallback) => {
  #|   const root = globalThis;
  #|   if (typeof root.__gameEngineEnsureWindowState === "function") {
  #|     root.__gameEngineEnsureWindowState(selector);
  #|   }
  #|   const state = root.__gameEngineWebRuntime;
  #|   const doc = typeof document === "undefined" ? null : document;
  #|   if (doc != null && typeof doc.querySelector === "function") {
  #|     const canvas = doc.querySelector(selector);
  #|     if (canvas != null && doc.pointerLockElement === canvas) {
  #|       state.cursorMode = 2;
  #|       return 2;
  #|     }
  #|     if (canvas != null && Number(state?.cursorMode ?? fallback) === 2) {
  #|       state.cursorMode = canvas.style != null && canvas.style.cursor === "none" ? 1 : 0;
  #|     }
  #|   }
  #|   if (state == null) return (Number(fallback) | 0);
  #|   const mode = Number(state.cursorMode ?? fallback) | 0;
  #|   if (mode !== 1 && mode !== 2) return 0;
  #|   return mode;
  #| }

///|
extern "js" fn js_set_device_scale_factor(scale : Double) -> Double =
  #| (scale) => {
  #|   const root = globalThis;
  #|   if (typeof root.__gameEngineEnsureWindowState === "function") {
  #|     root.__gameEngineEnsureWindowState("#app");
  #|   }
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {});
  #|   const normalized = Number(scale) > 0 ? Number(scale) : 1;
  #|   state.deviceScaleOverride = normalized;
  #|   return normalized;
  #| }

///|
extern "js" fn js_device_scale_factor(fallback : Double) -> Double =
  #| (fallback) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   const safeFallback = Number(fallback) > 0 ? Number(fallback) : 1;
  #|   if (state == null) return safeFallback;
  #|   const override = Number(state.deviceScaleOverride ?? 0);
  #|   if (override > 0) return override;
  #|   const dpr = Number(state.dpr ?? safeFallback);
  #|   return dpr > 0 ? dpr : safeFallback;
  #| }

///|
extern "js" fn js_set_vsync_enabled(enabled : Bool) -> Bool =
  #| (enabled) => {
  #|   const root = globalThis;
  #|   if (typeof root.__gameEngineEnsureWindowState === "function") {
  #|     root.__gameEngineEnsureWindowState("#app");
  #|   }
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {});
  #|   state.vsyncEnabled = !!enabled;
  #|   return !!enabled;
  #| }

///|
extern "js" fn js_is_vsync_enabled(fallback : Bool) -> Bool =
  #| (fallback) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null || state.vsyncEnabled == null) return !!fallback;
  #|   return !!state.vsyncEnabled;
  #| }

///|
extern "js" fn js_input_cursor_x() -> Double =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   return Number(state.cursorX ?? 0) || 0;
  #| }

///|
extern "js" fn js_input_cursor_y() -> Double =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   return Number(state.cursorY ?? 0) || 0;
  #| }

///|
extern "js" fn js_input_wheel_x() -> Double =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   return Number(state.wheelX ?? 0) || 0;
  #| }

///|
extern "js" fn js_input_wheel_y() -> Double =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   return Number(state.wheelY ?? 0) || 0;
  #| }

///|
extern "js" fn js_clear_input_wheel() -> Unit =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   state.wheelX = 0;
  #|   state.wheelY = 0;
  #| }

///|
extern "js" fn js_input_pressed_key_count() -> Int =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null || !Array.isArray(state.pressedKeys)) return 0;
  #|   return Math.max(0, Number(state.pressedKeys.length) | 0);
  #| }

///|
extern "js" fn js_input_pressed_key_at(index : Int) -> Int =
  #| (index) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null || !Array.isArray(state.pressedKeys)) return 0;
  #|   const i = Number(index) | 0;
  #|   if (i < 0 || i >= state.pressedKeys.length) return 0;
  #|   return Number(state.pressedKeys[i] ?? 0) | 0;
  #| }

///|
extern "js" fn js_input_pressed_mouse_button_count() -> Int =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null || !Array.isArray(state.pressedMouseButtons)) return 0;
  #|   return Math.max(0, Number(state.pressedMouseButtons.length) | 0);
  #| }

///|
extern "js" fn js_input_pressed_mouse_button_at(index : Int) -> Int =
  #| (index) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null || !Array.isArray(state.pressedMouseButtons)) return -1;
  #|   const i = Number(index) | 0;
  #|   if (i < 0 || i >= state.pressedMouseButtons.length) return -1;
  #|   return Number(state.pressedMouseButtons[i] ?? -1) | 0;
  #| }

///|
extern "js" fn js_input_touch_count() -> Int =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null || !Array.isArray(state.touches)) return 0;
  #|   return Math.max(0, Number(state.touches.length) | 0);
  #| }

///|
extern "js" fn js_input_touch_id_at(index : Int) -> Int =
  #| (index) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null || !Array.isArray(state.touches)) return 0;
  #|   const i = Number(index) | 0;
  #|   if (i < 0 || i >= state.touches.length) return 0;
  #|   const touch = state.touches[i];
  #|   return Number(touch?.id ?? 0) | 0;
  #| }

///|
extern "js" fn js_input_touch_x_at(index : Int) -> Double =
  #| (index) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null || !Array.isArray(state.touches)) return 0;
  #|   const i = Number(index) | 0;
  #|   if (i < 0 || i >= state.touches.length) return 0;
  #|   const touch = state.touches[i];
  #|   return Number(touch?.x ?? 0) || 0;
  #| }

///|
extern "js" fn js_input_touch_y_at(index : Int) -> Double =
  #| (index) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null || !Array.isArray(state.touches)) return 0;
  #|   const i = Number(index) | 0;
  #|   if (i < 0 || i >= state.touches.length) return 0;
  #|   const touch = state.touches[i];
  #|   return Number(touch?.y ?? 0) || 0;
  #| }

///|
extern "js" fn js_input_gamepad_count() -> Int =
  #| () => {
  #|   const root = globalThis;
  #|   const state = root.__gameEngineWebRuntime;
  #|   if (state != null && Array.isArray(state.testGamepads) && state.testGamepads.length > 0) {
  #|     return Math.max(0, Number(state.testGamepads.length) | 0);
  #|   }
  #|   const nav = root.navigator;
  #|   if (nav == null || typeof nav.getGamepads !== "function") return 0;
  #|   const pads = nav.getGamepads();
  #|   if (pads == null || typeof pads.length !== "number") return 0;
  #|   let count = 0;
  #|   for (let i = 0; i < pads.length; i++) {
  #|     if (pads[i] != null) count++;
  #|   }
  #|   return count | 0;
  #| }

///|
extern "js" fn js_input_gamepad_id_at(index : Int) -> Int =
  #| (index) => {
  #|   const root = globalThis;
  #|   const i = Number(index) | 0;
  #|   if (i < 0) return -1;
  #|   const state = root.__gameEngineWebRuntime;
  #|   const testPads = state != null && Array.isArray(state.testGamepads) ? state.testGamepads : null;
  #|   if (testPads != null && testPads.length > 0) {
  #|     if (i >= testPads.length || testPads[i] == null) return -1;
  #|     return Number(testPads[i].id ?? i) | 0;
  #|   }
  #|   const nav = root.navigator;
  #|   if (nav == null || typeof nav.getGamepads !== "function") return -1;
  #|   const pads = nav.getGamepads();
  #|   if (pads == null || typeof pads.length !== "number") return -1;
  #|   let found = 0;
  #|   for (let padIndex = 0; padIndex < pads.length; padIndex++) {
  #|     const pad = pads[padIndex];
  #|     if (pad == null) continue;
  #|     if (found === i) {
  #|       return Number(pad.index ?? padIndex) | 0;
  #|     }
  #|     found++;
  #|   }
  #|   return -1;
  #| }

///|
extern "js" fn js_input_gamepad_pressed_button_count(
  gamepad_index : Int,
) -> Int =
  #| (gamepadIndex) => {
  #|   const root = globalThis;
  #|   const gpIndex = Number(gamepadIndex) | 0;
  #|   if (gpIndex < 0) return 0;
  #|   const state = root.__gameEngineWebRuntime;
  #|   const testPads = state != null && Array.isArray(state.testGamepads) ? state.testGamepads : null;
  #|   const target = testPads != null && testPads.length > 0 ? testPads[gpIndex] : null;
  #|   if (target != null && Array.isArray(target.pressedButtons)) {
  #|     return Math.max(0, Number(target.pressedButtons.length) | 0);
  #|   }
  #|   const nav = root.navigator;
  #|   if (nav == null || typeof nav.getGamepads !== "function") return 0;
  #|   const pads = nav.getGamepads();
  #|   if (pads == null) return 0;
  #|   let found = 0;
  #|   let pad = null;
  #|   for (let i = 0; i < pads.length; i++) {
  #|     if (pads[i] == null) continue;
  #|     if (found === gpIndex) {
  #|       pad = pads[i];
  #|       break;
  #|     }
  #|     found++;
  #|   }
  #|   if (pad == null || !Array.isArray(pad.buttons)) return 0;
  #|   let count = 0;
  #|   for (let i = 0; i < pad.buttons.length; i++) {
  #|     const button = pad.buttons[i];
  #|     if (button != null && !!button.pressed) count++;
  #|   }
  #|   return count | 0;
  #| }

///|
extern "js" fn js_input_gamepad_pressed_button_at(
  gamepad_index : Int,
  button_index : Int,
) -> Int =
  #| (gamepadIndex, buttonIndex) => {
  #|   const root = globalThis;
  #|   const gpIndex = Number(gamepadIndex) | 0;
  #|   const btnIndex = Number(buttonIndex) | 0;
  #|   if (gpIndex < 0 || btnIndex < 0) return -1;
  #|   const state = root.__gameEngineWebRuntime;
  #|   const testPads = state != null && Array.isArray(state.testGamepads) ? state.testGamepads : null;
  #|   const target = testPads != null && testPads.length > 0 ? testPads[gpIndex] : null;
  #|   if (target != null && Array.isArray(target.pressedButtons)) {
  #|     if (btnIndex >= target.pressedButtons.length) return -1;
  #|     return Number(target.pressedButtons[btnIndex] ?? -1) | 0;
  #|   }
  #|   const nav = root.navigator;
  #|   if (nav == null || typeof nav.getGamepads !== "function") return -1;
  #|   const pads = nav.getGamepads();
  #|   if (pads == null) return -1;
  #|   let foundPad = null;
  #|   let found = 0;
  #|   for (let i = 0; i < pads.length; i++) {
  #|     if (pads[i] == null) continue;
  #|     if (found === gpIndex) {
  #|       foundPad = pads[i];
  #|       break;
  #|     }
  #|     found++;
  #|   }
  #|   const pad = foundPad;
  #|   if (pad == null || !Array.isArray(pad.buttons)) return -1;
  #|   let pressedFound = 0;
  #|   for (let i = 0; i < pad.buttons.length; i++) {
  #|     const button = pad.buttons[i];
  #|     if (button != null && !!button.pressed) {
  #|       if (pressedFound === btnIndex) return i;
  #|       pressedFound++;
  #|     }
  #|   }
  #|   return -1;
  #| }

///|
extern "js" fn js_input_gamepad_axis_count(gamepad_index : Int) -> Int =
  #| (gamepadIndex) => {
  #|   const root = globalThis;
  #|   const gpIndex = Number(gamepadIndex) | 0;
  #|   if (gpIndex < 0) return 0;
  #|   const state = root.__gameEngineWebRuntime;
  #|   const testPads = state != null && Array.isArray(state.testGamepads) ? state.testGamepads : null;
  #|   const target = testPads != null && testPads.length > 0 ? testPads[gpIndex] : null;
  #|   if (target != null && Array.isArray(target.axes)) {
  #|     return Math.max(0, Number(target.axes.length) | 0);
  #|   }
  #|   const nav = root.navigator;
  #|   if (nav == null || typeof nav.getGamepads !== "function") return 0;
  #|   const pads = nav.getGamepads();
  #|   if (pads == null) return 0;
  #|   let found = 0;
  #|   let pad = null;
  #|   for (let i = 0; i < pads.length; i++) {
  #|     if (pads[i] == null) continue;
  #|     if (found === gpIndex) {
  #|       pad = pads[i];
  #|       break;
  #|     }
  #|     found++;
  #|   }
  #|   if (pad == null || !Array.isArray(pad.axes)) return 0;
  #|   return Math.max(0, Number(pad.axes.length) | 0);
  #| }

///|
extern "js" fn js_input_gamepad_axis_at(
  gamepad_index : Int,
  axis_index : Int,
) -> Double =
  #| (gamepadIndex, axisIndex) => {
  #|   const root = globalThis;
  #|   const gpIndex = Number(gamepadIndex) | 0;
  #|   const axIndex = Number(axisIndex) | 0;
  #|   if (gpIndex < 0 || axIndex < 0) return 0;
  #|   const state = root.__gameEngineWebRuntime;
  #|   const testPads = state != null && Array.isArray(state.testGamepads) ? state.testGamepads : null;
  #|   const target = testPads != null && testPads.length > 0 ? testPads[gpIndex] : null;
  #|   if (target != null && Array.isArray(target.axes)) {
  #|     if (axIndex >= target.axes.length) return 0;
  #|     return Number(target.axes[axIndex] ?? 0) || 0;
  #|   }
  #|   const nav = root.navigator;
  #|   if (nav == null || typeof nav.getGamepads !== "function") return 0;
  #|   const pads = nav.getGamepads();
  #|   if (pads == null) return 0;
  #|   let found = 0;
  #|   let pad = null;
  #|   for (let i = 0; i < pads.length; i++) {
  #|     if (pads[i] == null) continue;
  #|     if (found === gpIndex) {
  #|       pad = pads[i];
  #|       break;
  #|     }
  #|     found++;
  #|   }
  #|   if (pad == null || !Array.isArray(pad.axes)) return 0;
  #|   if (axIndex >= pad.axes.length) return 0;
  #|   return Number(pad.axes[axIndex] ?? 0) || 0;
  #| }

///|
extern "js" fn js_request_attention() -> Unit =
  #| () => {
  #|   const root = globalThis;
  #|   if (typeof root.__gameEngineEnsureWindowState === "function") {
  #|     root.__gameEngineEnsureWindowState("#app");
  #|   }
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {});
  #|   state.attentionRequests = (Number(state.attentionRequests ?? 0) | 0) + 1;
  #|   const doc = typeof document === "undefined" ? null : document;
  #|   if (doc != null && typeof doc.hasFocus === "function" && !doc.hasFocus()) {
  #|     const title = typeof doc.title === "string" ? doc.title : "";
  #|     if (title.length > 0 && !title.startsWith("(*) ")) {
  #|       doc.title = "(*) " + title;
  #|     }
  #|   }
  #| }

///|
extern "js" fn js_try_initialize_webgpu(
  selector : String,
  fallback_width : Int,
  fallback_height : Int,
) -> Bool =
  #| (selector, fallbackWidth, fallbackHeight) => {
  #|   const root = globalThis;
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {
  #|     nextSurfaceId: 100,
  #|     selector: "#app",
  #|     canvas: null,
  #|     surfaceId: 0,
  #|     width: fallbackWidth,
  #|     height: fallbackHeight,
  #|     dpr: 1,
  #|     webgpu: { context: null, device: null, format: "bgra8unorm", pending: null, pipeline: null, pipelineFormat: "", presentScheduled: false, clear: [0, 0, 0, 1], drawCalls: 0, lastError: "" },
  #|     webgl2: { context: null, program: null, vao: null, presentScheduled: false, clear: [0, 0, 0, 1], drawCalls: 0 },
  #|   });
  #|   state.selector = selector;
  #|   const doc = typeof document === "undefined" ? null : document;
  #|   if (doc != null && typeof doc.querySelector === "function") {
  #|     const canvas = doc.querySelector(selector);
  #|     if (canvas == null || typeof canvas.getContext !== "function") return false;
  #|     const CanvasType = typeof HTMLCanvasElement === "undefined" ? null : HTMLCanvasElement;
  #|     if (CanvasType != null && !(canvas instanceof CanvasType)) return false;
  #|     const dpr = Number(root.devicePixelRatio ?? 1) || 1;
  #|     const rect = typeof canvas.getBoundingClientRect === "function"
  #|       ? canvas.getBoundingClientRect()
  #|       : { width: fallbackWidth, height: fallbackHeight };
  #|     const cssWidth = rect.width > 0 ? rect.width : fallbackWidth;
  #|     const cssHeight = rect.height > 0 ? rect.height : fallbackHeight;
  #|     const pixelWidth = Math.max(1, Math.round(cssWidth * dpr));
  #|     const pixelHeight = Math.max(1, Math.round(cssHeight * dpr));
  #|     if (canvas.width !== pixelWidth) canvas.width = pixelWidth;
  #|     if (canvas.height !== pixelHeight) canvas.height = pixelHeight;
  #|     if (canvas.__gameEngineSurfaceId == null) {
  #|       canvas.__gameEngineSurfaceId = state.nextSurfaceId++;
  #|     }
  #|     state.canvas = canvas;
  #|     state.surfaceId = Number(canvas.__gameEngineSurfaceId) | 0;
  #|     state.width = pixelWidth;
  #|     state.height = pixelHeight;
  #|     state.dpr = dpr;
  #|   } else {
  #|     state.canvas = null;
  #|     state.surfaceId = 1;
  #|     state.width = fallbackWidth;
  #|     state.height = fallbackHeight;
  #|     state.dpr = 1;
  #|   }
  #|   if (state == null || state.canvas == null) {
  #|     return true;
  #|   }
  #|   const nav = typeof navigator === "undefined" ? null : navigator;
  #|   if (nav == null || nav.gpu == null) {
  #|     return false;
  #|   }
  #|   const context = state.canvas.getContext("webgpu");
  #|   if (context == null) {
  #|     return false;
  #|   }
  #|   state.webgpu.context = context;
  #|   if (state.webgpu.device != null) {
  #|     return true;
  #|   }
  #|   if (state.webgpu.pending == null) {
  #|     state.webgpu.pending = nav.gpu.requestAdapter()
  #|       .then((adapter) => adapter == null ? null : adapter.requestDevice())
  #|       .then((device) => {
  #|         if (device == null) return;
  #|         const format = typeof nav.gpu.getPreferredCanvasFormat === "function"
  #|           ? nav.gpu.getPreferredCanvasFormat()
  #|           : "bgra8unorm";
  #|         state.webgpu.format = format;
  #|         state.webgpu.device = device;
  #|         state.webgpu.pipeline = null;
  #|         state.webgpu.pipelineFormat = "";
  #|         if (state.webgpu.context != null) {
  #|           state.webgpu.context.configure({
  #|             device,
  #|             format,
  #|             alphaMode: "opaque",
  #|           });
  #|         }
  #|       })
  #|       .catch((error) => {
  #|         state.webgpu.lastError = String(error);
  #|         state.webgpu.device = null;
  #|         state.webgpu.pipeline = null;
  #|         state.webgpu.pipelineFormat = "";
  #|       })
  #|       .finally(() => {
  #|         state.webgpu.pending = null;
  #|       });
  #|   }
  #|   return true;
  #| }

///|
extern "js" fn js_try_initialize_webgl2(
  selector : String,
  fallback_width : Int,
  fallback_height : Int,
) -> Bool =
  #| (selector, fallbackWidth, fallbackHeight) => {
  #|   const root = globalThis;
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {
  #|     nextSurfaceId: 100,
  #|     selector: "#app",
  #|     canvas: null,
  #|     surfaceId: 0,
  #|     width: fallbackWidth,
  #|     height: fallbackHeight,
  #|     dpr: 1,
  #|     webgpu: { context: null, device: null, format: "bgra8unorm", pending: null, pipeline: null, pipelineFormat: "", presentScheduled: false, clear: [0, 0, 0, 1], drawCalls: 0, lastError: "" },
  #|     webgl2: { context: null, program: null, vao: null, presentScheduled: false, clear: [0, 0, 0, 1], drawCalls: 0 },
  #|   });
  #|   state.selector = selector;
  #|   const doc = typeof document === "undefined" ? null : document;
  #|   if (doc != null && typeof doc.querySelector === "function") {
  #|     const canvas = doc.querySelector(selector);
  #|     if (canvas == null || typeof canvas.getContext !== "function") return false;
  #|     const CanvasType = typeof HTMLCanvasElement === "undefined" ? null : HTMLCanvasElement;
  #|     if (CanvasType != null && !(canvas instanceof CanvasType)) return false;
  #|     const dpr = Number(root.devicePixelRatio ?? 1) || 1;
  #|     const rect = typeof canvas.getBoundingClientRect === "function"
  #|       ? canvas.getBoundingClientRect()
  #|       : { width: fallbackWidth, height: fallbackHeight };
  #|     const cssWidth = rect.width > 0 ? rect.width : fallbackWidth;
  #|     const cssHeight = rect.height > 0 ? rect.height : fallbackHeight;
  #|     const pixelWidth = Math.max(1, Math.round(cssWidth * dpr));
  #|     const pixelHeight = Math.max(1, Math.round(cssHeight * dpr));
  #|     if (canvas.width !== pixelWidth) canvas.width = pixelWidth;
  #|     if (canvas.height !== pixelHeight) canvas.height = pixelHeight;
  #|     if (canvas.__gameEngineSurfaceId == null) {
  #|       canvas.__gameEngineSurfaceId = state.nextSurfaceId++;
  #|     }
  #|     state.canvas = canvas;
  #|     state.surfaceId = Number(canvas.__gameEngineSurfaceId) | 0;
  #|     state.width = pixelWidth;
  #|     state.height = pixelHeight;
  #|     state.dpr = dpr;
  #|   } else {
  #|     state.canvas = null;
  #|     state.surfaceId = 1;
  #|     state.width = fallbackWidth;
  #|     state.height = fallbackHeight;
  #|     state.dpr = 1;
  #|   }
  #|   if (state == null || state.canvas == null) {
  #|     return true;
  #|   }
  #|   const context = state.canvas.getContext("webgl2", {
  #|     alpha: true,
  #|     antialias: false,
  #|     depth: false,
  #|     stencil: false,
  #|   });
  #|   if (context == null) {
  #|     return false;
  #|   }
  #|   const previousContext = state.webgl2.context;
  #|   state.webgl2.context = context;
  #|   if (previousContext !== context) {
  #|     state.webgl2.program = null;
  #|     state.webgl2.vao = null;
  #|   }
  #|   context.viewport(0, 0, state.width, state.height);
  #|   return true;
  #| }

///|
extern "js" fn js_webgpu_begin(
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
) -> Unit =
  #| (r, g, b, a) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const gpu = state.webgpu;
  #|   if (gpu == null) return;
  #|   gpu.clear = [r, g, b, a];
  #|   gpu.drawCalls = 0;
  #|   gpu.commandCount = 0;
  #|   gpu.lastPipelineId = 0;
  #|   gpu.lastUniformHash = 0;
  #|   gpu.lastBlendMode = 1;
  #|   gpu.lastDstImageId = 0;
  #|   gpu.lastShaderId = 0;
  #|   gpu.lastIndexOffset = 0;
  #|   gpu.lastRegionCount = 0;
  #|   gpu.lastTotalIndexCount = 0;
  #|   gpu.lastVertexFloatCount = 0;
  #|   gpu.lastIndexCount = 0;
  #|   gpu.lastSrcImageCount = 0;
  #|   gpu.lastUniformDwordCount = 0;
  #| }

///|
extern "js" fn js_webgpu_record_draw(
  draw_calls : Int,
  pipeline_id : Int,
  uniform_hash : Int,
  blend_mode : Int,
  dst_image_id : Int,
  shader_id : Int,
  index_offset : Int,
  region_count : Int,
  total_index_count : Int,
  vertex_float_count : Int,
  index_count : Int,
  src_image_count : Int,
  uniform_dword_count : Int,
  payload_has_triangle : Int,
  payload_ax : Double,
  payload_ay : Double,
  payload_bx : Double,
  payload_by : Double,
  payload_cx : Double,
  payload_cy : Double,
  payload_au : Double,
  payload_av : Double,
  payload_bu : Double,
  payload_bv : Double,
  payload_cu : Double,
  payload_cv : Double,
  payload_uniform_r : Double,
  payload_uniform_g : Double,
  payload_uniform_b : Double,
  payload_uniform_a : Double,
  payload_texture_seed : Int,
) -> Unit =
  #| (drawCalls, pipelineId, uniformHash, blendMode, dstImageId, shaderId, indexOffset, regionCount, totalIndexCount, vertexFloatCount, indexCount, srcImageCount, uniformDwordCount, payloadHasTriangle, payloadAx, payloadAy, payloadBx, payloadBy, payloadCx, payloadCy, payloadAu, payloadAv, payloadBu, payloadBv, payloadCu, payloadCv, payloadUniformR, payloadUniformG, payloadUniformB, payloadUniformA, payloadTextureSeed) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const gpu = state.webgpu;
  #|   if (gpu == null) return;
  #|   gpu.drawCalls += drawCalls <= 0 ? 1 : drawCalls;
  #|   gpu.commandCount = (Number(gpu.commandCount ?? 0) | 0) + 1;
  #|   gpu.lastPipelineId = Number(pipelineId ?? 0) | 0;
  #|   gpu.lastUniformHash = Number(uniformHash ?? 0) | 0;
  #|   let safeBlend = Number(blendMode ?? 1) | 0;
  #|   if (safeBlend < 0 || safeBlend > 3) safeBlend = 1;
  #|   gpu.lastBlendMode = safeBlend;
  #|   gpu.lastDstImageId = Number(dstImageId ?? 0) | 0;
  #|   gpu.lastShaderId = Number(shaderId ?? 0) | 0;
  #|   gpu.lastIndexOffset = Number(indexOffset ?? 0) | 0;
  #|   gpu.lastRegionCount = Number(regionCount ?? 0) | 0;
  #|   gpu.lastTotalIndexCount = Number(totalIndexCount ?? 0) | 0;
  #|   gpu.lastVertexFloatCount = Number(vertexFloatCount ?? 0) | 0;
  #|   gpu.lastIndexCount = Number(indexCount ?? 0) | 0;
  #|   gpu.lastSrcImageCount = Number(srcImageCount ?? 0) | 0;
  #|   gpu.lastUniformDwordCount = Number(uniformDwordCount ?? 0) | 0;
  #|   gpu.lastPayloadHasTriangle = (Number(payloadHasTriangle ?? 0) | 0) !== 0;
  #|   gpu.lastPayloadAx = Number(payloadAx ?? 0);
  #|   gpu.lastPayloadAy = Number(payloadAy ?? 0);
  #|   gpu.lastPayloadBx = Number(payloadBx ?? 0);
  #|   gpu.lastPayloadBy = Number(payloadBy ?? 0);
  #|   gpu.lastPayloadCx = Number(payloadCx ?? 0);
  #|   gpu.lastPayloadCy = Number(payloadCy ?? 0);
  #|   gpu.lastPayloadAu = Number(payloadAu ?? 0);
  #|   gpu.lastPayloadAv = Number(payloadAv ?? 0);
  #|   gpu.lastPayloadBu = Number(payloadBu ?? 0);
  #|   gpu.lastPayloadBv = Number(payloadBv ?? 0);
  #|   gpu.lastPayloadCu = Number(payloadCu ?? 0);
  #|   gpu.lastPayloadCv = Number(payloadCv ?? 0);
  #|   gpu.lastPayloadUniformR = Number(payloadUniformR ?? 1);
  #|   gpu.lastPayloadUniformG = Number(payloadUniformG ?? 1);
  #|   gpu.lastPayloadUniformB = Number(payloadUniformB ?? 1);
  #|   gpu.lastPayloadUniformA = Number(payloadUniformA ?? 1);
  #|   gpu.lastPayloadTextureSeed = Number(payloadTextureSeed ?? 0) | 0;
  #| }

///|
extern "js" fn js_webgpu_present() -> Bool =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return false;
  #|   const gpu = state.webgpu;
  #|   const device = gpu == null ? null : gpu.device;
  #|   const context = gpu == null ? null : gpu.context;
  #|   if (gpu == null || device == null || context == null) {
  #|     return false;
  #|   }
  #|   const presentNow = (currentState) => {
  #|     const canvas = currentState.canvas;
  #|     if (canvas != null && typeof canvas.getBoundingClientRect === "function") {
  #|       const dpr = Number(globalThis.devicePixelRatio ?? 1) || 1;
  #|       const rect = canvas.getBoundingClientRect();
  #|       const cssWidth = rect.width > 0 ? rect.width : currentState.width;
  #|       const cssHeight = rect.height > 0 ? rect.height : currentState.height;
  #|       const pixelWidth = Math.max(1, Math.round(cssWidth * dpr));
  #|       const pixelHeight = Math.max(1, Math.round(cssHeight * dpr));
  #|       if (canvas.width !== pixelWidth) canvas.width = pixelWidth;
  #|       if (canvas.height !== pixelHeight) canvas.height = pixelHeight;
  #|       currentState.width = pixelWidth;
  #|       currentState.height = pixelHeight;
  #|       currentState.dpr = dpr;
  #|     }
  #|     const currentGpu = currentState.webgpu;
  #|     const currentDevice = currentGpu == null ? null : currentGpu.device;
  #|     const currentContext = currentGpu == null ? null : currentGpu.context;
  #|     if (currentGpu == null || currentDevice == null || currentContext == null) {
  #|       return false;
  #|     }
  #|     const format = typeof currentGpu.format === "string"
  #|       ? currentGpu.format
  #|       : "bgra8unorm";
  #|     currentContext.configure({
  #|       device: currentDevice,
  #|       format,
  #|       alphaMode: "opaque",
  #|     });
  #|     const [r, g, b, a] = currentGpu.clear;
  #|     const texture = currentContext.getCurrentTexture();
  #|     const view = texture.createView();
  #|     const encoder = currentDevice.createCommandEncoder();
  #|     const pass = encoder.beginRenderPass({
  #|       colorAttachments: [{
  #|         view,
  #|         clearValue: { r, g, b, a },
  #|         loadOp: "clear",
  #|         storeOp: "store",
  #|       }],
  #|     });
  #|     const drawCalls = Number(currentGpu.drawCalls ?? 0) | 0;
  #|     if (drawCalls > 0) {
  #|       const payloadHasTriangle = !!currentGpu.lastPayloadHasTriangle;
  #|       const ax = payloadHasTriangle ? Number(currentGpu.lastPayloadAx ?? 0.0) : 0.0;
  #|       const ay = payloadHasTriangle ? Number(currentGpu.lastPayloadAy ?? 0.5) : 0.5;
  #|       const bx = payloadHasTriangle ? Number(currentGpu.lastPayloadBx ?? -0.5) : -0.5;
  #|       const by = payloadHasTriangle ? Number(currentGpu.lastPayloadBy ?? -0.5) : -0.5;
  #|       const cx = payloadHasTriangle ? Number(currentGpu.lastPayloadCx ?? 0.5) : 0.5;
  #|       const cy = payloadHasTriangle ? Number(currentGpu.lastPayloadCy ?? -0.5) : -0.5;
  #|       const uniformR = Number(currentGpu.lastPayloadUniformR ?? 1.0);
  #|       const uniformG = Number(currentGpu.lastPayloadUniformG ?? 0.0);
  #|       const uniformB = Number(currentGpu.lastPayloadUniformB ?? 0.0);
  #|       const uniformA = Number(currentGpu.lastPayloadUniformA ?? 1.0);
  #|       const shaderKey = [
  #|         format,
  #|         ax.toFixed(6), ay.toFixed(6), bx.toFixed(6), by.toFixed(6), cx.toFixed(6), cy.toFixed(6),
  #|         uniformR.toFixed(6), uniformG.toFixed(6), uniformB.toFixed(6), uniformA.toFixed(6),
  #|       ].join("|");
  #|       const needsPipeline = currentGpu.pipeline == null ||
  #|         currentGpu.pipelineFormat !== format ||
  #|         currentGpu.pipelineKey !== shaderKey;
  #|       if (needsPipeline && typeof currentDevice.createShaderModule === "function" && typeof currentDevice.createRenderPipeline === "function") {
  #|         const shaderSource = `@vertex
  #| fn vs_main(@builtin(vertex_index) idx : u32) -> @builtin(position) vec4f {
  #|   var pos = array<vec2f, 3>(
  #|     vec2f(${ax}, ${ay}),
  #|     vec2f(${bx}, ${by}),
  #|     vec2f(${cx}, ${cy}),
  #|   );
  #|   return vec4f(pos[idx], 0.0, 1.0);
  #| }
  #| 
  #| @fragment
  #| fn fs_main() -> @location(0) vec4f {
  #|   return vec4f(${uniformR}, ${uniformG}, ${uniformB}, ${uniformA});
  #| }`;
  #|         const shaderModule = currentDevice.createShaderModule({
  #|           code: shaderSource,
  #|         });
  #|         currentGpu.pipeline = currentDevice.createRenderPipeline({
  #|           layout: "auto",
  #|           vertex: {
  #|             module: shaderModule,
  #|             entryPoint: "vs_main",
  #|           },
  #|           fragment: {
  #|             module: shaderModule,
  #|             entryPoint: "fs_main",
  #|             targets: [{ format }],
  #|           },
  #|           primitive: {
  #|             topology: "triangle-list",
  #|             cullMode: "none",
  #|           },
  #|         });
  #|         currentGpu.pipelineFormat = format;
  #|         currentGpu.pipelineKey = shaderKey;
  #|         currentGpu.lastShaderSource = shaderSource;
  #|       }
  #|       if (currentGpu.pipeline != null && typeof pass.setPipeline === "function" && typeof pass.draw === "function") {
  #|         pass.setPipeline(currentGpu.pipeline);
  #|         for (let i = 0; i < drawCalls; i++) {
  #|           pass.draw(3, 1, 0, 0);
  #|         }
  #|       }
  #|     }
  #|     pass.end();
  #|     currentDevice.queue.submit([encoder.finish()]);
  #|     currentGpu.drawCalls = 0;
  #|     return true;
  #|   };
  #|   const scheduleVsync = !!state.vsyncEnabled && typeof globalThis.requestAnimationFrame === "function";
  #|   if (scheduleVsync) {
  #|     if (gpu.presentScheduled) {
  #|       return true;
  #|     }
  #|     gpu.presentScheduled = true;
  #|     globalThis.requestAnimationFrame(() => {
  #|       const current = globalThis.__gameEngineWebRuntime;
  #|       if (current == null) return;
  #|       if (current.webgpu != null) {
  #|         current.webgpu.presentScheduled = false;
  #|       }
  #|       try {
  #|         presentNow(current);
  #|       } catch (error) {
  #|         if (current.webgpu != null) {
  #|           current.webgpu.lastError = String(error);
  #|         }
  #|       }
  #|     });
  #|     return true;
  #|   }
  #|   try {
  #|     return presentNow(state);
  #|   } catch (error) {
  #|     gpu.lastError = String(error);
  #|     return false;
  #|   }
  #| }

///|
extern "js" fn js_webgl2_begin(
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
) -> Unit =
  #| (r, g, b, a) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const webgl2 = state.webgl2;
  #|   if (webgl2 == null) return;
  #|   webgl2.clear = [r, g, b, a];
  #|   webgl2.drawCalls = 0;
  #|   webgl2.commandCount = 0;
  #|   webgl2.lastPipelineId = 0;
  #|   webgl2.lastUniformHash = 0;
  #|   webgl2.lastBlendMode = 1;
  #|   webgl2.lastDstImageId = 0;
  #|   webgl2.lastShaderId = 0;
  #|   webgl2.lastIndexOffset = 0;
  #|   webgl2.lastRegionCount = 0;
  #|   webgl2.lastTotalIndexCount = 0;
  #|   webgl2.lastVertexFloatCount = 0;
  #|   webgl2.lastIndexCount = 0;
  #|   webgl2.lastSrcImageCount = 0;
  #|   webgl2.lastUniformDwordCount = 0;
  #| }

///|
extern "js" fn js_webgl2_record_draw(
  draw_calls : Int,
  pipeline_id : Int,
  uniform_hash : Int,
  blend_mode : Int,
  dst_image_id : Int,
  shader_id : Int,
  index_offset : Int,
  region_count : Int,
  total_index_count : Int,
  vertex_float_count : Int,
  index_count : Int,
  src_image_count : Int,
  uniform_dword_count : Int,
  payload_has_triangle : Int,
  payload_ax : Double,
  payload_ay : Double,
  payload_bx : Double,
  payload_by : Double,
  payload_cx : Double,
  payload_cy : Double,
  payload_au : Double,
  payload_av : Double,
  payload_bu : Double,
  payload_bv : Double,
  payload_cu : Double,
  payload_cv : Double,
  payload_uniform_r : Double,
  payload_uniform_g : Double,
  payload_uniform_b : Double,
  payload_uniform_a : Double,
  payload_texture_seed : Int,
) -> Unit =
  #| (drawCalls, pipelineId, uniformHash, blendMode, dstImageId, shaderId, indexOffset, regionCount, totalIndexCount, vertexFloatCount, indexCount, srcImageCount, uniformDwordCount, payloadHasTriangle, payloadAx, payloadAy, payloadBx, payloadBy, payloadCx, payloadCy, payloadAu, payloadAv, payloadBu, payloadBv, payloadCu, payloadCv, payloadUniformR, payloadUniformG, payloadUniformB, payloadUniformA, payloadTextureSeed) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const webgl2 = state.webgl2;
  #|   if (webgl2 == null) return;
  #|   webgl2.drawCalls += drawCalls <= 0 ? 1 : drawCalls;
  #|   webgl2.commandCount = (Number(webgl2.commandCount ?? 0) | 0) + 1;
  #|   webgl2.lastPipelineId = Number(pipelineId ?? 0) | 0;
  #|   webgl2.lastUniformHash = Number(uniformHash ?? 0) | 0;
  #|   let safeBlend = Number(blendMode ?? 1) | 0;
  #|   if (safeBlend < 0 || safeBlend > 3) safeBlend = 1;
  #|   webgl2.lastBlendMode = safeBlend;
  #|   webgl2.lastDstImageId = Number(dstImageId ?? 0) | 0;
  #|   webgl2.lastShaderId = Number(shaderId ?? 0) | 0;
  #|   webgl2.lastIndexOffset = Number(indexOffset ?? 0) | 0;
  #|   webgl2.lastRegionCount = Number(regionCount ?? 0) | 0;
  #|   webgl2.lastTotalIndexCount = Number(totalIndexCount ?? 0) | 0;
  #|   webgl2.lastVertexFloatCount = Number(vertexFloatCount ?? 0) | 0;
  #|   webgl2.lastIndexCount = Number(indexCount ?? 0) | 0;
  #|   webgl2.lastSrcImageCount = Number(srcImageCount ?? 0) | 0;
  #|   webgl2.lastUniformDwordCount = Number(uniformDwordCount ?? 0) | 0;
  #|   webgl2.lastPayloadHasTriangle = (Number(payloadHasTriangle ?? 0) | 0) !== 0;
  #|   webgl2.lastPayloadAx = Number(payloadAx ?? 0);
  #|   webgl2.lastPayloadAy = Number(payloadAy ?? 0);
  #|   webgl2.lastPayloadBx = Number(payloadBx ?? 0);
  #|   webgl2.lastPayloadBy = Number(payloadBy ?? 0);
  #|   webgl2.lastPayloadCx = Number(payloadCx ?? 0);
  #|   webgl2.lastPayloadCy = Number(payloadCy ?? 0);
  #|   webgl2.lastPayloadAu = Number(payloadAu ?? 0);
  #|   webgl2.lastPayloadAv = Number(payloadAv ?? 0);
  #|   webgl2.lastPayloadBu = Number(payloadBu ?? 0);
  #|   webgl2.lastPayloadBv = Number(payloadBv ?? 0);
  #|   webgl2.lastPayloadCu = Number(payloadCu ?? 0);
  #|   webgl2.lastPayloadCv = Number(payloadCv ?? 0);
  #|   webgl2.lastPayloadUniformR = Number(payloadUniformR ?? 1);
  #|   webgl2.lastPayloadUniformG = Number(payloadUniformG ?? 1);
  #|   webgl2.lastPayloadUniformB = Number(payloadUniformB ?? 1);
  #|   webgl2.lastPayloadUniformA = Number(payloadUniformA ?? 1);
  #|   webgl2.lastPayloadTextureSeed = Number(payloadTextureSeed ?? 0) | 0;
  #| }

///|
extern "js" fn js_webgl2_present() -> Bool =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return false;
  #|   const webgl2 = state.webgl2;
  #|   const gl = webgl2 == null ? null : webgl2.context;
  #|   if (webgl2 == null || gl == null) return false;
  #|   const presentNow = (currentState) => {
  #|     const canvas = currentState.canvas;
  #|     if (canvas != null && typeof canvas.getBoundingClientRect === "function") {
  #|       const dpr = Number(globalThis.devicePixelRatio ?? 1) || 1;
  #|       const rect = canvas.getBoundingClientRect();
  #|       const cssWidth = rect.width > 0 ? rect.width : currentState.width;
  #|       const cssHeight = rect.height > 0 ? rect.height : currentState.height;
  #|       const pixelWidth = Math.max(1, Math.round(cssWidth * dpr));
  #|       const pixelHeight = Math.max(1, Math.round(cssHeight * dpr));
  #|       if (canvas.width !== pixelWidth) canvas.width = pixelWidth;
  #|       if (canvas.height !== pixelHeight) canvas.height = pixelHeight;
  #|       currentState.width = pixelWidth;
  #|       currentState.height = pixelHeight;
  #|       currentState.dpr = dpr;
  #|     }
  #|     const currentWebgl2 = currentState.webgl2;
  #|     const currentGl = currentWebgl2 == null ? null : currentWebgl2.context;
  #|     if (currentWebgl2 == null || currentGl == null) {
  #|       return false;
  #|     }
  #|     currentGl.viewport(0, 0, currentState.width, currentState.height);
  #|     const [r, g, b, a] = currentWebgl2.clear;
  #|     currentGl.clearColor(r, g, b, a);
  #|     currentGl.clear(currentGl.COLOR_BUFFER_BIT);
  #|     const drawCalls = Number(currentWebgl2.drawCalls ?? 0) | 0;
  #|     if (drawCalls > 0) {
  #|       let program = currentWebgl2.program;
  #|       let vao = currentWebgl2.vao;
  #|       const payloadHasTriangle = !!currentWebgl2.lastPayloadHasTriangle;
  #|       const ax = payloadHasTriangle ? Number(currentWebgl2.lastPayloadAx ?? 0.0) : 0.0;
  #|       const ay = payloadHasTriangle ? Number(currentWebgl2.lastPayloadAy ?? 0.5) : 0.5;
  #|       const bx = payloadHasTriangle ? Number(currentWebgl2.lastPayloadBx ?? -0.5) : -0.5;
  #|       const by = payloadHasTriangle ? Number(currentWebgl2.lastPayloadBy ?? -0.5) : -0.5;
  #|       const cx = payloadHasTriangle ? Number(currentWebgl2.lastPayloadCx ?? 0.5) : 0.5;
  #|       const cy = payloadHasTriangle ? Number(currentWebgl2.lastPayloadCy ?? -0.5) : -0.5;
  #|       const uniformR = Number(currentWebgl2.lastPayloadUniformR ?? 1.0);
  #|       const uniformG = Number(currentWebgl2.lastPayloadUniformG ?? 0.0);
  #|       const uniformB = Number(currentWebgl2.lastPayloadUniformB ?? 0.0);
  #|       const uniformA = Number(currentWebgl2.lastPayloadUniformA ?? 1.0);
  #|       const shaderKey = [
  #|         ax.toFixed(6), ay.toFixed(6), bx.toFixed(6), by.toFixed(6), cx.toFixed(6), cy.toFixed(6),
  #|         uniformR.toFixed(6), uniformG.toFixed(6), uniformB.toFixed(6), uniformA.toFixed(6),
  #|       ].join("|");
  #|       const needsProgram = program == null || currentWebgl2.programKey !== shaderKey;
  #|       if (needsProgram && typeof currentGl.createShader === "function" && typeof currentGl.createProgram === "function") {
  #|         if (program != null && typeof currentGl.deleteProgram === "function") {
  #|           currentGl.deleteProgram(program);
  #|           program = null;
  #|         }
  #|         const compile = (type, source) => {
  #|           const shader = currentGl.createShader(type);
  #|           if (shader == null) return null;
  #|           currentGl.shaderSource(shader, source);
  #|           currentGl.compileShader(shader);
  #|           if (!currentGl.getShaderParameter(shader, currentGl.COMPILE_STATUS)) {
  #|             const log = typeof currentGl.getShaderInfoLog === "function"
  #|               ? currentGl.getShaderInfoLog(shader)
  #|               : "";
  #|             if (typeof currentGl.deleteShader === "function") currentGl.deleteShader(shader);
  #|             throw new Error(String(log || "webgl2 shader compile failed"));
  #|           }
  #|           return shader;
  #|         };
  #|         const vertexShaderSource = `#version 300 es
  #| precision highp float;
  #| const vec2 POS[3] = vec2[3](
  #|   vec2(${ax}, ${ay}),
  #|   vec2(${bx}, ${by}),
  #|   vec2(${cx}, ${cy})
  #| );
  #| void main() {
  #|   gl_Position = vec4(POS[gl_VertexID], 0.0, 1.0);
  #| }`;
  #|         const fragmentShaderSource = `#version 300 es
  #| precision highp float;
  #| out vec4 outColor;
  #| void main() {
  #|   outColor = vec4(${uniformR}, ${uniformG}, ${uniformB}, ${uniformA});
  #| }`;
  #|         const vs = compile(
  #|           currentGl.VERTEX_SHADER,
  #|           vertexShaderSource,
  #|         );
  #|         const fs = compile(
  #|           currentGl.FRAGMENT_SHADER,
  #|           fragmentShaderSource,
  #|         );
  #|         if (vs != null && fs != null) {
  #|           program = currentGl.createProgram();
  #|           if (program != null) {
  #|             currentGl.attachShader(program, vs);
  #|             currentGl.attachShader(program, fs);
  #|             currentGl.linkProgram(program);
  #|             if (!currentGl.getProgramParameter(program, currentGl.LINK_STATUS)) {
  #|               const log = typeof currentGl.getProgramInfoLog === "function"
  #|                 ? currentGl.getProgramInfoLog(program)
  #|                 : "";
  #|               if (typeof currentGl.deleteProgram === "function") currentGl.deleteProgram(program);
  #|               program = null;
  #|               throw new Error(String(log || "webgl2 program link failed"));
  #|             }
  #|             if (typeof currentGl.createVertexArray === "function") {
  #|               vao = currentGl.createVertexArray();
  #|             } else {
  #|               vao = null;
  #|             }
  #|             currentWebgl2.program = program;
  #|             currentWebgl2.vao = vao;
  #|             currentWebgl2.programKey = shaderKey;
  #|             currentWebgl2.lastVertexShaderSource = vertexShaderSource;
  #|             currentWebgl2.lastFragmentShaderSource = fragmentShaderSource;
  #|           }
  #|           if (typeof currentGl.deleteShader === "function") {
  #|             currentGl.deleteShader(vs);
  #|             currentGl.deleteShader(fs);
  #|           }
  #|         }
  #|       }
  #|       if (program != null && typeof currentGl.useProgram === "function" && typeof currentGl.drawArrays === "function") {
  #|         currentGl.useProgram(program);
  #|         if (vao != null && typeof currentGl.bindVertexArray === "function") {
  #|           currentGl.bindVertexArray(vao);
  #|         }
  #|         const tri = currentGl.TRIANGLES ?? 0x0004;
  #|         for (let i = 0; i < drawCalls; i++) {
  #|           currentGl.drawArrays(tri, 0, 3);
  #|         }
  #|         if (vao != null && typeof currentGl.bindVertexArray === "function") {
  #|           currentGl.bindVertexArray(null);
  #|         }
  #|         currentGl.useProgram(null);
  #|       }
  #|     }
  #|     currentWebgl2.drawCalls = 0;
  #|     return true;
  #|   };
  #|   const scheduleVsync = !!state.vsyncEnabled && typeof globalThis.requestAnimationFrame === "function";
  #|   if (scheduleVsync) {
  #|     if (webgl2.presentScheduled) {
  #|       return true;
  #|     }
  #|     webgl2.presentScheduled = true;
  #|     globalThis.requestAnimationFrame(() => {
  #|       const current = globalThis.__gameEngineWebRuntime;
  #|       if (current == null) return;
  #|       if (current.webgl2 != null) {
  #|         current.webgl2.presentScheduled = false;
  #|       }
  #|       try {
  #|         presentNow(current);
  #|       } catch (_) {}
  #|     });
  #|     return true;
  #|   }
  #|   try {
  #|     return presentNow(state);
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }

///|
extern "js" fn test_setup_present_state(
  use_webgpu : Bool,
  use_raf : Bool,
  vsync_enabled : Bool,
) -> Unit =
  #| (useWebGpu, useRaf, vsyncEnabled) => {
  #|   const root = globalThis;
  #|   if (!("__gameEnginePresentTestOriginalRAF" in root)) {
  #|     root.__gameEnginePresentTestOriginalRAF = root.requestAnimationFrame;
  #|   }
  #|   root.__gameEnginePresentTestQueue = [];
  #|   if (useRaf) {
  #|     root.requestAnimationFrame = (callback) => {
  #|       root.__gameEnginePresentTestQueue.push(callback);
  #|       return root.__gameEnginePresentTestQueue.length;
  #|     };
  #|   } else if (root.__gameEnginePresentTestOriginalRAF == null) {
  #|     root.requestAnimationFrame = undefined;
  #|   } else {
  #|     root.requestAnimationFrame = root.__gameEnginePresentTestOriginalRAF;
  #|   }
  #|   const stats = {
  #|     submits: 0,
  #|     clears: 0,
  #|     draws: 0,
  #|     lastWebGpuShaderCode: "",
  #|     lastWebgl2VertexShaderSource: "",
  #|     lastWebgl2FragmentShaderSource: "",
  #|   };
  #|   const webgpuContext = {
  #|     configure: () => {},
  #|     getCurrentTexture: () => ({ createView: () => ({}) }),
  #|   };
  #|   const webgpuDevice = {
  #|     createCommandEncoder: () => ({
  #|       beginRenderPass: () => ({
  #|         setPipeline: () => {},
  #|         draw: () => {
  #|           stats.draws += 1;
  #|         },
  #|         end: () => {},
  #|       }),
  #|       finish: () => ({}),
  #|     }),
  #|     createShaderModule: (descriptor) => {
  #|       stats.lastWebGpuShaderCode = descriptor == null
  #|         ? ""
  #|         : String(descriptor.code ?? "");
  #|       return {};
  #|     },
  #|     createRenderPipeline: () => ({}),
  #|     queue: {
  #|       submit: () => {
  #|         stats.submits += 1;
  #|       },
  #|     },
  #|   };
  #|   const webgl2Context = {
  #|     COLOR_BUFFER_BIT: 0x4000,
  #|     viewport: () => {},
  #|     clearColor: () => {},
  #|     clear: () => {
  #|       stats.clears += 1;
  #|     },
  #|     drawArrays: () => {
  #|       stats.draws += 1;
  #|     },
  #|     createShader: (type) => ({ __shaderType: Number(type) | 0 }),
  #|     shaderSource: (shader, source) => {
  #|       const shaderType = shader == null ? 0 : (Number(shader.__shaderType ?? 0) | 0);
  #|       if (shaderType === 0x8B31) {
  #|         stats.lastWebgl2VertexShaderSource = String(source ?? "");
  #|       } else if (shaderType === 0x8B30) {
  #|         stats.lastWebgl2FragmentShaderSource = String(source ?? "");
  #|       }
  #|     },
  #|     compileShader: () => {},
  #|     getShaderParameter: () => true,
  #|     getShaderInfoLog: () => "",
  #|     deleteShader: () => {},
  #|     createProgram: () => ({}),
  #|     attachShader: () => {},
  #|     linkProgram: () => {},
  #|     getProgramParameter: () => true,
  #|     getProgramInfoLog: () => "",
  #|     deleteProgram: () => {},
  #|     useProgram: () => {},
  #|     createVertexArray: () => ({}),
  #|     bindVertexArray: () => {},
  #|     VERTEX_SHADER: 0x8B31,
  #|     FRAGMENT_SHADER: 0x8B30,
  #|     COMPILE_STATUS: 0x8B81,
  #|     LINK_STATUS: 0x8B82,
  #|     TRIANGLES: 0x0004,
  #|   };
  #|   root.__gameEnginePresentTestStats = stats;
  #|   root.__gameEngineWebRuntime = {
  #|     canvas: null,
  #|     width: 320,
  #|     height: 240,
  #|     dpr: 1,
  #|     vsyncEnabled: !!vsyncEnabled,
  #|     webgpu: {
  #|       context: useWebGpu ? webgpuContext : null,
  #|       device: useWebGpu ? webgpuDevice : null,
  #|       format: "bgra8unorm",
  #|       pending: null,
  #|       pipeline: null,
  #|       pipelineFormat: "",
  #|       presentScheduled: false,
  #|       clear: [0, 0, 0, 1],
  #|       drawCalls: 1,
  #|       commandCount: 0,
  #|       lastPipelineId: 0,
  #|       lastUniformHash: 0,
  #|       lastBlendMode: 1,
  #|       lastDstImageId: 0,
  #|       lastShaderId: 0,
  #|       lastIndexOffset: 0,
  #|       lastRegionCount: 0,
  #|       lastTotalIndexCount: 0,
  #|       lastVertexFloatCount: 0,
  #|       lastIndexCount: 0,
  #|       lastSrcImageCount: 0,
  #|       lastUniformDwordCount: 0,
  #|       lastError: "",
  #|     },
  #|     webgl2: {
  #|       context: useWebGpu ? null : webgl2Context,
  #|       program: null,
  #|       vao: null,
  #|       presentScheduled: false,
  #|       clear: [0, 0, 0, 1],
  #|       drawCalls: 1,
  #|       commandCount: 0,
  #|       lastPipelineId: 0,
  #|       lastUniformHash: 0,
  #|       lastBlendMode: 1,
  #|       lastDstImageId: 0,
  #|       lastShaderId: 0,
  #|       lastIndexOffset: 0,
  #|       lastRegionCount: 0,
  #|       lastTotalIndexCount: 0,
  #|       lastVertexFloatCount: 0,
  #|       lastIndexCount: 0,
  #|       lastSrcImageCount: 0,
  #|       lastUniformDwordCount: 0,
  #|     },
  #|   };
  #| }

///|
extern "js" fn test_drain_present_raf() -> Int =
  #| () => {
  #|   const root = globalThis;
  #|   const queue = root.__gameEnginePresentTestQueue;
  #|   if (!Array.isArray(queue)) return 0;
  #|   let drained = 0;
  #|   while (queue.length > 0) {
  #|     const callback = queue.shift();
  #|     if (typeof callback === "function") {
  #|       callback(0);
  #|       drained += 1;
  #|     }
  #|   }
  #|   return drained;
  #| }

///|
extern "js" fn test_present_raf_queue_length() -> Int =
  #| () => {
  #|   const queue = globalThis.__gameEnginePresentTestQueue;
  #|   if (!Array.isArray(queue)) return 0;
  #|   return queue.length | 0;
  #| }

///|
extern "js" fn test_present_submit_count() -> Int =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return 0;
  #|   return Number(stats.submits ?? 0) | 0;
  #| }

///|
extern "js" fn test_present_clear_count() -> Int =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return 0;
  #|   return Number(stats.clears ?? 0) | 0;
  #| }

///|
extern "js" fn test_present_draw_count() -> Int =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return 0;
  #|   return Number(stats.draws ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_webgpu_shader_source() -> String =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return "";
  #|   return String(stats.lastWebGpuShaderCode ?? "");
  #| }

///|
extern "js" fn test_last_webgl2_vertex_shader_source() -> String =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return "";
  #|   return String(stats.lastWebgl2VertexShaderSource ?? "");
  #| }

///|
extern "js" fn test_last_webgl2_fragment_shader_source() -> String =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return "";
  #|   return String(stats.lastWebgl2FragmentShaderSource ?? "");
  #| }

///|
extern "js" fn test_last_pipeline_id(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastPipelineId ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_uniform_hash(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastUniformHash ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_blend_mode(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 1;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 1;
  #|   return Number(target.lastBlendMode ?? 1) | 0;
  #| }

///|
extern "js" fn test_last_dst_image_id(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastDstImageId ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_shader_id(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastShaderId ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_index_offset(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastIndexOffset ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_region_count(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastRegionCount ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_total_index_count(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastTotalIndexCount ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_vertex_float_count(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastVertexFloatCount ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_index_count(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastIndexCount ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_src_image_count(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastSrcImageCount ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_uniform_dword_count(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastUniformDwordCount ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_payload_has_triangle(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return target.lastPayloadHasTriangle ? 1 : 0;
  #| }

///|
extern "js" fn test_last_payload_ax(use_webgpu : Bool) -> Double =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastPayloadAx ?? 0);
  #| }

///|
extern "js" fn test_last_payload_uniform_r(use_webgpu : Bool) -> Double =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 1;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 1;
  #|   return Number(target.lastPayloadUniformR ?? 1);
  #| }

///|
extern "js" fn test_last_payload_texture_seed(use_webgpu : Bool) -> Int =
  #| (useWebGpu) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return 0;
  #|   const target = useWebGpu ? state.webgpu : state.webgl2;
  #|   if (target == null) return 0;
  #|   return Number(target.lastPayloadTextureSeed ?? 0) | 0;
  #| }

///|
extern "js" fn test_set_input_state(
  cursor_x : Double,
  cursor_y : Double,
  wheel_x : Double,
  wheel_y : Double,
  key0 : Int,
  key1 : Int,
  key_count : Int,
) -> Unit =
  #| (cursorX, cursorY, wheelX, wheelY, key0, key1, keyCount) => {
  #|   const root = globalThis;
  #|   if (typeof root.__gameEngineEnsureWindowState === "function") {
  #|     root.__gameEngineEnsureWindowState("#app");
  #|   }
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {});
  #|   state.cursorX = Number(cursorX) || 0;
  #|   state.cursorY = Number(cursorY) || 0;
  #|   state.wheelX = Number(wheelX) || 0;
  #|   state.wheelY = Number(wheelY) || 0;
  #|   const count = Number(keyCount) | 0;
  #|   const keys = [];
  #|   if (count > 0) keys.push(Number(key0) | 0);
  #|   if (count > 1) keys.push(Number(key1) | 0);
  #|   state.pressedKeys = keys;
  #|   state.pressedMouseButtons = [];
  #|   state.touches = [];
  #|   state.testGamepads = [];
  #| }

///|
extern "js" fn test_set_extended_input_state(
  cursor_x : Double,
  cursor_y : Double,
  wheel_x : Double,
  wheel_y : Double,
  key0 : Int,
  key1 : Int,
  key_count : Int,
  mouse_button0 : Int,
  mouse_button_count : Int,
  _touch_count : Int,
  touch0_id : Int,
  touch0_x : Double,
  touch0_y : Double,
  gamepad_count : Int,
  gamepad0_id : Int,
  gamepad0_axis_count : Int,
  gamepad0_axis0 : Double,
  gamepad0_axis1 : Double,
  gamepad0_button_count : Int,
  gamepad0_button0 : Int,
  gamepad0_button1 : Int,
) -> Unit =
  #| (
  #|   cursorX,
  #|   cursorY,
  #|   wheelX,
  #|   wheelY,
  #|   key0,
  #|   key1,
  #|   keyCount,
  #|   mouseButton0,
  #|   mouseButtonCount,
  #|   _touchCount,
  #|   touch0Id,
  #|   touch0X,
  #|   touch0Y,
  #|   gamepadCount,
  #|   gamepad0Id,
  #|   gamepad0AxisCount,
  #|   gamepad0Axis0,
  #|   gamepad0Axis1,
  #|   gamepad0ButtonCount,
  #|   gamepad0Button0,
  #|   gamepad0Button1
  #| ) => {
  #|   const root = globalThis;
  #|   if (typeof root.__gameEngineEnsureWindowState === "function") {
  #|     root.__gameEngineEnsureWindowState("#app");
  #|   }
  #|   const state = root.__gameEngineWebRuntime ?? (root.__gameEngineWebRuntime = {});
  #|   state.cursorX = Number(cursorX) || 0;
  #|   state.cursorY = Number(cursorY) || 0;
  #|   state.wheelX = Number(wheelX) || 0;
  #|   state.wheelY = Number(wheelY) || 0;
  #|   const count = Number(keyCount) | 0;
  #|   const keys = [];
  #|   if (count > 0) keys.push(Number(key0) | 0);
  #|   if (count > 1) keys.push(Number(key1) | 0);
  #|   state.pressedKeys = keys;
  #|   const mouseCount = Number(mouseButtonCount) | 0;
  #|   const mouseButtons = [];
  #|   if (mouseCount > 0) mouseButtons.push(Number(mouseButton0) | 0);
  #|   state.pressedMouseButtons = mouseButtons;
  #|   state.touches = [{
  #|     id: Number(touch0Id) | 0,
  #|     x: Number(touch0X) || 0,
  #|     y: Number(touch0Y) || 0,
  #|   }];
  #|   const gpCount = Number(gamepadCount) | 0;
  #|   if (gpCount > 0) {
  #|     const axes = [];
  #|     const axisCount = Number(gamepad0AxisCount) | 0;
  #|     if (axisCount > 0) axes.push(Number(gamepad0Axis0) || 0);
  #|     if (axisCount > 1) axes.push(Number(gamepad0Axis1) || 0);
  #|     const pressedButtons = [];
  #|     const buttonCount = Number(gamepad0ButtonCount) | 0;
  #|     if (buttonCount > 0) pressedButtons.push(Number(gamepad0Button0) | 0);
  #|     if (buttonCount > 1) pressedButtons.push(Number(gamepad0Button1) | 0);
  #|     state.testGamepads = [{ id: Number(gamepad0Id) | 0, axes, pressedButtons }];
  #|   } else {
  #|     state.testGamepads = [];
  #|   }
  #| }

///|
extern "js" fn test_reset_gamepad_state() -> Unit =
  #| () => {
  #|   const root = globalThis;
  #|   const state = root.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   state.testGamepads = [];
  #| }

///|
extern "js" fn test_teardown_present_state() -> Unit =
  #| () => {
  #|   const root = globalThis;
  #|   if ("__gameEnginePresentTestOriginalRAF" in root) {
  #|     const original = root.__gameEnginePresentTestOriginalRAF;
  #|     if (original == null) {
  #|       root.requestAnimationFrame = undefined;
  #|     } else {
  #|       root.requestAnimationFrame = original;
  #|     }
  #|   }
  #|   delete root.__gameEnginePresentTestQueue;
  #|   delete root.__gameEnginePresentTestStats;
  #|   delete root.__gameEngineWebRuntime;
  #| }

///|
fn new_test_payload_draw_command() -> @gfx.DrawTrianglesCommand {
  @gfx.new_draw_triangles_command(
    @gfx.new_image_handle(101, 64, 64),
    @gfx.new_shader_handle(201, "shader"),
    [@gfx.new_dst_region(0, 0, 32, 32, 3)],
    4,
    7,
    11,
    @gfx.blend_mode_from_int(2),
    [-0.8, 0.7, 0.0, 0.0, -0.2, -0.6, 1.0, 0.0, 0.9, -0.3, 1.0, 1.0],
    [0, 1, 2],
    [5],
    [51, 102, 229, 255],
  )
}

///|
test "js_webgpu_present schedules once when vsync is enabled" {
  test_setup_present_state(true, true, true)
  let first = js_webgpu_present()
  assert_true(first)
  assert_eq(test_present_raf_queue_length(), 1)
  assert_eq(test_present_submit_count(), 0)

  let second = js_webgpu_present()
  assert_true(second)
  assert_eq(test_present_raf_queue_length(), 1)
  assert_eq(test_present_submit_count(), 0)

  assert_eq(test_drain_present_raf(), 1)
  assert_eq(test_present_submit_count(), 1)
  test_teardown_present_state()
}

///|
test "js_webgpu_present is immediate when vsync is disabled" {
  test_setup_present_state(true, true, false)
  let presented = js_webgpu_present()
  assert_true(presented)
  assert_eq(test_present_raf_queue_length(), 0)
  assert_eq(test_present_submit_count(), 1)
  test_teardown_present_state()
}

///|
test "js_webgl2_present schedules once when vsync is enabled" {
  test_setup_present_state(false, true, true)
  let first = js_webgl2_present()
  assert_true(first)
  assert_eq(test_present_raf_queue_length(), 1)
  assert_eq(test_present_clear_count(), 0)

  let second = js_webgl2_present()
  assert_true(second)
  assert_eq(test_present_raf_queue_length(), 1)
  assert_eq(test_present_clear_count(), 0)

  assert_eq(test_drain_present_raf(), 1)
  assert_eq(test_present_clear_count(), 1)
  test_teardown_present_state()
}

///|
test "js_webgpu_present emits draw calls from recorded count" {
  test_setup_present_state(true, false, false)
  js_webgpu_begin(0.0, 0.0, 0.0, 1.0)
  js_webgpu_record_draw(
    3, 7, 11, 2, 100, 200, 4, 2, 9, 16, 6, 2, 3, 1, -0.8, 0.7, -0.2, -0.6, 0.9, -0.3,
    0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.2, 0.4, 0.9, 1.0, 5,
  )
  let presented = js_webgpu_present()
  assert_true(presented)
  assert_eq(test_present_draw_count(), 3)
  assert_eq(test_last_pipeline_id(true), 7)
  assert_eq(test_last_uniform_hash(true), 11)
  assert_eq(test_last_blend_mode(true), 2)
  assert_eq(test_last_dst_image_id(true), 100)
  assert_eq(test_last_shader_id(true), 200)
  assert_eq(test_last_index_offset(true), 4)
  assert_eq(test_last_region_count(true), 2)
  assert_eq(test_last_total_index_count(true), 9)
  assert_eq(test_last_vertex_float_count(true), 16)
  assert_eq(test_last_index_count(true), 6)
  assert_eq(test_last_src_image_count(true), 2)
  assert_eq(test_last_uniform_dword_count(true), 3)
  assert_eq(test_last_payload_has_triangle(true), 1)
  assert_true(test_last_payload_ax(true) < -0.7)
  assert_true(test_last_payload_uniform_r(true) > 0.19)
  assert_eq(test_last_payload_texture_seed(true), 5)
  assert_true(test_last_webgpu_shader_source().contains("vec2f(-0.8, 0.7)"))
  assert_true(test_last_webgpu_shader_source().contains("vec4f(0.2, 0.4, 0.9"))
  test_teardown_present_state()
}

///|
test "js_webgl2_present emits draw calls from recorded count" {
  test_setup_present_state(false, false, false)
  js_webgl2_begin(0.0, 0.0, 0.0, 1.0)
  js_webgl2_record_draw(
    4, 9, 13, 3, 101, 201, 8, 1, 3, 12, 3, 1, 4, 1, -0.7, 0.6, -0.1, -0.5, 0.8, -0.4,
    0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.3, 0.5, 0.8, 1.0, 8,
  )
  let presented = js_webgl2_present()
  assert_true(presented)
  assert_eq(test_present_draw_count(), 4)
  assert_eq(test_last_pipeline_id(false), 9)
  assert_eq(test_last_uniform_hash(false), 13)
  assert_eq(test_last_blend_mode(false), 3)
  assert_eq(test_last_dst_image_id(false), 101)
  assert_eq(test_last_shader_id(false), 201)
  assert_eq(test_last_index_offset(false), 8)
  assert_eq(test_last_region_count(false), 1)
  assert_eq(test_last_total_index_count(false), 3)
  assert_eq(test_last_vertex_float_count(false), 12)
  assert_eq(test_last_index_count(false), 3)
  assert_eq(test_last_src_image_count(false), 1)
  assert_eq(test_last_uniform_dword_count(false), 4)
  assert_eq(test_last_payload_has_triangle(false), 1)
  assert_true(test_last_payload_ax(false) < -0.6)
  assert_true(test_last_payload_uniform_r(false) > 0.29)
  assert_eq(test_last_payload_texture_seed(false), 8)
  assert_true(
    test_last_webgl2_vertex_shader_source().contains("vec2(-0.7, 0.6)"),
  )
  assert_true(
    test_last_webgl2_fragment_shader_source().contains("vec4(0.3, 0.5, 0.8"),
  )
  test_teardown_present_state()
}

///|
test "bridge_web_gfx_on_draw decodes payload and routes webgpu/webgl fallback" {
  test_setup_present_state(true, false, false)
  js_ensure_window_state("#app")
  install("#app")
  let surface = @platform.create_webgpu_surface_token(1, 320, 240, 1.0)
  let driver = @gfx.create_webgpu_graphics(
    surface,
    @gfx.default_graphics_backend_options(),
  )
  driver.initialize()
  let command = new_test_payload_draw_command()

  web_fallback_to_webgl.val = false
  driver.draw_triangles(command)
  assert_eq(test_last_payload_has_triangle(true), 1)
  assert_true(test_last_payload_ax(true) < -0.7)
  assert_true(test_last_payload_uniform_r(true) > 0.19)
  assert_eq(test_last_payload_texture_seed(true), 5)

  web_fallback_to_webgl.val = true
  driver.draw_triangles(command)
  assert_eq(test_last_payload_has_triangle(false), 1)
  assert_true(test_last_payload_ax(false) < -0.7)
  assert_true(test_last_payload_uniform_r(false) > 0.19)
  assert_eq(test_last_payload_texture_seed(false), 5)

  uninstall()
  web_fallback_to_webgl.val = false
  test_teardown_present_state()
}

///|
test "bridge_web_capture_input reads js input state and consumes wheel" {
  js_ensure_window_state("#app")
  test_set_input_state(12.5, 34.25, -1.0, 2.5, 65, 68, 2)

  let input = bridge_web_capture_input(true, 1)
  assert_eq(input.cursor_x.to_int(), 12)
  assert_eq(input.cursor_y.to_int(), 34)
  assert_eq(input.wheel_x.to_int(), -1)
  assert_eq(input.wheel_y.to_int(), 2)
  assert_eq(input.pressed_keys.length(), 2)
  assert_eq(input.pressed_keys[0], 65)
  assert_eq(input.pressed_keys[1], 68)

  let input2 = bridge_web_capture_input(true, 2)
  assert_eq(input2.wheel_x.to_int(), 0)
  assert_eq(input2.wheel_y.to_int(), 0)
  assert_eq(input2.pressed_keys.length(), 2)
  assert_eq(input2.pressed_mouse_buttons.length(), 0)
  assert_eq(input2.touches.length(), 0)
  assert_eq(input2.gamepads.length(), 0)
}

///|
test "bridge_web_capture_input returns empty snapshot when inactive" {
  test_set_input_state(20.0, 30.0, 1.0, 1.0, 90, 0, 1)
  let input = bridge_web_capture_input(false, 1)
  assert_eq(input.cursor_x.to_int(), 0)
  assert_eq(input.cursor_y.to_int(), 0)
  assert_eq(input.wheel_x.to_int(), 0)
  assert_eq(input.wheel_y.to_int(), 0)
  assert_eq(input.pressed_keys.length(), 0)
  assert_eq(input.pressed_mouse_buttons.length(), 0)
  assert_eq(input.touches.length(), 0)
  assert_eq(input.gamepads.length(), 0)
}

///|
test "bridge_web_capture_input reads mouse touch and gamepad state" {
  js_ensure_window_state("#app")
  test_set_extended_input_state(
    1.0, 2.0, 0.0, 0.0, 70, 71, 2, 1, 1, 0, 42, 88.0, 99.0, 1, 7, 2, 0.25, -0.5,
    2, 0, 3,
  )

  let input = bridge_web_capture_input(true, 5)
  assert_eq(input.pressed_keys.length(), 2)
  assert_eq(input.pressed_mouse_buttons.length(), 1)
  assert_eq(input.pressed_mouse_buttons[0], 1)
  assert_eq(input.touches.length(), 1)
  assert_eq(input.touches[0].id, 42)
  assert_eq(input.touches[0].x.to_int(), 88)
  assert_eq(input.touches[0].y.to_int(), 99)
  assert_eq(input.gamepads.length(), 1)
  assert_eq(input.gamepads[0].id, 7)
  assert_eq(input.gamepads[0].axes.length(), 2)
  assert_eq(input.gamepads[0].axes[0].to_int(), 0)
  assert_eq(input.gamepads[0].axes[1].to_int(), 0)
  assert_eq(input.gamepads[0].pressed_buttons.length(), 2)
  assert_eq(input.gamepads[0].pressed_buttons[0], 0)
  assert_eq(input.gamepads[0].pressed_buttons[1], 3)

  test_reset_gamepad_state()
}

///|
fn sync_surface_info(fallback_width : Int, fallback_height : Int) -> Bool {
  js_prepare_surface(web_canvas_selector.val, fallback_width, fallback_height)
}

///|
fn bridge_web_try_initialize(
  canvas_selector : String,
  options : @platform.WindowOptions,
) -> Bool {
  if !web_hooks_installed.val || canvas_selector != web_canvas_selector.val {
    false
  } else {
    js_ensure_window_state(canvas_selector)
    sync_surface_info(options.width, options.height)
  }
}

///|
fn bridge_web_poll(active : Bool) -> Unit {
  if active && web_hooks_installed.val {
    js_ensure_window_state(web_canvas_selector.val)
  }
}

///|
fn bridge_web_should_close() -> Bool {
  js_should_close_state()
}

///|
fn bridge_web_outside_size(width : Int, height : Int) -> @core.OutsideSize {
  let _ = sync_surface_info(width, height)
  @core.new_outside_size(
    js_surface_width(width).to_double(),
    js_surface_height(height).to_double(),
  )
}

///|
fn bridge_web_current_surface(
  _canvas_selector : String,
  options : @platform.WindowOptions,
) -> @platform.SurfaceToken {
  let _ = sync_surface_info(options.width, options.height)
  let width = js_surface_width(options.width)
  let height = js_surface_height(options.height)
  let dpr = js_surface_dpr()
  let id = js_surface_id()
  if web_fallback_to_webgl.val {
    @platform.create_webgl_surface_token(id, width, height, dpr)
  } else {
    @platform.create_webgpu_surface_token(id, width, height, dpr)
  }
}

///|
fn bridge_web_gfx_try_initialize(
  kind : @gfx.GraphicsBackendKind,
  width : Int,
  height : Int,
) -> Bool {
  match kind {
    @gfx.GraphicsBackendKind::WebGpu => {
      let webgpu_ready = js_try_initialize_webgpu(
        web_canvas_selector.val,
        width,
        height,
      )
      if webgpu_ready {
        web_fallback_to_webgl.val = false
        true
      } else {
        let webgl_ready = js_try_initialize_webgl2(
          web_canvas_selector.val,
          width,
          height,
        )
        web_fallback_to_webgl.val = webgl_ready
        webgl_ready
      }
    }
    @gfx.GraphicsBackendKind::WebGl2 => {
      let webgl_ready = js_try_initialize_webgl2(
        web_canvas_selector.val,
        width,
        height,
      )
      web_fallback_to_webgl.val = webgl_ready
      webgl_ready
    }
    _ => false
  }
}

///|
fn bridge_web_gfx_on_begin(
  active : Bool,
  kind : @gfx.GraphicsBackendKind,
  pass : @gfx.RenderPassDesc,
) -> Unit {
  if active {
    match kind {
      @gfx.GraphicsBackendKind::WebGpu =>
        if web_fallback_to_webgl.val {
          js_webgl2_begin(
            pass.clear_color.r,
            pass.clear_color.g,
            pass.clear_color.b,
            pass.clear_color.a,
          )
        } else {
          js_webgpu_begin(
            pass.clear_color.r,
            pass.clear_color.g,
            pass.clear_color.b,
            pass.clear_color.a,
          )
        }
      @gfx.GraphicsBackendKind::WebGl2 =>
        js_webgl2_begin(
          pass.clear_color.r,
          pass.clear_color.g,
          pass.clear_color.b,
          pass.clear_color.a,
        )
      _ => ()
    }
  }
}

///|
fn bridge_web_gfx_on_end(
  active : Bool,
  kind : @gfx.GraphicsBackendKind,
  present : Bool,
) -> Unit {
  if active && present {
    match kind {
      @gfx.GraphicsBackendKind::WebGpu =>
        if web_fallback_to_webgl.val {
          let _ = js_webgl2_present()
        } else {
          let _ = js_webgpu_present()
        }
      @gfx.GraphicsBackendKind::WebGl2 => {
        let _ = js_webgl2_present()
      }
      _ => ()
    }
  }
}

///|
fn bridge_web_gfx_on_draw(
  active : Bool,
  kind : @gfx.GraphicsBackendKind,
  command : @gfx.DrawTrianglesCommand,
) -> Unit {
  if active {
    let dispatch = @gfx.build_draw_command_dispatch(command)
    let payload = @payload2d.decode_triangle_payload(
      command.vertex_data,
      command.indices,
      command.uniform_dwords,
      command.src_image_ids,
    )
    let payload_has_triangle = if payload.has_payload { 1 } else { 0 }
    match kind {
      @gfx.GraphicsBackendKind::WebGpu =>
        if web_fallback_to_webgl.val {
          js_webgl2_record_draw(
            dispatch.draw_calls,
            dispatch.pipeline_id,
            dispatch.uniform_hash,
            dispatch.blend_mode,
            dispatch.dst_image_id,
            dispatch.shader_id,
            dispatch.index_offset,
            dispatch.region_count,
            dispatch.total_index_count,
            dispatch.vertex_float_count,
            dispatch.index_count,
            dispatch.src_image_count,
            dispatch.uniform_dword_count,
            payload_has_triangle,
            payload.ax,
            payload.ay,
            payload.bx,
            payload.by,
            payload.cx,
            payload.cy,
            payload.au,
            payload.av,
            payload.bu,
            payload.bv,
            payload.cu,
            payload.cv,
            payload.uniform_r,
            payload.uniform_g,
            payload.uniform_b,
            payload.uniform_a,
            payload.texture_seed,
          )
        } else {
          js_webgpu_record_draw(
            dispatch.draw_calls,
            dispatch.pipeline_id,
            dispatch.uniform_hash,
            dispatch.blend_mode,
            dispatch.dst_image_id,
            dispatch.shader_id,
            dispatch.index_offset,
            dispatch.region_count,
            dispatch.total_index_count,
            dispatch.vertex_float_count,
            dispatch.index_count,
            dispatch.src_image_count,
            dispatch.uniform_dword_count,
            payload_has_triangle,
            payload.ax,
            payload.ay,
            payload.bx,
            payload.by,
            payload.cx,
            payload.cy,
            payload.au,
            payload.av,
            payload.bu,
            payload.bv,
            payload.cu,
            payload.cv,
            payload.uniform_r,
            payload.uniform_g,
            payload.uniform_b,
            payload.uniform_a,
            payload.texture_seed,
          )
        }
      @gfx.GraphicsBackendKind::WebGl2 =>
        js_webgl2_record_draw(
          dispatch.draw_calls,
          dispatch.pipeline_id,
          dispatch.uniform_hash,
          dispatch.blend_mode,
          dispatch.dst_image_id,
          dispatch.shader_id,
          dispatch.index_offset,
          dispatch.region_count,
          dispatch.total_index_count,
          dispatch.vertex_float_count,
          dispatch.index_count,
          dispatch.src_image_count,
          dispatch.uniform_dword_count,
          payload_has_triangle,
          payload.ax,
          payload.ay,
          payload.bx,
          payload.by,
          payload.cx,
          payload.cy,
          payload.au,
          payload.av,
          payload.bu,
          payload.bv,
          payload.cu,
          payload.cv,
          payload.uniform_r,
          payload.uniform_g,
          payload.uniform_b,
          payload.uniform_a,
          payload.texture_seed,
        )
      _ => ()
    }
  }
}

///|
fn bridge_web_capture_input(active : Bool, _tick : Int) -> @core.InputSnapshot {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    let pressed_keys : Array[Int] = []
    let key_count = js_input_pressed_key_count()
    for i in 0..<key_count {
      pressed_keys.push(js_input_pressed_key_at(i))
    }
    let pressed_mouse_buttons : Array[Int] = []
    let mouse_button_count = js_input_pressed_mouse_button_count()
    for i in 0..<mouse_button_count {
      let button = js_input_pressed_mouse_button_at(i)
      if button >= 0 {
        pressed_mouse_buttons.push(button)
      }
    }

    let touches : Array[@core.TouchPoint] = []
    let touch_count = js_input_touch_count()
    for i in 0..<touch_count {
      touches.push(
        @core.new_touch_point(
          js_input_touch_id_at(i),
          js_input_touch_x_at(i),
          js_input_touch_y_at(i),
        ),
      )
    }

    let gamepads : Array[@core.GamepadSnapshot] = []
    let gamepad_count = js_input_gamepad_count()
    for i in 0..<gamepad_count {
      let axes : Array[Double] = []
      let axis_count = js_input_gamepad_axis_count(i)
      for j in 0..<axis_count {
        axes.push(js_input_gamepad_axis_at(i, j))
      }

      let pressed_buttons : Array[Int] = []
      let button_count = js_input_gamepad_pressed_button_count(i)
      for j in 0..<button_count {
        let button_id = js_input_gamepad_pressed_button_at(i, j)
        if button_id >= 0 {
          pressed_buttons.push(button_id)
        }
      }

      gamepads.push(
        @core.new_gamepad_snapshot(
          js_input_gamepad_id_at(i),
          axes,
          pressed_buttons,
        ),
      )
    }

    let snapshot = @core.new_input_snapshot_full(
      js_input_cursor_x(),
      js_input_cursor_y(),
      js_input_wheel_x(),
      js_input_wheel_y(),
      pressed_keys,
      pressed_mouse_buttons,
      touches,
      gamepads,
    )
    js_clear_input_wheel()
    snapshot
  } else {
    @core.empty_input_snapshot()
  }
}

///|
fn bridge_web_set_fullscreen(
  _canvas_selector : String,
  active : Bool,
  enabled : Bool,
) -> Bool {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    js_set_fullscreen(web_canvas_selector.val, enabled)
  } else {
    enabled
  }
}

///|
fn bridge_web_is_fullscreen(
  _canvas_selector : String,
  active : Bool,
  current : Bool,
) -> Bool {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    js_is_fullscreen(web_canvas_selector.val, current)
  } else {
    current
  }
}

///|
fn bridge_web_set_cursor_mode(
  _canvas_selector : String,
  active : Bool,
  mode : @platform.CursorMode,
) -> @platform.CursorMode {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    @platform.cursor_mode_from_int(
      js_set_cursor_mode(
        web_canvas_selector.val,
        @platform.cursor_mode_to_int(mode),
      ),
    )
  } else {
    mode
  }
}

///|
fn bridge_web_cursor_mode(
  _canvas_selector : String,
  active : Bool,
  current : @platform.CursorMode,
) -> @platform.CursorMode {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    @platform.cursor_mode_from_int(
      js_cursor_mode(
        web_canvas_selector.val,
        @platform.cursor_mode_to_int(current),
      ),
    )
  } else {
    current
  }
}

///|
fn bridge_web_set_device_scale_factor(
  _canvas_selector : String,
  active : Bool,
  scale : Double,
) -> Double {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    js_set_device_scale_factor(scale)
  } else if scale <= 0.0 {
    1.0
  } else {
    scale
  }
}

///|
fn bridge_web_device_scale_factor(
  _canvas_selector : String,
  active : Bool,
  current : Double,
) -> Double {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    js_device_scale_factor(current)
  } else if current <= 0.0 {
    1.0
  } else {
    current
  }
}

///|
fn bridge_web_set_vsync_enabled(
  _canvas_selector : String,
  active : Bool,
  enabled : Bool,
) -> Bool {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    js_set_vsync_enabled(enabled)
  } else {
    enabled
  }
}

///|
fn bridge_web_is_vsync_enabled(
  _canvas_selector : String,
  active : Bool,
  current : Bool,
) -> Bool {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    js_is_vsync_enabled(current)
  } else {
    current
  }
}

///|
fn bridge_web_close_window(_canvas_selector : String, active : Bool) -> Unit {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    js_set_should_close(true)
  }
}

///|
fn bridge_web_request_attention(
  _canvas_selector : String,
  active : Bool,
) -> Unit {
  if active {
    js_ensure_window_state(web_canvas_selector.val)
    js_request_attention()
  }
}

///|
pub fn install(canvas_selector : String) -> Unit {
  web_canvas_selector.val = canvas_selector
  web_hooks_installed.val = true
  web_fallback_to_webgl.val = false
  js_ensure_window_state(canvas_selector)
  js_set_should_close(false)
  let _ = js_set_vsync_enabled(true)
  @platform.set_web_canvas_hooks(
    @platform.new_web_canvas_hooks(
      bridge_web_try_initialize, bridge_web_poll, bridge_web_should_close, bridge_web_outside_size,
      bridge_web_current_surface, bridge_web_capture_input, bridge_web_set_fullscreen,
      bridge_web_is_fullscreen, bridge_web_set_cursor_mode, bridge_web_cursor_mode,
      bridge_web_set_device_scale_factor, bridge_web_device_scale_factor, bridge_web_set_vsync_enabled,
      bridge_web_is_vsync_enabled, bridge_web_close_window, bridge_web_request_attention,
    ),
  )
  @gfx.set_web_graphics_hooks(
    @gfx.new_web_graphics_hooks(
      bridge_web_gfx_try_initialize, bridge_web_gfx_on_begin, bridge_web_gfx_on_end,
      bridge_web_gfx_on_draw,
    ),
  )
}

///|
pub fn uninstall() -> Unit {
  web_hooks_installed.val = false
  web_fallback_to_webgl.val = false
  js_ensure_window_state(web_canvas_selector.val)
  js_set_should_close(false)
  @gfx.reset_web_graphics_hooks()
  @platform.reset_web_canvas_hooks()
}

///|
pub fn is_ready() -> Bool {
  web_hooks_installed.val
}

///|
pub fn shutdown() -> Unit {
  uninstall()
}
