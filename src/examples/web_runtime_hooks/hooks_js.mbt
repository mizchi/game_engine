///|
let web_canvas_selector : Ref[String] = Ref::new("#app")

///|
let web_hooks_installed : Ref[Bool] = Ref::new(false)

///|
priv struct SyncedSourceGeneration {
  image_id : Int
  generation : Int
}

///|
priv struct SourceImageCacheEntry {
  image_id : Int
  width : Int
  height : Int
  pixels_rgba8 : Array[Int]
}

///|
let synced_source_generations : Ref[Array[SyncedSourceGeneration]] = Ref::new([])

///|
let source_image_cache : Ref[Array[SourceImageCacheEntry]] = Ref::new([])

///|
let gpu_texture_dirty : Ref[Array[Int]] = Ref::new([])

///|
fn mark_gpu_texture_dirty(image_id : Int) -> Unit {
  for id in gpu_texture_dirty.val {
    if id == image_id {
      return
    }
  }
  gpu_texture_dirty.val.push(image_id)
}

///|
fn clear_gpu_texture_dirty() -> Unit {
  gpu_texture_dirty.val = []
}

///|
fn normalized_size(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
fn normalized_source_generation(generation : Int) -> Int {
  if generation <= 0 {
    1
  } else {
    generation
  }
}

///|
fn synced_source_generation_at(image_id : Int) -> Int {
  let mut generation = 0
  for entry in synced_source_generations.val {
    if entry.image_id == image_id {
      generation = entry.generation
    }
  }
  generation
}

///|
fn set_synced_source_generation(image_id : Int, generation : Int) -> Unit {
  let next : Array[SyncedSourceGeneration] = []
  let mut replaced = false
  let safe_generation = normalized_source_generation(generation)
  for entry in synced_source_generations.val {
    if entry.image_id == image_id {
      next.push({ image_id, generation: safe_generation })
      replaced = true
    } else {
      next.push(entry)
    }
  }
  if !replaced {
    next.push({ image_id, generation: safe_generation })
  }
  synced_source_generations.val = next
}

///|
fn clear_synced_source_generations() -> Unit {
  synced_source_generations.val = []
}

///|
fn drop_synced_source_generation(image_id : Int) -> Unit {
  let next : Array[SyncedSourceGeneration] = []
  for entry in synced_source_generations.val {
    if entry.image_id != image_id {
      next.push(entry)
    }
  }
  synced_source_generations.val = next
}

///|
fn expected_rgba8_channel_count(width : Int, height : Int) -> Int {
  normalized_size(width) * normalized_size(height) * 4
}

///|
fn has_valid_rgba8_payload(
  rgba8_channels : Array[Int],
  width : Int,
  height : Int,
) -> Bool {
  let expected = expected_rgba8_channel_count(width, height)
  expected > 0 && rgba8_channels.length() >= expected
}

///|
fn clamp_u8_channel(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn normalized_rgba8_channels(
  rgba8_channels : Array[Int],
  width : Int,
  height : Int,
) -> Array[Int] {
  let expected = expected_rgba8_channel_count(width, height)
  let out : Array[Int] = []
  if expected <= 0 || rgba8_channels.length() < expected {
    out
  } else {
    for i in 0..<expected {
      out.push(clamp_u8_channel(rgba8_channels[i]))
    }
    out
  }
}

///|
fn source_image_cache_entry_at(image_id : Int) -> SourceImageCacheEntry? {
  let mut out : SourceImageCacheEntry? = None
  for entry in source_image_cache.val {
    if entry.image_id == image_id {
      out = Some(entry)
    }
  }
  out
}

///|
fn set_source_image_cache_entry(next_entry : SourceImageCacheEntry) -> Unit {
  let next : Array[SourceImageCacheEntry] = []
  let mut replaced = false
  for entry in source_image_cache.val {
    if entry.image_id == next_entry.image_id {
      next.push(next_entry)
      replaced = true
    } else {
      next.push(entry)
    }
  }
  if !replaced {
    next.push(next_entry)
  }
  source_image_cache.val = next
}

///|
fn clear_source_image_cache() -> Unit {
  source_image_cache.val = []
}

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
  #|       _pipeline: null,
  #|       _pipelineFormat: "",
  #|       _uniformBGL: null,
  #|       _texBGL: null,
  #|       _defaultTexture: null,
  #|       _defaultTexView: null,
  #|       _defaultSampler: null,
  #|       _drawResourceCache: null,
  #|       _currentDraw: null,
  #|       _pendingTexture: null,
  #|       presentScheduled: false,
  #|       clear: [0, 0, 0, 1],
  #|       commands: [],
  #|       textures: null,
  #|       lastError: "",
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
  #|       webgpu: { context: null, device: null, format: "bgra8unorm", pending: null, _pipeline: null, _pipelineFormat: "", _uniformBGL: null, _texBGL: null, _defaultTexture: null, _defaultTexView: null, _defaultSampler: null, _drawResourceCache: null, _currentDraw: null, _pendingTexture: null, presentScheduled: false, clear: [0, 0, 0, 1], commands: [], textures: null, lastError: "" },
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
  #|       state.webgpu = { context: null, device: null, format: "bgra8unorm", pending: null, _pipeline: null, _pipelineFormat: "", _uniformBGL: null, _texBGL: null, _defaultTexture: null, _defaultTexView: null, _defaultSampler: null, _drawResourceCache: null, _currentDraw: null, _pendingTexture: null, presentScheduled: false, clear: [0, 0, 0, 1], commands: [], textures: null, lastError: "" };
  #|     } else {
  #|       if (!Array.isArray(state.webgpu.clear)) state.webgpu.clear = [0, 0, 0, 1];
  #|       if (!Array.isArray(state.webgpu.commands)) state.webgpu.commands = [];
  #|       if (state.webgpu._pipeline == null) state.webgpu._pipeline = null;
  #|       if (typeof state.webgpu._pipelineFormat !== "string") state.webgpu._pipelineFormat = "";
  #|       if (state.webgpu._uniformBGL == null) state.webgpu._uniformBGL = null;
  #|       if (state.webgpu._texBGL == null) state.webgpu._texBGL = null;
  #|       if (state.webgpu._defaultTexture == null) state.webgpu._defaultTexture = null;
  #|       if (state.webgpu._defaultTexView == null) state.webgpu._defaultTexView = null;
  #|       if (state.webgpu._defaultSampler == null) state.webgpu._defaultSampler = null;
  #|       if (state.webgpu._drawResourceCache == null) state.webgpu._drawResourceCache = null;
  #|       if (state.webgpu._currentDraw == null) state.webgpu._currentDraw = null;
  #|       if (state.webgpu._pendingTexture == null) state.webgpu._pendingTexture = null;
  #|       if (state.webgpu.presentScheduled == null) state.webgpu.presentScheduled = false;
  #|       if (state.webgpu.lastError == null) state.webgpu.lastError = "";
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
  #|     webgpu: { context: null, device: null, format: "bgra8unorm", pending: null, _pipeline: null, _pipelineFormat: "", _uniformBGL: null, _texBGL: null, _defaultTexture: null, _defaultTexView: null, _defaultSampler: null, _drawResourceCache: null, _currentDraw: null, _pendingTexture: null, presentScheduled: false, clear: [0, 0, 0, 1], commands: [], textures: null, lastError: "" },
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
  #|         state.webgpu._pipeline = null;
  #|         state.webgpu._pipelineFormat = "";
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
  #|         state.webgpu._pipeline = null;
  #|         state.webgpu._pipelineFormat = "";
  #|       })
  #|       .finally(() => {
  #|         state.webgpu.pending = null;
  #|       });
  #|   }
  #|   return true;
  #| }

///|
extern "js" fn js_release_webgpu_resources() -> Unit =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   const gpu = state == null ? null : state.webgpu;
  #|   if (gpu == null) return;
  #|   const releaseBufferEntries = (entries) => {
  #|     if (!Array.isArray(entries)) return;
  #|     for (let i = 0; i < entries.length; i += 1) {
  #|       const entry = entries[i];
  #|       const buffer = entry == null ? null : entry.buffer;
  #|       if (buffer != null && typeof buffer.destroy === "function") {
  #|         try { buffer.destroy(); } catch (_) {}
  #|       }
  #|     }
  #|   };
  #|   const cache = gpu._drawResourceCache;
  #|   if (cache != null) {
  #|     releaseBufferEntries(cache.vertexBuffers);
  #|     releaseBufferEntries(cache.indexBuffers);
  #|     releaseBufferEntries(cache.uniformBuffers);
  #|   }
  #|   const textures = gpu.textures;
  #|   if (textures != null && typeof textures.values === "function") {
  #|     for (const entry of textures.values()) {
  #|       const texture = entry == null ? null : entry.texture;
  #|       if (texture != null && typeof texture.destroy === "function") {
  #|         try { texture.destroy(); } catch (_) {}
  #|       }
  #|     }
  #|   }
  #|   if (textures != null && typeof textures.clear === "function") {
  #|     textures.clear();
  #|   }
  #|   if (gpu._defaultTexture != null && typeof gpu._defaultTexture.destroy === "function") {
  #|     try { gpu._defaultTexture.destroy(); } catch (_) {}
  #|   }
  #|   if (gpu.context != null && typeof gpu.context.unconfigure === "function") {
  #|     try { gpu.context.unconfigure(); } catch (_) {}
  #|   }
  #|   gpu._pipeline = null;
  #|   gpu._pipelineFormat = "";
  #|   gpu._uniformBGL = null;
  #|   gpu._texBGL = null;
  #|   gpu._defaultTexture = null;
  #|   gpu._defaultTexView = null;
  #|   gpu._defaultSampler = null;
  #|   gpu._drawResourceCache = null;
  #|   gpu._pendingTexture = null;
  #|   gpu._currentDraw = null;
  #|   gpu.commands = [];
  #|   gpu.textures = new Map();
  #|   gpu.presentScheduled = false;
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
  #|   gpu.commands = [];
  #|   gpu._currentDraw = null;
  #| }

///|
extern "js" fn js_gfx_draw_begin(
  vertex_count : Int,
  index_count : Int,
  src_image_id : Int,
  uniform_r : Int,
  uniform_g : Int,
  uniform_b : Int,
  uniform_a : Int,
) -> Unit =
  #| (vertexCount, indexCount, srcImageId, uniformR, uniformG, uniformB, uniformA) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const gpu = state.webgpu;
  #|   if (gpu == null) return;
  #|   gpu._currentDraw = {
  #|     vertexData: new Float32Array((vertexCount | 0) * 4),
  #|     indices: new Uint32Array(indexCount | 0),
  #|     srcImageId: srcImageId | 0,
  #|     uniformR: (uniformR & 0xff) / 255.0,
  #|     uniformG: (uniformG & 0xff) / 255.0,
  #|     uniformB: (uniformB & 0xff) / 255.0,
  #|     uniformA: (uniformA & 0xff) / 255.0,
  #|   };
  #| }

///|
extern "js" fn js_gfx_draw_vertex(
  offset : Int,
  x : Double,
  y : Double,
  u : Double,
  v : Double,
) -> Unit =
  #| (offset, x, y, u, v) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const gpu = state.webgpu;
  #|   if (gpu == null || gpu._currentDraw == null) return;
  #|   const base = (offset | 0) * 4;
  #|   gpu._currentDraw.vertexData[base] = x;
  #|   gpu._currentDraw.vertexData[base + 1] = y;
  #|   gpu._currentDraw.vertexData[base + 2] = u;
  #|   gpu._currentDraw.vertexData[base + 3] = v;
  #| }

///|
extern "js" fn js_gfx_draw_index(offset : Int, value : Int) -> Unit =
  #| (offset, value) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const gpu = state.webgpu;
  #|   if (gpu == null || gpu._currentDraw == null) return;
  #|   gpu._currentDraw.indices[offset | 0] = value | 0;
  #| }

///|
extern "js" fn js_gfx_draw_end() -> Unit =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const gpu = state.webgpu;
  #|   if (gpu == null || gpu._currentDraw == null) return;
  #|   if (!Array.isArray(gpu.commands)) gpu.commands = [];
  #|   gpu.commands.push(gpu._currentDraw);
  #|   gpu._currentDraw = null;
  #| }

///|
extern "js" fn js_gfx_upload_texture_begin(
  image_id : Int,
  width : Int,
  height : Int,
) -> Unit =
  #| (imageId, width, height) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const gpu = state.webgpu;
  #|   if (gpu == null) return;
  #|   gpu._pendingTexture = {
  #|     imageId: imageId | 0,
  #|     width: Math.max(1, width | 0),
  #|     height: Math.max(1, height | 0),
  #|     pixels: new Uint8Array(Math.max(1, width | 0) * Math.max(1, height | 0) * 4),
  #|   };
  #| }

///|
extern "js" fn js_gfx_upload_texture_pixel(
  offset : Int,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
) -> Unit =
  #| (offset, r, g, b, a) => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const gpu = state.webgpu;
  #|   if (gpu == null || gpu._pendingTexture == null) return;
  #|   const base = (offset | 0) * 4;
  #|   gpu._pendingTexture.pixels[base] = r & 0xff;
  #|   gpu._pendingTexture.pixels[base + 1] = g & 0xff;
  #|   gpu._pendingTexture.pixels[base + 2] = b & 0xff;
  #|   gpu._pendingTexture.pixels[base + 3] = a & 0xff;
  #| }

///|
extern "js" fn js_gfx_upload_texture_end() -> Unit =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return;
  #|   const gpu = state.webgpu;
  #|   if (gpu == null || gpu._pendingTexture == null || gpu.device == null) return;
  #|   const { imageId, width, height, pixels } = gpu._pendingTexture;
  #|   gpu._pendingTexture = null;
  #|   if (width <= 0 || height <= 0) return;
  #|   if (gpu.textures == null) gpu.textures = new Map();
  #|   const existing = gpu.textures.get(imageId);
  #|   if (existing != null && (existing.width !== width || existing.height !== height)) {
  #|     if (existing.texture != null && typeof existing.texture.destroy === "function") {
  #|       existing.texture.destroy();
  #|     }
  #|     gpu.textures.delete(imageId);
  #|   }
  #|   let entry = gpu.textures.get(imageId);
  #|   if (entry == null) {
  #|     const nextRevision = existing != null && Number.isFinite(existing.revision)
  #|       ? ((existing.revision | 0) + 1)
  #|       : 1;
  #|     const texture = gpu.device.createTexture({
  #|       size: { width, height },
  #|       format: "rgba8unorm",
  #|       usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
  #|     });
  #|     const view = texture.createView();
  #|     const sampler = gpu.device.createSampler({
  #|       magFilter: "nearest",
  #|       minFilter: "nearest",
  #|       addressModeU: "clamp-to-edge",
  #|       addressModeV: "clamp-to-edge",
  #|     });
  #|     entry = { texture, view, sampler, width, height, revision: nextRevision };
  #|     gpu.textures.set(imageId, entry);
  #|   } else if (!Number.isFinite(entry.revision)) {
  #|     entry.revision = 1;
  #|   }
  #|   gpu.device.queue.writeTexture(
  #|     { texture: entry.texture },
  #|     pixels,
  #|     { bytesPerRow: width * 4 },
  #|     { width, height },
  #|   );
  #| }

///|
extern "js" fn js_webgpu_present() -> Bool =
  #| () => {
  #|   const state = globalThis.__gameEngineWebRuntime;
  #|   if (state == null) return false;
  #|   const gpu = state.webgpu;
  #|   const device = gpu == null ? null : gpu.device;
  #|   const context = gpu == null ? null : gpu.context;
  #|   if (gpu == null || device == null || context == null) return false;
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
  #|     if (currentGpu == null || currentDevice == null || currentContext == null) return false;
  #|     const format = typeof currentGpu.format === "string" ? currentGpu.format : "bgra8unorm";
  #|     currentContext.configure({ device: currentDevice, format, alphaMode: "opaque" });
  #|     if (currentGpu._pipeline == null || currentGpu._pipelineFormat !== format) {
  #|       const shaderCode = `
  #| struct Uniforms { color: vec4f }
  #| @group(0) @binding(0) var<uniform> uniforms: Uniforms;
  #| @group(1) @binding(0) var tex: texture_2d<f32>;
  #| @group(1) @binding(1) var tex_sampler: sampler;
  #| struct VertexOutput {
  #|   @builtin(position) position: vec4f,
  #|   @location(0) uv: vec2f,
  #| }
  #| @vertex fn vs_main(@location(0) pos: vec2f, @location(1) uv: vec2f) -> VertexOutput {
  #|   var out: VertexOutput;
  #|   out.position = vec4f(pos, 0.0, 1.0);
  #|   out.uv = uv;
  #|   return out;
  #| }
  #| @fragment fn fs_main(input: VertexOutput) -> @location(0) vec4f {
  #|   let tex_color = textureSample(tex, tex_sampler, input.uv);
  #|   return tex_color * uniforms.color;
  #| }`;
  #|       const shaderModule = currentDevice.createShaderModule({ code: shaderCode });
  #|       const texBGL = currentDevice.createBindGroupLayout({
  #|         entries: [
  #|           { binding: 0, visibility: GPUShaderStage.FRAGMENT, texture: { sampleType: "float" } },
  #|           { binding: 1, visibility: GPUShaderStage.FRAGMENT, sampler: {} },
  #|         ],
  #|       });
  #|       const uniformBGL = currentDevice.createBindGroupLayout({
  #|         entries: [
  #|           { binding: 0, visibility: GPUShaderStage.FRAGMENT | GPUShaderStage.VERTEX, buffer: { type: "uniform" } },
  #|         ],
  #|       });
  #|       const pipelineLayout = currentDevice.createPipelineLayout({ bindGroupLayouts: [uniformBGL, texBGL] });
  #|       currentGpu._pipeline = currentDevice.createRenderPipeline({
  #|         layout: pipelineLayout,
  #|         vertex: {
  #|           module: shaderModule,
  #|           entryPoint: "vs_main",
  #|           buffers: [{
  #|             arrayStride: 16,
  #|             attributes: [
  #|               { shaderLocation: 0, offset: 0, format: "float32x2" },
  #|               { shaderLocation: 1, offset: 8, format: "float32x2" },
  #|             ],
  #|           }],
  #|         },
  #|         fragment: {
  #|           module: shaderModule,
  #|           entryPoint: "fs_main",
  #|           targets: [{
  #|             format,
  #|             blend: {
  #|               color: { srcFactor: "src-alpha", dstFactor: "one-minus-src-alpha", operation: "add" },
  #|               alpha: { srcFactor: "one", dstFactor: "one-minus-src-alpha", operation: "add" },
  #|             },
  #|           }],
  #|         },
  #|         primitive: { topology: "triangle-list", cullMode: "none" },
  #|       });
  #|       currentGpu._pipelineFormat = format;
  #|       currentGpu._uniformBGL = uniformBGL;
  #|       currentGpu._texBGL = texBGL;
  #|       currentGpu._drawResourceCache = null;
  #|       const defaultTex = currentDevice.createTexture({
  #|         size: { width: 1, height: 1 },
  #|         format: "rgba8unorm",
  #|         usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
  #|       });
  #|       currentDevice.queue.writeTexture(
  #|         { texture: defaultTex },
  #|         new Uint8Array([255, 255, 255, 255]),
  #|         { bytesPerRow: 4 },
  #|         { width: 1, height: 1 },
  #|       );
  #|       currentGpu._defaultTexture = defaultTex;
  #|       currentGpu._defaultTexView = defaultTex.createView();
  #|       currentGpu._defaultSampler = currentDevice.createSampler({ magFilter: "nearest", minFilter: "nearest" });
  #|     }
  #|     const [r, g, b, a] = currentGpu.clear;
  #|     const texture = currentContext.getCurrentTexture();
  #|     const view = texture.createView();
  #|     const encoder = currentDevice.createCommandEncoder();
  #|     const pass = encoder.beginRenderPass({
  #|       colorAttachments: [{ view, clearValue: { r, g, b, a }, loadOp: "clear", storeOp: "store" }],
  #|     });
  #|     const drawCommands = Array.isArray(currentGpu.commands) ? currentGpu.commands : [];
  #|     if (currentGpu._drawResourceCache == null) {
  #|       currentGpu._drawResourceCache = {
  #|         vertexBuffers: [],
  #|         indexBuffers: [],
  #|         uniformBuffers: [],
  #|         uniformBindGroups: [],
  #|         uniformBindBuffers: [],
  #|         textureBindGroups: [],
  #|         textureBindImageIds: [],
  #|         textureBindRevisions: [],
  #|       };
  #|     }
  #|     const cache = currentGpu._drawResourceCache;
  #|     const ensureBufferEntry = (slots, slotIndex, minSize, usage) => {
  #|       const requiredSize = Math.max(16, Number(minSize) | 0);
  #|       let entry = slots[slotIndex];
  #|       const currentSize = entry == null ? 0 : (Number(entry.size ?? 0) | 0);
  #|       if (entry == null || currentSize < requiredSize) {
  #|         if (entry != null && entry.buffer != null && typeof entry.buffer.destroy === "function") {
  #|           try { entry.buffer.destroy(); } catch (_) {}
  #|         }
  #|         entry = {
  #|           size: requiredSize,
  #|           buffer: currentDevice.createBuffer({ size: requiredSize, usage }),
  #|         };
  #|         slots[slotIndex] = entry;
  #|       }
  #|       return entry;
  #|     };
  #|     for (let drawIndex = 0; drawIndex < drawCommands.length; drawIndex += 1) {
  #|       const cmd = drawCommands[drawIndex];
  #|       if (cmd.vertexData == null || cmd.vertexData.length === 0) continue;
  #|       if (cmd.indices == null || cmd.indices.length === 0) continue;
  #|       const vbEntry = ensureBufferEntry(
  #|         cache.vertexBuffers,
  #|         drawIndex,
  #|         cmd.vertexData.byteLength,
  #|         GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
  #|       );
  #|       currentDevice.queue.writeBuffer(vbEntry.buffer, 0, cmd.vertexData);
  #|       const ibEntry = ensureBufferEntry(
  #|         cache.indexBuffers,
  #|         drawIndex,
  #|         cmd.indices.byteLength,
  #|         GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST,
  #|       );
  #|       currentDevice.queue.writeBuffer(ibEntry.buffer, 0, cmd.indices);
  #|       const ubEntry = ensureBufferEntry(
  #|         cache.uniformBuffers,
  #|         drawIndex,
  #|         16,
  #|         GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
  #|       );
  #|       currentDevice.queue.writeBuffer(
  #|         ubEntry.buffer,
  #|         0,
  #|         new Float32Array([cmd.uniformR, cmd.uniformG, cmd.uniformB, cmd.uniformA]),
  #|       );
  #|       let uniformBG = cache.uniformBindGroups[drawIndex];
  #|       if (uniformBG == null || cache.uniformBindBuffers[drawIndex] !== ubEntry.buffer) {
  #|         uniformBG = currentDevice.createBindGroup({
  #|           layout: currentGpu._uniformBGL,
  #|           entries: [{ binding: 0, resource: { buffer: ubEntry.buffer } }],
  #|         });
  #|         cache.uniformBindGroups[drawIndex] = uniformBG;
  #|         cache.uniformBindBuffers[drawIndex] = ubEntry.buffer;
  #|       }
  #|       let texView = currentGpu._defaultTexView;
  #|       let texSampler = currentGpu._defaultSampler;
  #|       let resolvedImageId = 0;
  #|       let resolvedRevision = -1;
  #|       if (currentGpu.textures != null && cmd.srcImageId > 0) {
  #|         const texEntry = currentGpu.textures.get(cmd.srcImageId);
  #|         if (texEntry != null) {
  #|           texView = texEntry.view;
  #|           texSampler = texEntry.sampler;
  #|           resolvedImageId = cmd.srcImageId | 0;
  #|           resolvedRevision = Number.isFinite(texEntry.revision)
  #|             ? (texEntry.revision | 0)
  #|             : 0;
  #|         }
  #|       }
  #|       let texBG = cache.textureBindGroups[drawIndex];
  #|       if (
  #|         texBG == null ||
  #|         cache.textureBindImageIds[drawIndex] !== resolvedImageId ||
  #|         cache.textureBindRevisions[drawIndex] !== resolvedRevision
  #|       ) {
  #|         texBG = currentDevice.createBindGroup({
  #|           layout: currentGpu._texBGL,
  #|           entries: [{ binding: 0, resource: texView }, { binding: 1, resource: texSampler }],
  #|         });
  #|         cache.textureBindGroups[drawIndex] = texBG;
  #|         cache.textureBindImageIds[drawIndex] = resolvedImageId;
  #|         cache.textureBindRevisions[drawIndex] = resolvedRevision;
  #|       }
  #|       pass.setPipeline(currentGpu._pipeline);
  #|       pass.setBindGroup(0, uniformBG);
  #|       pass.setBindGroup(1, texBG);
  #|       pass.setVertexBuffer(0, vbEntry.buffer);
  #|       pass.setIndexBuffer(ibEntry.buffer, "uint32");
  #|       pass.drawIndexed(cmd.indices.length);
  #|     }
  #|     pass.end();
  #|     currentDevice.queue.submit([encoder.finish()]);
  #|     currentGpu.commands = [];
  #|     return true;
  #|   };
  #|   const scheduleVsync = !!state.vsyncEnabled && typeof globalThis.requestAnimationFrame === "function";
  #|   if (scheduleVsync) {
  #|     if (gpu.presentScheduled) return true;
  #|     gpu.presentScheduled = true;
  #|     globalThis.requestAnimationFrame(() => {
  #|       const current = globalThis.__gameEngineWebRuntime;
  #|       if (current == null) return;
  #|       if (current.webgpu != null) current.webgpu.presentScheduled = false;
  #|       try { presentNow(current); } catch (error) {
  #|         if (current.webgpu != null) current.webgpu.lastError = String(error);
  #|       }
  #|     });
  #|     return true;
  #|   }
  #|   try { return presentNow(state); } catch (error) { gpu.lastError = String(error); return false; }
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
  #|   if (typeof globalThis.GPUShaderStage === "undefined") {
  #|     globalThis.GPUShaderStage = { VERTEX: 1, FRAGMENT: 2, COMPUTE: 4 };
  #|   }
  #|   if (typeof globalThis.GPUBufferUsage === "undefined") {
  #|     globalThis.GPUBufferUsage = { MAP_READ: 1, MAP_WRITE: 2, COPY_SRC: 4, COPY_DST: 8, INDEX: 16, VERTEX: 32, UNIFORM: 64, STORAGE: 128, INDIRECT: 256, QUERY_RESOLVE: 512 };
  #|   }
  #|   if (typeof globalThis.GPUTextureUsage === "undefined") {
  #|     globalThis.GPUTextureUsage = { COPY_SRC: 1, COPY_DST: 2, TEXTURE_BINDING: 4, STORAGE_BINDING: 8, RENDER_ATTACHMENT: 16 };
  #|   }
  #|   const stats = {
  #|     submits: 0,
  #|     clears: 0,
  #|     draws: 0,
  #|     bufferCreates: 0,
  #|     bufferDestroys: 0,
  #|     bindGroupCreates: 0,
  #|     textureDestroys: 0,
  #|     lastWebGpuShaderCode: "",
  #|   };
  #|   const webgpuContext = {
  #|     configure: () => {},
  #|     getCurrentTexture: () => ({ createView: () => ({}) }),
  #|   };
  #|   const createMockBuffer = () => ({
  #|     destroy: () => { stats.bufferDestroys += 1; },
  #|   });
  #|   const createMockTexture = () => ({
  #|     createView: () => ({}),
  #|     destroy: () => { stats.textureDestroys += 1; },
  #|   });
  #|   const mockSampler = {};
  #|   const webgpuDevice = {
  #|     createCommandEncoder: () => ({
  #|       beginRenderPass: () => ({
  #|         setPipeline: () => {},
  #|         setBindGroup: () => {},
  #|         setVertexBuffer: () => {},
  #|         setIndexBuffer: () => {},
  #|         draw: () => { stats.draws += 1; },
  #|         drawIndexed: (count) => { stats.draws += 1; },
  #|         end: () => {},
  #|       }),
  #|       finish: () => ({}),
  #|     }),
  #|     createShaderModule: (descriptor) => {
  #|       stats.lastWebGpuShaderCode = descriptor == null ? "" : String(descriptor.code ?? "");
  #|       return {};
  #|     },
  #|     createRenderPipeline: () => ({ getBindGroupLayout: (i) => ({}) }),
  #|     createPipelineLayout: () => ({}),
  #|     createBuffer: () => { stats.bufferCreates += 1; return createMockBuffer(); },
  #|     createTexture: () => createMockTexture(),
  #|     createSampler: () => mockSampler,
  #|     createBindGroup: () => { stats.bindGroupCreates += 1; return {}; },
  #|     createBindGroupLayout: () => ({}),
  #|     queue: {
  #|       submit: () => { stats.submits += 1; },
  #|       writeBuffer: () => {},
  #|       writeTexture: () => {},
  #|     },
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
  #|       _pipeline: null,
  #|       _pipelineFormat: "",
  #|       presentScheduled: false,
  #|       clear: [0, 0, 0, 1],
  #|       commands: [],
  #|       textures: null,
  #|       lastError: "",
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
extern "js" fn test_present_buffer_create_count() -> Int =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return 0;
  #|   return Number(stats.bufferCreates ?? 0) | 0;
  #| }

///|
extern "js" fn test_present_buffer_destroy_count() -> Int =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return 0;
  #|   return Number(stats.bufferDestroys ?? 0) | 0;
  #| }

///|
extern "js" fn test_present_bind_group_create_count() -> Int =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return 0;
  #|   return Number(stats.bindGroupCreates ?? 0) | 0;
  #| }

///|
extern "js" fn test_present_texture_destroy_count() -> Int =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return 0;
  #|   return Number(stats.textureDestroys ?? 0) | 0;
  #| }

///|
extern "js" fn test_last_webgpu_shader_source() -> String =
  #| () => {
  #|   const stats = globalThis.__gameEnginePresentTestStats;
  #|   if (stats == null) return "";
  #|   return String(stats.lastWebGpuShaderCode ?? "");
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
test "js_webgpu_present emits draw calls using new draw FFI" {
  test_setup_present_state(true, false, false)
  js_webgpu_begin(0.0, 0.0, 0.0, 1.0)
  js_gfx_draw_begin(3, 3, 0, 255, 0, 0, 255)
  js_gfx_draw_vertex(0, -0.8, 0.7, 0.0, 0.0)
  js_gfx_draw_vertex(1, -0.2, -0.6, 1.0, 0.0)
  js_gfx_draw_vertex(2, 0.9, -0.3, 1.0, 1.0)
  js_gfx_draw_index(0, 0)
  js_gfx_draw_index(1, 1)
  js_gfx_draw_index(2, 2)
  js_gfx_draw_end()
  let presented = js_webgpu_present()
  assert_true(presented)
  assert_eq(test_present_draw_count(), 1)
  assert_eq(test_present_submit_count(), 1)
  test_teardown_present_state()
}

///|
test "js_webgpu_present renders multiple queued draw commands" {
  test_setup_present_state(true, false, false)
  js_webgpu_begin(0.0, 0.0, 0.0, 1.0)
  js_gfx_draw_begin(3, 3, 0, 255, 0, 0, 255)
  js_gfx_draw_vertex(0, -0.8, 0.7, 0.0, 0.0)
  js_gfx_draw_vertex(1, -0.2, -0.6, 1.0, 0.0)
  js_gfx_draw_vertex(2, 0.9, -0.3, 1.0, 1.0)
  js_gfx_draw_index(0, 0)
  js_gfx_draw_index(1, 1)
  js_gfx_draw_index(2, 2)
  js_gfx_draw_end()
  js_gfx_draw_begin(3, 3, 0, 0, 255, 0, 255)
  js_gfx_draw_vertex(0, -0.6, 0.5, 0.0, 0.0)
  js_gfx_draw_vertex(1, -0.1, -0.7, 1.0, 0.0)
  js_gfx_draw_vertex(2, 0.7, -0.2, 1.0, 1.0)
  js_gfx_draw_index(0, 0)
  js_gfx_draw_index(1, 1)
  js_gfx_draw_index(2, 2)
  js_gfx_draw_end()
  let presented = js_webgpu_present()
  assert_true(presented)
  assert_eq(test_present_draw_count(), 2)
  assert_eq(test_present_submit_count(), 1)
  test_teardown_present_state()
}

///|
test "js_webgpu_present reuses draw buffers and bind groups across frames" {
  test_setup_present_state(true, false, false)

  js_webgpu_begin(0.0, 0.0, 0.0, 1.0)
  js_gfx_draw_begin(3, 3, 0, 255, 0, 0, 255)
  js_gfx_draw_vertex(0, -0.8, 0.7, 0.0, 0.0)
  js_gfx_draw_vertex(1, -0.2, -0.6, 1.0, 0.0)
  js_gfx_draw_vertex(2, 0.9, -0.3, 1.0, 1.0)
  js_gfx_draw_index(0, 0)
  js_gfx_draw_index(1, 1)
  js_gfx_draw_index(2, 2)
  js_gfx_draw_end()
  let first_presented = js_webgpu_present()
  assert_true(first_presented)
  let first_buffer_creates = test_present_buffer_create_count()
  let first_bind_group_creates = test_present_bind_group_create_count()
  assert_true(first_buffer_creates >= 3)
  assert_true(first_bind_group_creates >= 2)

  js_webgpu_begin(0.0, 0.0, 0.0, 1.0)
  js_gfx_draw_begin(3, 3, 0, 0, 255, 0, 255)
  js_gfx_draw_vertex(0, -0.6, 0.5, 0.0, 0.0)
  js_gfx_draw_vertex(1, -0.1, -0.7, 1.0, 0.0)
  js_gfx_draw_vertex(2, 0.7, -0.2, 1.0, 1.0)
  js_gfx_draw_index(0, 0)
  js_gfx_draw_index(1, 1)
  js_gfx_draw_index(2, 2)
  js_gfx_draw_end()
  let second_presented = js_webgpu_present()
  assert_true(second_presented)
  assert_eq(test_present_buffer_create_count(), first_buffer_creates)
  assert_eq(test_present_bind_group_create_count(), first_bind_group_creates)

  test_teardown_present_state()
}

///|
test "uninstall releases cached webgpu buffers and textures" {
  test_setup_present_state(true, false, false)

  install("#app")

  js_webgpu_begin(0.0, 0.0, 0.0, 1.0)
  js_gfx_draw_begin(3, 3, 0, 255, 0, 0, 255)
  js_gfx_draw_vertex(0, -0.8, 0.7, 0.0, 0.0)
  js_gfx_draw_vertex(1, -0.2, -0.6, 1.0, 0.0)
  js_gfx_draw_vertex(2, 0.9, -0.3, 1.0, 1.0)
  js_gfx_draw_index(0, 0)
  js_gfx_draw_index(1, 1)
  js_gfx_draw_index(2, 2)
  js_gfx_draw_end()
  let presented = js_webgpu_present()
  assert_true(presented)

  assert_eq(test_present_buffer_destroy_count(), 0)
  assert_eq(test_present_texture_destroy_count(), 0)

  uninstall()

  assert_true(test_present_buffer_destroy_count() > 0)
  assert_true(test_present_texture_destroy_count() > 0)

  test_teardown_present_state()
}

///|
test "bridge_web_gfx_on_draw emits draw commands via new FFI" {
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
  driver.draw_triangles(command)
  let presented = js_webgpu_present()
  assert_true(presented)
  assert_eq(test_present_submit_count(), 1)
  uninstall()
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
  @platform.create_webgpu_surface_token(id, width, height, dpr)
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
      webgpu_ready
    }
    _ => false
  }
}

///|
fn bridge_web_gfx_on_begin(
  active : Bool,
  _kind : @gfx.GraphicsBackendKind,
  pass : @gfx.RenderPassDesc,
) -> Unit {
  if active {
    js_webgpu_begin(
      pass.clear_color.r,
      pass.clear_color.g,
      pass.clear_color.b,
      pass.clear_color.a,
    )
    // Upload dirty textures to GPU
    let dirty = gpu_texture_dirty.val
    for image_id in dirty {
      match source_image_cache_entry_at(image_id) {
        Some(entry) => {
          let w = entry.width
          let h = entry.height
          let px = entry.pixels_rgba8
          let pixel_count = w * h
          if px.length() >= pixel_count * 4 {
            js_gfx_upload_texture_begin(image_id, w, h)
            for i = 0; i < pixel_count; i = i + 1 {
              let base = i * 4
              js_gfx_upload_texture_pixel(
                i,
                px[base],
                px[base + 1],
                px[base + 2],
                px[base + 3],
              )
            }
            js_gfx_upload_texture_end()
          }
        }
        None => ()
      }
    }
    gpu_texture_dirty.val = []
  }
}

///|
fn bridge_web_gfx_on_end(
  active : Bool,
  _kind : @gfx.GraphicsBackendKind,
  present : Bool,
) -> Unit {
  if active && present {
    let _ = js_webgpu_present()
  }
}

///|
fn bridge_web_gfx_on_draw(
  active : Bool,
  _kind : @gfx.GraphicsBackendKind,
  command : @gfx.DrawTrianglesCommand,
) -> Unit {
  if active {
    let src_id = if command.src_image_ids.length() > 0 {
      command.src_image_ids[0]
    } else {
      0
    }
    let ur = if command.uniform_dwords.length() > 0 {
      command.uniform_dwords[0]
    } else {
      255
    }
    let ug = if command.uniform_dwords.length() > 1 {
      command.uniform_dwords[1]
    } else {
      255
    }
    let ub = if command.uniform_dwords.length() > 2 {
      command.uniform_dwords[2]
    } else {
      255
    }
    let ua = if command.uniform_dwords.length() > 3 {
      command.uniform_dwords[3]
    } else {
      255
    }
    let vc = command.vertex_data.length() / 4
    let ic = command.indices.length()
    js_gfx_draw_begin(vc, ic, src_id, ur, ug, ub, ua)
    for i = 0; i < vc; i = i + 1 {
      let base = i * 4
      js_gfx_draw_vertex(
        i,
        command.vertex_data[base],
        command.vertex_data[base + 1],
        command.vertex_data[base + 2],
        command.vertex_data[base + 3],
      )
    }
    for i = 0; i < ic; i = i + 1 {
      js_gfx_draw_index(i, command.indices[i])
    }
    js_gfx_draw_end()
  }
}

///|
fn bridge_web_gfx_on_resize(
  active : Bool,
  _kind : @gfx.GraphicsBackendKind,
  width : Int,
  height : Int,
) -> Unit {
  if active {
    let _ = js_prepare_surface(web_canvas_selector.val, width, height)
    let _ = js_try_initialize_webgpu(web_canvas_selector.val, width, height)
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
  clear_source_image_cache()
  clear_synced_source_generations()
  clear_gpu_texture_dirty()
  js_ensure_window_state(canvas_selector)
  js_release_webgpu_resources()
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
      bridge_web_gfx_on_draw, bridge_web_gfx_on_resize,
    ),
  )
}

///|
pub fn uninstall() -> Unit {
  web_hooks_installed.val = false
  clear_source_image_cache()
  clear_synced_source_generations()
  clear_gpu_texture_dirty()
  js_ensure_window_state(web_canvas_selector.val)
  js_release_webgpu_resources()
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

///|
pub fn register_source_image_palette(
  source_image_id : Int,
  _palette : @image_palette.ImagePalette2x2,
) -> Unit {
  if source_image_id < 0 {
    return
  }
  let mut width = 1
  let mut height = 1
  let mut pixels_rgba8 : Array[Int] = []
  match source_image_cache_entry_at(source_image_id) {
    Some(entry) => {
      width = entry.width
      height = entry.height
      pixels_rgba8 = entry.pixels_rgba8
    }
    None => ()
  }
  set_source_image_cache_entry({
    image_id: source_image_id,
    width,
    height,
    pixels_rgba8,
  })
  drop_synced_source_generation(source_image_id)
}

///|
pub fn register_source_image_solid_color(
  source_image_id : Int,
  color : @image_palette.Rgba,
) -> Unit {
  register_source_image_palette(
    source_image_id,
    @image_palette.new_solid_palette(color),
  )
}

///|
pub fn register_source_image_rgba8(
  source_image_id : Int,
  width : Int,
  height : Int,
  rgba8_channels : Array[Int],
) -> Unit {
  if source_image_id < 0 {
    return
  }
  let safe_width = normalized_size(width)
  let safe_height = normalized_size(height)
  let pixels_rgba8 = normalized_rgba8_channels(
    rgba8_channels, safe_width, safe_height,
  )
  if pixels_rgba8.length() == 0 {
    return
  }
  set_source_image_cache_entry({
    image_id: source_image_id,
    width: safe_width,
    height: safe_height,
    pixels_rgba8,
  })
  drop_synced_source_generation(source_image_id)
  mark_gpu_texture_dirty(source_image_id)
}

///|
pub fn patch_source_image_rgba8(
  source_image_id : Int,
  width : Int,
  height : Int,
  dirty_x : Int,
  dirty_y : Int,
  dirty_width : Int,
  dirty_height : Int,
  rgba8_channels : Array[Int],
) -> Bool {
  if source_image_id < 0 {
    return false
  }
  let safe_width = normalized_size(width)
  let safe_height = normalized_size(height)
  if !has_valid_rgba8_payload(rgba8_channels, safe_width, safe_height) {
    return false
  }
  match source_image_cache_entry_at(source_image_id) {
    Some(entry) =>
      if entry.width != safe_width ||
        entry.height != safe_height ||
        !has_valid_rgba8_payload(entry.pixels_rgba8, safe_width, safe_height) {
        false
      } else {
        let x0 = if dirty_x < 0 {
          0
        } else if dirty_x > safe_width {
          safe_width
        } else {
          dirty_x
        }
        let y0 = if dirty_y < 0 {
          0
        } else if dirty_y > safe_height {
          safe_height
        } else {
          dirty_y
        }
        let x1_raw = dirty_x + dirty_width
        let y1_raw = dirty_y + dirty_height
        let x1 = if x1_raw < 0 {
          0
        } else if x1_raw > safe_width {
          safe_width
        } else {
          x1_raw
        }
        let y1 = if y1_raw < 0 {
          0
        } else if y1_raw > safe_height {
          safe_height
        } else {
          y1_raw
        }
        if x1 <= x0 || y1 <= y0 {
          false
        } else {
          let next_pixels = entry.pixels_rgba8
          for y in y0..<y1 {
            for x in x0..<x1 {
              let base = (y * safe_width + x) * 4
              next_pixels[base] = clamp_u8_channel(rgba8_channels[base])
              next_pixels[base + 1] = clamp_u8_channel(rgba8_channels[base + 1])
              next_pixels[base + 2] = clamp_u8_channel(rgba8_channels[base + 2])
              next_pixels[base + 3] = clamp_u8_channel(rgba8_channels[base + 3])
            }
          }
          set_source_image_cache_entry({
            image_id: source_image_id,
            width: safe_width,
            height: safe_height,
            pixels_rgba8: next_pixels,
          })
          drop_synced_source_generation(source_image_id)
          mark_gpu_texture_dirty(source_image_id)
          true
        }
      }
    None => false
  }
}

///|
pub fn clear_source_image_palettes() -> Unit {
  clear_source_image_cache()
  clear_synced_source_generations()
}

///|
pub fn sync_source_image_palettes(
  bindings : Array[@asset.ImagePaletteBinding],
) -> Int {
  let mut count = 0
  for binding in bindings {
    if binding.image_id >= 0 {
      register_source_image_palette(binding.image_id, binding.palette)
      count = count + 1
    }
  }
  count
}

///|
pub fn sync_source_image_palettes_from_repository(
  repository : @asset.SimpleImageRepository,
) -> Int {
  sync_source_image_palettes(@asset.list_image_palette_bindings(repository))
}

///|
pub fn sync_source_images(bindings : Array[@asset.SourceImageBinding]) -> Int {
  let mut count = 0
  for binding in bindings {
    if binding.image_id < 0 {
      continue
    }
    let generation = normalized_source_generation(binding.generation)
    if synced_source_generation_at(binding.image_id) == generation {
      continue
    }
    let required_channels = expected_rgba8_channel_count(
      binding.width,
      binding.height,
    )
    if required_channels > 0 &&
      binding.pixels_rgba8.length() >= required_channels {
      let mut patched = false
      match binding.dirty_rect {
        Some(rect) => {
          let full_rect = rect.x <= 0 &&
            rect.y <= 0 &&
            rect.width >= normalized_size(binding.width) &&
            rect.height >= normalized_size(binding.height)
          if !full_rect {
            patched = patch_source_image_rgba8(
              binding.image_id,
              binding.width,
              binding.height,
              rect.x,
              rect.y,
              rect.width,
              rect.height,
              binding.pixels_rgba8,
            )
          }
        }
        None => ()
      }
      if !patched {
        register_source_image_rgba8(
          binding.image_id,
          binding.width,
          binding.height,
          binding.pixels_rgba8,
        )
      }
    } else {
      register_source_image_palette(binding.image_id, binding.palette)
    }
    set_synced_source_generation(binding.image_id, generation)
    count = count + 1
  }
  count
}

///|
pub fn sync_source_images_from_repository(
  repository : @asset.SimpleImageRepository,
) -> Int {
  sync_source_images(@asset.list_source_image_bindings(repository))
}

///|
pub fn sync_dirty_source_images_from_repository(
  repository : @asset.SimpleImageRepository,
) -> Int {
  let count = sync_source_images(
    @asset.list_dirty_source_image_bindings(repository),
  )
  let _ = @asset.clear_source_image_dirty_flags(repository)
  count
}

///|
pub fn sync_dirty_atlas_pages_from_repository(
  repository : @asset.SimpleAtlasImageRepository,
) -> Int {
  let count = sync_source_images(
    @asset.list_dirty_atlas_page_bindings(repository),
  )
  let _ = @asset.clear_dirty_atlas_page_flags(repository)
  count
}

///|
pub fn source_image_cache_count() -> Int {
  source_image_cache.val.length()
}

///|
pub fn source_image_generation(image_id : Int) -> Int {
  synced_source_generation_at(image_id)
}

///|
pub fn source_image_width(image_id : Int) -> Int {
  match source_image_cache_entry_at(image_id) {
    Some(entry) => entry.width
    None => 0
  }
}

///|
pub fn source_image_height(image_id : Int) -> Int {
  match source_image_cache_entry_at(image_id) {
    Some(entry) => entry.height
    None => 0
  }
}

///|
pub fn source_image_pixel_channel(
  image_id : Int,
  x : Int,
  y : Int,
  channel_index : Int,
) -> Int {
  if channel_index < 0 || channel_index > 3 {
    return -1
  }
  match source_image_cache_entry_at(image_id) {
    Some(entry) =>
      if x < 0 || y < 0 || x >= entry.width || y >= entry.height {
        -1
      } else {
        let base = (y * entry.width + x) * 4
        let offset = base + channel_index
        if offset < 0 || offset >= entry.pixels_rgba8.length() {
          -1
        } else {
          entry.pixels_rgba8[offset]
        }
      }
    None => -1
  }
}
