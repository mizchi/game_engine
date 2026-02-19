// WebGPU C API スタブ
// wgpu-native が完全な C API を提供しているため、このファイルは最小限

#include <moonbit.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// WebGPU と GLFW の macOS 固有ヘッダー
#if __has_include("../../deps/wgpu-macos/include/webgpu/webgpu.h")
#include "../../deps/wgpu-macos/include/webgpu/webgpu.h"
#elif __has_include(<webgpu/webgpu.h>)
#include <webgpu/webgpu.h>
#else
#error "webgpu/webgpu.h not found. run: bash scripts/setup-wgpu-native.sh"
#endif

#define GLFW_EXPOSE_NATIVE_COCOA
#if __has_include("/opt/homebrew/include/GLFW/glfw3.h")
#include "/opt/homebrew/include/GLFW/glfw3.h"
#include "/opt/homebrew/include/GLFW/glfw3native.h"
#elif __has_include("/usr/local/include/GLFW/glfw3.h")
#include "/usr/local/include/GLFW/glfw3.h"
#include "/usr/local/include/GLFW/glfw3native.h"
#elif __has_include("/Users/mz/brew/include/GLFW/glfw3.h")
#include "/Users/mz/brew/include/GLFW/glfw3.h"
#include "/Users/mz/brew/include/GLFW/glfw3native.h"
#elif __has_include(<GLFW/glfw3.h>)
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>
#else
#error "GLFW headers not found. install glfw (brew install glfw)."
#endif

// macOS Cocoa フレームワーク
#import <QuartzCore/CAMetalLayer.h>
#import <Cocoa/Cocoa.h>

// GLFW のヘルパー関数
// glfwGetWindowSize は out パラメータを使うため、MoonBit から直接呼べない
// タプルを返すヘルパー関数を提供する

// NOTE: glfw3.h をインクルードしているため、前方宣言は不要

// MoonBit の WindowSize 構造体（生成されたコードに合わせる）
struct $WindowSize {
  int32_t $0;  // width
  int32_t $1;  // height
};

// ウィンドウサイズを取得して構造体で返す（クラッシュするため未使用）
struct $WindowSize moonbit_glfw_get_window_size_struct(GLFWwindow* window) {
  printf("[C] moonbit_glfw_get_window_size_struct() called, window=%p\n", (void*)window);
  fflush(stdout);

  int width, height;
  glfwGetWindowSize(window, &width, &height);
  printf("[C] Got size: %dx%d\n", width, height);
  fflush(stdout);

  struct $WindowSize result;
  result.$0 = width;
  result.$1 = height;

  printf("[C] Returning WindowSize struct\n");
  fflush(stdout);

  return result;
}

// ウィンドウサイズを個別に取得（分割版）
int32_t moonbit_glfw_get_window_width(GLFWwindow* window) {
  int width, height;
  glfwGetWindowSize(window, &width, &height);
  return width;
}

int32_t moonbit_glfw_get_window_height(GLFWwindow* window) {
  int width, height;
  glfwGetWindowSize(window, &width, &height);
  return height;
}

static int g_windowed_x = 100;
static int g_windowed_y = 100;
static int g_windowed_width = 800;
static int g_windowed_height = 600;
static GLFWwindow* g_input_window = NULL;
static double g_scroll_x = 0.0;
static double g_scroll_y = 0.0;
#define MOONBIT_MAX_TOUCHES 16
typedef struct {
  int32_t id;
  double x;
  double y;
} moonbit_touch_state;
static moonbit_touch_state g_touches[MOONBIT_MAX_TOUCHES];
static int32_t g_touch_count = 0;
static WGPUTextureFormat g_configured_surface_format = WGPUTextureFormat_BGRA8Unorm;

static void moonbit_glfw_scroll_callback(GLFWwindow* window, double xoffset, double yoffset) {
  if (window == NULL || window != g_input_window) {
    return;
  }
  g_scroll_x += xoffset;
  g_scroll_y += yoffset;
}

static int32_t moonbit_touch_id_from_identity(id identity) {
  if (identity == nil) {
    return -1;
  }
  const NSUInteger hash_value = [identity hash];
  return (int32_t)(hash_value & 0x7fffffffU);
}

static void moonbit_reset_touches(void) {
  g_touch_count = 0;
  for (int i = 0; i < MOONBIT_MAX_TOUCHES; i++) {
    g_touches[i].id = -1;
    g_touches[i].x = 0.0;
    g_touches[i].y = 0.0;
  }
}

static void moonbit_update_touches(GLFWwindow* window) {
  moonbit_reset_touches();
  if (window == NULL || window != g_input_window) {
    return;
  }
  NSWindow* nswindow = glfwGetCocoaWindow(window);
  if (nswindow == nil) {
    return;
  }
  NSView* contentView = [nswindow contentView];
  if (contentView == nil) {
    return;
  }
  NSEvent* event = [NSApp currentEvent];
  if (event == nil) {
    return;
  }

  NSSet* touches = nil;
  @try {
    touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:contentView];
  } @catch (NSException* exception) {
    (void)exception;
    return;
  }
  if (touches == nil || [touches count] == 0) {
    return;
  }

  NSRect bounds = [contentView bounds];
  const double width = bounds.size.width > 0.0 ? bounds.size.width : 1.0;
  const double height = bounds.size.height > 0.0 ? bounds.size.height : 1.0;

  int32_t index = 0;
  for (NSTouch* touch in touches) {
    if (index >= MOONBIT_MAX_TOUCHES) {
      break;
    }
    const NSPoint normalized = [touch normalizedPosition];
    double x = normalized.x * width;
    double y = (1.0 - normalized.y) * height;
    if (x < 0.0) {
      x = 0.0;
    }
    if (y < 0.0) {
      y = 0.0;
    }
    g_touches[index].id = moonbit_touch_id_from_identity([touch identity]);
    if (g_touches[index].id < 0) {
      g_touches[index].id = index;
    }
    g_touches[index].x = x;
    g_touches[index].y = y;
    index++;
  }
  g_touch_count = index;
}

int32_t moonbit_glfw_is_fullscreen(GLFWwindow* window) {
  if (window == NULL) {
    return 0;
  }
  return glfwGetWindowMonitor(window) != NULL ? 1 : 0;
}

int32_t moonbit_glfw_set_fullscreen(GLFWwindow* window, int32_t enabled) {
  if (window == NULL) {
    return 0;
  }

  const int is_fullscreen = moonbit_glfw_is_fullscreen(window);
  if (enabled != 0) {
    if (is_fullscreen) {
      return 1;
    }
    GLFWmonitor* monitor = glfwGetPrimaryMonitor();
    if (monitor == NULL) {
      return 0;
    }
    const GLFWvidmode* mode = glfwGetVideoMode(monitor);
    if (mode == NULL) {
      return 0;
    }
    glfwGetWindowPos(window, &g_windowed_x, &g_windowed_y);
    glfwGetWindowSize(window, &g_windowed_width, &g_windowed_height);
    glfwSetWindowMonitor(
      window,
      monitor,
      0,
      0,
      mode->width,
      mode->height,
      mode->refreshRate
    );
    return moonbit_glfw_is_fullscreen(window);
  }

  if (!is_fullscreen) {
    return 0;
  }
  const int restore_width = g_windowed_width <= 0 ? 800 : g_windowed_width;
  const int restore_height = g_windowed_height <= 0 ? 600 : g_windowed_height;
  glfwSetWindowMonitor(
    window,
    NULL,
    g_windowed_x,
    g_windowed_y,
    restore_width,
    restore_height,
    0
  );
  return moonbit_glfw_is_fullscreen(window);
}

static int32_t moonbit_cursor_mode_from_glfw(int glfw_mode) {
  switch (glfw_mode) {
    case GLFW_CURSOR_HIDDEN:
      return 1;
    case GLFW_CURSOR_DISABLED:
      return 2;
    case GLFW_CURSOR_NORMAL:
    default:
      return 0;
  }
}

static int moonbit_cursor_mode_to_glfw(int32_t cursor_mode) {
  switch (cursor_mode) {
    case 1:
      return GLFW_CURSOR_HIDDEN;
    case 2:
      return GLFW_CURSOR_DISABLED;
    case 0:
    default:
      return GLFW_CURSOR_NORMAL;
  }
}

int32_t moonbit_glfw_set_cursor_mode(GLFWwindow* window, int32_t cursor_mode) {
  if (window == NULL) {
    return 0;
  }
  glfwSetInputMode(window, GLFW_CURSOR, moonbit_cursor_mode_to_glfw(cursor_mode));
  const int current = glfwGetInputMode(window, GLFW_CURSOR);
  return moonbit_cursor_mode_from_glfw(current);
}

int32_t moonbit_glfw_get_cursor_mode(GLFWwindow* window) {
  if (window == NULL) {
    return 0;
  }
  const int current = glfwGetInputMode(window, GLFW_CURSOR);
  return moonbit_cursor_mode_from_glfw(current);
}

double moonbit_glfw_get_cursor_x(GLFWwindow* window) {
  if (window == NULL) {
    return 0.0;
  }
  double cursor_x = 0.0;
  double cursor_y = 0.0;
  glfwGetCursorPos(window, &cursor_x, &cursor_y);
  return cursor_x;
}

double moonbit_glfw_get_cursor_y(GLFWwindow* window) {
  if (window == NULL) {
    return 0.0;
  }
  double cursor_x = 0.0;
  double cursor_y = 0.0;
  glfwGetCursorPos(window, &cursor_x, &cursor_y);
  return cursor_y;
}

double moonbit_glfw_take_scroll_x(GLFWwindow* window) {
  if (window == NULL || window != g_input_window) {
    return 0.0;
  }
  const double current = g_scroll_x;
  g_scroll_x = 0.0;
  return current;
}

double moonbit_glfw_take_scroll_y(GLFWwindow* window) {
  if (window == NULL || window != g_input_window) {
    return 0.0;
  }
  const double current = g_scroll_y;
  g_scroll_y = 0.0;
  return current;
}

int32_t moonbit_glfw_pressed_key_count(GLFWwindow* window) {
  if (window == NULL) {
    return 0;
  }
  int32_t count = 0;
  for (int key = GLFW_KEY_SPACE; key <= GLFW_KEY_LAST; key++) {
    const int state = glfwGetKey(window, key);
    if (state == GLFW_PRESS || state == GLFW_REPEAT) {
      count++;
    }
  }
  return count;
}

int32_t moonbit_glfw_pressed_key_at(GLFWwindow* window, int32_t index) {
  if (window == NULL || index < 0) {
    return -1;
  }
  int32_t current_index = 0;
  for (int key = GLFW_KEY_SPACE; key <= GLFW_KEY_LAST; key++) {
    const int state = glfwGetKey(window, key);
    if (state == GLFW_PRESS || state == GLFW_REPEAT) {
      if (current_index == index) {
        return key;
      }
      current_index++;
    }
  }
  return -1;
}

int32_t moonbit_glfw_pressed_mouse_button_count(GLFWwindow* window) {
  if (window == NULL) {
    return 0;
  }
  int32_t count = 0;
  for (int button = GLFW_MOUSE_BUTTON_1; button <= GLFW_MOUSE_BUTTON_LAST; button++) {
    const int state = glfwGetMouseButton(window, button);
    if (state == GLFW_PRESS) {
      count++;
    }
  }
  return count;
}

int32_t moonbit_glfw_pressed_mouse_button_at(GLFWwindow* window, int32_t index) {
  if (window == NULL || index < 0) {
    return -1;
  }
  int32_t current_index = 0;
  for (int button = GLFW_MOUSE_BUTTON_1; button <= GLFW_MOUSE_BUTTON_LAST; button++) {
    const int state = glfwGetMouseButton(window, button);
    if (state == GLFW_PRESS) {
      if (current_index == index) {
        return button;
      }
      current_index++;
    }
  }
  return -1;
}

int32_t moonbit_glfw_touch_count(GLFWwindow* window) {
  moonbit_update_touches(window);
  return g_touch_count;
}

int32_t moonbit_glfw_touch_id_at(GLFWwindow* window, int32_t index) {
  moonbit_update_touches(window);
  if (index < 0 || index >= g_touch_count) {
    return -1;
  }
  return g_touches[index].id;
}

double moonbit_glfw_touch_x_at(GLFWwindow* window, int32_t index) {
  moonbit_update_touches(window);
  if (index < 0 || index >= g_touch_count) {
    return 0.0;
  }
  return g_touches[index].x;
}

double moonbit_glfw_touch_y_at(GLFWwindow* window, int32_t index) {
  moonbit_update_touches(window);
  if (index < 0 || index >= g_touch_count) {
    return 0.0;
  }
  return g_touches[index].y;
}

#if defined(GLFW_GAMEPAD_AXIS_LAST) && defined(GLFW_GAMEPAD_BUTTON_LAST)
static int32_t moonbit_glfw_gamepad_jid_at(int32_t index) {
  if (index < 0) {
    return -1;
  }
  int32_t current_index = 0;
  for (int jid = GLFW_JOYSTICK_1; jid <= GLFW_JOYSTICK_LAST; jid++) {
    if (glfwJoystickPresent(jid) != GLFW_TRUE) {
      continue;
    }
    if (glfwJoystickIsGamepad(jid) != GLFW_TRUE) {
      continue;
    }
    if (current_index == index) {
      return (int32_t)jid;
    }
    current_index++;
  }
  return -1;
}

int32_t moonbit_glfw_gamepad_count(void) {
  int32_t count = 0;
  for (int jid = GLFW_JOYSTICK_1; jid <= GLFW_JOYSTICK_LAST; jid++) {
    if (glfwJoystickPresent(jid) == GLFW_TRUE && glfwJoystickIsGamepad(jid) == GLFW_TRUE) {
      count++;
    }
  }
  return count;
}

int32_t moonbit_glfw_gamepad_id_at(int32_t index) {
  return moonbit_glfw_gamepad_jid_at(index);
}

int32_t moonbit_glfw_gamepad_axis_count(int32_t index) {
  const int32_t jid = moonbit_glfw_gamepad_jid_at(index);
  if (jid < 0) {
    return 0;
  }
  GLFWgamepadstate state;
  if (glfwGetGamepadState((int)jid, &state) != GLFW_TRUE) {
    return 0;
  }
  return (int32_t)(GLFW_GAMEPAD_AXIS_LAST + 1);
}

double moonbit_glfw_gamepad_axis_at(int32_t gamepad_index, int32_t axis_index) {
  if (axis_index < 0 || axis_index > GLFW_GAMEPAD_AXIS_LAST) {
    return 0.0;
  }
  const int32_t jid = moonbit_glfw_gamepad_jid_at(gamepad_index);
  if (jid < 0) {
    return 0.0;
  }
  GLFWgamepadstate state;
  if (glfwGetGamepadState((int)jid, &state) != GLFW_TRUE) {
    return 0.0;
  }
  return (double)state.axes[axis_index];
}

int32_t moonbit_glfw_gamepad_pressed_button_count(int32_t index) {
  const int32_t jid = moonbit_glfw_gamepad_jid_at(index);
  if (jid < 0) {
    return 0;
  }
  GLFWgamepadstate state;
  if (glfwGetGamepadState((int)jid, &state) != GLFW_TRUE) {
    return 0;
  }
  int32_t count = 0;
  for (int button = 0; button <= GLFW_GAMEPAD_BUTTON_LAST; button++) {
    if (state.buttons[button] == GLFW_PRESS) {
      count++;
    }
  }
  return count;
}

int32_t moonbit_glfw_gamepad_pressed_button_at(int32_t gamepad_index, int32_t button_index) {
  if (button_index < 0) {
    return -1;
  }
  const int32_t jid = moonbit_glfw_gamepad_jid_at(gamepad_index);
  if (jid < 0) {
    return -1;
  }
  GLFWgamepadstate state;
  if (glfwGetGamepadState((int)jid, &state) != GLFW_TRUE) {
    return -1;
  }
  int32_t current_index = 0;
  for (int button = 0; button <= GLFW_GAMEPAD_BUTTON_LAST; button++) {
    if (state.buttons[button] == GLFW_PRESS) {
      if (current_index == button_index) {
        return (int32_t)button;
      }
      current_index++;
    }
  }
  return -1;
}
#else
int32_t moonbit_glfw_gamepad_count(void) {
  return 0;
}

int32_t moonbit_glfw_gamepad_id_at(int32_t index) {
  (void)index;
  return -1;
}

int32_t moonbit_glfw_gamepad_axis_count(int32_t index) {
  (void)index;
  return 0;
}

double moonbit_glfw_gamepad_axis_at(int32_t gamepad_index, int32_t axis_index) {
  (void)gamepad_index;
  (void)axis_index;
  return 0.0;
}

int32_t moonbit_glfw_gamepad_pressed_button_count(int32_t index) {
  (void)index;
  return 0;
}

int32_t moonbit_glfw_gamepad_pressed_button_at(int32_t gamepad_index, int32_t button_index) {
  (void)gamepad_index;
  (void)button_index;
  return -1;
}
#endif

double moonbit_glfw_get_window_content_scale(GLFWwindow* window) {
  if (window == NULL) {
    return 1.0;
  }
  float xscale = 1.0f;
  float yscale = 1.0f;
  glfwGetWindowContentScale(window, &xscale, &yscale);
  if (xscale <= 0.0f) {
    return 1.0;
  }
  return (double)xscale;
}

void moonbit_glfw_request_window_attention_safe(GLFWwindow* window) {
  if (window == NULL) {
    return;
  }
#if defined(GLFW_VERSION_MAJOR) && (GLFW_VERSION_MAJOR > 3 || (GLFW_VERSION_MAJOR == 3 && GLFW_VERSION_MINOR >= 3))
  glfwRequestWindowAttention(window);
#endif
}

// MoonBit String から安全にウィンドウを作成
// MoonBit の String は UTF-16 エンコード (uint16_t*)
GLFWwindow* moonbit_glfw_create_window_safe(int32_t width, int32_t height, uint16_t* title_utf16) {
  // UTF-16 から UTF-8 に変換（簡易版：ASCII範囲のみ対応）
  char title_utf8[256] = {0};
  if (title_utf16) {
    int i = 0;
    while (i < 255 && title_utf16[i] != 0) {
      // ASCII範囲のみ変換（0x00-0x7F）
      if (title_utf16[i] < 0x80) {
        title_utf8[i] = (char)title_utf16[i];
      } else {
        title_utf8[i] = '?';  // 非ASCII文字は'?'に
      }
      i++;
    }
    title_utf8[i] = '\0';
  } else {
    strcpy(title_utf8, "Window");
  }

  // ウィンドウヒント設定（WebGPU 用）
  glfwWindowHint(0x00022001, 0);  // GLFW_CLIENT_API = GLFW_NO_API
  glfwWindowHint(0x00020003, 1);  // GLFW_RESIZABLE = GLFW_TRUE

  // ウィンドウ作成
  GLFWwindow* window = glfwCreateWindow(width, height, title_utf8, NULL, NULL);
  g_input_window = window;
  g_scroll_x = 0.0;
  g_scroll_y = 0.0;
  if (window != NULL) {
    glfwSetScrollCallback(window, moonbit_glfw_scroll_callback);
    NSWindow* nswindow = glfwGetCocoaWindow(window);
    if (nswindow != nil) {
      NSView* contentView = [nswindow contentView];
      if (contentView != nil) {
        if ([contentView respondsToSelector:@selector(setAllowedTouchTypes:)]) {
          [contentView setAllowedTouchTypes:(NSTouchTypeMaskDirect | NSTouchTypeMaskIndirect)];
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if ([contentView respondsToSelector:@selector(setAcceptsTouchEvents:)]) {
          [contentView setAcceptsTouchEvents:YES];
        }
#pragma clang diagnostic pop
        if ([contentView respondsToSelector:@selector(setWantsRestingTouches:)]) {
          [contentView setWantsRestingTouches:YES];
        }
      }
    }
  }
  moonbit_reset_touches();

  return window;
}

// ===============================
// WebGPU Surface 作成
// ===============================

// GLFWwindow から CAMetalLayer を取得/作成
CAMetalLayer* get_metal_layer_from_glfw(GLFWwindow* window) {
  NSWindow* nswindow = glfwGetCocoaWindow(window);
  if (!nswindow) {
    printf("[ERROR] Failed to get NSWindow from GLFW\n");
    return NULL;
  }

  NSView* contentView = [nswindow contentView];
  if (!contentView) {
    printf("[ERROR] Failed to get content view\n");
    return NULL;
  }

  // CAMetalLayer が既にある場合はそれを返す
  if ([[contentView layer] isKindOfClass:[CAMetalLayer class]]) {
    return (CAMetalLayer*)[contentView layer];
  }

  // CAMetalLayer を新規作成
  [contentView setWantsLayer:YES];
  CAMetalLayer* metalLayer = [CAMetalLayer layer];
  [contentView setLayer:metalLayer];

  printf("[INFO] Created CAMetalLayer for GLFW window\n");
  return metalLayer;
}

// GLFW window から wgpu Surface を作成
void* moonbit_create_surface_from_glfw(void* instance, GLFWwindow* window) {
  printf("[C] moonbit_create_surface_from_glfw() called\n");
  printf("[C]   instance=%p, window=%p\n", instance, (void*)window);

  // Metal layer を取得
  CAMetalLayer* metalLayer = get_metal_layer_from_glfw(window);
  if (!metalLayer) {
    printf("[ERROR] Failed to get Metal layer\n");
    return NULL;
  }

  printf("[C]   metalLayer=%p\n", (void*)metalLayer);

  // WGPUSurfaceSourceMetalLayer 構造体を作成
  WGPUSurfaceSourceMetalLayer metalSurfaceSource = {
    .chain = {
      .next = NULL,
      .sType = WGPUSType_SurfaceSourceMetalLayer
    },
    .layer = metalLayer
  };

  // WGPUSurfaceDescriptor を作成
  WGPUSurfaceDescriptor surfaceDescriptor = {
    .nextInChain = (WGPUChainedStruct*)&metalSurfaceSource,
    .label = "GLFW Surface"
  };

  // Surface を作成
  WGPUSurface surface = wgpuInstanceCreateSurface((WGPUInstance)instance, &surfaceDescriptor);
  printf("[C] wgpuInstanceCreateSurface() returned: %p\n", (void*)surface);

  return surface;
}

// ===============================
// Adapter 取得（非同期コールバック対応）
// ===============================

// グローバル変数でコールバック結果を保存
static WGPUAdapter g_adapter = NULL;
static WGPURequestAdapterStatus g_adapter_status;
static int g_adapter_received = 0;

// Adapter 取得のコールバック
void adapter_request_callback(
    WGPURequestAdapterStatus status,
    WGPUAdapter adapter,
    WGPUStringView message,
    void* userdata1,
    void* userdata2
) {
  printf("[C] Adapter callback: status=%d, adapter=%p\n", status, (void*)adapter);
  if (message.data && message.length > 0) {
    printf("[C] Message: %.*s\n", (int)message.length, message.data);
  }

  g_adapter_status = status;
  g_adapter = adapter;
  g_adapter_received = 1;
}

// Adapter をリクエストして同期的に待機（MoonBit から呼び出し）
WGPUAdapter moonbit_request_adapter_sync(WGPUInstance instance, WGPUSurface surface) {
  printf("[C] moonbit_request_adapter_sync() called\n");
  printf("[C]   instance=%p, surface=%p\n", (void*)instance, (void*)surface);

  // グローバル変数をリセット
  g_adapter = NULL;
  g_adapter_status = 0;
  g_adapter_received = 0;

  // RequestAdapterOptions を設定
  WGPURequestAdapterOptions options = {
    .nextInChain = NULL,
    .compatibleSurface = surface,
    .powerPreference = WGPUPowerPreference_HighPerformance,
    .backendType = WGPUBackendType_Undefined,  // Metal を自動選択
    .forceFallbackAdapter = 0
  };

  // コールバック情報を設定
  // AllowSpontaneous: コールバックが即座に呼ばれる（wgpuInstanceWaitAny 不要）
  WGPURequestAdapterCallbackInfo callbackInfo = {
    .nextInChain = NULL,
    .mode = WGPUCallbackMode_AllowSpontaneous,
    .callback = adapter_request_callback,
    .userdata1 = NULL,
    .userdata2 = NULL
  };

  // Adapter をリクエスト（非同期）
  printf("[C] Calling wgpuInstanceRequestAdapter...\n");
  WGPUFuture future = wgpuInstanceRequestAdapter(instance, &options, callbackInfo);
  printf("[C] Got future: id=%llu\n", future.id);

  // AllowSpontaneous モードではコールバックが即座に呼ばれる
  // 念のため少し待機
  for (int i = 0; i < 100 && !g_adapter_received; i++) {
    // スピンウェイト
  }

  if (!g_adapter_received) {
    printf("[ERROR] Callback not called: received=%d\n", g_adapter_received);
    return NULL;
  }

  if (g_adapter_status != WGPURequestAdapterStatus_Success) {
    printf("[ERROR] Adapter request failed: status=%d\n", g_adapter_status);
    return NULL;
  }

  printf("[C] ✓ Adapter acquired successfully: %p\n", (void*)g_adapter);
  return g_adapter;
}

// ===============================
// Device 取得（非同期コールバック対応）
// ===============================

// グローバル変数でコールバック結果を保存
static WGPUDevice g_device = NULL;
static WGPURequestDeviceStatus g_device_status;
static int g_device_received = 0;

// Device 取得のコールバック
void device_request_callback(
    WGPURequestDeviceStatus status,
    WGPUDevice device,
    WGPUStringView message,
    void* userdata1,
    void* userdata2
) {
  printf("[C] Device callback: status=%d, device=%p\n", status, (void*)device);
  if (message.data && message.length > 0) {
    printf("[C] Message: %.*s\n", (int)message.length, message.data);
  }

  g_device_status = status;
  g_device = device;
  g_device_received = 1;
}

// Device をリクエストして同期的に待機（MoonBit から呼び出し）
WGPUDevice moonbit_request_device_sync(WGPUAdapter adapter) {
  printf("[C] moonbit_request_device_sync() called\n");
  printf("[C]   adapter=%p\n", (void*)adapter);

  // グローバル変数をリセット
  g_device = NULL;
  g_device_status = 0;
  g_device_received = 0;

  // DeviceDescriptor を設定（最小限）
  WGPUDeviceDescriptor descriptor = {
    .nextInChain = NULL,
    .label = "Main Device",
    .requiredFeatureCount = 0,
    .requiredFeatures = NULL,
    .requiredLimits = NULL,
    .defaultQueue = {
      .nextInChain = NULL,
      .label = "Main Queue"
    },
    .deviceLostCallbackInfo = {
      .nextInChain = NULL,
      .mode = WGPUCallbackMode_AllowSpontaneous,
      .callback = NULL
    },
    .uncapturedErrorCallbackInfo = {
      .nextInChain = NULL,
      .callback = NULL
    }
  };

  // コールバック情報を設定
  WGPURequestDeviceCallbackInfo callbackInfo = {
    .nextInChain = NULL,
    .mode = WGPUCallbackMode_AllowSpontaneous,
    .callback = device_request_callback,
    .userdata1 = NULL,
    .userdata2 = NULL
  };

  // Device をリクエスト（非同期）
  printf("[C] Calling wgpuAdapterRequestDevice...\n");
  WGPUFuture future = wgpuAdapterRequestDevice(adapter, &descriptor, callbackInfo);
  printf("[C] Got future: id=%llu\n", future.id);

  // AllowSpontaneous モードではコールバックが即座に呼ばれる
  for (int i = 0; i < 100 && !g_device_received; i++) {
    // スピンウェイト
  }

  if (!g_device_received) {
    printf("[ERROR] Device callback not called: received=%d\n", g_device_received);
    return NULL;
  }

  if (g_device_status != WGPURequestDeviceStatus_Success) {
    printf("[ERROR] Device request failed: status=%d\n", g_device_status);
    return NULL;
  }

  printf("[C] ✓ Device acquired successfully: %p\n", (void*)g_device);
  return g_device;
}

// Queue を取得（Device から）
WGPUQueue moonbit_device_get_queue(WGPUDevice device) {
  printf("[C] moonbit_device_get_queue() called\n");
  printf("[C]   device=%p\n", (void*)device);

  WGPUQueue queue = wgpuDeviceGetQueue(device);
  printf("[C] ✓ Queue acquired: %p\n", (void*)queue);

  return queue;
}

// ===============================
// Surface Configuration
// ===============================

// Surface を設定（MoonBit から呼び出し）
void moonbit_configure_surface(
    WGPUSurface surface,
    WGPUDevice device,
    WGPUAdapter adapter,
    uint32_t width,
    uint32_t height
) {
  printf("[C] moonbit_configure_surface() called\n");
  printf("[C]   surface=%p, device=%p, adapter=%p, size=%dx%d\n",
         (void*)surface, (void*)device, (void*)adapter, width, height);

  // Surface の capabilities を取得
  WGPUSurfaceCapabilities capabilities = {0};
  WGPUStatus status = wgpuSurfaceGetCapabilities(surface, adapter, &capabilities);

  if (status != WGPUStatus_Success) {
    printf("[ERROR] Failed to get surface capabilities: status=%d\n", status);
    return;
  }

  printf("[C] Surface capabilities:\n");
  printf("[C]   formatCount=%zu\n", capabilities.formatCount);
  if (capabilities.formatCount > 0) {
    printf("[C]   format[0]=%d\n", capabilities.formats[0]);
  }

  // 最初のフォーマットを使用（通常は BGRA8Unorm）
  WGPUTextureFormat format = capabilities.formatCount > 0
    ? capabilities.formats[0]
    : WGPUTextureFormat_BGRA8Unorm;
  g_configured_surface_format = format;

  printf("[C] Using format: %d\n", format);

  // Surface を設定
  WGPUSurfaceConfiguration config = {
    .nextInChain = NULL,
    .device = device,
    .format = format,
    .usage = WGPUTextureUsage_RenderAttachment,
    .width = width,
    .height = height,
    .viewFormatCount = 0,
    .viewFormats = NULL,
    .alphaMode = WGPUCompositeAlphaMode_Auto,
    .presentMode = WGPUPresentMode_Fifo
  };

  wgpuSurfaceConfigure(surface, &config);
  printf("[C] ✓ Surface configured successfully\n");

  // capabilities のメモリを解放
  wgpuSurfaceCapabilitiesFreeMembers(capabilities);
}

// ===============================
// Shader Module
// ===============================

// UTF-16 文字列を UTF-8 に変換（ASCII範囲のみ）
char* utf16_to_utf8(uint16_t* utf16_str) {
  if (!utf16_str) return NULL;

  // 文字列長を計算
  size_t len = 0;
  while (utf16_str[len] != 0) {
    len++;
  }

  // UTF-8 バッファを確保（ASCII範囲なので長さは同じ）
  char* utf8_str = (char*)malloc(len + 1);
  if (!utf8_str) return NULL;

  // 変換（ASCII範囲のみ）
  for (size_t i = 0; i < len; i++) {
    utf8_str[i] = (utf16_str[i] < 0x80) ? utf16_str[i] : '?';
  }
  utf8_str[len] = '\0';

  return utf8_str;
}

static WGPUShaderModule moonbit_create_shader_module_from_utf8(
    WGPUDevice device,
    const char* wgsl_code
) {
  if (device == NULL || wgsl_code == NULL) {
    return NULL;
  }

  WGPUShaderSourceWGSL wgslDesc = {
    .chain = {
      .next = NULL,
      .sType = WGPUSType_ShaderSourceWGSL
    },
    .code = {
      .data = wgsl_code,
      .length = strlen(wgsl_code)
    }
  };

  WGPUShaderModuleDescriptor descriptor = {
    .nextInChain = (WGPUChainedStruct*)&wgslDesc,
    .label = "Dynamic Payload Shader"
  };

  return wgpuDeviceCreateShaderModule(device, &descriptor);
}

// ShaderModule を作成（WGSL シェーダーコードから）
void* moonbit_create_shader_module(WGPUDevice device, uint16_t* wgsl_code_utf16) {
  printf("[C] moonbit_create_shader_module() called\n");
  printf("[C]   device=%p\n", (void*)device);

  // UTF-16 → UTF-8 変換
  char* wgsl_code = utf16_to_utf8(wgsl_code_utf16);
  if (!wgsl_code) {
    printf("[ERROR] Failed to convert WGSL code\n");
    return NULL;
  }

  printf("[C] WGSL code (first 100 chars):\n%.*s\n", 100, wgsl_code);

  // ShaderSourceWGSL を作成
  WGPUShaderSourceWGSL wgslDesc = {
    .chain = {
      .next = NULL,
      .sType = WGPUSType_ShaderSourceWGSL
    },
    .code = {
      .data = wgsl_code,
      .length = strlen(wgsl_code)
    }
  };

  // ShaderModuleDescriptor を作成
  WGPUShaderModuleDescriptor descriptor = {
    .nextInChain = (WGPUChainedStruct*)&wgslDesc,
    .label = "Triangle Shader"
  };

  // ShaderModule を作成
  WGPUShaderModule shaderModule = wgpuDeviceCreateShaderModule(device, &descriptor);
  printf("[C] ✓ ShaderModule created: %p\n", (void*)shaderModule);

  free(wgsl_code);
  return shaderModule;
}

// ===============================
// Render Pipeline
// ===============================

// シンプルな RenderPipeline を作成（三角形描画用）
void* moonbit_create_render_pipeline(
    WGPUDevice device,
    WGPUShaderModule shaderModule,
    uint32_t format
) {
  printf("[C] moonbit_create_render_pipeline() called\n");
  printf("[C]   device=%p, shader=%p, format=%d\n",
         (void*)device, (void*)shaderModule, format);

  // Vertex state（頂点なし、シェーダーで生成）
  WGPUVertexState vertexState = {
    .module = shaderModule,
    .entryPoint = {.data = "vs_main", .length = 7},
    .constantCount = 0,
    .constants = NULL,
    .bufferCount = 0,
    .buffers = NULL
  };

  // Fragment state
  WGPUColorTargetState colorTarget = {
    .format = format,
    .blend = NULL,
    .writeMask = WGPUColorWriteMask_All
  };

  WGPUFragmentState fragmentState = {
    .module = shaderModule,
    .entryPoint = {.data = "fs_main", .length = 7},
    .constantCount = 0,
    .constants = NULL,
    .targetCount = 1,
    .targets = &colorTarget
  };

  // RenderPipelineDescriptor
  WGPURenderPipelineDescriptor descriptor = {
    .nextInChain = NULL,
    .label = "Triangle Pipeline",
    .layout = NULL,  // Auto layout
    .vertex = vertexState,
    .primitive = {
      .topology = WGPUPrimitiveTopology_TriangleList,
      .stripIndexFormat = WGPUIndexFormat_Undefined,
      .frontFace = WGPUFrontFace_CCW,
      .cullMode = WGPUCullMode_None
    },
    .depthStencil = NULL,
    .multisample = {
      .count = 1,
      .mask = 0xFFFFFFFF,
      .alphaToCoverageEnabled = 0
    },
    .fragment = &fragmentState
  };

  WGPURenderPipeline pipeline = wgpuDeviceCreateRenderPipeline(device, &descriptor);
  printf("[C] ✓ RenderPipeline created: %p\n", (void*)pipeline);

  return pipeline;
}

// ===============================
// Rendering
// ===============================

static void moonbit_render_frame_impl(
    WGPUSurface surface,
    WGPUDevice device,
    WGPUQueue queue,
    WGPURenderPipeline pipeline,
    double clear_r,
    double clear_g,
    double clear_b,
    double clear_a,
    int32_t draw_calls,
    int32_t has_triangle_payload,
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
    double au,
    double av,
    double bu,
    double bv,
    double cu,
    double cv,
    double uniform_r,
    double uniform_g,
    double uniform_b,
    double uniform_a,
    int32_t texture_seed
) {
  if (draw_calls < 0) {
    draw_calls = 0;
  }

  // Surface から現在のテクスチャを取得
  WGPUSurfaceTexture surfaceTexture;
  wgpuSurfaceGetCurrentTexture(surface, &surfaceTexture);

  if (surfaceTexture.status != WGPUSurfaceGetCurrentTextureStatus_SuccessOptimal &&
      surfaceTexture.status != WGPUSurfaceGetCurrentTextureStatus_SuccessSuboptimal) {
    printf("[ERROR] Failed to get surface texture: status=%d\n", surfaceTexture.status);
    return;
  }

  // TextureView を作成
  WGPUTextureViewDescriptor viewDesc = {
    .nextInChain = NULL,
    .label = "Surface Texture View",
    .format = WGPUTextureFormat_Undefined,  // Use texture's format
    .dimension = WGPUTextureViewDimension_2D,
    .baseMipLevel = 0,
    .mipLevelCount = 1,
    .baseArrayLayer = 0,
    .arrayLayerCount = 1,
    .aspect = WGPUTextureAspect_All
  };

  WGPUTextureView view = wgpuTextureCreateView(surfaceTexture.texture, &viewDesc);

  // CommandEncoder を作成
  WGPUCommandEncoderDescriptor encoderDesc = {
    .nextInChain = NULL,
    .label = "Command Encoder"
  };
  WGPUCommandEncoder encoder = wgpuDeviceCreateCommandEncoder(device, &encoderDesc);

  // RenderPass を開始
  WGPURenderPassColorAttachment colorAttachment = {
    .view = view,
    .depthSlice = WGPU_DEPTH_SLICE_UNDEFINED,
    .resolveTarget = NULL,
    .loadOp = WGPULoadOp_Clear,
    .storeOp = WGPUStoreOp_Store,
    .clearValue = {(float)clear_r, (float)clear_g, (float)clear_b, (float)clear_a}
  };

  WGPURenderPassDescriptor renderPassDesc = {
    .nextInChain = NULL,
    .label = "Render Pass",
    .colorAttachmentCount = 1,
    .colorAttachments = &colorAttachment,
    .depthStencilAttachment = NULL,
    .occlusionQuerySet = NULL,
    .timestampWrites = NULL
  };

  WGPURenderPassEncoder pass = wgpuCommandEncoderBeginRenderPass(encoder, &renderPassDesc);
  WGPUShaderModule payload_shader = NULL;
  WGPURenderPipeline payload_pipeline = NULL;
  WGPURenderPipeline active_pipeline = pipeline;

  if (draw_calls > 0) {
    if (has_triangle_payload != 0) {
      const double texture_frequency = (double)((texture_seed % 11) + 1);
      char wgsl[2048];
      const int n = snprintf(
        wgsl,
        sizeof(wgsl),
        "struct VsOut {\n"
        "  @builtin(position) position: vec4f,\n"
        "  @location(0) uv: vec2f,\n"
        "};\n\n"
        "@vertex\n"
        "fn vs_main(@builtin(vertex_index) idx: u32) -> VsOut {\n"
        "  let i = idx %% 3u;\n"
        "  var pos = array<vec2f, 3>(vec2f(%f, %f), vec2f(%f, %f), vec2f(%f, %f));\n"
        "  var uv = array<vec2f, 3>(vec2f(%f, %f), vec2f(%f, %f), vec2f(%f, %f));\n"
        "  var out : VsOut;\n"
        "  out.position = vec4f(pos[i], 0.0, 1.0);\n"
        "  out.uv = uv[i];\n"
        "  return out;\n"
        "}\n\n"
        "@fragment\n"
        "fn fs_main(@location(0) in_uv: vec2f) -> @location(0) vec4f {\n"
        "  let fu = floor(in_uv.x * %f);\n"
        "  let fv = floor(in_uv.y * %f);\n"
        "  let checker = step(0.5, fract((fu + fv) * 0.5));\n"
        "  let tex = vec3f(0.15 + checker * 0.85, 0.2 + checker * 0.8, 0.25 + checker * 0.75);\n"
        "  let tint = vec3f(%f, %f, %f);\n"
        "  return vec4f(tex * tint, %f);\n"
        "}\n",
        ax,
        ay,
        bx,
        by,
        cx,
        cy,
        au,
        av,
        bu,
        bv,
        cu,
        cv,
        texture_frequency,
        texture_frequency,
        uniform_r,
        uniform_g,
        uniform_b,
        uniform_a
      );
      if (n > 0 && (size_t)n < sizeof(wgsl)) {
        payload_shader = moonbit_create_shader_module_from_utf8(device, wgsl);
        if (payload_shader != NULL) {
          payload_pipeline = moonbit_create_render_pipeline(
            device,
            payload_shader,
            g_configured_surface_format
          );
          if (payload_pipeline != NULL) {
            active_pipeline = payload_pipeline;
          }
        }
      }
    }

    // Pipeline を設定して三角形を描画
    wgpuRenderPassEncoderSetPipeline(pass, active_pipeline);
    for (int32_t i = 0; i < draw_calls; i++) {
      wgpuRenderPassEncoderDraw(pass, 3, 1, 0, 0);  // 3 vertices
    }
  }

  // RenderPass を終了
  wgpuRenderPassEncoderEnd(pass);
  wgpuRenderPassEncoderRelease(pass);

  // CommandBuffer を作成して Queue に送信
  WGPUCommandBufferDescriptor cmdBufferDesc = {
    .nextInChain = NULL,
    .label = "Command Buffer"
  };
  WGPUCommandBuffer cmdBuffer = wgpuCommandEncoderFinish(encoder, &cmdBufferDesc);
  wgpuQueueSubmit(queue, 1, &cmdBuffer);

  // リソースをクリーンアップ
  wgpuCommandBufferRelease(cmdBuffer);
  wgpuCommandEncoderRelease(encoder);
  wgpuTextureViewRelease(view);

  // Present
  wgpuSurfacePresent(surface);

  // Texture を解放
  wgpuTextureRelease(surfaceTexture.texture);
  if (payload_pipeline != NULL) {
    wgpuRenderPipelineRelease(payload_pipeline);
  }
  if (payload_shader != NULL) {
    wgpuShaderModuleRelease(payload_shader);
  }
}

// 1フレーム描画（後方互換 API）
void moonbit_render_frame(
    WGPUSurface surface,
    WGPUDevice device,
    WGPUQueue queue,
    WGPURenderPipeline pipeline
) {
  moonbit_render_frame_impl(
    surface,
    device,
    queue,
    pipeline,
    0.1,
    0.2,
    0.3,
    1.0,
    1,
    0,
    0.0,
    0.5,
    -0.5,
    -0.5,
    0.5,
    -0.5,
    0.0,
    0.0,
    1.0,
    0.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    0
  );
}

// 1フレーム描画（clear 色・draw 回数を指定）
void moonbit_render_frame_with_plan(
    WGPUSurface surface,
    WGPUDevice device,
    WGPUQueue queue,
    WGPURenderPipeline pipeline,
    double clear_r,
    double clear_g,
    double clear_b,
    double clear_a,
    int32_t draw_calls
) {
  moonbit_render_frame_impl(
    surface,
    device,
    queue,
    pipeline,
    clear_r,
    clear_g,
    clear_b,
    clear_a,
    draw_calls,
    0,
    0.0,
    0.5,
    -0.5,
    -0.5,
    0.5,
    -0.5,
    0.0,
    0.0,
    1.0,
    0.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    0
  );
}

void moonbit_render_frame_with_plan_payload(
    WGPUSurface surface,
    WGPUDevice device,
    WGPUQueue queue,
    WGPURenderPipeline pipeline,
    double clear_r,
    double clear_g,
    double clear_b,
    double clear_a,
    int32_t draw_calls,
    int32_t has_triangle_payload,
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
    double au,
    double av,
    double bu,
    double bv,
    double cu,
    double cv,
    double uniform_r,
    double uniform_g,
    double uniform_b,
    double uniform_a,
    int32_t texture_seed
) {
  moonbit_render_frame_impl(
    surface,
    device,
    queue,
    pipeline,
    clear_r,
    clear_g,
    clear_b,
    clear_a,
    draw_calls,
    has_triangle_payload,
    ax,
    ay,
    bx,
    by,
    cx,
    cy,
    au,
    av,
    bu,
    bv,
    cu,
    cv,
    uniform_r,
    uniform_g,
    uniform_b,
    uniform_a,
    texture_seed
  );
}
