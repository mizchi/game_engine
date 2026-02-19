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
fn find_player(
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
  self.players.push(
    { id, clip, state: PlayerState::Stopped, volume: 1.0, position_samples: 0 },
  )
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
    Some(player) => samples_to_duration(player.clip.format, player.position_samples)
    None => 0.0
  }
}

///|
pub impl AudioContext for SimpleAudioContext with seek(self, id, position) {
  match self.find_player(id) {
    Some(player) =>
      player.position_samples = duration_to_samples(player.clip.format, position)
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
  let buffer = @ma.new_audio_buffer(clip.format.channels, clip.format.sample_rate, frames)
  let channels = clip.format.channels
  for frame = 0; frame < frames; frame = frame + 1 {
    for ch = 0; ch < channels; ch = ch + 1 {
      let byte_offset = (frame * channels + ch) * 2
      let lo = clip.data[byte_offset].to_int()
      let hi = clip.data[byte_offset + 1].to_int()
      let i16_val = lo | (hi << 8)
      // Sign extend 16-bit
      let signed_val = if i16_val >= 32768 {
        i16_val - 65536
      } else {
        i16_val
      }
      let sample = signed_val.to_float() / 32767.0
      @ma.set_sample(buffer, frame, ch, sample)
    }
  }
  buffer
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
  let voice = @ma.new_voice_from_buffer(
    self.mixer,
    buffer,
    looping=clip.loop_,
  )
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
    Some(vid) => {
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
    Some(vid) => {
      match @ma.find_voice(self.mixer, vid) {
        Some(voice) => {
          let frame = (position * voice.sample_rate.to_double()).to_int()
          let _ = @ma.seek_voice(self.mixer, vid, frame)
        }
        None => ()
      }
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
