#![no_std]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// --- Constants ---

const SCREEN_W: i32 = 320;
const SCREEN_H: i32 = 240;
const BIRD_X: f64 = 60.0;
const BIRD_SIZE: f64 = 12.0;
const GRAVITY: f64 = 0.25;
const JUMP_VELOCITY: f64 = -4.5;
const PIPE_WIDTH: f64 = 36.0;
const PIPE_GAP: f64 = 70.0;
const PIPE_SPEED: f64 = 1.5;
const PIPE_INTERVAL: i32 = 120;
const GROUND_H: f64 = 20.0;
const KEY_SPACE: i32 = 32;
const KEY_UP: i32 = 38;
const MAX_PIPES: usize = 16;

// --- Bump Allocator (static, not address-0) ---

static mut BUMP_OFFSET: usize = 0;
// Reserve 8KB for statics, start heap after that
const HEAP_BASE: usize = 8192;

unsafe fn bump_alloc(size: usize) -> *mut u8 {
    let ptr = BUMP_OFFSET;
    BUMP_OFFSET = ptr + size;
    ptr as *mut u8
}

unsafe fn bump_reset() {
    BUMP_OFFSET = HEAP_BASE;
}

// --- Direct memory helpers ---

unsafe fn write_i32_at(ptr: *mut u8, val: i32) {
    (ptr as *mut i32).write_unaligned(val);
}

unsafe fn write_f32_at(ptr: *mut u8, val: f32) {
    (ptr as *mut f32).write_unaligned(val);
}

unsafe fn read_i32_at(ptr: *const u8) -> i32 {
    (ptr as *const i32).read_unaligned()
}

unsafe fn read_f64_at(ptr: *const u8) -> f64 {
    (ptr as *const f64).read_unaligned()
}

// --- Game State ---

#[derive(Clone, Copy)]
struct Pipe {
    x: f64,
    gap_y: f64,
}

static mut GAME: Game = Game {
    game_mode: 0,
    score: 0,
    bird_y: (SCREEN_H as f64) / 2.0,
    velocity: 0.0,
    frame_count: 0,
    pipe_timer: 0,
    pipe_count: 0,
    pipes: [Pipe { x: 0.0, gap_y: 0.0 }; MAX_PIPES],
    prev_action: false,
};

struct Game {
    game_mode: i32,
    score: i32,
    bird_y: f64,
    velocity: f64,
    frame_count: i32,
    pipe_timer: i32,
    pipe_count: usize,
    pipes: [Pipe; MAX_PIPES],
    prev_action: bool,
}

fn pseudo_random(seed: i32) -> f64 {
    let x = seed.wrapping_mul(1103515245).wrapping_add(12345);
    ((x >> 16) & 0x7FFF) as f64 / 32767.0
}

// --- Input ---

struct InputState {
    keys: [i32; 16],
    key_count: usize,
    mouse_btn_count: usize,
}

unsafe fn read_input(ptr: *const u8) -> InputState {
    // Skip cursor_x(f64), cursor_y(f64), wheel_x(f64), wheel_y(f64) = 32 bytes
    let _ = read_f64_at(ptr);
    let key_count = read_i32_at(ptr.add(32)) as usize;
    let mut keys = [0i32; 16];
    let kc = if key_count > 16 { 16 } else { key_count };
    for i in 0..kc {
        keys[i] = read_i32_at(ptr.add(36 + i * 4));
    }
    let mouse_offset = 36 + key_count * 4;
    let mouse_btn_count = read_i32_at(ptr.add(mouse_offset)) as usize;
    InputState {
        keys,
        key_count: kc,
        mouse_btn_count,
    }
}

fn is_key_pressed(input: &InputState, key_code: i32) -> bool {
    for i in 0..input.key_count {
        if input.keys[i] == key_code {
            return true;
        }
    }
    false
}

// --- Draw ---

fn rect_cmd_vertices(x: f64, y: f64, w: f64, h: f64, sw: f64, sh: f64) -> [f32; 16] {
    let x0 = (x / sw * 2.0 - 1.0) as f32;
    let y0 = (1.0 - y / sh * 2.0) as f32;
    let x1 = ((x + w) / sw * 2.0 - 1.0) as f32;
    let y1 = (1.0 - (y + h) / sh * 2.0) as f32;
    [
        x0, y0, 0.0, 0.0, // top-left
        x1, y0, 1.0, 0.0, // top-right
        x1, y1, 1.0, 1.0, // bottom-right
        x0, y1, 0.0, 1.0, // bottom-left
    ]
}

const CMD_SIZE: usize = 28 + 16 * 4 + 6 * 4; // header + 4 verts * 4 floats + 6 indices

unsafe fn write_rect(x: f64, y: f64, w: f64, h: f64, sw: f64, sh: f64, fill: i32, alpha: i32) {
    let verts = rect_cmd_vertices(x, y, w, h, sw, sh);
    let r = (fill >> 16) & 0xFF;
    let g = (fill >> 8) & 0xFF;
    let b = fill & 0xFF;
    let p = bump_alloc(CMD_SIZE);
    write_i32_at(p, 4); // vertex_count
    write_i32_at(p.add(4), 6); // index_count
    write_i32_at(p.add(8), 0); // src_image_id
    write_i32_at(p.add(12), r);
    write_i32_at(p.add(16), g);
    write_i32_at(p.add(20), b);
    write_i32_at(p.add(24), alpha);
    for i in 0..16 {
        write_f32_at(p.add(28 + i * 4), verts[i]);
    }
    let idx_base = 28 + 16 * 4;
    let indices: [i32; 6] = [0, 1, 2, 0, 2, 3];
    for i in 0..6 {
        write_i32_at(p.add(idx_base + i * 4), indices[i]);
    }
}

// --- Game Logic ---

impl Game {
    fn reset(&mut self) {
        self.bird_y = (SCREEN_H as f64) / 2.0;
        self.velocity = 0.0;
        self.game_mode = 0;
        self.score = 0;
        self.pipe_count = 0;
        self.pipe_timer = 0;
    }

    fn update(&mut self, input: &InputState) {
        self.frame_count += 1;
        let current_action = is_key_pressed(input, KEY_SPACE)
            || is_key_pressed(input, KEY_UP)
            || input.mouse_btn_count > 0;
        let action = current_action && !self.prev_action;
        self.prev_action = current_action;

        match self.game_mode {
            0 => {
                if action {
                    self.game_mode = 1;
                    self.velocity = JUMP_VELOCITY;
                }
            }
            1 => {
                self.velocity += GRAVITY;
                self.bird_y += self.velocity;
                if action {
                    self.velocity = JUMP_VELOCITY;
                }
                self.pipe_timer += 1;
                if self.pipe_timer >= PIPE_INTERVAL && self.pipe_count < MAX_PIPES {
                    self.pipe_timer = 0;
                    let sh = SCREEN_H as f64;
                    let min_gap_y = 40.0;
                    let max_gap_y = sh - GROUND_H - PIPE_GAP - 40.0;
                    let gap_y =
                        min_gap_y + pseudo_random(self.frame_count) * (max_gap_y - min_gap_y);
                    self.pipes[self.pipe_count] = Pipe {
                        x: SCREEN_W as f64,
                        gap_y,
                    };
                    self.pipe_count += 1;
                }
                for i in 0..self.pipe_count {
                    let old_x = self.pipes[i].x;
                    self.pipes[i].x -= PIPE_SPEED;
                    let pr = old_x + PIPE_WIDTH;
                    let pr_new = self.pipes[i].x + PIPE_WIDTH;
                    if pr >= BIRD_X && pr_new < BIRD_X {
                        self.score += 1;
                    }
                }
                let mut write = 0;
                for read in 0..self.pipe_count {
                    if self.pipes[read].x + PIPE_WIDTH > 0.0 {
                        self.pipes[write] = self.pipes[read];
                        write += 1;
                    }
                }
                self.pipe_count = write;
                let ground_top = SCREEN_H as f64 - GROUND_H;
                if self.bird_y + BIRD_SIZE > ground_top || self.bird_y < 0.0 {
                    self.game_mode = 2;
                }
                for i in 0..self.pipe_count {
                    let pipe = &self.pipes[i];
                    let bird_right = BIRD_X + BIRD_SIZE;
                    let bird_bottom = self.bird_y + BIRD_SIZE;
                    let pipe_right = pipe.x + PIPE_WIDTH;
                    if bird_right > pipe.x && BIRD_X < pipe_right {
                        let gap_bottom = pipe.gap_y + PIPE_GAP;
                        if self.bird_y < pipe.gap_y || bird_bottom > gap_bottom {
                            self.game_mode = 2;
                        }
                    }
                }
            }
            _ => {
                if action {
                    self.reset();
                }
            }
        }
    }
}

// --- WASM Exports ---

#[no_mangle]
pub extern "C" fn kagura_init() -> i32 {
    unsafe {
        bump_reset();
        let ptr = bump_alloc(64);
        write_i32_at(ptr, SCREEN_W);
        write_i32_at(ptr.add(4), SCREEN_H);
        let title = b"Flappy Bird (Rust)";
        write_i32_at(ptr.add(8), title.len() as i32);
        core::ptr::copy_nonoverlapping(title.as_ptr(), ptr.add(12), title.len());
        ptr as i32
    }
}

#[no_mangle]
pub extern "C" fn kagura_alloc(size: i32) -> i32 {
    unsafe { bump_alloc(size as usize) as i32 }
}

#[no_mangle]
pub extern "C" fn kagura_update(ptr: i32, _len: i32) {
    unsafe {
        let input = read_input(ptr as *const u8);
        GAME.update(&input);
    }
}

#[no_mangle]
pub extern "C" fn kagura_draw() -> i32 {
    unsafe {
        bump_reset();
        let sw = SCREEN_W as f64;
        let sh = SCREEN_H as f64;
        let ground_y = sh - GROUND_H;

        // Count commands
        let mut cmd_count: i32 = 3; // sky + ground + bird
        for i in 0..GAME.pipe_count {
            let pipe = &GAME.pipes[i];
            if pipe.gap_y > 0.0 {
                cmd_count += 1;
            }
            if ground_y - (pipe.gap_y + PIPE_GAP) > 0.0 {
                cmd_count += 1;
            }
        }
        if GAME.game_mode == 2 {
            cmd_count += 1;
        }

        let header = bump_alloc(4);
        write_i32_at(header, cmd_count);

        // Sky
        write_rect(0.0, 0.0, sw, sh, sw, sh, 0x87CEEB, 255);
        // Ground
        write_rect(0.0, ground_y, sw, GROUND_H, sw, sh, 0x8B4513, 255);
        // Pipes
        for i in 0..GAME.pipe_count {
            let pipe = &GAME.pipes[i];
            if pipe.gap_y > 0.0 {
                write_rect(pipe.x, 0.0, PIPE_WIDTH, pipe.gap_y, sw, sh, 0x228B22, 255);
            }
            let lower_y = pipe.gap_y + PIPE_GAP;
            let lower_h = ground_y - lower_y;
            if lower_h > 0.0 {
                write_rect(pipe.x, lower_y, PIPE_WIDTH, lower_h, sw, sh, 0x228B22, 255);
            }
        }
        // Bird
        write_rect(
            BIRD_X,
            GAME.bird_y,
            BIRD_SIZE,
            BIRD_SIZE,
            sw,
            sh,
            0xFFD700,
            255,
        );
        // Game over overlay
        if GAME.game_mode == 2 {
            write_rect(
                sw / 2.0 - 50.0,
                sh / 2.0 - 20.0,
                100.0,
                40.0,
                sw,
                sh,
                0x000000,
                128,
            );
        }

        header as i32
    }
}
