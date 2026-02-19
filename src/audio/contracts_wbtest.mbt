///|
fn approx(a : Double, b : Double) -> Bool {
  (a - b).abs() < 0.01
}

///|
test "default_audio_format" {
  let fmt = default_audio_format()
  assert_eq!(fmt.sample_rate, 44100)
  assert_eq!(fmt.channels, 2)
  assert_eq!(fmt.bits_per_sample, 16)
}

///|
test "bytes_per_sample" {
  let fmt = default_audio_format()
  // 16-bit stereo = 4 bytes per sample
  assert_eq!(bytes_per_sample(fmt), 4)
  let mono = mono_format(22050)
  // 16-bit mono = 2 bytes per sample
  assert_eq!(bytes_per_sample(mono), 2)
}

///|
test "sample byte conversion" {
  let fmt = default_audio_format()
  assert_eq!(samples_to_bytes(fmt, 100), 400)
  assert_eq!(bytes_to_samples(fmt, 400), 100)
}

///|
test "duration conversion" {
  let fmt = default_audio_format()
  let samples = duration_to_samples(fmt, 1.0)
  assert_eq!(samples, 44100)
  let dur = samples_to_duration(fmt, 44100)
  assert_true!(approx(dur, 1.0))
}

///|
test "clip_duration" {
  let fmt = default_audio_format()
  // 1 second of audio = 44100 * 4 bytes
  let data = Bytes::make(44100 * 4, 0)
  let clip = new_audio_clip(fmt, data, false)
  assert_eq!(clip_sample_count(clip), 44100)
  assert_true!(approx(clip_duration(clip), 1.0))
}

///|
test "SimpleAudioContext create and play" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let data = Bytes::make(1000, 0)
  let clip = new_audio_clip(default_audio_format(), data, false)
  let id = ctx.create_player(clip)
  assert_eq!(ctx.player_count(), 1)
  // Initial state is stopped
  match ctx.state(id) {
    PlayerState::Stopped => ()
    _ => fail!("expected Stopped")
  }
  ctx.play(id)
  match ctx.state(id) {
    PlayerState::Playing => ()
    _ => fail!("expected Playing")
  }
  ctx.pause(id)
  match ctx.state(id) {
    PlayerState::Paused => ()
    _ => fail!("expected Paused")
  }
  ctx.stop(id)
  match ctx.state(id) {
    PlayerState::Stopped => ()
    _ => fail!("expected Stopped")
  }
}

///|
test "SimpleAudioContext volume" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let data = Bytes::make(1000, 0)
  let clip = new_audio_clip(default_audio_format(), data, false)
  let id = ctx.create_player(clip)
  ctx.set_volume(id, 0.5)
  // Volume is clamped
  ctx.set_volume(id, -0.5)
  ctx.set_volume(id, 2.0)
}

///|
test "SimpleAudioContext tick advances position" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let fmt = default_audio_format()
  let data = Bytes::make(44100 * 4, 0) // 1 second
  let clip = new_audio_clip(fmt, data, false)
  let id = ctx.create_player(clip)
  ctx.play(id)
  // Advance 22050 samples (0.5s)
  ctx.tick(22050)
  assert_true!(approx(ctx.current_position(id), 0.5))
  // Advance past end
  ctx.tick(44100)
  // Should stop (non-looping)
  match ctx.state(id) {
    PlayerState::Stopped => ()
    _ => fail!("expected Stopped after end")
  }
}

///|
test "SimpleAudioContext tick loops" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let fmt = default_audio_format()
  let data = Bytes::make(44100 * 4, 0) // 1 second
  let clip = new_audio_clip(fmt, data, true) // looping
  let id = ctx.create_player(clip)
  ctx.play(id)
  // Advance past end
  ctx.tick(66150) // 1.5 seconds
  // Should still be playing (looping)
  match ctx.state(id) {
    PlayerState::Playing => ()
    _ => fail!("expected Playing for loop")
  }
  // Position should wrap around to ~0.5s
  assert_true!(approx(ctx.current_position(id), 0.5))
}

///|
test "SimpleAudioContext seek" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let fmt = default_audio_format()
  let data = Bytes::make(44100 * 4, 0)
  let clip = new_audio_clip(fmt, data, false)
  let id = ctx.create_player(clip)
  ctx.seek(id, 0.5)
  assert_true!(approx(ctx.current_position(id), 0.5))
}

///|
test "SimpleAudioContext dispose" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let data = Bytes::make(1000, 0)
  let clip = new_audio_clip(default_audio_format(), data, false)
  let id = ctx.create_player(clip)
  assert_eq!(ctx.player_count(), 1)
  ctx.dispose(id)
  assert_eq!(ctx.player_count(), 0)
}

///|
test "audio_buffer_to_clip roundtrip" {
  // Create a simple AudioBuffer with known samples
  let buffer = @ma.new_audio_buffer(1, 44100, 4)
  @ma.set_sample(buffer, 0, 0, 0.0)
  @ma.set_sample(buffer, 1, 0, 0.5)
  @ma.set_sample(buffer, 2, 0, -0.5)
  @ma.set_sample(buffer, 3, 0, 1.0)
  let clip = audio_buffer_to_clip(buffer, false)
  assert_eq!(clip.format.sample_rate, 44100)
  assert_eq!(clip.format.channels, 1)
  assert_eq!(clip_sample_count(clip), 4)
  // Roundtrip back
  let buffer2 = clip_to_audio_buffer(clip)
  assert_eq!(@ma.frame_count(buffer2), 4)
  // Check samples are approximately preserved
  assert_true!((@ma.get_sample(buffer2, 0, 0) - 0.0).abs() < 0.001)
  assert_true!((@ma.get_sample(buffer2, 1, 0) - 0.5).abs() < 0.001)
  assert_true!((@ma.get_sample(buffer2, 2, 0) - (-0.5)).abs() < 0.001)
  assert_true!((@ma.get_sample(buffer2, 3, 0) - 1.0).abs() < 0.001)
}

///|
test "audio_buffer_to_clip stereo" {
  let buffer = @ma.new_audio_buffer(2, 48000, 2)
  @ma.set_sample(buffer, 0, 0, 0.25)
  @ma.set_sample(buffer, 0, 1, -0.25)
  @ma.set_sample(buffer, 1, 0, 0.75)
  @ma.set_sample(buffer, 1, 1, -0.75)
  let clip = audio_buffer_to_clip(buffer, true)
  assert_eq!(clip.format.channels, 2)
  assert_eq!(clip.format.sample_rate, 48000)
  assert_eq!(clip.loop_, true)
  assert_eq!(clip_sample_count(clip), 2)
}

///|
test "MixerAudioContext create and lifecycle" {
  let ctx = MixerAudioContext::new(44100)
  let fmt : AudioFormat = { sample_rate: 44100, channels: 1, bits_per_sample: 16 }
  let data = Bytes::make(44100 * 2, 0) // 1 second mono 16-bit
  let clip = new_audio_clip(fmt, data, false)
  let id = ctx.create_player(clip)
  // Initial state
  match ctx.state(id) {
    PlayerState::Stopped => ()
    _ => fail!("expected Stopped")
  }
}

///|
test "detect_audio_format" {
  // Unknown format
  let unknown = Bytes::make(10, 0)
  assert_eq!(detect_audio_format(unknown), "")
  // WAV magic bytes
  let wav_bytes = Bytes::from_array(
    [b'R', b'I', b'F', b'F', b'\x00', b'\x00', b'\x00', b'\x00'],
  )
  assert_eq!(detect_audio_format(wav_bytes), "wav")
  // OGG magic bytes
  let ogg_bytes = Bytes::from_array(
    [b'O', b'g', b'g', b'S', b'\x00', b'\x00', b'\x00', b'\x00'],
  )
  assert_eq!(detect_audio_format(ogg_bytes), "ogg")
}

///|
test "decode_audio_clip_auto unknown returns None" {
  let data = Bytes::make(10, 0)
  let result = decode_audio_clip_auto(data, false)
  match result {
    None => ()
    Some(_) => fail!("expected None for unknown format")
  }
}
