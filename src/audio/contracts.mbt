///|
/// Audio subsystem contracts.
///
/// Reference:
/// - Ebiten audio package (Context, Player, stream)
/// - Web Audio API / native audio backends

///|
pub struct AudioFormat {
  sample_rate : Int
  channels : Int
  bits_per_sample : Int
} derive(Show)

///|
pub fn default_audio_format() -> AudioFormat {
  { sample_rate: 44100, channels: 2, bits_per_sample: 16 }
}

///|
pub fn cd_quality_format() -> AudioFormat {
  { sample_rate: 44100, channels: 2, bits_per_sample: 16 }
}

///|
pub fn mono_format(sample_rate : Int) -> AudioFormat {
  { sample_rate, channels: 1, bits_per_sample: 16 }
}

///|
pub fn bytes_per_sample(format : AudioFormat) -> Int {
  format.bits_per_sample / 8 * format.channels
}

///|
pub fn samples_to_bytes(format : AudioFormat, sample_count : Int) -> Int {
  sample_count * bytes_per_sample(format)
}

///|
pub fn bytes_to_samples(format : AudioFormat, byte_count : Int) -> Int {
  let bps = bytes_per_sample(format)
  if bps <= 0 {
    0
  } else {
    byte_count / bps
  }
}

///|
pub fn duration_to_samples(format : AudioFormat, seconds : Double) -> Int {
  (format.sample_rate.to_double() * seconds).to_int()
}

///|
pub fn samples_to_duration(format : AudioFormat, sample_count : Int) -> Double {
  if format.sample_rate <= 0 {
    0.0
  } else {
    sample_count.to_double() / format.sample_rate.to_double()
  }
}

///|
pub enum PlayerState {
  Stopped
  Playing
  Paused
} derive(Show)

///|
pub struct PlayerId {
  value : Int
} derive(Show)

///|
pub struct AudioClip {
  format : AudioFormat
  data : Bytes
  loop_ : Bool
} derive(Show)

///|
pub fn new_audio_clip(
  format : AudioFormat,
  data : Bytes,
  loop_ : Bool,
) -> AudioClip {
  { format, data, loop_ }
}

///|
pub fn clip_sample_count(clip : AudioClip) -> Int {
  bytes_to_samples(clip.format, clip.data.length())
}

///|
pub fn clip_duration(clip : AudioClip) -> Double {
  samples_to_duration(clip.format, clip_sample_count(clip))
}

///|
pub trait AudioStream {
  /// Read PCM samples into the buffer. Returns number of bytes read.
  read(Self, buf : FixedArray[Byte], length : Int) -> Int
  /// Total length in bytes, or -1 if unknown (e.g., streaming).
  content_length(Self) -> Int
}

///|
pub trait AudioContext {
  /// Create a player for the given clip.
  create_player(Self, clip : AudioClip) -> PlayerId raise
  /// Start playback.
  play(Self, id : PlayerId) -> Unit raise
  /// Pause playback.
  pause(Self, id : PlayerId) -> Unit raise
  /// Stop and rewind.
  stop(Self, id : PlayerId) -> Unit raise
  /// Get current state.
  state(Self, id : PlayerId) -> PlayerState
  /// Set volume (0.0 to 1.0).
  set_volume(Self, id : PlayerId, volume : Double) -> Unit
  /// Get current playback position in seconds.
  current_position(Self, id : PlayerId) -> Double
  /// Seek to position in seconds.
  seek(Self, id : PlayerId, position : Double) -> Unit raise
  /// Dispose player.
  dispose(Self, id : PlayerId) -> Unit
}

///|
pub struct SimpleAudioPlayer {
  id : PlayerId
  clip : AudioClip
  mut state : PlayerState
  mut volume : Double
  mut position_samples : Int
}

///|
pub struct SimpleAudioContext {
  mut players : Array[SimpleAudioPlayer]
  mut next_id : Int
  format : AudioFormat
}

///|
pub fn SimpleAudioContext::new(format : AudioFormat) -> SimpleAudioContext {
  { players: [], next_id: 1, format }
}

///|
fn SimpleAudioContext::find_player(
  self : SimpleAudioContext,
  id : PlayerId,
) -> SimpleAudioPlayer? {
  for player in self.players {
    if player.id.value == id.value {
      return Some(player)
    }
  }
  None
}

///|
pub impl AudioContext for SimpleAudioContext with create_player(self, clip) {
  let id : PlayerId = { value: self.next_id }
  self.next_id = self.next_id + 1
  self.players.push({
    id,
    clip,
    state: PlayerState::Stopped,
    volume: 1.0,
    position_samples: 0,
  })
  id
}

///|
pub impl AudioContext for SimpleAudioContext with play(self, id) {
  match self.find_player(id) {
    Some(player) => player.state = PlayerState::Playing
    None => ()
  }
}

///|
pub impl AudioContext for SimpleAudioContext with pause(self, id) {
  match self.find_player(id) {
    Some(player) => player.state = PlayerState::Paused
    None => ()
  }
}

///|
pub impl AudioContext for SimpleAudioContext with stop(self, id) {
  match self.find_player(id) {
    Some(player) => {
      player.state = PlayerState::Stopped
      player.position_samples = 0
    }
    None => ()
  }
}

///|
pub impl AudioContext for SimpleAudioContext with state(self, id) {
  match self.find_player(id) {
    Some(player) => player.state
    None => PlayerState::Stopped
  }
}

///|
pub impl AudioContext for SimpleAudioContext with set_volume(self, id, volume) {
  match self.find_player(id) {
    Some(player) =>
      player.volume = if volume < 0.0 {
        0.0
      } else if volume > 1.0 {
        1.0
      } else {
        volume
      }
    None => ()
  }
}

///|
pub impl AudioContext for SimpleAudioContext with current_position(self, id) {
  match self.find_player(id) {
    Some(player) =>
      samples_to_duration(player.clip.format, player.position_samples)
    None => 0.0
  }
}

///|
pub impl AudioContext for SimpleAudioContext with seek(self, id, position) {
  match self.find_player(id) {
    Some(player) =>
      player.position_samples = duration_to_samples(
        player.clip.format,
        position,
      )
    None => ()
  }
}

///|
pub impl AudioContext for SimpleAudioContext with dispose(self, id) {
  self.players = self.players.filter(fn(p) { p.id.value != id.value })
}

///|
/// Advance all playing players by the given number of samples.
pub fn SimpleAudioContext::tick(
  self : SimpleAudioContext,
  samples : Int,
) -> Unit {
  for player in self.players {
    match player.state {
      PlayerState::Playing => {
        player.position_samples = player.position_samples + samples
        let total = clip_sample_count(player.clip)
        if player.position_samples >= total {
          if player.clip.loop_ {
            player.position_samples = player.position_samples % total
          } else {
            player.position_samples = total
            player.state = PlayerState::Stopped
          }
        }
      }
      _ => ()
    }
  }
}

///|
pub fn SimpleAudioContext::player_count(self : SimpleAudioContext) -> Int {
  self.players.length()
}

///|
/// Convert a mizchi/audio AudioBuffer to an AudioClip.
/// Converts Float samples to 16-bit PCM Bytes.
pub fn audio_buffer_to_clip(
  buffer : @ma.AudioBuffer,
  loop_ : Bool,
) -> AudioClip {
  let format : AudioFormat = {
    sample_rate: buffer.sample_rate,
    channels: buffer.channels,
    bits_per_sample: 16,
  }
  let sample_count = @ma.frame_count(buffer) * buffer.channels
  let bytes_arr : Array[Byte] = []
  for i = 0; i < sample_count; i = i + 1 {
    let frame = i / buffer.channels
    let ch = i % buffer.channels
    let sample = @ma.get_sample(buffer, frame, ch)
    // Clamp to [-1.0, 1.0] and convert to 16-bit signed
    let clamped : Float = if sample < -1.0 {
      -1.0
    } else if sample > 1.0 {
      1.0
    } else {
      sample
    }
    let i16_val = (clamped * 32767.0).to_int()
    bytes_arr.push((i16_val & 0xFF).to_byte())
    bytes_arr.push(((i16_val >> 8) & 0xFF).to_byte())
  }
  let data = Bytes::from_array(bytes_arr)
  new_audio_clip(format, data, loop_)
}

///|
/// Decode WAV bytes into an AudioClip.
pub fn decode_wav_clip(
  wav_bytes : Bytes,
  loop_ : Bool,
) -> AudioClip raise @ma.AudioError {
  let buffer = @ma.decode_wav(wav_bytes)
  audio_buffer_to_clip(buffer, loop_)
}

///|
/// Decode OGG/Vorbis bytes into an AudioClip.
pub fn decode_ogg_clip(
  ogg_bytes : Bytes,
  loop_ : Bool,
) -> AudioClip raise @ma.AudioError {
  let buffer = @ma.decode_ogg(ogg_bytes)
  audio_buffer_to_clip(buffer, loop_)
}

///|
/// Detect audio format from magic bytes.
/// Returns "wav", "ogg", or empty string if unknown.
pub fn detect_audio_format(data : Bytes) -> String {
  if data.length() >= 4 {
    if data[0] == b'R' && data[1] == b'I' && data[2] == b'F' && data[3] == b'F' {
      return "wav"
    }
    if data[0] == b'O' && data[1] == b'g' && data[2] == b'g' && data[3] == b'S' {
      return "ogg"
    }
  }
  ""
}

///|
/// Detect audio format from bytes and decode accordingly.
/// Returns None if format is not recognized.
pub fn decode_audio_clip_auto(
  data : Bytes,
  loop_ : Bool,
) -> AudioClip? raise @ma.AudioError {
  match detect_audio_format(data) {
    "wav" => Some(decode_wav_clip(data, loop_))
    "ogg" => Some(decode_ogg_clip(data, loop_))
    _ => None
  }
}

///|
/// Convert an AudioClip back to a mizchi/audio AudioBuffer.
/// Assumes 16-bit PCM format.
pub fn clip_to_audio_buffer(clip : AudioClip) -> @ma.AudioBuffer {
  let frames = clip_sample_count(clip)
  let buffer = @ma.new_audio_buffer(
    clip.format.channels,
    clip.format.sample_rate,
    frames,
  )
  let channels = clip.format.channels
  for frame = 0; frame < frames; frame = frame + 1 {
    for ch = 0; ch < channels; ch = ch + 1 {
      let byte_offset = (frame * channels + ch) * 2
      let lo = clip.data[byte_offset].to_int()
      let hi = clip.data[byte_offset + 1].to_int()
      let i16_val = lo | (hi << 8)
      // Sign extend 16-bit
      let signed_val = if i16_val >= 32768 { i16_val - 65536 } else { i16_val }
      let sample = signed_val.to_float() / 32767.0
      @ma.set_sample(buffer, frame, ch, sample)
    }
  }
  buffer
}

///|
/// Stream that reads sequentially from an AudioClip.
pub struct AudioClipStream {
  clip : AudioClip
  mut position : Int
}

///|
pub fn AudioClipStream::new(clip : AudioClip) -> AudioClipStream {
  { clip, position: 0 }
}

///|
pub fn AudioClipStream::reset(self : AudioClipStream) -> Unit {
  self.position = 0
}

///|
pub fn AudioClipStream::remaining(self : AudioClipStream) -> Int {
  self.clip.data.length() - self.position
}

///|
pub impl AudioStream for AudioClipStream with read(self, buf, length) {
  let available = self.clip.data.length() - self.position
  let to_read = if length < available { length } else { available }
  if to_read > buf.length() {
    let actual = buf.length()
    for i = 0; i < actual; i = i + 1 {
      buf[i] = self.clip.data[self.position + i]
    }
    self.position = self.position + actual
    return actual
  }
  for i = 0; i < to_read; i = i + 1 {
    buf[i] = self.clip.data[self.position + i]
  }
  self.position = self.position + to_read
  to_read
}

///|
pub impl AudioStream for AudioClipStream with content_length(self) {
  self.clip.data.length()
}

///|
/// Buffered stream that accumulates audio data chunks progressively.
/// Useful for network streaming or progressive decoding.
pub struct BufferedAudioStream {
  chunks : Array[Bytes]
  mut total_bytes : Int
  mut read_chunk_idx : Int
  mut read_byte_idx : Int
  mut finalized : Bool
  mut final_length : Int
}

///|
pub fn BufferedAudioStream::new() -> BufferedAudioStream {
  {
    chunks: [],
    total_bytes: 0,
    read_chunk_idx: 0,
    read_byte_idx: 0,
    finalized: false,
    final_length: -1,
  }
}

///|
/// Append a data chunk to the stream buffer.
pub fn BufferedAudioStream::push_chunk(
  self : BufferedAudioStream,
  data : Bytes,
) -> Unit {
  self.total_bytes = self.total_bytes + data.length()
  self.chunks.push(data)
}

///|
/// Mark the stream as complete with known total length.
pub fn BufferedAudioStream::finalize(self : BufferedAudioStream) -> Unit {
  self.finalized = true
  self.final_length = self.total_bytes
}

///|
/// Check if more data is available to read.
pub fn BufferedAudioStream::has_data(self : BufferedAudioStream) -> Bool {
  self.buffered_bytes() > 0
}

///|
/// Get the number of bytes available for reading.
pub fn BufferedAudioStream::buffered_bytes(self : BufferedAudioStream) -> Int {
  let mut read_pos = 0
  for i = 0; i < self.read_chunk_idx; i = i + 1 {
    read_pos = read_pos + self.chunks[i].length()
  }
  read_pos = read_pos + self.read_byte_idx
  self.total_bytes - read_pos
}

///|
pub fn BufferedAudioStream::is_finalized(self : BufferedAudioStream) -> Bool {
  self.finalized
}

///|
pub fn BufferedAudioStream::reset(self : BufferedAudioStream) -> Unit {
  self.read_chunk_idx = 0
  self.read_byte_idx = 0
}

///|
pub impl AudioStream for BufferedAudioStream with read(self, buf, length) {
  let mut written = 0
  let to_read = if length < buf.length() { length } else { buf.length() }
  while written < to_read && self.read_chunk_idx < self.chunks.length() {
    let chunk = self.chunks[self.read_chunk_idx]
    let chunk_remaining = chunk.length() - self.read_byte_idx
    let need = to_read - written
    let take = if need < chunk_remaining { need } else { chunk_remaining }
    for i = 0; i < take; i = i + 1 {
      buf[written + i] = chunk[self.read_byte_idx + i]
    }
    written = written + take
    self.read_byte_idx = self.read_byte_idx + take
    if self.read_byte_idx >= chunk.length() {
      self.read_chunk_idx = self.read_chunk_idx + 1
      self.read_byte_idx = 0
    }
  }
  written
}

///|
pub impl AudioStream for BufferedAudioStream with content_length(self) {
  if self.finalized {
    self.final_length
  } else {
    -1
  }
}

///|
/// MixerAudioContext wraps mizchi/audio's Mixer to implement AudioContext.
pub struct MixerAudioContext {
  mixer : @ma.Mixer
  mut player_map : Array[(PlayerId, @ma.VoiceId)]
  mut next_id : Int
}

///|
pub fn MixerAudioContext::new(sample_rate : Int) -> MixerAudioContext {
  { mixer: @ma.new_mixer(sample_rate), player_map: [], next_id: 1 }
}

///|
fn MixerAudioContext::find_voice_id(
  self : MixerAudioContext,
  id : PlayerId,
) -> @ma.VoiceId? {
  for pair in self.player_map {
    let (pid, vid) = pair
    if pid.value == id.value {
      return Some(vid)
    }
  }
  None
}

///|
pub impl AudioContext for MixerAudioContext with create_player(self, clip) {
  let buffer = clip_to_audio_buffer(clip)
  let voice = @ma.new_voice_from_buffer(self.mixer, buffer, looping=clip.loop_)
  let voice_id = @ma.add_voice(self.mixer, voice)
  // Stop immediately - AudioContext contract expects Stopped initial state
  let _ = @ma.stop_voice(self.mixer, voice_id)
  let player_id : PlayerId = { value: self.next_id }
  self.next_id = self.next_id + 1
  self.player_map.push((player_id, voice_id))
  player_id
}

///|
pub impl AudioContext for MixerAudioContext with play(self, id) {
  match self.find_voice_id(id) {
    Some(vid) => {
      let _ = @ma.resume_voice(self.mixer, vid)
    }
    None => ()
  }
}

///|
pub impl AudioContext for MixerAudioContext with pause(self, id) {
  match self.find_voice_id(id) {
    Some(vid) => {
      let _ = @ma.pause_voice(self.mixer, vid)
    }
    None => ()
  }
}

///|
pub impl AudioContext for MixerAudioContext with stop(self, id) {
  match self.find_voice_id(id) {
    Some(vid) => {
      let _ = @ma.stop_voice(self.mixer, vid)
    }
    None => ()
  }
}

///|
pub impl AudioContext for MixerAudioContext with state(self, id) {
  match self.find_voice_id(id) {
    Some(vid) =>
      match @ma.voice_state(self.mixer, vid) {
        Some(@ma.VoiceState::Playing) => PlayerState::Playing
        Some(@ma.VoiceState::Paused) => PlayerState::Paused
        _ => PlayerState::Stopped
      }
    None => PlayerState::Stopped
  }
}

///|
pub impl AudioContext for MixerAudioContext with set_volume(self, id, volume) {
  match self.find_voice_id(id) {
    Some(vid) =>
      match @ma.find_voice(self.mixer, vid) {
        Some(voice) => {
          let clamped = if volume < 0.0 {
            0.0
          } else if volume > 1.0 {
            1.0
          } else {
            volume
          }
          voice.gain = clamped.to_float()
        }
        None => ()
      }
    None => ()
  }
}

///|
pub impl AudioContext for MixerAudioContext with current_position(self, id) {
  match self.find_voice_id(id) {
    Some(vid) =>
      match @ma.voice_position(self.mixer, vid) {
        Some(pos) => pos.to_double()
        None => 0.0
      }
    None => 0.0
  }
}

///|
pub impl AudioContext for MixerAudioContext with seek(self, id, position) {
  match self.find_voice_id(id) {
    Some(vid) =>
      match @ma.find_voice(self.mixer, vid) {
        Some(voice) => {
          let frame = (position * voice.sample_rate.to_double()).to_int()
          let _ = @ma.seek_voice(self.mixer, vid, frame)
        }
        None => ()
      }
    None => ()
  }
}

///|
pub impl AudioContext for MixerAudioContext with dispose(self, id) {
  match self.find_voice_id(id) {
    Some(vid) => {
      let _ = @ma.stop_voice(self.mixer, vid)
      self.player_map = self.player_map.filter(fn(pair) {
        let (pid, _) = pair
        pid.value != id.value
      })
    }
    None => ()
  }
}

///|
/// Render audio frames into an output buffer.
pub fn MixerAudioContext::render(
  self : MixerAudioContext,
  frames : Int,
  output : FixedArray[Float],
) -> Unit {
  @ma.tick(self.mixer, frames, output)
  @ma.collect_stopped(self.mixer)
}

///|
/// Audio output hooks for backend integration (Web Audio API / native audio).
pub struct AudioOutputHooks {
  /// Initialize the audio output device with the given format. Returns true on success.
  try_initialize : (AudioFormat) -> Bool
  /// Write PCM frames to the output device. Returns number of frames written.
  write_frames : (FixedArray[Float], Int) -> Int
  /// Suspend audio output (e.g., tab hidden, app backgrounded).
  suspend : () -> Unit
  /// Resume audio output after suspend.
  resume : () -> Unit
  /// Close the audio output device and release resources.
  close : () -> Unit
  /// Query the actual output latency in seconds. Returns 0.0 if unknown.
  output_latency : () -> Double
}

///|
pub fn new_audio_output_hooks(
  try_initialize : (AudioFormat) -> Bool,
  write_frames : (FixedArray[Float], Int) -> Int,
  suspend : () -> Unit,
  resume : () -> Unit,
  close : () -> Unit,
) -> AudioOutputHooks {
  {
    try_initialize,
    write_frames,
    suspend,
    resume,
    close,
    output_latency: default_audio_output_latency,
  }
}

///|
pub fn new_audio_output_hooks_full(
  try_initialize : (AudioFormat) -> Bool,
  write_frames : (FixedArray[Float], Int) -> Int,
  suspend : () -> Unit,
  resume : () -> Unit,
  close : () -> Unit,
  output_latency : () -> Double,
) -> AudioOutputHooks {
  { try_initialize, write_frames, suspend, resume, close, output_latency }
}

///|
fn default_audio_try_initialize(_format : AudioFormat) -> Bool {
  false
}

///|
fn default_audio_write_frames(
  _output : FixedArray[Float],
  _frames : Int,
) -> Int {
  0
}

///|
fn default_audio_suspend() -> Unit {
  ()
}

///|
fn default_audio_resume() -> Unit {
  ()
}

///|
fn default_audio_close() -> Unit {
  ()
}

///|
fn default_audio_output_latency() -> Double {
  0.0
}

///|
fn default_audio_output_hooks() -> AudioOutputHooks {
  new_audio_output_hooks(
    default_audio_try_initialize, default_audio_write_frames, default_audio_suspend,
    default_audio_resume, default_audio_close,
  )
}

///|
let audio_output_hooks : Ref[AudioOutputHooks] = Ref::new(
  default_audio_output_hooks(),
)

///|
pub fn set_audio_output_hooks(hooks : AudioOutputHooks) -> Unit {
  audio_output_hooks.val = hooks
}

///|
pub fn reset_audio_output_hooks() -> Unit {
  audio_output_hooks.val = default_audio_output_hooks()
}

///|
pub fn audio_try_initialize(format : AudioFormat) -> Bool {
  (audio_output_hooks.val.try_initialize)(format)
}

///|
pub fn audio_write_frames(output : FixedArray[Float], frames : Int) -> Int {
  (audio_output_hooks.val.write_frames)(output, frames)
}

///|
pub fn audio_suspend() -> Unit {
  (audio_output_hooks.val.suspend)()
}

///|
pub fn audio_resume() -> Unit {
  (audio_output_hooks.val.resume)()
}

///|
pub fn audio_close() -> Unit {
  (audio_output_hooks.val.close)()
}

///|
pub fn audio_output_latency() -> Double {
  (audio_output_hooks.val.output_latency)()
}

///|
pub struct AudioOutputStats {
  initialized : Bool
  frames_written : Int
  suspended : Bool
} derive(Show)

///|
/// Render audio from a MixerAudioContext and write to output hooks.
/// Returns the number of frames actually written.
pub fn audio_render_and_write(mixer : MixerAudioContext, frames : Int) -> Int {
  let channels = 2 // stereo
  let buf : FixedArray[Float] = FixedArray::make(frames * channels, 0.0)
  mixer.render(frames, buf)
  audio_write_frames(buf, frames)
}

///|
/// Create default AudioOutputStats.
pub fn default_audio_output_stats() -> AudioOutputStats {
  { initialized: false, frames_written: 0, suspended: false }
}

///|
/// Create a tracked AudioOutputHooks wrapper that updates stats.
pub fn new_tracked_audio_output_hooks(
  inner : AudioOutputHooks,
  stats : Ref[AudioOutputStats],
) -> AudioOutputHooks {
  {
    try_initialize: fn(fmt) {
      let ok = (inner.try_initialize)(fmt)
      if ok {
        stats.val = { ..stats.val, initialized: true }
      }
      ok
    },
    write_frames: fn(output, frames) {
      let written = (inner.write_frames)(output, frames)
      stats.val = {
        ..stats.val,
        frames_written: stats.val.frames_written + written,
      }
      written
    },
    suspend: fn() {
      (inner.suspend)()
      stats.val = { ..stats.val, suspended: true }
    },
    resume: fn() {
      (inner.resume)()
      stats.val = { ..stats.val, suspended: false }
    },
    close: inner.close,
    output_latency: inner.output_latency,
  }
}
