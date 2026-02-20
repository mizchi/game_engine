// WebGPU C API スタブ
// wgpu-native が完全な C API を提供しているため、このファイルは最小限

#include <moonbit.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>

// WebGPU と GLFW の macOS 固有ヘッダー
#if __has_include("../../deps/wgpu-macos/include/webgpu/webgpu.h")
#include "../../deps/wgpu-macos/include/webgpu/webgpu.h"
#elif __has_include(<webgpu/webgpu.h>)
#include <webgpu/webgpu.h>
#else
#error "webgpu/webgpu.h not found. run: bash scripts/setup-wgpu-native.sh"
#endif

// wgpu-native extension header (provides wgpuDevicePoll etc.)
#if __has_include("../../deps/wgpu-macos/include/webgpu/wgpu.h")
#include "../../deps/wgpu-macos/include/webgpu/wgpu.h"
#elif __has_include(<webgpu/wgpu.h>)
#include <webgpu/wgpu.h>
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
  int32_t touch_type; // 0=Direct, 1=Indirect, 3=Unknown
} moonbit_touch_state;
static moonbit_touch_state g_touches[MOONBIT_MAX_TOUCHES];
static int32_t g_touch_count = 0;
static WGPUTextureFormat g_configured_surface_format = WGPUTextureFormat_BGRA8Unorm;

// readback state
static WGPUBuffer g_readback_buffer = NULL;
static uint32_t g_readback_width = 0;
static uint32_t g_readback_height = 0;
static uint8_t* g_readback_data = NULL;
static int32_t g_readback_valid = 0;

// Forward declarations for readback (defined later in file)
static void moonbit_readback_encode_copy(
    WGPUDevice device, WGPUCommandEncoder encoder, WGPUTexture surface_texture,
    uint32_t tex_width, uint32_t tex_height);
static void moonbit_readback_map_and_read(WGPUDevice device);

#define MOONBIT_MAX_PLANNED_DRAW_COMMANDS 4096
typedef struct {
  int32_t draw_calls;
  int32_t has_triangle_payload;
  double ax;
  double ay;
  double bx;
  double by;
  double cx;
  double cy;
  double au;
  double av;
  double bu;
  double bv;
  double cu;
  double cv;
  double uniform_r;
  double uniform_g;
  double uniform_b;
  double uniform_a;
  int32_t texture_seed;
  int32_t dst_image_id;
} moonbit_planned_draw_command;
static moonbit_planned_draw_command g_planned_draw_commands[MOONBIT_MAX_PLANNED_DRAW_COMMANDS];
static int32_t g_planned_draw_command_count = 0;

typedef struct {
  float x;
  float y;
  float u;
  float v;
} moonbit_payload_vertex;

#define MOONBIT_MAX_PLANNED_PIPELINE_CACHE_ENTRIES 128
typedef struct {
  int32_t used;
  uintptr_t device_key;
  WGPUTextureFormat format;
  char shader_key[512];
  WGPUShaderModule shader;
  WGPURenderPipeline pipeline;
  uint64_t stamp;
} moonbit_planned_pipeline_cache_entry;
static moonbit_planned_pipeline_cache_entry g_planned_pipeline_cache[MOONBIT_MAX_PLANNED_PIPELINE_CACHE_ENTRIES];
static uint64_t g_planned_pipeline_cache_stamp = 1;

#define MOONBIT_MAX_PLANNED_TEXTURE_CACHE_ENTRIES 256
typedef struct {
  int32_t used;
  uintptr_t device_key;
  int32_t texture_seed;
  uint32_t texture_generation;
  uint32_t texture_width;
  uint32_t texture_height;
  WGPUTexture texture;
  WGPUTextureView texture_view;
  WGPUSampler sampler;
  uint64_t stamp;
} moonbit_planned_texture_cache_entry;
static moonbit_planned_texture_cache_entry g_planned_texture_cache[MOONBIT_MAX_PLANNED_TEXTURE_CACHE_ENTRIES];
static uint64_t g_planned_texture_cache_stamp = 1;

#define MOONBIT_MAX_PLANNED_BIND_GROUP_CACHE_ENTRIES 256
typedef struct {
  int32_t used;
  uintptr_t device_key;
  uintptr_t pipeline_key;
  int32_t texture_seed;
  uint32_t texture_generation;
  WGPUBindGroup bind_group;
  uint64_t stamp;
} moonbit_planned_bind_group_cache_entry;
static moonbit_planned_bind_group_cache_entry g_planned_bind_group_cache[MOONBIT_MAX_PLANNED_BIND_GROUP_CACHE_ENTRIES];
static uint64_t g_planned_bind_group_cache_stamp = 1;

#define MOONBIT_MAX_OFFSCREEN_TARGETS 64
typedef struct {
  int32_t used;
  int32_t image_id;
  uint32_t width;
  uint32_t height;
  WGPUTexture texture;
  WGPUTextureView view;
} moonbit_offscreen_target;
static moonbit_offscreen_target g_offscreen_targets[MOONBIT_MAX_OFFSCREEN_TARGETS];

static moonbit_offscreen_target* moonbit_find_offscreen_target(int32_t image_id) {
  for (int i = 0; i < MOONBIT_MAX_OFFSCREEN_TARGETS; i++) {
    if (g_offscreen_targets[i].used && g_offscreen_targets[i].image_id == image_id) {
      return &g_offscreen_targets[i];
    }
  }
  return NULL;
}

#define MOONBIT_MAX_PLANNED_IMAGE_PALETTE_ENTRIES 512
typedef struct {
  int32_t used;
  int32_t image_id;
  uint32_t generation;
  uint8_t pixels[16];
  uint64_t stamp;
} moonbit_planned_image_palette_entry;
static moonbit_planned_image_palette_entry g_planned_image_palette[MOONBIT_MAX_PLANNED_IMAGE_PALETTE_ENTRIES];
static uint64_t g_planned_image_palette_stamp = 1;

#define MOONBIT_MAX_PLANNED_SOURCE_IMAGE_ENTRIES 256
typedef struct {
  int32_t used;
  int32_t image_id;
  uint32_t width;
  uint32_t height;
  uint32_t generation;
  int32_t upload_mode; // 0: none, 1: full, 2: patch
  int32_t touched_any;
  uint32_t touched_min_x;
  uint32_t touched_min_y;
  uint32_t touched_max_x;
  uint32_t touched_max_y;
  int32_t dirty_has_rect;
  uint32_t dirty_x;
  uint32_t dirty_y;
  uint32_t dirty_width;
  uint32_t dirty_height;
  uint8_t* pixels;
  size_t pixel_length;
  uint64_t stamp;
} moonbit_planned_source_image_entry;
static moonbit_planned_source_image_entry g_planned_source_images[MOONBIT_MAX_PLANNED_SOURCE_IMAGE_ENTRIES];
static uint64_t g_planned_source_image_stamp = 1;

void moonbit_clear_planned_bind_group_cache(void);

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
    g_touches[i].touch_type = 3; // Unknown
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
    // Determine touch type: Direct(0), Indirect(1), Unknown(3)
    if ([touch respondsToSelector:@selector(type)]) {
      NSInteger touchType = [touch type];
      if (touchType == NSTouchTypeDirect) {
        g_touches[index].touch_type = 0; // Direct
      } else if (touchType == NSTouchTypeIndirect) {
        g_touches[index].touch_type = 1; // Indirect
      } else {
        g_touches[index].touch_type = 3; // Unknown
      }
    } else {
      g_touches[index].touch_type = 3; // Unknown
    }
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

int32_t moonbit_glfw_touch_type_at(GLFWwindow* window, int32_t index) {
  moonbit_update_touches(window);
  if (index < 0 || index >= g_touch_count) {
    return 3; // Unknown
  }
  return g_touches[index].touch_type;
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
    .usage = WGPUTextureUsage_RenderAttachment | WGPUTextureUsage_CopySrc,
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

static uint64_t moonbit_next_planned_pipeline_cache_stamp(void) {
  uint64_t stamp = g_planned_pipeline_cache_stamp;
  g_planned_pipeline_cache_stamp += 1;
  if (g_planned_pipeline_cache_stamp == 0) {
    g_planned_pipeline_cache_stamp = 1;
  }
  return stamp;
}

static void moonbit_release_planned_pipeline_cache_entry(
    moonbit_planned_pipeline_cache_entry* entry
) {
  if (entry == NULL || entry->used == 0) {
    return;
  }
  if (entry->pipeline != NULL) {
    wgpuRenderPipelineRelease(entry->pipeline);
  }
  if (entry->shader != NULL) {
    wgpuShaderModuleRelease(entry->shader);
  }
  entry->used = 0;
  entry->device_key = 0;
  entry->format = WGPUTextureFormat_Undefined;
  entry->shader_key[0] = '\0';
  entry->shader = NULL;
  entry->pipeline = NULL;
  entry->stamp = 0;
}

void moonbit_clear_planned_pipeline_cache(void) {
  moonbit_clear_planned_bind_group_cache();
  for (int i = 0; i < MOONBIT_MAX_PLANNED_PIPELINE_CACHE_ENTRIES; i++) {
    moonbit_release_planned_pipeline_cache_entry(&g_planned_pipeline_cache[i]);
  }
  g_planned_pipeline_cache_stamp = 1;
}

static uint64_t moonbit_next_planned_texture_cache_stamp(void) {
  uint64_t stamp = g_planned_texture_cache_stamp;
  g_planned_texture_cache_stamp += 1;
  if (g_planned_texture_cache_stamp == 0) {
    g_planned_texture_cache_stamp = 1;
  }
  return stamp;
}

static void moonbit_release_planned_texture_cache_entry(
    moonbit_planned_texture_cache_entry* entry
) {
  if (entry == NULL || entry->used == 0) {
    return;
  }
  if (entry->sampler != NULL) {
    wgpuSamplerRelease(entry->sampler);
  }
  if (entry->texture_view != NULL) {
    wgpuTextureViewRelease(entry->texture_view);
  }
  if (entry->texture != NULL) {
    wgpuTextureRelease(entry->texture);
  }
  entry->used = 0;
  entry->device_key = 0;
  entry->texture_seed = 0;
  entry->texture_generation = 0;
  entry->texture_width = 0;
  entry->texture_height = 0;
  entry->texture = NULL;
  entry->texture_view = NULL;
  entry->sampler = NULL;
  entry->stamp = 0;
}

void moonbit_clear_planned_texture_cache(void) {
  moonbit_clear_planned_bind_group_cache();
  for (int i = 0; i < MOONBIT_MAX_PLANNED_TEXTURE_CACHE_ENTRIES; i++) {
    moonbit_release_planned_texture_cache_entry(&g_planned_texture_cache[i]);
  }
  g_planned_texture_cache_stamp = 1;
}

static uint64_t moonbit_next_planned_bind_group_cache_stamp(void) {
  uint64_t stamp = g_planned_bind_group_cache_stamp;
  g_planned_bind_group_cache_stamp += 1;
  if (g_planned_bind_group_cache_stamp == 0) {
    g_planned_bind_group_cache_stamp = 1;
  }
  return stamp;
}

static void moonbit_release_planned_bind_group_cache_entry(
    moonbit_planned_bind_group_cache_entry* entry
) {
  if (entry == NULL || entry->used == 0) {
    return;
  }
  if (entry->bind_group != NULL) {
    wgpuBindGroupRelease(entry->bind_group);
  }
  entry->used = 0;
  entry->device_key = 0;
  entry->pipeline_key = 0;
  entry->texture_seed = 0;
  entry->texture_generation = 0;
  entry->bind_group = NULL;
  entry->stamp = 0;
}

void moonbit_clear_planned_bind_group_cache(void) {
  for (int i = 0; i < MOONBIT_MAX_PLANNED_BIND_GROUP_CACHE_ENTRIES; i++) {
    moonbit_release_planned_bind_group_cache_entry(&g_planned_bind_group_cache[i]);
  }
  g_planned_bind_group_cache_stamp = 1;
}

static uint8_t moonbit_clamp_u8_channel(int32_t value) {
  if (value < 0) {
    return 0;
  }
  if (value > 255) {
    return 255;
  }
  return (uint8_t)value;
}

static uint32_t moonbit_next_resource_generation(uint32_t current) {
  if (current == UINT32_MAX) {
    return 1U;
  }
  if (current == 0U) {
    return 1U;
  }
  return current + 1U;
}

static uint64_t moonbit_next_planned_image_palette_stamp(void) {
  uint64_t stamp = g_planned_image_palette_stamp;
  g_planned_image_palette_stamp += 1;
  if (g_planned_image_palette_stamp == 0) {
    g_planned_image_palette_stamp = 1;
  }
  return stamp;
}

static moonbit_planned_image_palette_entry* moonbit_lookup_planned_image_palette_entry(
    int32_t image_id,
    int touch_stamp
) {
  if (image_id < 0) {
    return NULL;
  }
  for (int i = 0; i < MOONBIT_MAX_PLANNED_IMAGE_PALETTE_ENTRIES; i++) {
    moonbit_planned_image_palette_entry* entry = &g_planned_image_palette[i];
    if (entry->used != 0 && entry->image_id == image_id) {
      if (touch_stamp != 0) {
        entry->stamp = moonbit_next_planned_image_palette_stamp();
      }
      return entry;
    }
  }
  return NULL;
}

void moonbit_clear_planned_image_palette_registry(void) {
  for (int i = 0; i < MOONBIT_MAX_PLANNED_IMAGE_PALETTE_ENTRIES; i++) {
    g_planned_image_palette[i].used = 0;
    g_planned_image_palette[i].image_id = 0;
    g_planned_image_palette[i].generation = 0;
    memset(g_planned_image_palette[i].pixels, 0, sizeof(g_planned_image_palette[i].pixels));
    g_planned_image_palette[i].stamp = 0;
  }
  g_planned_image_palette_stamp = 1;
  moonbit_clear_planned_texture_cache();
}

void moonbit_register_planned_image_palette(
    int32_t image_id,
    int32_t p00_r,
    int32_t p00_g,
    int32_t p00_b,
    int32_t p00_a,
    int32_t p10_r,
    int32_t p10_g,
    int32_t p10_b,
    int32_t p10_a,
    int32_t p01_r,
    int32_t p01_g,
    int32_t p01_b,
    int32_t p01_a,
    int32_t p11_r,
    int32_t p11_g,
    int32_t p11_b,
    int32_t p11_a
) {
  if (image_id < 0) {
    return;
  }

  moonbit_planned_image_palette_entry* entry = moonbit_lookup_planned_image_palette_entry(
    image_id,
    0
  );
  if (entry == NULL) {
    int empty_index = -1;
    int lru_index = 0;
    uint64_t lru_stamp = UINT64_MAX;
    for (int i = 0; i < MOONBIT_MAX_PLANNED_IMAGE_PALETTE_ENTRIES; i++) {
      moonbit_planned_image_palette_entry* cursor = &g_planned_image_palette[i];
      if (cursor->used == 0) {
        if (empty_index < 0) {
          empty_index = i;
        }
        continue;
      }
      if (cursor->stamp < lru_stamp) {
        lru_stamp = cursor->stamp;
        lru_index = i;
      }
    }
    const int chosen_index = empty_index >= 0 ? empty_index : lru_index;
    entry = &g_planned_image_palette[chosen_index];
    if (entry->used != 0 && entry->image_id != image_id) {
      entry->generation = 0;
    }
  }

  entry->used = 1;
  entry->image_id = image_id;
  entry->pixels[0] = moonbit_clamp_u8_channel(p00_r);
  entry->pixels[1] = moonbit_clamp_u8_channel(p00_g);
  entry->pixels[2] = moonbit_clamp_u8_channel(p00_b);
  entry->pixels[3] = moonbit_clamp_u8_channel(p00_a);
  entry->pixels[4] = moonbit_clamp_u8_channel(p10_r);
  entry->pixels[5] = moonbit_clamp_u8_channel(p10_g);
  entry->pixels[6] = moonbit_clamp_u8_channel(p10_b);
  entry->pixels[7] = moonbit_clamp_u8_channel(p10_a);
  entry->pixels[8] = moonbit_clamp_u8_channel(p01_r);
  entry->pixels[9] = moonbit_clamp_u8_channel(p01_g);
  entry->pixels[10] = moonbit_clamp_u8_channel(p01_b);
  entry->pixels[11] = moonbit_clamp_u8_channel(p01_a);
  entry->pixels[12] = moonbit_clamp_u8_channel(p11_r);
  entry->pixels[13] = moonbit_clamp_u8_channel(p11_g);
  entry->pixels[14] = moonbit_clamp_u8_channel(p11_b);
  entry->pixels[15] = moonbit_clamp_u8_channel(p11_a);
  entry->generation = moonbit_next_resource_generation(entry->generation);
  entry->stamp = moonbit_next_planned_image_palette_stamp();
}

int32_t moonbit_planned_image_palette_registry_count(void) {
  int32_t count = 0;
  for (int i = 0; i < MOONBIT_MAX_PLANNED_IMAGE_PALETTE_ENTRIES; i++) {
    if (g_planned_image_palette[i].used != 0) {
      count += 1;
    }
  }
  return count;
}

int32_t moonbit_planned_image_palette_channel(
    int32_t image_id,
    int32_t pixel_index,
    int32_t channel_index
) {
  if (pixel_index < 0 || pixel_index >= 4) {
    return -1;
  }
  if (channel_index < 0 || channel_index >= 4) {
    return -1;
  }
  moonbit_planned_image_palette_entry* entry = moonbit_lookup_planned_image_palette_entry(
    image_id,
    0
  );
  if (entry == NULL) {
    return -1;
  }
  const int offset = pixel_index * 4 + channel_index;
  return (int32_t)entry->pixels[offset];
}

int32_t moonbit_planned_image_palette_generation(int32_t image_id) {
  moonbit_planned_image_palette_entry* entry = moonbit_lookup_planned_image_palette_entry(
    image_id,
    0
  );
  if (entry == NULL) {
    return -1;
  }
  return (int32_t)entry->generation;
}

static uint64_t moonbit_next_planned_source_image_stamp(void) {
  uint64_t stamp = g_planned_source_image_stamp;
  g_planned_source_image_stamp += 1;
  if (g_planned_source_image_stamp == 0) {
    g_planned_source_image_stamp = 1;
  }
  return stamp;
}

static void moonbit_release_planned_source_image_entry(
    moonbit_planned_source_image_entry* entry
) {
  if (entry == NULL || entry->used == 0) {
    return;
  }
  if (entry->pixels != NULL) {
    free(entry->pixels);
  }
  entry->used = 0;
  entry->image_id = 0;
  entry->width = 0;
  entry->height = 0;
  entry->generation = 0;
  entry->upload_mode = 0;
  entry->touched_any = 0;
  entry->touched_min_x = 0;
  entry->touched_min_y = 0;
  entry->touched_max_x = 0;
  entry->touched_max_y = 0;
  entry->dirty_has_rect = 0;
  entry->dirty_x = 0;
  entry->dirty_y = 0;
  entry->dirty_width = 0;
  entry->dirty_height = 0;
  entry->pixels = NULL;
  entry->pixel_length = 0;
  entry->stamp = 0;
}

static moonbit_planned_source_image_entry* moonbit_lookup_planned_source_image_entry(
    int32_t image_id,
    int touch_stamp
) {
  if (image_id < 0) {
    return NULL;
  }
  for (int i = 0; i < MOONBIT_MAX_PLANNED_SOURCE_IMAGE_ENTRIES; i++) {
    moonbit_planned_source_image_entry* entry = &g_planned_source_images[i];
    if (entry->used != 0 && entry->image_id == image_id) {
      if (touch_stamp != 0) {
        entry->stamp = moonbit_next_planned_source_image_stamp();
      }
      return entry;
    }
  }
  return NULL;
}

static void moonbit_reset_source_image_upload_state(
    moonbit_planned_source_image_entry* entry,
    int32_t upload_mode
) {
  if (entry == NULL) {
    return;
  }
  entry->upload_mode = upload_mode;
  entry->touched_any = 0;
  entry->touched_min_x = 0;
  entry->touched_min_y = 0;
  entry->touched_max_x = 0;
  entry->touched_max_y = 0;
}

static void moonbit_mark_source_image_touched(
    moonbit_planned_source_image_entry* entry,
    uint32_t x,
    uint32_t y
) {
  if (entry == NULL) {
    return;
  }
  if (entry->touched_any == 0) {
    entry->touched_any = 1;
    entry->touched_min_x = x;
    entry->touched_max_x = x;
    entry->touched_min_y = y;
    entry->touched_max_y = y;
    return;
  }
  if (x < entry->touched_min_x) {
    entry->touched_min_x = x;
  }
  if (x > entry->touched_max_x) {
    entry->touched_max_x = x;
  }
  if (y < entry->touched_min_y) {
    entry->touched_min_y = y;
  }
  if (y > entry->touched_max_y) {
    entry->touched_max_y = y;
  }
}

void moonbit_clear_planned_source_image_registry(void) {
  for (int i = 0; i < MOONBIT_MAX_PLANNED_SOURCE_IMAGE_ENTRIES; i++) {
    moonbit_release_planned_source_image_entry(&g_planned_source_images[i]);
  }
  g_planned_source_image_stamp = 1;
  moonbit_clear_planned_texture_cache();
}

void moonbit_begin_planned_source_image_upload(
    int32_t image_id,
    int32_t width,
    int32_t height
) {
  if (image_id < 0) {
    return;
  }
  const uint32_t safe_width = width <= 0 ? 1U : (uint32_t)width;
  const uint32_t safe_height = height <= 0 ? 1U : (uint32_t)height;
  const size_t pixel_length = (size_t)safe_width * (size_t)safe_height * 4U;
  if (pixel_length == 0) {
    return;
  }

  moonbit_planned_source_image_entry* entry = moonbit_lookup_planned_source_image_entry(
    image_id,
    0
  );
  if (entry == NULL) {
    int empty_index = -1;
    int lru_index = 0;
    uint64_t lru_stamp = UINT64_MAX;
    for (int i = 0; i < MOONBIT_MAX_PLANNED_SOURCE_IMAGE_ENTRIES; i++) {
      moonbit_planned_source_image_entry* cursor = &g_planned_source_images[i];
      if (cursor->used == 0) {
        if (empty_index < 0) {
          empty_index = i;
        }
        continue;
      }
      if (cursor->stamp < lru_stamp) {
        lru_stamp = cursor->stamp;
        lru_index = i;
      }
    }
    const int chosen_index = empty_index >= 0 ? empty_index : lru_index;
    entry = &g_planned_source_images[chosen_index];
    if (entry->used != 0) {
      moonbit_release_planned_source_image_entry(entry);
    }
  } else if (entry->pixels != NULL) {
    free(entry->pixels);
    entry->pixels = NULL;
  }

  uint8_t* pixels = (uint8_t*)malloc(pixel_length);
  if (pixels == NULL) {
    moonbit_release_planned_source_image_entry(entry);
    return;
  }
  memset(pixels, 0, pixel_length);
  entry->used = 1;
  entry->image_id = image_id;
  entry->width = safe_width;
  entry->height = safe_height;
  entry->pixels = pixels;
  entry->pixel_length = pixel_length;
  entry->dirty_has_rect = 0;
  entry->dirty_x = 0;
  entry->dirty_y = 0;
  entry->dirty_width = 0;
  entry->dirty_height = 0;
  moonbit_reset_source_image_upload_state(entry, 1);
  entry->stamp = moonbit_next_planned_source_image_stamp();
}

int32_t moonbit_begin_planned_source_image_patch(int32_t image_id) {
  moonbit_planned_source_image_entry* entry = moonbit_lookup_planned_source_image_entry(
    image_id,
    0
  );
  if (entry == NULL || entry->pixels == NULL || entry->width == 0 || entry->height == 0) {
    return 0;
  }
  moonbit_reset_source_image_upload_state(entry, 2);
  return 1;
}

void moonbit_set_planned_source_image_pixel(
    int32_t image_id,
    int32_t x,
    int32_t y,
    int32_t r,
    int32_t g,
    int32_t b,
    int32_t a
) {
  moonbit_planned_source_image_entry* entry = moonbit_lookup_planned_source_image_entry(
    image_id,
    0
  );
  if (entry == NULL || entry->pixels == NULL) {
    return;
  }
  if (x < 0 || y < 0) {
    return;
  }
  const uint32_t ux = (uint32_t)x;
  const uint32_t uy = (uint32_t)y;
  if (ux >= entry->width || uy >= entry->height) {
    return;
  }
  const size_t offset = ((size_t)uy * (size_t)entry->width + (size_t)ux) * 4U;
  if (offset + 3 >= entry->pixel_length) {
    return;
  }
  entry->pixels[offset + 0] = moonbit_clamp_u8_channel(r);
  entry->pixels[offset + 1] = moonbit_clamp_u8_channel(g);
  entry->pixels[offset + 2] = moonbit_clamp_u8_channel(b);
  entry->pixels[offset + 3] = moonbit_clamp_u8_channel(a);
  moonbit_mark_source_image_touched(entry, ux, uy);
  entry->stamp = moonbit_next_planned_source_image_stamp();
}

void moonbit_end_planned_source_image_upload(int32_t image_id) {
  moonbit_planned_source_image_entry* entry = moonbit_lookup_planned_source_image_entry(
    image_id,
    0
  );
  if (entry == NULL) {
    return;
  }
  if (entry->upload_mode == 1) {
    entry->dirty_has_rect = 1;
    entry->dirty_x = 0;
    entry->dirty_y = 0;
    entry->dirty_width = entry->width;
    entry->dirty_height = entry->height;
  } else if (entry->upload_mode == 2 && entry->touched_any != 0) {
    entry->dirty_has_rect = 1;
    entry->dirty_x = entry->touched_min_x;
    entry->dirty_y = entry->touched_min_y;
    entry->dirty_width = entry->touched_max_x - entry->touched_min_x + 1U;
    entry->dirty_height = entry->touched_max_y - entry->touched_min_y + 1U;
  }
  entry->generation = moonbit_next_resource_generation(entry->generation);
  moonbit_reset_source_image_upload_state(entry, 0);
  entry->stamp = moonbit_next_planned_source_image_stamp();
}

int32_t moonbit_end_planned_source_image_patch(int32_t image_id) {
  moonbit_planned_source_image_entry* entry = moonbit_lookup_planned_source_image_entry(
    image_id,
    0
  );
  if (entry == NULL || entry->upload_mode != 2) {
    return 0;
  }
  if (entry->touched_any == 0) {
    moonbit_reset_source_image_upload_state(entry, 0);
    return 0;
  }
  entry->dirty_has_rect = 1;
  entry->dirty_x = entry->touched_min_x;
  entry->dirty_y = entry->touched_min_y;
  entry->dirty_width = entry->touched_max_x - entry->touched_min_x + 1U;
  entry->dirty_height = entry->touched_max_y - entry->touched_min_y + 1U;
  entry->generation = moonbit_next_resource_generation(entry->generation);
  moonbit_reset_source_image_upload_state(entry, 0);
  entry->stamp = moonbit_next_planned_source_image_stamp();
  return 1;
}

int32_t moonbit_planned_source_image_registry_count(void) {
  int32_t count = 0;
  for (int i = 0; i < MOONBIT_MAX_PLANNED_SOURCE_IMAGE_ENTRIES; i++) {
    if (g_planned_source_images[i].used != 0) {
      count += 1;
    }
  }
  return count;
}

int32_t moonbit_planned_source_image_width(int32_t image_id) {
  moonbit_planned_source_image_entry* entry = moonbit_lookup_planned_source_image_entry(
    image_id,
    0
  );
  if (entry == NULL) {
    return -1;
  }
  return (int32_t)entry->width;
}

int32_t moonbit_planned_source_image_height(int32_t image_id) {
  moonbit_planned_source_image_entry* entry = moonbit_lookup_planned_source_image_entry(
    image_id,
    0
  );
  if (entry == NULL) {
    return -1;
  }
  return (int32_t)entry->height;
}

int32_t moonbit_planned_source_image_generation(int32_t image_id) {
  moonbit_planned_source_image_entry* entry = moonbit_lookup_planned_source_image_entry(
    image_id,
    0
  );
  if (entry == NULL) {
    return -1;
  }
  return (int32_t)entry->generation;
}

int32_t moonbit_planned_source_image_pixel_channel(
    int32_t image_id,
    int32_t x,
    int32_t y,
    int32_t channel_index
) {
  if (channel_index < 0 || channel_index > 3) {
    return -1;
  }
  moonbit_planned_source_image_entry* entry = moonbit_lookup_planned_source_image_entry(
    image_id,
    0
  );
  if (entry == NULL || entry->pixels == NULL || x < 0 || y < 0) {
    return -1;
  }
  const uint32_t ux = (uint32_t)x;
  const uint32_t uy = (uint32_t)y;
  if (ux >= entry->width || uy >= entry->height) {
    return -1;
  }
  const size_t offset =
    ((size_t)uy * (size_t)entry->width + (size_t)ux) * 4U + (size_t)channel_index;
  if (offset >= entry->pixel_length) {
    return -1;
  }
  return (int32_t)entry->pixels[offset];
}

static uint32_t moonbit_fill_seed_texture_pixels(int32_t texture_seed, uint8_t out_pixels[16]) {
  if (out_pixels == NULL) {
    return 0U;
  }
  moonbit_planned_image_palette_entry* entry = moonbit_lookup_planned_image_palette_entry(
    texture_seed,
    1
  );
  if (entry != NULL) {
    memcpy(out_pixels, entry->pixels, sizeof(entry->pixels));
    return entry->generation;
  }
  const uint8_t seed0 = (uint8_t)((texture_seed * 53 + 17) & 0xFF);
  const uint8_t seed1 = (uint8_t)((texture_seed * 97 + 73) & 0xFF);
  const uint8_t seed2 = (uint8_t)((texture_seed * 193 + 151) & 0xFF);
  const uint8_t inv0 = (uint8_t)(255 - seed0);
  const uint8_t inv1 = (uint8_t)(255 - seed1);
  const uint8_t inv2 = (uint8_t)(255 - seed2);
  out_pixels[0] = seed0;
  out_pixels[1] = seed1;
  out_pixels[2] = seed2;
  out_pixels[3] = 255;
  out_pixels[4] = inv0;
  out_pixels[5] = inv1;
  out_pixels[6] = inv2;
  out_pixels[7] = 255;
  out_pixels[8] = inv0;
  out_pixels[9] = seed1;
  out_pixels[10] = seed2;
  out_pixels[11] = 255;
  out_pixels[12] = seed0;
  out_pixels[13] = inv1;
  out_pixels[14] = inv2;
  out_pixels[15] = 255;
  return 0U;
}

static int moonbit_create_seed_texture_resources(
    WGPUDevice device,
    WGPUQueue queue,
    int32_t texture_seed,
    WGPUTexture* out_texture,
    WGPUTextureView* out_texture_view,
    WGPUSampler* out_sampler,
    uint32_t* out_texture_generation,
    uint32_t* out_texture_width,
    uint32_t* out_texture_height
) {
  if (device == NULL || queue == NULL ||
      out_texture == NULL || out_texture_view == NULL || out_sampler == NULL ||
      out_texture_generation == NULL || out_texture_width == NULL ||
      out_texture_height == NULL) {
    return 0;
  }
  *out_texture = NULL;
  *out_texture_view = NULL;
  *out_sampler = NULL;
  *out_texture_generation = 0U;
  *out_texture_width = 0U;
  *out_texture_height = 0U;

  uint8_t fallback_pixels[16];
  const uint8_t* pixel_data = fallback_pixels;
  size_t pixel_data_size = sizeof(fallback_pixels);
  uint32_t texture_width = 2;
  uint32_t texture_height = 2;
  uint32_t resolved_generation = 0U;
  moonbit_planned_source_image_entry* source_image =
    moonbit_lookup_planned_source_image_entry(texture_seed, 1);
  if (source_image != NULL &&
      source_image->pixels != NULL &&
      source_image->width > 0 &&
      source_image->height > 0 &&
      source_image->pixel_length >= (size_t)source_image->width * (size_t)source_image->height * 4U) {
    pixel_data = source_image->pixels;
    pixel_data_size = source_image->pixel_length;
    texture_width = source_image->width;
    texture_height = source_image->height;
    resolved_generation = source_image->generation;
  } else {
    resolved_generation = moonbit_fill_seed_texture_pixels(texture_seed, fallback_pixels);
  }

  WGPUTextureDescriptor texture_desc = {
    .nextInChain = NULL,
    .label = "Payload Texture",
    .usage = WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopyDst,
    .dimension = WGPUTextureDimension_2D,
    .size = {
      .width = texture_width,
      .height = texture_height,
      .depthOrArrayLayers = 1
    },
    .format = WGPUTextureFormat_RGBA8Unorm,
    .mipLevelCount = 1,
    .sampleCount = 1,
    .viewFormatCount = 0,
    .viewFormats = NULL
  };
  WGPUTexture texture = wgpuDeviceCreateTexture(device, &texture_desc);
  if (texture == NULL) {
    return 0;
  }

  WGPUTexelCopyTextureInfo dst = {
    .texture = texture,
    .mipLevel = 0,
    .origin = { .x = 0, .y = 0, .z = 0 },
    .aspect = WGPUTextureAspect_All
  };
  WGPUTexelCopyBufferLayout layout = {
    .offset = 0,
    .bytesPerRow = texture_width * 4,
    .rowsPerImage = texture_height
  };
  WGPUExtent3D write_size = {
    .width = texture_width,
    .height = texture_height,
    .depthOrArrayLayers = 1
  };
  wgpuQueueWriteTexture(
    queue,
    &dst,
    pixel_data,
    pixel_data_size,
    &layout,
    &write_size
  );

  WGPUTextureViewDescriptor texture_view_desc = {
    .nextInChain = NULL,
    .label = "Payload Texture View",
    .format = WGPUTextureFormat_RGBA8Unorm,
    .dimension = WGPUTextureViewDimension_2D,
    .baseMipLevel = 0,
    .mipLevelCount = 1,
    .baseArrayLayer = 0,
    .arrayLayerCount = 1,
    .aspect = WGPUTextureAspect_All
  };
  WGPUTextureView texture_view = wgpuTextureCreateView(texture, &texture_view_desc);
  if (texture_view == NULL) {
    wgpuTextureRelease(texture);
    return 0;
  }

  WGPUSamplerDescriptor sampler_desc = {
    .nextInChain = NULL,
    .label = "Payload Sampler",
    .addressModeU = WGPUAddressMode_Repeat,
    .addressModeV = WGPUAddressMode_Repeat,
    .addressModeW = WGPUAddressMode_Repeat,
    .magFilter = WGPUFilterMode_Linear,
    .minFilter = WGPUFilterMode_Linear,
    .mipmapFilter = WGPUMipmapFilterMode_Linear,
    .lodMinClamp = 0.0f,
    .lodMaxClamp = 32.0f,
    .compare = WGPUCompareFunction_Undefined,
    .maxAnisotropy = 1
  };
  WGPUSampler sampler = wgpuDeviceCreateSampler(device, &sampler_desc);
  if (sampler == NULL) {
    wgpuTextureViewRelease(texture_view);
    wgpuTextureRelease(texture);
    return 0;
  }

  *out_texture = texture;
  *out_texture_view = texture_view;
  *out_sampler = sampler;
  *out_texture_generation = resolved_generation;
  *out_texture_width = texture_width;
  *out_texture_height = texture_height;
  return 1;
}

static uint32_t moonbit_resolve_texture_generation(int32_t texture_seed) {
  moonbit_planned_source_image_entry* source_image =
    moonbit_lookup_planned_source_image_entry(texture_seed, 1);
  if (source_image != NULL &&
      source_image->pixels != NULL &&
      source_image->width > 0 &&
      source_image->height > 0 &&
      source_image->pixel_length >= (size_t)source_image->width * (size_t)source_image->height * 4U) {
    return source_image->generation;
  }
  moonbit_planned_image_palette_entry* palette_entry =
    moonbit_lookup_planned_image_palette_entry(texture_seed, 1);
  if (palette_entry != NULL) {
    return palette_entry->generation;
  }
  return 0U;
}

static size_t moonbit_required_write_data_size(
    uint32_t bytes_per_row,
    uint32_t write_width,
    uint32_t write_height
) {
  if (write_width == 0 || write_height == 0) {
    return 0;
  }
  if (write_height == 1) {
    return (size_t)write_width * 4U;
  }
  return ((size_t)write_height - 1U) * (size_t)bytes_per_row + (size_t)write_width * 4U;
}

static int moonbit_write_texture_region(
    WGPUQueue queue,
    WGPUTexture texture,
    const uint8_t* pixel_data,
    size_t pixel_data_size,
    uint32_t texture_width,
    uint32_t texture_height,
    uint32_t write_x,
    uint32_t write_y,
    uint32_t write_width,
    uint32_t write_height
) {
  if (queue == NULL || texture == NULL || pixel_data == NULL) {
    return 0;
  }
  if (texture_width == 0 || texture_height == 0 || write_width == 0 || write_height == 0) {
    return 0;
  }
  if (write_x + write_width > texture_width || write_y + write_height > texture_height) {
    return 0;
  }
  const uint32_t bytes_per_row = texture_width * 4U;
  const size_t required_size = moonbit_required_write_data_size(
    bytes_per_row,
    write_width,
    write_height
  );
  if (required_size == 0 || pixel_data_size < required_size) {
    return 0;
  }

  WGPUTexelCopyTextureInfo dst = {
    .texture = texture,
    .mipLevel = 0,
    .origin = { .x = write_x, .y = write_y, .z = 0 },
    .aspect = WGPUTextureAspect_All
  };
  WGPUTexelCopyBufferLayout layout = {
    .offset = 0,
    .bytesPerRow = bytes_per_row,
    .rowsPerImage = texture_height
  };
  WGPUExtent3D write_size = {
    .width = write_width,
    .height = write_height,
    .depthOrArrayLayers = 1
  };
  wgpuQueueWriteTexture(
    queue,
    &dst,
    pixel_data,
    required_size,
    &layout,
    &write_size
  );
  return 1;
}

static int moonbit_try_update_cached_seed_texture_resources(
    moonbit_planned_texture_cache_entry* cache_entry,
    WGPUQueue queue,
    int32_t texture_seed,
    uint32_t target_generation
) {
  if (cache_entry == NULL || cache_entry->used == 0 ||
      queue == NULL || cache_entry->texture == NULL ||
      cache_entry->texture_width == 0 || cache_entry->texture_height == 0) {
    return 0;
  }

  moonbit_planned_source_image_entry* source_image =
    moonbit_lookup_planned_source_image_entry(texture_seed, 1);
  if (source_image != NULL &&
      source_image->generation == target_generation &&
      source_image->pixels != NULL &&
      source_image->width > 0 &&
      source_image->height > 0 &&
      source_image->pixel_length >= (size_t)source_image->width * (size_t)source_image->height * 4U &&
      cache_entry->texture_width == source_image->width &&
      cache_entry->texture_height == source_image->height) {
    uint32_t write_x = 0U;
    uint32_t write_y = 0U;
    uint32_t write_width = source_image->width;
    uint32_t write_height = source_image->height;
    const uint8_t* pixel_data = source_image->pixels;
    size_t pixel_data_size = source_image->pixel_length;
    if (source_image->dirty_has_rect != 0 &&
        source_image->dirty_width > 0 &&
        source_image->dirty_height > 0 &&
        source_image->dirty_x + source_image->dirty_width <= source_image->width &&
        source_image->dirty_y + source_image->dirty_height <= source_image->height) {
      write_x = source_image->dirty_x;
      write_y = source_image->dirty_y;
      write_width = source_image->dirty_width;
      write_height = source_image->dirty_height;
      const size_t offset =
        ((size_t)write_y * (size_t)source_image->width + (size_t)write_x) * 4U;
      if (offset >= source_image->pixel_length) {
        return 0;
      }
      pixel_data = source_image->pixels + offset;
      pixel_data_size = source_image->pixel_length - offset;
    }
    if (!moonbit_write_texture_region(
          queue,
          cache_entry->texture,
          pixel_data,
          pixel_data_size,
          source_image->width,
          source_image->height,
          write_x,
          write_y,
          write_width,
          write_height
        )) {
      return 0;
    }
    cache_entry->texture_generation = target_generation;
    cache_entry->stamp = moonbit_next_planned_texture_cache_stamp();
    return 1;
  }

  moonbit_planned_image_palette_entry* palette_entry =
    moonbit_lookup_planned_image_palette_entry(texture_seed, 1);
  if (palette_entry != NULL &&
      palette_entry->generation == target_generation &&
      cache_entry->texture_width == 2U &&
      cache_entry->texture_height == 2U) {
    if (!moonbit_write_texture_region(
          queue,
          cache_entry->texture,
          palette_entry->pixels,
          sizeof(palette_entry->pixels),
          2U,
          2U,
          0U,
          0U,
          2U,
          2U
        )) {
      return 0;
    }
    cache_entry->texture_generation = target_generation;
    cache_entry->stamp = moonbit_next_planned_texture_cache_stamp();
    return 1;
  }

  return 0;
}

static int moonbit_get_or_create_seed_texture_resources(
    WGPUDevice device,
    WGPUQueue queue,
    int32_t texture_seed,
    WGPUTextureView* out_texture_view,
    WGPUSampler* out_sampler,
    uint32_t* out_texture_generation
) {
  if (device == NULL || queue == NULL || out_texture_view == NULL ||
      out_sampler == NULL || out_texture_generation == NULL) {
    return 0;
  }
  *out_texture_view = NULL;
  *out_sampler = NULL;
  *out_texture_generation = 0U;

  const uintptr_t device_key = (uintptr_t)device;
  const int32_t safe_seed = texture_seed < 0 ? 0 : texture_seed;
  const uint32_t safe_generation = moonbit_resolve_texture_generation(safe_seed);
  int empty_index = -1;
  int lru_index = 0;
  uint64_t lru_stamp = UINT64_MAX;
  for (int i = 0; i < MOONBIT_MAX_PLANNED_TEXTURE_CACHE_ENTRIES; i++) {
    moonbit_planned_texture_cache_entry* entry = &g_planned_texture_cache[i];
    if (entry->used == 0) {
      if (empty_index < 0) {
        empty_index = i;
      }
      continue;
    }
    if (entry->stamp < lru_stamp) {
      lru_stamp = entry->stamp;
      lru_index = i;
    }
    if (entry->device_key == device_key &&
        entry->texture_seed == safe_seed &&
        entry->texture_generation == safe_generation) {
      entry->stamp = moonbit_next_planned_texture_cache_stamp();
      *out_texture_view = entry->texture_view;
      *out_sampler = entry->sampler;
      *out_texture_generation = entry->texture_generation;
      return 1;
    }
    if (entry->device_key == device_key &&
        entry->texture_seed == safe_seed &&
        entry->texture_generation != safe_generation) {
      if (moonbit_try_update_cached_seed_texture_resources(
            entry,
            queue,
            safe_seed,
            safe_generation
          )) {
        *out_texture_view = entry->texture_view;
        *out_sampler = entry->sampler;
        *out_texture_generation = entry->texture_generation;
        return 1;
      }
    }
  }

  WGPUTexture texture = NULL;
  WGPUTextureView texture_view = NULL;
  WGPUSampler sampler = NULL;
  uint32_t texture_generation = 0U;
  uint32_t texture_width = 0U;
  uint32_t texture_height = 0U;
  if (!moonbit_create_seed_texture_resources(
        device,
        queue,
        safe_seed,
        &texture,
        &texture_view,
        &sampler,
        &texture_generation,
        &texture_width,
        &texture_height
      )) {
    return 0;
  }

  const int cache_index = empty_index >= 0 ? empty_index : lru_index;
  moonbit_planned_texture_cache_entry* target = &g_planned_texture_cache[cache_index];
  if (target->used != 0) {
    moonbit_clear_planned_bind_group_cache();
    moonbit_release_planned_texture_cache_entry(target);
  }
  target->used = 1;
  target->device_key = device_key;
  target->texture_seed = safe_seed;
  target->texture_generation = texture_generation;
  target->texture_width = texture_width;
  target->texture_height = texture_height;
  target->texture = texture;
  target->texture_view = texture_view;
  target->sampler = sampler;
  target->stamp = moonbit_next_planned_texture_cache_stamp();
  *out_texture_view = target->texture_view;
  *out_sampler = target->sampler;
  *out_texture_generation = target->texture_generation;
  return 1;
}

static WGPUBindGroup moonbit_get_or_create_planned_payload_bind_group(
    WGPUDevice device,
    WGPURenderPipeline pipeline,
    int32_t texture_seed,
    uint32_t texture_generation,
    WGPUTextureView texture_view,
    WGPUSampler sampler
) {
  if (device == NULL || pipeline == NULL || texture_view == NULL || sampler == NULL) {
    return NULL;
  }

  const uintptr_t device_key = (uintptr_t)device;
  const uintptr_t pipeline_key = (uintptr_t)pipeline;
  const int32_t safe_seed = texture_seed < 0 ? 0 : texture_seed;
  const uint32_t safe_generation = texture_generation;
  int empty_index = -1;
  int lru_index = 0;
  uint64_t lru_stamp = UINT64_MAX;
  for (int i = 0; i < MOONBIT_MAX_PLANNED_BIND_GROUP_CACHE_ENTRIES; i++) {
    moonbit_planned_bind_group_cache_entry* entry = &g_planned_bind_group_cache[i];
    if (entry->used == 0) {
      if (empty_index < 0) {
        empty_index = i;
      }
      continue;
    }
    if (entry->stamp < lru_stamp) {
      lru_stamp = entry->stamp;
      lru_index = i;
    }
    if (entry->device_key == device_key &&
        entry->pipeline_key == pipeline_key &&
        entry->texture_seed == safe_seed &&
        entry->texture_generation == safe_generation) {
      entry->stamp = moonbit_next_planned_bind_group_cache_stamp();
      return entry->bind_group;
    }
  }

  WGPUBindGroupLayout bind_group_layout = wgpuRenderPipelineGetBindGroupLayout(
    pipeline,
    0
  );
  if (bind_group_layout == NULL) {
    return NULL;
  }

  WGPUBindGroupEntry entries[2] = {
    {
      .nextInChain = NULL,
      .binding = 0,
      .buffer = NULL,
      .offset = 0,
      .size = 0,
      .sampler = sampler,
      .textureView = NULL
    },
    {
      .nextInChain = NULL,
      .binding = 1,
      .buffer = NULL,
      .offset = 0,
      .size = 0,
      .sampler = NULL,
      .textureView = texture_view
    }
  };
  WGPUBindGroupDescriptor bind_group_desc = {
    .nextInChain = NULL,
    .label = "Payload Bind Group",
    .layout = bind_group_layout,
    .entryCount = 2,
    .entries = entries
  };
  WGPUBindGroup bind_group = wgpuDeviceCreateBindGroup(device, &bind_group_desc);
  wgpuBindGroupLayoutRelease(bind_group_layout);
  if (bind_group == NULL) {
    return NULL;
  }

  const int cache_index = empty_index >= 0 ? empty_index : lru_index;
  moonbit_planned_bind_group_cache_entry* target = &g_planned_bind_group_cache[cache_index];
  if (target->used != 0) {
    moonbit_release_planned_bind_group_cache_entry(target);
  }
  target->used = 1;
  target->device_key = device_key;
  target->pipeline_key = pipeline_key;
  target->texture_seed = safe_seed;
  target->texture_generation = safe_generation;
  target->bind_group = bind_group;
  target->stamp = moonbit_next_planned_bind_group_cache_stamp();
  return target->bind_group;
}

static int moonbit_build_payload_shader_key(
    char* key_buffer,
    size_t key_buffer_size,
    WGPUTextureFormat format,
    const moonbit_planned_draw_command* command
) {
  if (key_buffer == NULL || key_buffer_size == 0 || command == NULL) {
    return 0;
  }
  const int n = snprintf(
    key_buffer,
    key_buffer_size,
    "%d|%.6f|%.6f|%.6f|%.6f|%d",
    (int)format,
    command->uniform_r,
    command->uniform_g,
    command->uniform_b,
    command->uniform_a,
    command->texture_seed
  );
  return n > 0 && (size_t)n < key_buffer_size;
}

static int moonbit_build_payload_wgsl(
    char* wgsl_buffer,
    size_t wgsl_buffer_size,
    const moonbit_planned_draw_command* command
) {
  if (wgsl_buffer == NULL || wgsl_buffer_size == 0 || command == NULL) {
    return 0;
  }
  const double texture_frequency = (double)((command->texture_seed % 11) + 1);
  const int n = snprintf(
    wgsl_buffer,
    wgsl_buffer_size,
    "struct VsIn {\n"
    "  @location(0) position: vec2f,\n"
    "  @location(1) uv: vec2f,\n"
    "};\n\n"
    "struct VsOut {\n"
    "  @builtin(position) position: vec4f,\n"
    "  @location(0) uv: vec2f,\n"
    "};\n\n"
    "@group(0) @binding(0) var tex_sampler: sampler;\n"
    "@group(0) @binding(1) var tex: texture_2d<f32>;\n\n"
    "@vertex\n"
    "fn vs_main(in: VsIn) -> VsOut {\n"
    "  var out : VsOut;\n"
    "  out.position = vec4f(in.position, 0.0, 1.0);\n"
    "  out.uv = in.uv;\n"
    "  return out;\n"
    "}\n\n"
    "@fragment\n"
    "fn fs_main(@location(0) in_uv: vec2f) -> @location(0) vec4f {\n"
    "  let fu = floor(in_uv.x * %f);\n"
    "  let fv = floor(in_uv.y * %f);\n"
    "  let checker = step(0.5, fract((fu + fv) * 0.5));\n"
    "  let sampled = textureSample(tex, tex_sampler, in_uv);\n"
    "  let tex_rgb = sampled.rgb * (0.35 + checker * 0.65);\n"
    "  let tint = vec3f(%f, %f, %f);\n"
    "  return vec4f(tex_rgb * tint, sampled.a * %f);\n"
    "}\n",
    texture_frequency,
    texture_frequency,
    command->uniform_r,
    command->uniform_g,
    command->uniform_b,
    command->uniform_a
  );
  return n > 0 && (size_t)n < wgsl_buffer_size;
}

static WGPURenderPipeline moonbit_create_payload_render_pipeline(
    WGPUDevice device,
    WGPUShaderModule shaderModule,
    uint32_t format
) {
  WGPUVertexAttribute attributes[2] = {
    {
      .format = WGPUVertexFormat_Float32x2,
      .offset = 0,
      .shaderLocation = 0
    },
    {
      .format = WGPUVertexFormat_Float32x2,
      .offset = sizeof(float) * 2,
      .shaderLocation = 1
    }
  };
  WGPUVertexBufferLayout buffers[1] = {
    {
      .arrayStride = sizeof(moonbit_payload_vertex),
      .stepMode = WGPUVertexStepMode_Vertex,
      .attributeCount = 2,
      .attributes = attributes
    }
  };

  WGPUVertexState vertexState = {
    .module = shaderModule,
    .entryPoint = {.data = "vs_main", .length = 7},
    .constantCount = 0,
    .constants = NULL,
    .bufferCount = 1,
    .buffers = buffers
  };

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

  WGPURenderPipelineDescriptor descriptor = {
    .nextInChain = NULL,
    .label = "Payload Triangle Pipeline",
    .layout = NULL,
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

  return wgpuDeviceCreateRenderPipeline(device, &descriptor);
}

static WGPURenderPipeline moonbit_get_or_create_planned_payload_pipeline(
    WGPUDevice device,
    WGPUTextureFormat format,
    const moonbit_planned_draw_command* command
) {
  if (device == NULL || command == NULL) {
    return NULL;
  }

  char shader_key[512];
  if (!moonbit_build_payload_shader_key(shader_key, sizeof(shader_key), format, command)) {
    return NULL;
  }

  const uintptr_t device_key = (uintptr_t)device;
  int empty_index = -1;
  int lru_index = 0;
  uint64_t lru_stamp = UINT64_MAX;
  for (int i = 0; i < MOONBIT_MAX_PLANNED_PIPELINE_CACHE_ENTRIES; i++) {
    moonbit_planned_pipeline_cache_entry* entry = &g_planned_pipeline_cache[i];
    if (entry->used == 0) {
      if (empty_index < 0) {
        empty_index = i;
      }
      continue;
    }
    if (entry->stamp < lru_stamp) {
      lru_stamp = entry->stamp;
      lru_index = i;
    }
    if (entry->device_key == device_key &&
        entry->format == format &&
        strcmp(entry->shader_key, shader_key) == 0) {
      entry->stamp = moonbit_next_planned_pipeline_cache_stamp();
      return entry->pipeline;
    }
  }

  char wgsl[2048];
  if (!moonbit_build_payload_wgsl(wgsl, sizeof(wgsl), command)) {
    return NULL;
  }

  WGPUShaderModule shader = moonbit_create_shader_module_from_utf8(device, wgsl);
  if (shader == NULL) {
    return NULL;
  }
  WGPURenderPipeline pipeline = moonbit_create_payload_render_pipeline(
    device,
    shader,
    format
  );
  if (pipeline == NULL) {
    wgpuShaderModuleRelease(shader);
    return NULL;
  }

  const int cache_index = empty_index >= 0 ? empty_index : lru_index;
  moonbit_planned_pipeline_cache_entry* target = &g_planned_pipeline_cache[cache_index];
  if (target->used != 0) {
    moonbit_clear_planned_bind_group_cache();
    moonbit_release_planned_pipeline_cache_entry(target);
  }
  target->used = 1;
  target->device_key = device_key;
  target->format = format;
  strncpy(target->shader_key, shader_key, sizeof(target->shader_key) - 1);
  target->shader_key[sizeof(target->shader_key) - 1] = '\0';
  target->shader = shader;
  target->pipeline = pipeline;
  target->stamp = moonbit_next_planned_pipeline_cache_stamp();
  return target->pipeline;
}

// ===============================
// Offscreen Target Management
// ===============================

void moonbit_register_offscreen_target(int32_t image_id, int32_t width, int32_t height) {
  if (image_id <= 0 || width <= 0 || height <= 0) return;

  // Check if already registered with same dimensions
  moonbit_offscreen_target* existing = moonbit_find_offscreen_target(image_id);
  if (existing != NULL) {
    if ((int32_t)existing->width == width && (int32_t)existing->height == height) {
      return; // Already registered with same size
    }
    // Destroy old resources
    if (existing->view != NULL) {
      wgpuTextureViewRelease(existing->view);
      existing->view = NULL;
    }
    if (existing->texture != NULL) {
      wgpuTextureRelease(existing->texture);
      existing->texture = NULL;
    }
    existing->used = 0;
  }

  // Find free slot
  moonbit_offscreen_target* target = NULL;
  for (int i = 0; i < MOONBIT_MAX_OFFSCREEN_TARGETS; i++) {
    if (!g_offscreen_targets[i].used) {
      target = &g_offscreen_targets[i];
      break;
    }
  }
  if (target == NULL) return; // No free slots

  target->used = 1;
  target->image_id = image_id;
  target->width = (uint32_t)width;
  target->height = (uint32_t)height;
  target->texture = NULL;
  target->view = NULL;
  // Note: actual GPU texture creation is deferred to rendering time when device is available
}

void moonbit_clear_offscreen_targets(void) {
  for (int i = 0; i < MOONBIT_MAX_OFFSCREEN_TARGETS; i++) {
    if (g_offscreen_targets[i].used) {
      if (g_offscreen_targets[i].view != NULL) {
        wgpuTextureViewRelease(g_offscreen_targets[i].view);
      }
      if (g_offscreen_targets[i].texture != NULL) {
        wgpuTextureRelease(g_offscreen_targets[i].texture);
      }
    }
    memset(&g_offscreen_targets[i], 0, sizeof(moonbit_offscreen_target));
  }
}

static void moonbit_ensure_offscreen_gpu_texture(
    WGPUDevice device,
    moonbit_offscreen_target* target
) {
  if (target == NULL || device == NULL || !target->used) return;
  if (target->texture != NULL) return; // Already created

  WGPUTextureDescriptor texDesc = {
    .nextInChain = NULL,
    .label = "Offscreen Target",
    .usage = WGPUTextureUsage_RenderAttachment | WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopySrc,
    .dimension = WGPUTextureDimension_2D,
    .size = { .width = target->width, .height = target->height, .depthOrArrayLayers = 1 },
    .format = g_configured_surface_format,
    .mipLevelCount = 1,
    .sampleCount = 1,
    .viewFormatCount = 0,
    .viewFormats = NULL,
  };
  target->texture = wgpuDeviceCreateTexture(device, &texDesc);
  if (target->texture != NULL) {
    WGPUTextureViewDescriptor viewDesc = {
      .nextInChain = NULL,
      .label = "Offscreen Target View",
      .format = WGPUTextureFormat_Undefined,
      .dimension = WGPUTextureViewDimension_2D,
      .baseMipLevel = 0,
      .mipLevelCount = 1,
      .baseArrayLayer = 0,
      .arrayLayerCount = 1,
      .aspect = WGPUTextureAspect_All,
    };
    target->view = wgpuTextureCreateView(target->texture, &viewDesc);
  }
}

// ===============================
// Rendering
// ===============================

void moonbit_reset_planned_draw_queue(void) {
  g_planned_draw_command_count = 0;
}

void moonbit_push_planned_draw_command(
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
    int32_t texture_seed,
    int32_t dst_image_id
) {
  if (g_planned_draw_command_count >= MOONBIT_MAX_PLANNED_DRAW_COMMANDS) {
    return;
  }
  moonbit_planned_draw_command* command = &g_planned_draw_commands[g_planned_draw_command_count++];
  command->draw_calls = draw_calls <= 0 ? 1 : draw_calls;
  command->has_triangle_payload = has_triangle_payload != 0 ? 1 : 0;
  command->ax = ax;
  command->ay = ay;
  command->bx = bx;
  command->by = by;
  command->cx = cx;
  command->cy = cy;
  command->au = au;
  command->av = av;
  command->bu = bu;
  command->bv = bv;
  command->cu = cu;
  command->cv = cv;
  command->uniform_r = uniform_r;
  command->uniform_g = uniform_g;
  command->uniform_b = uniform_b;
  command->uniform_a = uniform_a;
  command->texture_seed = texture_seed < 0 ? 0 : texture_seed;
  command->dst_image_id = dst_image_id;
}

static void moonbit_fill_payload_vertices(
    const moonbit_planned_draw_command* command,
    moonbit_payload_vertex out_vertices[3]
) {
  if (command == NULL || out_vertices == NULL) {
    return;
  }
  out_vertices[0].x = (float)command->ax;
  out_vertices[0].y = (float)command->ay;
  out_vertices[0].u = (float)command->au;
  out_vertices[0].v = (float)command->av;
  out_vertices[1].x = (float)command->bx;
  out_vertices[1].y = (float)command->by;
  out_vertices[1].u = (float)command->bu;
  out_vertices[1].v = (float)command->bv;
  out_vertices[2].x = (float)command->cx;
  out_vertices[2].y = (float)command->cy;
  out_vertices[2].u = (float)command->cu;
  out_vertices[2].v = (float)command->cv;
}

static int moonbit_draw_payload_with_vertex_index_buffers(
    WGPUDevice device,
    WGPUQueue queue,
    WGPURenderPassEncoder pass,
    WGPURenderPipeline pipeline,
    const moonbit_planned_draw_command* command,
    int32_t draw_calls
) {
  if (device == NULL || queue == NULL || pass == NULL || pipeline == NULL || command == NULL) {
    return 0;
  }
  if (draw_calls <= 0) {
    return 1;
  }

  moonbit_payload_vertex vertices[3];
  moonbit_fill_payload_vertices(command, vertices);
  uint32_t indices[3] = {0, 1, 2};

  WGPUBufferDescriptor vertex_buffer_desc = {
    .nextInChain = NULL,
    .label = "Payload Vertex Buffer",
    .usage = WGPUBufferUsage_Vertex | WGPUBufferUsage_CopyDst,
    .size = sizeof(vertices),
    .mappedAtCreation = 0
  };
  WGPUBuffer vertex_buffer = wgpuDeviceCreateBuffer(device, &vertex_buffer_desc);
  if (vertex_buffer == NULL) {
    return 0;
  }

  WGPUBufferDescriptor index_buffer_desc = {
    .nextInChain = NULL,
    .label = "Payload Index Buffer",
    .usage = WGPUBufferUsage_Index | WGPUBufferUsage_CopyDst,
    .size = sizeof(indices),
    .mappedAtCreation = 0
  };
  WGPUBuffer index_buffer = wgpuDeviceCreateBuffer(device, &index_buffer_desc);
  if (index_buffer == NULL) {
    wgpuBufferRelease(vertex_buffer);
    return 0;
  }

  wgpuQueueWriteBuffer(queue, vertex_buffer, 0, vertices, sizeof(vertices));
  wgpuQueueWriteBuffer(queue, index_buffer, 0, indices, sizeof(indices));

  WGPUTextureView texture_view = NULL;
  WGPUSampler sampler = NULL;
  uint32_t texture_generation = 0U;
  if (!moonbit_get_or_create_seed_texture_resources(
        device,
        queue,
        command->texture_seed,
        &texture_view,
        &sampler,
        &texture_generation
      )) {
    wgpuBufferRelease(index_buffer);
    wgpuBufferRelease(vertex_buffer);
    return 0;
  }

  WGPUBindGroup bind_group = moonbit_get_or_create_planned_payload_bind_group(
    device,
    pipeline,
    command->texture_seed,
    texture_generation,
    texture_view,
    sampler
  );
  if (bind_group == NULL) {
    wgpuBufferRelease(index_buffer);
    wgpuBufferRelease(vertex_buffer);
    return 0;
  }

  wgpuRenderPassEncoderSetPipeline(pass, pipeline);
  wgpuRenderPassEncoderSetBindGroup(pass, 0, bind_group, 0, NULL);
  wgpuRenderPassEncoderSetVertexBuffer(pass, 0, vertex_buffer, 0, WGPU_WHOLE_SIZE);
  wgpuRenderPassEncoderSetIndexBuffer(
    pass,
    index_buffer,
    WGPUIndexFormat_Uint32,
    0,
    WGPU_WHOLE_SIZE
  );
  for (int32_t i = 0; i < draw_calls; i++) {
    wgpuRenderPassEncoderDrawIndexed(pass, 3, 1, 0, 0, 0);
  }

  wgpuBufferRelease(index_buffer);
  wgpuBufferRelease(vertex_buffer);
  return 1;
}

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

  if (draw_calls > 0) {
    int used_payload_buffer_draw = 0;
    if (has_triangle_payload != 0) {
      moonbit_planned_draw_command payload_command;
      payload_command.draw_calls = draw_calls;
      payload_command.has_triangle_payload = has_triangle_payload != 0 ? 1 : 0;
      payload_command.ax = ax;
      payload_command.ay = ay;
      payload_command.bx = bx;
      payload_command.by = by;
      payload_command.cx = cx;
      payload_command.cy = cy;
      payload_command.au = au;
      payload_command.av = av;
      payload_command.bu = bu;
      payload_command.bv = bv;
      payload_command.cu = cu;
      payload_command.cv = cv;
      payload_command.uniform_r = uniform_r;
      payload_command.uniform_g = uniform_g;
      payload_command.uniform_b = uniform_b;
      payload_command.uniform_a = uniform_a;
      payload_command.texture_seed = texture_seed < 0 ? 0 : texture_seed;
      WGPURenderPipeline cached_payload_pipeline =
        moonbit_get_or_create_planned_payload_pipeline(
          device,
          g_configured_surface_format,
          &payload_command
        );
      if (cached_payload_pipeline != NULL) {
        used_payload_buffer_draw = moonbit_draw_payload_with_vertex_index_buffers(
          device,
          queue,
          pass,
          cached_payload_pipeline,
          &payload_command,
          draw_calls
        );
      }
    }

    if (!used_payload_buffer_draw) {
      // Fallback: no payload path, keep fixed triangle pipeline.
      wgpuRenderPassEncoderSetPipeline(pass, pipeline);
      for (int32_t i = 0; i < draw_calls; i++) {
        wgpuRenderPassEncoderDraw(pass, 3, 1, 0, 0);  // 3 vertices
      }
    }
  }

  // RenderPass を終了
  wgpuRenderPassEncoderEnd(pass);
  wgpuRenderPassEncoderRelease(pass);

  // Readback: encode copy command into same encoder (before finish)
  {
    uint32_t tw = wgpuTextureGetWidth(surfaceTexture.texture);
    uint32_t th = wgpuTextureGetHeight(surfaceTexture.texture);
    moonbit_readback_encode_copy(device, encoder, surfaceTexture.texture, tw, th);
  }

  // CommandBuffer を作成して Queue に送信
  WGPUCommandBufferDescriptor cmdBufferDesc = {
    .nextInChain = NULL,
    .label = "Command Buffer"
  };
  WGPUCommandBuffer cmdBuffer = wgpuCommandEncoderFinish(encoder, &cmdBufferDesc);
  wgpuQueueSubmit(queue, 1, &cmdBuffer);

  // Readback: map buffer and read pixels (after submit)
  moonbit_readback_map_and_read(device);

  // リソースをクリーンアップ
  wgpuCommandBufferRelease(cmdBuffer);
  wgpuCommandEncoderRelease(encoder);
  wgpuTextureViewRelease(view);

  // Present
  wgpuSurfacePresent(surface);

  // Texture を解放
  wgpuTextureRelease(surfaceTexture.texture);
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

void moonbit_render_frame_with_staged_plan(
    WGPUSurface surface,
    WGPUDevice device,
    WGPUQueue queue,
    WGPURenderPipeline pipeline,
    double clear_r,
    double clear_g,
    double clear_b,
    double clear_a
) {
  WGPUSurfaceTexture surfaceTexture;
  wgpuSurfaceGetCurrentTexture(surface, &surfaceTexture);

  if (surfaceTexture.status != WGPUSurfaceGetCurrentTextureStatus_SuccessOptimal &&
      surfaceTexture.status != WGPUSurfaceGetCurrentTextureStatus_SuccessSuboptimal) {
    printf("[ERROR] Failed to get surface texture: status=%d\n", surfaceTexture.status);
    g_planned_draw_command_count = 0;
    return;
  }

  WGPUTextureViewDescriptor viewDesc = {
    .nextInChain = NULL,
    .label = "Surface Texture View",
    .format = WGPUTextureFormat_Undefined,
    .dimension = WGPUTextureViewDimension_2D,
    .baseMipLevel = 0,
    .mipLevelCount = 1,
    .baseArrayLayer = 0,
    .arrayLayerCount = 1,
    .aspect = WGPUTextureAspect_All
  };

  WGPUTextureView view = wgpuTextureCreateView(surfaceTexture.texture, &viewDesc);

  WGPUCommandEncoderDescriptor encoderDesc = {
    .nextInChain = NULL,
    .label = "Command Encoder"
  };
  WGPUCommandEncoder encoder = wgpuDeviceCreateCommandEncoder(device, &encoderDesc);

  // First pass: render to offscreen targets
  for (int32_t command_index = 0; command_index < g_planned_draw_command_count; command_index++) {
    moonbit_planned_draw_command command = g_planned_draw_commands[command_index];
    if (command.dst_image_id <= 0) continue; // Screen commands handled in second pass

    moonbit_offscreen_target* target = moonbit_find_offscreen_target(command.dst_image_id);
    if (target == NULL || !target->used) continue;

    moonbit_ensure_offscreen_gpu_texture(device, target);
    if (target->texture == NULL || target->view == NULL) continue;

    // Create a separate render pass for this offscreen target
    WGPURenderPassColorAttachment offscreenAttachment = {
      .view = target->view,
      .depthSlice = WGPU_DEPTH_SLICE_UNDEFINED,
      .resolveTarget = NULL,
      .loadOp = WGPULoadOp_Load, // Preserve existing content
      .storeOp = WGPUStoreOp_Store,
      .clearValue = {0.0f, 0.0f, 0.0f, 0.0f}
    };
    WGPURenderPassDescriptor offscreenPassDesc = {
      .nextInChain = NULL,
      .label = "Offscreen Render Pass",
      .colorAttachmentCount = 1,
      .colorAttachments = &offscreenAttachment,
      .depthStencilAttachment = NULL,
      .occlusionQuerySet = NULL,
      .timestampWrites = NULL
    };
    WGPURenderPassEncoder offscreenPass = wgpuCommandEncoderBeginRenderPass(encoder, &offscreenPassDesc);

    int32_t draw_calls = command.draw_calls <= 0 ? 1 : command.draw_calls;
    int used_payload_buffer_draw = 0;
    if (command.has_triangle_payload != 0) {
      WGPURenderPipeline cached_payload_pipeline =
        moonbit_get_or_create_planned_payload_pipeline(device, g_configured_surface_format, &command);
      if (cached_payload_pipeline != NULL) {
        used_payload_buffer_draw = moonbit_draw_payload_with_vertex_index_buffers(
          device, queue, offscreenPass, cached_payload_pipeline, &command, draw_calls);
      }
    }
    if (!used_payload_buffer_draw) {
      wgpuRenderPassEncoderSetPipeline(offscreenPass, pipeline);
      for (int32_t i = 0; i < draw_calls; i++) {
        wgpuRenderPassEncoderDraw(offscreenPass, 3, 1, 0, 0);
      }
    }

    wgpuRenderPassEncoderEnd(offscreenPass);
    wgpuRenderPassEncoderRelease(offscreenPass);
  }

  // Second pass: render screen commands (dst_image_id == 0) to swap chain
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

  for (int32_t command_index = 0; command_index < g_planned_draw_command_count; command_index++) {
    moonbit_planned_draw_command command = g_planned_draw_commands[command_index];
    if (command.dst_image_id > 0) continue; // Already rendered to offscreen

    int32_t draw_calls = command.draw_calls <= 0 ? 1 : command.draw_calls;
    int used_payload_buffer_draw = 0;
    if (command.has_triangle_payload != 0) {
      WGPURenderPipeline cached_payload_pipeline =
        moonbit_get_or_create_planned_payload_pipeline(
          device, g_configured_surface_format, &command);
      if (cached_payload_pipeline != NULL) {
        used_payload_buffer_draw = moonbit_draw_payload_with_vertex_index_buffers(
          device, queue, pass, cached_payload_pipeline, &command, draw_calls);
      }
    }
    if (!used_payload_buffer_draw) {
      wgpuRenderPassEncoderSetPipeline(pass, pipeline);
      for (int32_t i = 0; i < draw_calls; i++) {
        wgpuRenderPassEncoderDraw(pass, 3, 1, 0, 0);
      }
    }
  }

  wgpuRenderPassEncoderEnd(pass);
  wgpuRenderPassEncoderRelease(pass);

  // Readback: encode copy command into same encoder (before finish)
  {
    uint32_t tw = wgpuTextureGetWidth(surfaceTexture.texture);
    uint32_t th = wgpuTextureGetHeight(surfaceTexture.texture);
    moonbit_readback_encode_copy(device, encoder, surfaceTexture.texture, tw, th);
  }

  WGPUCommandBufferDescriptor cmdBufferDesc = {
    .nextInChain = NULL,
    .label = "Command Buffer"
  };
  WGPUCommandBuffer cmdBuffer = wgpuCommandEncoderFinish(encoder, &cmdBufferDesc);
  wgpuQueueSubmit(queue, 1, &cmdBuffer);

  // Readback: map buffer and read pixels (after submit)
  moonbit_readback_map_and_read(device);

  wgpuCommandBufferRelease(cmdBuffer);
  wgpuCommandEncoderRelease(encoder);
  wgpuTextureViewRelease(view);

  wgpuSurfacePresent(surface);
  wgpuTextureRelease(surfaceTexture.texture);
  g_planned_draw_command_count = 0;
}

// ===============================
// Readback: texture → buffer copy
// ===============================

static uint32_t readback_bytes_per_row(uint32_t width) {
  // wgpu requires 256-byte alignment for buffer copy
  uint32_t unaligned = width * 4;
  return (unaligned + 255) & ~255u;
}

typedef struct { int done; WGPUMapAsyncStatus status; } ReadbackMapCtx;

static void moonbit_readback_map_callback(WGPUMapAsyncStatus status, WGPUStringView message, void* userdata1, void* userdata2) {
  (void)message;
  (void)userdata2;
  ReadbackMapCtx* ctx = (ReadbackMapCtx*)userdata1;
  ctx->status = status;
  ctx->done = 1;
}

// Phase 1: Encode texture→buffer copy into the given command encoder.
// Must be called BEFORE wgpuCommandEncoderFinish.
static void moonbit_readback_encode_copy(
    WGPUDevice device,
    WGPUCommandEncoder encoder,
    WGPUTexture surface_texture,
    uint32_t tex_width,
    uint32_t tex_height
) {
  if (device == NULL || encoder == NULL || surface_texture == NULL) {
    return;
  }
  if (tex_width == 0 || tex_height == 0) {
    return;
  }

  uint32_t bpr = readback_bytes_per_row(tex_width);
  uint64_t buffer_size = (uint64_t)bpr * tex_height;

  // (Re)create buffer if size changed
  if (g_readback_buffer == NULL || g_readback_width != tex_width || g_readback_height != tex_height) {
    if (g_readback_buffer != NULL) {
      wgpuBufferRelease(g_readback_buffer);
      g_readback_buffer = NULL;
    }
    WGPUBufferDescriptor buf_desc = {
      .nextInChain = NULL,
      .label = "Readback Buffer",
      .usage = WGPUBufferUsage_CopyDst | WGPUBufferUsage_MapRead,
      .size = buffer_size,
      .mappedAtCreation = 0,
    };
    g_readback_buffer = wgpuDeviceCreateBuffer(device, &buf_desc);
    g_readback_width = tex_width;
    g_readback_height = tex_height;
  }
  if (g_readback_buffer == NULL) {
    g_readback_valid = 0;
    return;
  }

  WGPUTexelCopyTextureInfo src_info = {
    .texture = surface_texture,
    .mipLevel = 0,
    .origin = { .x = 0, .y = 0, .z = 0 },
    .aspect = WGPUTextureAspect_All,
  };
  WGPUTexelCopyBufferInfo dst_info = {
    .buffer = g_readback_buffer,
    .layout = {
      .offset = 0,
      .bytesPerRow = bpr,
      .rowsPerImage = tex_height,
    },
  };
  WGPUExtent3D copy_size = {
    .width = tex_width,
    .height = tex_height,
    .depthOrArrayLayers = 1,
  };
  wgpuCommandEncoderCopyTextureToBuffer(encoder, &src_info, &dst_info, &copy_size);
}

// Phase 2: After queue submit, synchronously map the readback buffer
// and copy BGRA→RGBA into g_readback_data.
static void moonbit_readback_map_and_read(WGPUDevice device) {
  if (device == NULL || g_readback_buffer == NULL) {
    g_readback_valid = 0;
    return;
  }

  uint32_t bpr = readback_bytes_per_row(g_readback_width);
  uint64_t buffer_size = (uint64_t)bpr * g_readback_height;

  // Synchronous poll to finish all GPU work
  wgpuDevicePoll(device, 1, NULL);

  // Map buffer
  ReadbackMapCtx map_ctx = { .done = 0, .status = WGPUMapAsyncStatus_Unknown };
  WGPUBufferMapCallbackInfo map_cb_info = {
    .nextInChain = NULL,
    .mode = WGPUCallbackMode_AllowSpontaneous,
    .callback = moonbit_readback_map_callback,
    .userdata1 = &map_ctx,
    .userdata2 = NULL,
  };
  wgpuBufferMapAsync(g_readback_buffer, WGPUMapMode_Read, 0, buffer_size, map_cb_info);
  while (!map_ctx.done) {
    wgpuDevicePoll(device, 1, NULL);
  }

  if (map_ctx.status != WGPUMapAsyncStatus_Success) {
    g_readback_valid = 0;
    return;
  }

  const uint8_t* mapped = (const uint8_t*)wgpuBufferGetConstMappedRange(g_readback_buffer, 0, buffer_size);
  if (mapped == NULL) {
    wgpuBufferUnmap(g_readback_buffer);
    g_readback_valid = 0;
    return;
  }

  // Allocate/reallocate RGBA output
  uint32_t rgba_size = g_readback_width * g_readback_height * 4;
  if (g_readback_data != NULL) {
    free(g_readback_data);
  }
  g_readback_data = (uint8_t*)malloc(rgba_size);
  if (g_readback_data == NULL) {
    wgpuBufferUnmap(g_readback_buffer);
    g_readback_valid = 0;
    return;
  }

  // Copy with BGRA→RGBA swizzle
  for (uint32_t row = 0; row < g_readback_height; row++) {
    const uint8_t* src_row = mapped + row * bpr;
    uint8_t* dst_row = g_readback_data + row * g_readback_width * 4;
    for (uint32_t col = 0; col < g_readback_width; col++) {
      dst_row[col * 4 + 0] = src_row[col * 4 + 2]; // R ← B
      dst_row[col * 4 + 1] = src_row[col * 4 + 1]; // G ← G
      dst_row[col * 4 + 2] = src_row[col * 4 + 0]; // B ← R
      dst_row[col * 4 + 3] = src_row[col * 4 + 3]; // A ← A
    }
  }

  wgpuBufferUnmap(g_readback_buffer);
  g_readback_valid = 1;
}

// FFI: readback query functions
int32_t moonbit_read_pixels_available(void) {
  return g_readback_valid;
}

int32_t moonbit_read_pixels_width(void) {
  return g_readback_valid ? (int32_t)g_readback_width : 0;
}

int32_t moonbit_read_pixels_height(void) {
  return g_readback_valid ? (int32_t)g_readback_height : 0;
}

int32_t moonbit_read_pixels_channel(int32_t offset) {
  if (!g_readback_valid || g_readback_data == NULL || offset < 0) {
    return 0;
  }
  uint32_t rgba_size = g_readback_width * g_readback_height * 4;
  if ((uint32_t)offset >= rgba_size) {
    return 0;
  }
  return (int32_t)g_readback_data[offset];
}
