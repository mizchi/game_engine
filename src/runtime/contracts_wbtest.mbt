///|
fn install_test_web_hooks(max_polls~ : Int = 3) -> Unit {
  let poll_count : Ref[Int] = Ref::new(0)
  @platform.set_web_canvas_hooks(
    @platform.new_web_canvas_hooks(
      fn(_canvas_selector, _options) { true },
      fn(_active) { poll_count.val = poll_count.val + 1 },
      fn() { poll_count.val >= max_polls },
      fn(width, height) {
        @core.new_outside_size(width.to_double(), height.to_double())
      },
      fn(_canvas_selector, options) {
        @platform.create_webgpu_surface_token(
          77,
          options.width,
          options.height,
          1.0,
        )
      },
      fn(_active, _tick) { @core.empty_input_snapshot() },
      fn(_canvas_selector, _active, enabled) { enabled },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, mode) { mode },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, scale) { scale },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, enabled) { enabled },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active) { () },
      fn(_canvas_selector, _active) { () },
      fn(_s, _a, _e) { () },
      fn(_s, _a) { false },
      fn(_s, _a, c) { c },
      fn(_s, _a, c) { c },
    ),
  )
  @gfx.set_web_graphics_hooks(
    @gfx.new_web_graphics_hooks(
      fn(_kind, _width, _height) { true },
      fn(_active, _kind, _pass) { () },
      fn(_active, _kind, _present) { () },
      fn(_active, _kind, _command) { () },
      fn(_active, _kind, _width, _height) { () },
    ),
  )
}

///|
fn install_test_web_hooks_with_tick_input(max_polls~ : Int = 3) -> Unit {
  let poll_count : Ref[Int] = Ref::new(0)
  @platform.set_web_canvas_hooks(
    @platform.new_web_canvas_hooks(
      fn(_canvas_selector, _options) { true },
      fn(_active) { poll_count.val = poll_count.val + 1 },
      fn() { poll_count.val >= max_polls },
      fn(width, height) {
        @core.new_outside_size(width.to_double(), height.to_double())
      },
      fn(_canvas_selector, options) {
        @platform.create_webgpu_surface_token(
          77,
          options.width,
          options.height,
          1.0,
        )
      },
      fn(_active, tick) {
        @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [tick], [], [], [])
      },
      fn(_canvas_selector, _active, enabled) { enabled },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, mode) { mode },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, scale) { scale },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, enabled) { enabled },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active) { () },
      fn(_canvas_selector, _active) { () },
      fn(_s, _a, _e) { () },
      fn(_s, _a) { false },
      fn(_s, _a, c) { c },
      fn(_s, _a, c) { c },
    ),
  )
  @gfx.set_web_graphics_hooks(
    @gfx.new_web_graphics_hooks(
      fn(_kind, _width, _height) { true },
      fn(_active, _kind, _pass) { () },
      fn(_active, _kind, _present) { () },
      fn(_active, _kind, _command) { () },
      fn(_active, _kind, _width, _height) { () },
    ),
  )
}

///|
fn reset_test_web_hooks() -> Unit {
  @gfx.reset_web_graphics_hooks()
  @platform.reset_web_canvas_hooks()
}

///|
fn install_test_native_hooks(max_polls~ : Int = 3) -> Unit {
  let poll_count : Ref[Int] = Ref::new(0)
  @platform.set_desktop_native_hooks(
    @platform.new_desktop_native_hooks(
      fn(_options) { true },
      fn(_active) { poll_count.val = poll_count.val + 1 },
      fn() { poll_count.val >= max_polls },
      fn(width, height) {
        @core.new_outside_size(width.to_double(), height.to_double())
      },
      fn(_active, _tick) { @core.empty_input_snapshot() },
      fn(_active, enabled) { enabled },
      fn(_active, current) { current },
      fn(_active, mode) { mode },
      fn(_active, current) { current },
      fn(_active, scale) { scale },
      fn(_active, current) { current },
      fn(_active, enabled) { enabled },
      fn(_active, current) { current },
      fn(_active) { () },
      fn(_active) { () },
      fn(_a, _e) { () },
      fn(_a) { false },
    ),
  )
  @gfx.set_native_graphics_hooks(
    @gfx.new_native_graphics_hooks(
      fn(_width, _height) { true },
      fn(_active, _pass) { () },
      fn(_active, _present) { () },
      fn(_active, _command) { () },
      fn(_active, _width, _height) { () },
    ),
  )
}

///|
fn install_test_native_hooks_with_tick_input(max_polls~ : Int = 3) -> Unit {
  let poll_count : Ref[Int] = Ref::new(0)
  @platform.set_desktop_native_hooks(
    @platform.new_desktop_native_hooks(
      fn(_options) { true },
      fn(_active) { poll_count.val = poll_count.val + 1 },
      fn() { poll_count.val >= max_polls },
      fn(width, height) {
        @core.new_outside_size(width.to_double(), height.to_double())
      },
      fn(_active, tick) {
        @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [tick], [], [], [])
      },
      fn(_active, enabled) { enabled },
      fn(_active, current) { current },
      fn(_active, mode) { mode },
      fn(_active, current) { current },
      fn(_active, scale) { scale },
      fn(_active, current) { current },
      fn(_active, enabled) { enabled },
      fn(_active, current) { current },
      fn(_active) { () },
      fn(_active) { () },
      fn(_a, _e) { () },
      fn(_a) { false },
    ),
  )
  @gfx.set_native_graphics_hooks(
    @gfx.new_native_graphics_hooks(
      fn(_width, _height) { true },
      fn(_active, _pass) { () },
      fn(_active, _present) { () },
      fn(_active, _command) { () },
      fn(_active, _width, _height) { () },
    ),
  )
}

///|
fn reset_test_native_hooks() -> Unit {
  @gfx.reset_native_graphics_hooks()
  @platform.reset_desktop_native_hooks()
}

///|
struct RunLoopProbeSummary {
  update_count : Int
  begin_count : Int
  end_count : Int
  last_update_tick : Int
  last_begin_clear_enabled : Int
  last_begin_clear_r : Double
  last_end_present : Int
} derive(Show)

///|
fn bool_to_int(value : Bool) -> Int {
  if value {
    1
  } else {
    0
  }
}

///|
fn last_or_default(values : Array[Int], fallback : Int) -> Int {
  if values.length() == 0 {
    fallback
  } else {
    values[values.length() - 1]
  }
}

///|
fn last_or_default_double(values : Array[Double], fallback : Double) -> Double {
  if values.length() == 0 {
    fallback
  } else {
    values[values.length() - 1]
  }
}

///|
fn run_terminating_probe_with_webgpu(
  close_after_polls : Int,
  clear_screen_every_frame : Bool,
) -> RunLoopProbeSummary raise {
  let safe_close_after = if close_after_polls <= 0 {
    1
  } else {
    close_after_polls
  }
  let poll_count : Ref[Int] = Ref::new(0)
  let observed_ticks : Ref[Array[Int]] = Ref::new([])
  let begin_clear_enabled : Ref[Array[Int]] = Ref::new([])
  let begin_clear_r : Ref[Array[Double]] = Ref::new([])
  let end_present : Ref[Array[Int]] = Ref::new([])

  @platform.set_web_canvas_hooks(
    @platform.new_web_canvas_hooks(
      fn(_canvas_selector, _options) { true },
      fn(_active) { poll_count.val = poll_count.val + 1 },
      fn() { poll_count.val >= safe_close_after },
      fn(width, height) {
        @core.new_outside_size(width.to_double(), height.to_double())
      },
      fn(_canvas_selector, options) {
        @platform.create_webgpu_surface_token(
          77,
          options.width,
          options.height,
          1.0,
        )
      },
      fn(_active, tick) {
        @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [tick], [], [], [])
      },
      fn(_canvas_selector, _active, enabled) { enabled },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, mode) { mode },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, scale) { scale },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, enabled) { enabled },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active) { () },
      fn(_canvas_selector, _active) { () },
      fn(_s, _a, _e) { () },
      fn(_s, _a) { false },
      fn(_s, _a, c) { c },
      fn(_s, _a, c) { c },
    ),
  )
  @gfx.set_web_graphics_hooks(
    @gfx.new_web_graphics_hooks(
      fn(_kind, _width, _height) { true },
      fn(active, _kind, pass) {
        if active {
          begin_clear_enabled.val.push(bool_to_int(pass.present))
          begin_clear_r.val.push(pass.clear_color.r)
        }
      },
      fn(active, _kind, present) {
        if active {
          end_present.val.push(bool_to_int(present))
        }
      },
      fn(_active, _kind, _command) { () },
      fn(_active, _kind, _width, _height) { () },
    ),
  )

  let hooks = new_runtime_hooks(fn(tick, _input) {
    observed_ticks.val.push(tick)
  })
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_web_canvas_platform("#app")
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_webgpu_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame,
  }
  run_loop_with_hooks(game, platform, graphics, options, runtime_config, hooks)
  let summary : RunLoopProbeSummary = {
    update_count: observed_ticks.val.length(),
    begin_count: graphics.begin_count,
    end_count: graphics.end_count,
    last_update_tick: last_or_default(observed_ticks.val, -1),
    last_begin_clear_enabled: last_or_default(begin_clear_enabled.val, -1),
    last_begin_clear_r: last_or_default_double(begin_clear_r.val, -1.0),
    last_end_present: last_or_default(end_present.val, -1),
  }
  reset_test_web_hooks()
  summary
}

///|
fn run_terminating_probe_with_native(
  close_after_polls : Int,
  clear_screen_every_frame : Bool,
) -> RunLoopProbeSummary raise {
  let safe_close_after = if close_after_polls <= 0 {
    1
  } else {
    close_after_polls
  }
  let poll_count : Ref[Int] = Ref::new(0)
  let observed_ticks : Ref[Array[Int]] = Ref::new([])
  let begin_clear_enabled : Ref[Array[Int]] = Ref::new([])
  let begin_clear_r : Ref[Array[Double]] = Ref::new([])
  let end_present : Ref[Array[Int]] = Ref::new([])

  @platform.set_desktop_native_hooks(
    @platform.new_desktop_native_hooks(
      fn(_options) { true },
      fn(_active) { poll_count.val = poll_count.val + 1 },
      fn() { poll_count.val >= safe_close_after },
      fn(width, height) {
        @core.new_outside_size(width.to_double(), height.to_double())
      },
      fn(_active, tick) {
        @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [tick], [], [], [])
      },
      fn(_active, enabled) { enabled },
      fn(_active, current) { current },
      fn(_active, mode) { mode },
      fn(_active, current) { current },
      fn(_active, scale) { scale },
      fn(_active, current) { current },
      fn(_active, enabled) { enabled },
      fn(_active, current) { current },
      fn(_active) { () },
      fn(_active) { () },
      fn(_a, _e) { () },
      fn(_a) { false },
    ),
  )
  @gfx.set_native_graphics_hooks(
    @gfx.new_native_graphics_hooks(
      fn(_width, _height) { true },
      fn(active, pass) {
        if active {
          begin_clear_enabled.val.push(bool_to_int(pass.present))
          begin_clear_r.val.push(pass.clear_color.r)
        }
      },
      fn(active, present) {
        if active {
          end_present.val.push(bool_to_int(present))
        }
      },
      fn(_active, _command) { () },
      fn(_active, _width, _height) { () },
    ),
  )

  let hooks = new_runtime_hooks(fn(tick, _input) {
    observed_ticks.val.push(tick)
  })
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_desktop_glfw_platform()
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_wgpu_native_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame,
  }
  run_loop_with_hooks(game, platform, graphics, options, runtime_config, hooks)
  let summary : RunLoopProbeSummary = {
    update_count: observed_ticks.val.length(),
    begin_count: graphics.begin_count,
    end_count: graphics.end_count,
    last_update_tick: last_or_default(observed_ticks.val, -1),
    last_begin_clear_enabled: last_or_default(begin_clear_enabled.val, -1),
    last_begin_clear_r: last_or_default_double(begin_clear_r.val, -1.0),
    last_end_present: last_or_default(end_present.val, -1),
  }
  reset_test_native_hooks()
  summary
}

///|
fn run_counting_game_with_webgpu() -> (Int, Int) raise {
  install_test_web_hooks()
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_web_canvas_platform("#app")
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_webgpu_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame: true,
  }
  run_loop(game, platform, graphics, options, runtime_config)
  let result = (graphics.begin_count, graphics.end_count)
  reset_test_web_hooks()
  result
}

///|
fn run_counting_game_with_webgl() -> (Int, Int) raise {
  install_test_web_hooks()
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_web_canvas_platform("#app")
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_webgl_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame: true,
  }
  run_loop(game, platform, graphics, options, runtime_config)
  let result = (graphics.begin_count, graphics.end_count)
  reset_test_web_hooks()
  result
}

///|
fn run_counting_game_with_native() -> (Int, Int) raise {
  install_test_native_hooks()
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_desktop_glfw_platform()
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_wgpu_native_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame: true,
  }
  run_loop(game, platform, graphics, options, runtime_config)
  let result = (graphics.begin_count, graphics.end_count)
  reset_test_native_hooks()
  result
}

///|
fn run_observed_input_ticks_with_webgpu() -> Array[Int] raise {
  install_test_web_hooks_with_tick_input()
  let observed_ticks : Ref[Array[Int]] = Ref::new([])
  let hooks = new_runtime_hooks(fn(tick, _input) {
    observed_ticks.val.push(tick)
  })
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_web_canvas_platform("#app")
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_webgpu_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame: true,
  }
  run_loop_with_hooks(game, platform, graphics, options, runtime_config, hooks)
  let result = observed_ticks.val
  reset_test_web_hooks()
  result
}

///|
fn run_observed_input_ticks_with_native() -> Array[Int] raise {
  install_test_native_hooks_with_tick_input()
  let observed_ticks : Ref[Array[Int]] = Ref::new([])
  let hooks = new_runtime_hooks(fn(tick, _input) {
    observed_ticks.val.push(tick)
  })
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_desktop_glfw_platform()
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_wgpu_native_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame: true,
  }
  run_loop_with_hooks(game, platform, graphics, options, runtime_config, hooks)
  let result = observed_ticks.val
  reset_test_native_hooks()
  result
}

///|
fn run_resized_frame_sizes_with_webgpu() -> (Array[Int], Array[Int]) raise {
  let poll_count : Ref[Int] = Ref::new(0)
  let resized_widths : Ref[Array[Int]] = Ref::new([])
  let resized_heights : Ref[Array[Int]] = Ref::new([])
  @platform.set_web_canvas_hooks(
    @platform.new_web_canvas_hooks(
      fn(_canvas_selector, _options) { true },
      fn(_active) { poll_count.val = poll_count.val + 1 },
      fn() { poll_count.val >= 3 },
      fn(_width, _height) {
        if poll_count.val <= 1 {
          @core.new_outside_size(320.0, 240.0)
        } else {
          @core.new_outside_size(640.0, 360.0)
        }
      },
      fn(_canvas_selector, options) {
        @platform.create_webgpu_surface_token(
          77,
          options.width,
          options.height,
          1.0,
        )
      },
      fn(_active, _tick) { @core.empty_input_snapshot() },
      fn(_canvas_selector, _active, enabled) { enabled },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, mode) { mode },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, scale) { scale },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active, enabled) { enabled },
      fn(_canvas_selector, _active, current) { current },
      fn(_canvas_selector, _active) { () },
      fn(_canvas_selector, _active) { () },
      fn(_s, _a, _e) { () },
      fn(_s, _a) { false },
      fn(_s, _a, c) { c },
      fn(_s, _a, c) { c },
    ),
  )
  @gfx.set_web_graphics_hooks(
    @gfx.new_web_graphics_hooks(
      fn(_kind, _width, _height) { true },
      fn(_active, _kind, _pass) { () },
      fn(_active, _kind, _present) { () },
      fn(_active, _kind, _command) { () },
      fn(active, _kind, width, height) {
        if active {
          resized_widths.val.push(width)
          resized_heights.val.push(height)
        }
      },
    ),
  )

  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_web_canvas_platform("#app")
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_webgpu_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame: true,
  }
  run_loop(game, platform, graphics, options, runtime_config)
  let result = (resized_widths.val, resized_heights.val)
  reset_test_web_hooks()
  result
}

///|
fn run_resized_frame_sizes_with_native() -> (Array[Int], Array[Int]) raise {
  let poll_count : Ref[Int] = Ref::new(0)
  let resized_widths : Ref[Array[Int]] = Ref::new([])
  let resized_heights : Ref[Array[Int]] = Ref::new([])
  @platform.set_desktop_native_hooks(
    @platform.new_desktop_native_hooks(
      fn(_options) { true },
      fn(_active) { poll_count.val = poll_count.val + 1 },
      fn() { poll_count.val >= 3 },
      fn(_width, _height) {
        if poll_count.val <= 1 {
          @core.new_outside_size(320.0, 240.0)
        } else {
          @core.new_outside_size(640.0, 360.0)
        }
      },
      fn(_active, _tick) { @core.empty_input_snapshot() },
      fn(_active, enabled) { enabled },
      fn(_active, current) { current },
      fn(_active, mode) { mode },
      fn(_active, current) { current },
      fn(_active, scale) { scale },
      fn(_active, current) { current },
      fn(_active, enabled) { enabled },
      fn(_active, current) { current },
      fn(_active) { () },
      fn(_active) { () },
      fn(_a, _e) { () },
      fn(_a) { false },
    ),
  )
  @gfx.set_native_graphics_hooks(
    @gfx.new_native_graphics_hooks(
      fn(_width, _height) { true },
      fn(_active, _pass) { () },
      fn(_active, _present) { () },
      fn(_active, _command) { () },
      fn(active, width, height) {
        if active {
          resized_widths.val.push(width)
          resized_heights.val.push(height)
        }
      },
    ),
  )

  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_desktop_glfw_platform()
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_wgpu_native_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame: true,
  }
  run_loop(game, platform, graphics, options, runtime_config)
  let result = (resized_widths.val, resized_heights.val)
  reset_test_native_hooks()
  result
}

///|
test "plan_frame clamps updates by max_skip_frames" {
  let state = @core.initial_fixed_step_state()
  let cfg = @core.new_fixed_step_config(60, 8)
  let step = @core.step_fixed_timestep(state, 1000.0, cfg)
  let plan = plan_frame(step, 2)
  assert_eq(plan.updates, 2)
}

///|
test "run_loop works with noop game + stub platform/gfx" {
  install_test_web_hooks()
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_web_canvas_platform("#app")
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_webgpu_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame: true,
  }
  run_loop(game, platform, graphics, options, runtime_config)
  assert_true(!platform.is_vsync_enabled())
  reset_test_web_hooks()
}

///|
test "run_loop begin/end counts match between webgpu and webgl" {
  let (webgpu_begin, webgpu_end) = run_counting_game_with_webgpu()
  let (webgl_begin, webgl_end) = run_counting_game_with_webgl()

  assert_eq(webgpu_begin, webgl_begin)
  assert_eq(webgpu_end, webgl_end)
}

///|
test "run_loop begin/end counts match between native and webgpu" {
  let (native_begin, native_end) = run_counting_game_with_native()
  let (webgpu_begin, webgpu_end) = run_counting_game_with_webgpu()

  assert_eq(native_begin, webgpu_begin)
  assert_eq(native_end, webgpu_end)
}

///|
test "run_loop_with_hooks observed input ticks match between native and webgpu" {
  let native_ticks = run_observed_input_ticks_with_native()
  let web_ticks = run_observed_input_ticks_with_webgpu()
  assert_eq(native_ticks.length(), web_ticks.length())
  for i in 0..<native_ticks.length() {
    assert_eq(native_ticks[i], web_ticks[i])
  }
}

///|
test "run_loop resize notifications match between native and webgpu" {
  let (native_widths, native_heights) = run_resized_frame_sizes_with_native()
  let (web_widths, web_heights) = run_resized_frame_sizes_with_webgpu()
  assert_eq(native_widths.length(), web_widths.length())
  assert_eq(native_heights.length(), web_heights.length())
  assert_eq(native_widths.length(), 2)
  assert_eq(native_heights.length(), 2)
  assert_eq(native_widths[0], 320)
  assert_eq(native_heights[0], 240)
  assert_eq(native_widths[1], 640)
  assert_eq(native_heights[1], 360)
  for i in 0..<native_widths.length() {
    assert_eq(native_widths[i], web_widths[i])
    assert_eq(native_heights[i], web_heights[i])
  }
}

///|
test "run_loop termination and minimal render summary match between native and webgpu" {
  let native = run_terminating_probe_with_native(3, false)
  let webgpu = run_terminating_probe_with_webgpu(3, false)

  assert_true(native.update_count > 0)
  assert_true(webgpu.update_count > 0)
  assert_eq(native.update_count, webgpu.update_count)
  assert_eq(native.begin_count, webgpu.begin_count)
  assert_eq(native.end_count, webgpu.end_count)
  assert_eq(native.last_update_tick, webgpu.last_update_tick)
  assert_eq(native.last_begin_clear_enabled, webgpu.last_begin_clear_enabled)
  assert_eq(native.last_begin_clear_r, webgpu.last_begin_clear_r)
  assert_eq(native.last_end_present, webgpu.last_end_present)

  assert_eq(native.last_begin_clear_enabled, 0)
  assert_eq(webgpu.last_begin_clear_enabled, 0)
  assert_eq(native.last_end_present, 1)
  assert_eq(webgpu.last_end_present, 1)
  assert_eq(native.last_begin_clear_r, 0.0)
  assert_eq(webgpu.last_begin_clear_r, 0.0)
}

///|
test "run_loop_with_hooks passes captured input snapshots to observer" {
  install_test_web_hooks_with_tick_input()
  let observed_ticks : Ref[Array[Int]] = Ref::new([])
  let observed_first_keys : Ref[Array[Int]] = Ref::new([])
  let hooks = new_runtime_hooks(fn(tick, input) {
    observed_ticks.val.push(tick)
    if input.pressed_keys.length() > 0 {
      observed_first_keys.val.push(input.pressed_keys[0])
    } else {
      observed_first_keys.val.push(-1)
    }
  })
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_web_canvas_platform("#app")
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_webgpu_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame: true,
  }
  run_loop_with_hooks(game, platform, graphics, options, runtime_config, hooks)
  assert_true(observed_ticks.val.length() > 0)
  assert_eq(observed_ticks.val.length(), observed_first_keys.val.length())
  for i in 0..<observed_ticks.val.length() {
    assert_eq(observed_ticks.val[i], observed_first_keys.val[i])
    if i > 0 {
      assert_true(observed_ticks.val[i] > observed_ticks.val[i - 1])
    }
  }
  reset_test_web_hooks()
}

///|
test "input edge observer tracks deltas and keeps bounded history" {
  let observer = new_input_edge_observer_state(2)
  let edge1 = observe_input_edge(
    observer,
    1,
    @core.new_input_snapshot_full(
      0.0,
      0.0,
      0.0,
      0.0,
      [1],
      [0],
      [@core.new_touch_point(10, 1.0, 2.0)],
      [@core.new_gamepad_snapshot(7, [], [1])],
    ),
  )
  assert_eq(edge1.tick, 1)
  assert_eq(edge1.just_pressed_key_count, 1)
  assert_eq(edge1.just_released_key_count, 0)
  assert_eq(edge1.just_pressed_mouse_button_count, 1)
  assert_eq(edge1.just_released_mouse_button_count, 0)
  assert_eq(edge1.just_pressed_touch_count, 1)
  assert_eq(edge1.just_released_touch_count, 0)
  assert_eq(edge1.just_connected_gamepad_count, 1)
  assert_eq(edge1.just_disconnected_gamepad_count, 0)
  assert_eq(edge1.just_pressed_gamepad_button_count, 1)
  assert_eq(edge1.just_released_gamepad_button_count, 0)

  let edge2 = observe_input_edge(
    observer,
    2,
    @core.new_input_snapshot_full(
      0.0,
      0.0,
      0.0,
      0.0,
      [],
      [0, 2],
      [@core.new_touch_point(11, 3.0, 4.0)],
      [
        @core.new_gamepad_snapshot(7, [], [3]),
        @core.new_gamepad_snapshot(8, [], []),
      ],
    ),
  )
  assert_eq(edge2.just_pressed_key_count, 0)
  assert_eq(edge2.just_released_key_count, 1)
  assert_eq(edge2.just_pressed_mouse_button_count, 1)
  assert_eq(edge2.just_released_mouse_button_count, 0)
  assert_eq(edge2.just_pressed_touch_count, 1)
  assert_eq(edge2.just_released_touch_count, 1)
  assert_eq(edge2.just_connected_gamepad_count, 1)
  assert_eq(edge2.just_disconnected_gamepad_count, 0)
  assert_eq(edge2.just_pressed_gamepad_button_count, 1)
  assert_eq(edge2.just_released_gamepad_button_count, 1)

  let edge3 = observe_input_edge(
    observer,
    3,
    @core.new_input_snapshot_full(0.0, 0.0, 0.0, 0.0, [], [], [], []),
  )
  assert_eq(edge3.just_pressed_key_count, 0)
  assert_eq(edge3.just_released_key_count, 0)
  assert_eq(edge3.just_pressed_mouse_button_count, 0)
  assert_eq(edge3.just_released_mouse_button_count, 2)
  assert_eq(edge3.just_pressed_touch_count, 0)
  assert_eq(edge3.just_released_touch_count, 1)
  assert_eq(edge3.just_connected_gamepad_count, 0)
  assert_eq(edge3.just_disconnected_gamepad_count, 2)
  assert_eq(edge3.just_pressed_gamepad_button_count, 0)
  assert_eq(edge3.just_released_gamepad_button_count, 1)

  let history = append_input_edge_history(observer, [])
  assert_eq(history.length(), 2)
  assert_eq(history[0].tick, 2)
  assert_eq(history[1].tick, 3)
}

///|
test "new_input_edge_runtime_hooks wires observer to run_loop_with_hooks" {
  install_test_web_hooks_with_tick_input()
  let observer = new_input_edge_observer_state(4)
  let hooks = new_input_edge_runtime_hooks(observer)
  let game = @core.new_noop_game(320, 240)
  let platform = @platform.create_web_canvas_platform("#app")
  let surface = platform.current_surface()
  let gfx_options = @gfx.default_graphics_backend_options()
  let graphics = @gfx.create_webgpu_graphics(surface, gfx_options)
  let options = @core.default_run_options()
  let runtime_config = {
    max_skip_frames: 2,
    enable_vsync: false,
    clear_screen_every_frame: true,
  }
  run_loop_with_hooks(game, platform, graphics, options, runtime_config, hooks)
  let history = append_input_edge_history(observer, [])
  assert_true(history.length() > 0)
  assert_true(history[history.length() - 1].tick > 0)
  reset_test_web_hooks()
}

///|
test "default_runtime_config returns expected defaults" {
  let config = default_runtime_config()
  assert_eq(config.max_skip_frames, 5)
  assert_eq(config.enable_vsync, true)
  assert_eq(config.clear_screen_every_frame, true)
}

///|
test "default_runtime_hooks creates no-op hooks" {
  let hooks = default_runtime_hooks()
  // Should not panic when called
  (hooks.on_input_captured)(0, @core.empty_input_snapshot())
  (hooks.on_post_update)(0, @core.new_frame_budget(0, 0.0, 0))
}

///|
test "new_runtime_hooks_full wires both callbacks" {
  let captured_ticks : Array[Int] = []
  let post_update_ticks : Array[Int] = []
  let hooks = new_runtime_hooks_full(
    fn(tick, _input) { captured_ticks.push(tick) },
    fn(tick, _frame) { post_update_ticks.push(tick) },
  )
  (hooks.on_input_captured)(5, @core.empty_input_snapshot())
  (hooks.on_post_update)(7, @core.new_frame_budget(1, 0.5, 7))
  assert_eq(captured_ticks.length(), 1)
  assert_eq(captured_ticks[0], 5)
  assert_eq(post_update_ticks.length(), 1)
  assert_eq(post_update_ticks[0], 7)
}

///|
test "clear_input_edge_history empties history" {
  let observer = new_input_edge_observer_state(10)
  let _ = observe_input_edge(observer, 1, @core.empty_input_snapshot())
  let _ = observe_input_edge(observer, 2, @core.empty_input_snapshot())
  let before = append_input_edge_history(observer, [])
  assert_eq(before.length(), 2)
  clear_input_edge_history(observer)
  let after = append_input_edge_history(observer, [])
  assert_eq(after.length(), 0)
}

///|
test "plan_frame with small elapsed produces zero updates" {
  // 5ms is less than 1 tick (16.6ms at 60fps), so updates=0 but alpha>0
  let state = @core.initial_fixed_step_state()
  let config = @core.default_fixed_step_config()
  let step = @core.step_fixed_timestep(state, 5.0, config)
  let plan = plan_frame(step, 5)
  assert_eq(plan.updates, 0)
  // alpha > 0 from remainder, so should_draw = true
  assert_eq(plan.should_draw, true)
}

///|
test "plan_frame with zero elapsed does not draw" {
  let state = @core.initial_fixed_step_state()
  let config = @core.default_fixed_step_config()
  let step = @core.step_fixed_timestep(state, 0.0, config)
  let plan = plan_frame(step, 5)
  assert_eq(plan.updates, 0)
  assert_eq(plan.should_draw, false)
}
