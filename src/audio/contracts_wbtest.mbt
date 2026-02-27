///|
fn approx(a : Double, b : Double) -> Bool {
  (a - b).abs() < 0.01
}

///|
test "default_audio_format" {
  let fmt = default_audio_format()
  assert_eq(fmt.sample_rate, 44100)
  assert_eq(fmt.channels, 2)
  assert_eq(fmt.bits_per_sample, 16)
}

///|
test "bytes_per_sample" {
  let fmt = default_audio_format()
  // 16-bit stereo = 4 bytes per sample
  assert_eq(bytes_per_sample(fmt), 4)
  let mono = mono_format(22050)
  // 16-bit mono = 2 bytes per sample
  assert_eq(bytes_per_sample(mono), 2)
}

///|
test "sample byte conversion" {
  let fmt = default_audio_format()
  assert_eq(samples_to_bytes(fmt, 100), 400)
  assert_eq(bytes_to_samples(fmt, 400), 100)
}

///|
test "duration conversion" {
  let fmt = default_audio_format()
  let samples = duration_to_samples(fmt, 1.0)
  assert_eq(samples, 44100)
  let dur = samples_to_duration(fmt, 44100)
  assert_true(approx(dur, 1.0))
}

///|
test "clip_duration" {
  let fmt = default_audio_format()
  // 1 second of audio = 44100 * 4 bytes
  let data = Bytes::make(44100 * 4, 0)
  let clip = new_audio_clip(fmt, data, false)
  assert_eq(clip_sample_count(clip), 44100)
  assert_true(approx(clip_duration(clip), 1.0))
}

///|
test "SimpleAudioContext create and play" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let data = Bytes::make(1000, 0)
  let clip = new_audio_clip(default_audio_format(), data, false)
  let id = ctx.create_player(clip)
  assert_eq(ctx.player_count(), 1)
  // Initial state is stopped
  match ctx.state(id) {
    PlayerState::Stopped => ()
    _ => fail("expected Stopped")
  }
  ctx.play(id)
  match ctx.state(id) {
    PlayerState::Playing => ()
    _ => fail("expected Playing")
  }
  ctx.pause(id)
  match ctx.state(id) {
    PlayerState::Paused => ()
    _ => fail("expected Paused")
  }
  ctx.stop(id)
  match ctx.state(id) {
    PlayerState::Stopped => ()
    _ => fail("expected Stopped")
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
  assert_true(approx(ctx.current_position(id), 0.5))
  // Advance past end
  ctx.tick(44100)
  // Should stop (non-looping)
  match ctx.state(id) {
    PlayerState::Stopped => ()
    _ => fail("expected Stopped after end")
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
    _ => fail("expected Playing for loop")
  }
  // Position should wrap around to ~0.5s
  assert_true(approx(ctx.current_position(id), 0.5))
}

///|
test "SimpleAudioContext seek" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let fmt = default_audio_format()
  let data = Bytes::make(44100 * 4, 0)
  let clip = new_audio_clip(fmt, data, false)
  let id = ctx.create_player(clip)
  ctx.seek(id, 0.5)
  assert_true(approx(ctx.current_position(id), 0.5))
}

///|
test "SimpleAudioContext dispose" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let data = Bytes::make(1000, 0)
  let clip = new_audio_clip(default_audio_format(), data, false)
  let id = ctx.create_player(clip)
  assert_eq(ctx.player_count(), 1)
  ctx.dispose(id)
  assert_eq(ctx.player_count(), 0)
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
  assert_eq(clip.format.sample_rate, 44100)
  assert_eq(clip.format.channels, 1)
  assert_eq(clip_sample_count(clip), 4)
  // Roundtrip back
  let buffer2 = clip_to_audio_buffer(clip)
  assert_eq(@ma.frame_count(buffer2), 4)
  // Check samples are approximately preserved
  assert_true((@ma.get_sample(buffer2, 0, 0) - 0.0).abs() < 0.001)
  assert_true((@ma.get_sample(buffer2, 1, 0) - 0.5).abs() < 0.001)
  assert_true((@ma.get_sample(buffer2, 2, 0) - -0.5).abs() < 0.001)
  assert_true((@ma.get_sample(buffer2, 3, 0) - 1.0).abs() < 0.001)
}

///|
test "audio_buffer_to_clip stereo" {
  let buffer = @ma.new_audio_buffer(2, 48000, 2)
  @ma.set_sample(buffer, 0, 0, 0.25)
  @ma.set_sample(buffer, 0, 1, -0.25)
  @ma.set_sample(buffer, 1, 0, 0.75)
  @ma.set_sample(buffer, 1, 1, -0.75)
  let clip = audio_buffer_to_clip(buffer, true)
  assert_eq(clip.format.channels, 2)
  assert_eq(clip.format.sample_rate, 48000)
  assert_eq(clip.loop_, true)
  assert_eq(clip_sample_count(clip), 2)
}

///|
test "MixerAudioContext create and lifecycle" {
  let ctx = MixerAudioContext::new(44100)
  let fmt : AudioFormat = {
    sample_rate: 44100,
    channels: 1,
    bits_per_sample: 16,
  }
  let data = Bytes::make(44100 * 2, 0) // 1 second mono 16-bit
  let clip = new_audio_clip(fmt, data, false)
  let id = ctx.create_player(clip)
  // Initial state is Paused (voice is paused to prevent GC, not stopped)
  match ctx.state(id) {
    PlayerState::Paused => ()
    _ => fail("expected Paused")
  }
}

///|
test "detect_audio_format" {
  // Unknown format
  let unknown = Bytes::make(10, 0)
  assert_eq(detect_audio_format(unknown), "")
  // WAV magic bytes
  let wav_bytes = Bytes::from_array([
    b'R', b'I', b'F', b'F', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
  assert_eq(detect_audio_format(wav_bytes), "wav")
  // OGG magic bytes
  let ogg_bytes = Bytes::from_array([
    b'O', b'g', b'g', b'S', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
  assert_eq(detect_audio_format(ogg_bytes), "ogg")
}

///|
test "decode_audio_clip_auto unknown returns None" {
  let data = Bytes::make(10, 0)
  let result = decode_audio_clip_auto(data, false)
  match result {
    None => ()
    Some(_) => fail("expected None for unknown format")
  }
}

///|
test "AudioClipStream read full" {
  let fmt = mono_format(44100)
  // 10 bytes of data
  let data = Bytes::from_array([
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06', b'\x07', b'\x08', b'\x09',
    b'\x0A',
  ])
  let clip = new_audio_clip(fmt, data, false)
  let stream = AudioClipStream::new(clip)
  assert_eq(stream.content_length(), 10)
  assert_eq(stream.remaining(), 10)

  let buf : FixedArray[Byte] = FixedArray::make(20, b'\x00')
  let n = stream.read(buf, 20)
  assert_eq(n, 10) // Only 10 bytes available
  assert_eq(buf[0], b'\x01')
  assert_eq(buf[9], b'\x0A')
  assert_eq(stream.remaining(), 0)
}

///|
test "AudioClipStream partial read" {
  let fmt = mono_format(44100)
  let data = Bytes::from_array([
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06',
  ])
  let clip = new_audio_clip(fmt, data, false)
  let stream = AudioClipStream::new(clip)

  // Read first 3 bytes
  let buf : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  let n1 = stream.read(buf, 3)
  assert_eq(n1, 3)
  assert_eq(buf[0], b'\x01')
  assert_eq(buf[2], b'\x03')
  assert_eq(stream.remaining(), 3)

  // Read remaining 3 bytes
  let n2 = stream.read(buf, 10)
  assert_eq(n2, 3)
  assert_eq(buf[0], b'\x04')
  assert_eq(buf[2], b'\x06')
  assert_eq(stream.remaining(), 0)
}

///|
test "AudioClipStream reset" {
  let fmt = mono_format(44100)
  let data = Bytes::from_array([b'\x0A', b'\x0B'])
  let clip = new_audio_clip(fmt, data, false)
  let stream = AudioClipStream::new(clip)

  let buf : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  let _ = stream.read(buf, 10)
  assert_eq(stream.remaining(), 0)

  stream.reset()
  assert_eq(stream.remaining(), 2)
  let n = stream.read(buf, 10)
  assert_eq(n, 2)
  assert_eq(buf[0], b'\x0A')
}

///|
test "BufferedAudioStream push and read" {
  let stream = BufferedAudioStream::new()
  assert_eq(stream.content_length(), -1) // Unknown until finalized
  assert_eq(stream.has_data(), false)

  // Push first chunk
  stream.push_chunk(Bytes::from_array([b'\x01', b'\x02', b'\x03']))
  assert_eq(stream.buffered_bytes(), 3)
  assert_eq(stream.has_data(), true)

  // Read 2 bytes
  let buf : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  let n1 = stream.read(buf, 2)
  assert_eq(n1, 2)
  assert_eq(buf[0], b'\x01')
  assert_eq(buf[1], b'\x02')
  assert_eq(stream.buffered_bytes(), 1)

  // Push second chunk
  stream.push_chunk(Bytes::from_array([b'\x04', b'\x05']))
  assert_eq(stream.buffered_bytes(), 3) // 1 remaining + 2 new

  // Read across chunk boundary
  let n2 = stream.read(buf, 10)
  assert_eq(n2, 3)
  assert_eq(buf[0], b'\x03') // End of first chunk
  assert_eq(buf[1], b'\x04') // Start of second chunk
  assert_eq(buf[2], b'\x05')
}

///|
test "BufferedAudioStream finalize" {
  let stream = BufferedAudioStream::new()
  stream.push_chunk(Bytes::from_array([b'\x01', b'\x02']))
  stream.push_chunk(Bytes::from_array([b'\x03']))
  assert_eq(stream.is_finalized(), false)
  assert_eq(stream.content_length(), -1)

  stream.finalize()
  assert_eq(stream.is_finalized(), true)
  assert_eq(stream.content_length(), 3)
}

///|
test "BufferedAudioStream reset" {
  let stream = BufferedAudioStream::new()
  stream.push_chunk(Bytes::from_array([b'\x01', b'\x02', b'\x03']))

  let buf : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  let _ = stream.read(buf, 10)
  assert_eq(stream.buffered_bytes(), 0)

  stream.reset()
  assert_eq(stream.buffered_bytes(), 3)
  let n = stream.read(buf, 10)
  assert_eq(n, 3)
  assert_eq(buf[0], b'\x01')
}

///|
test "BufferedAudioStream empty read" {
  let stream = BufferedAudioStream::new()
  let buf : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  let n = stream.read(buf, 10)
  assert_eq(n, 0)
}

///|
test "SimpleAudioContext multiple players" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let fmt = default_audio_format()
  let data = Bytes::make(44100 * 4, 0)
  let ids : Array[PlayerId] = []
  for _i in 0..<5 {
    let clip = new_audio_clip(fmt, data, false)
    ids.push(ctx.create_player(clip))
  }
  assert_eq(ctx.player_count(), 5)
  // Play some, pause others
  ctx.play(ids[0])
  ctx.play(ids[2])
  ctx.play(ids[4])
  ctx.pause(ids[2])
  match ctx.state(ids[0]) {
    PlayerState::Playing => ()
    _ => panic()
  }
  match ctx.state(ids[1]) {
    PlayerState::Stopped => ()
    _ => panic()
  }
  match ctx.state(ids[2]) {
    PlayerState::Paused => ()
    _ => panic()
  }
  // Dispose one
  ctx.dispose(ids[3])
  assert_eq(ctx.player_count(), 4)
}

///|
test "SimpleAudioContext seek negative resets to zero" {
  let ctx = SimpleAudioContext::new(default_audio_format())
  let fmt = default_audio_format()
  let data = Bytes::make(44100 * 4, 0) // 1 second
  let clip = new_audio_clip(fmt, data, false)
  let id = ctx.create_player(clip)
  ctx.seek(id, 0.5)
  assert_true(approx(ctx.current_position(id), 0.5))
  ctx.seek(id, 0.0)
  assert_true(approx(ctx.current_position(id), 0.0))
}

///|
test "AudioClipStream read zero bytes" {
  let fmt = mono_format(44100)
  let data = Bytes::from_array([b'\x01', b'\x02'])
  let clip = new_audio_clip(fmt, data, false)
  let stream = AudioClipStream::new(clip)
  let buf : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  let n = stream.read(buf, 0)
  assert_eq(n, 0)
  assert_eq(stream.remaining(), 2)
}

///|
test "clip_to_audio_buffer preserves sample count" {
  let fmt : AudioFormat = {
    sample_rate: 44100,
    channels: 1,
    bits_per_sample: 16,
  }
  // 100 frames * 1ch * 2bytes = 200 bytes
  let data = Bytes::make(200, 0)
  let clip = new_audio_clip(fmt, data, false)
  let buffer = clip_to_audio_buffer(clip)
  assert_eq(@ma.frame_count(buffer), 100)
}

///|
test "mono_format creates correct format" {
  let fmt = mono_format(22050)
  assert_eq(fmt.sample_rate, 22050)
  assert_eq(fmt.channels, 1)
  assert_eq(fmt.bits_per_sample, 16)
}

///|
test "audio output hooks can be set and reset" {
  let init_calls : Ref[Int] = Ref::new(0)
  let write_calls : Ref[Int] = Ref::new(0)
  let suspend_calls : Ref[Int] = Ref::new(0)
  let resume_calls : Ref[Int] = Ref::new(0)
  let close_calls : Ref[Int] = Ref::new(0)
  set_audio_output_hooks(
    new_audio_output_hooks(
      fn(_fmt) {
        init_calls.val = init_calls.val + 1
        true
      },
      fn(_output, _frames) {
        write_calls.val = write_calls.val + 1
        128
      },
      fn() { suspend_calls.val = suspend_calls.val + 1 },
      fn() { resume_calls.val = resume_calls.val + 1 },
      fn() { close_calls.val = close_calls.val + 1 },
    ),
  )
  let ok = audio_try_initialize(default_audio_format())
  assert_true(ok)
  assert_eq(init_calls.val, 1)
  let buf : FixedArray[Float] = FixedArray::make(256, 0.0)
  let written = audio_write_frames(buf, 128)
  assert_eq(written, 128)
  assert_eq(write_calls.val, 1)
  audio_suspend()
  assert_eq(suspend_calls.val, 1)
  audio_resume()
  assert_eq(resume_calls.val, 1)
  audio_close()
  assert_eq(close_calls.val, 1)
  reset_audio_output_hooks()
}

///|
test "audio output hooks default returns false and zero" {
  reset_audio_output_hooks()
  let ok = audio_try_initialize(default_audio_format())
  assert_true(!ok)
  let buf : FixedArray[Float] = FixedArray::make(256, 0.0)
  let written = audio_write_frames(buf, 128)
  assert_eq(written, 0)
  assert_eq(audio_output_latency(), 0.0)
}

///|
test "default_audio_output_stats" {
  let stats = default_audio_output_stats()
  assert_eq(stats.initialized, false)
  assert_eq(stats.frames_written, 0)
  assert_eq(stats.suspended, false)
}

///|
test "audio_render_and_write calls mixer and hooks" {
  let written_ref : Ref[Int] = Ref::new(0)
  set_audio_output_hooks(
    new_audio_output_hooks(
      fn(_fmt) { true },
      fn(_output, frames) {
        written_ref.val = written_ref.val + frames
        frames
      },
      fn() {  },
      fn() {  },
      fn() {  },
    ),
  )
  let ctx = MixerAudioContext::new(44100)
  let result = audio_render_and_write(ctx, 256)
  assert_eq(result, 256)
  assert_eq(written_ref.val, 256)
  reset_audio_output_hooks()
}

///|
test "tracked hooks updates stats on initialize" {
  let stats : Ref[AudioOutputStats] = Ref::new(default_audio_output_stats())
  let inner = new_audio_output_hooks(
    fn(_fmt) { true },
    fn(_output, frames) { frames },
    fn() {  },
    fn() {  },
    fn() {  },
  )
  let tracked = new_tracked_audio_output_hooks(inner, stats)
  assert_eq(stats.val.initialized, false)
  let ok = (tracked.try_initialize)(default_audio_format())
  assert_true(ok)
  assert_eq(stats.val.initialized, true)
}

///|
test "tracked hooks accumulates frames_written" {
  let stats : Ref[AudioOutputStats] = Ref::new(default_audio_output_stats())
  let inner = new_audio_output_hooks(
    fn(_fmt) { true },
    fn(_output, frames) { frames },
    fn() {  },
    fn() {  },
    fn() {  },
  )
  let tracked = new_tracked_audio_output_hooks(inner, stats)
  let buf : FixedArray[Float] = FixedArray::make(512, 0.0)
  let _ = (tracked.write_frames)(buf, 100)
  assert_eq(stats.val.frames_written, 100)
  let _ = (tracked.write_frames)(buf, 200)
  assert_eq(stats.val.frames_written, 300)
}

///|
test "tracked hooks tracks suspend and resume" {
  let stats : Ref[AudioOutputStats] = Ref::new(default_audio_output_stats())
  let inner = new_audio_output_hooks(
    fn(_fmt) { true },
    fn(_output, frames) { frames },
    fn() {  },
    fn() {  },
    fn() {  },
  )
  let tracked = new_tracked_audio_output_hooks(inner, stats)
  assert_eq(stats.val.suspended, false)
  (tracked.suspend)()
  assert_eq(stats.val.suspended, true)
  (tracked.resume_playback)()
  assert_eq(stats.val.suspended, false)
}

///|
test "audio output hooks latency can be overridden" {
  set_audio_output_hooks({
    try_initialize: fn(_fmt) { true },
    write_frames: fn(_output, _frames) { 0 },
    suspend: fn() {  },
    resume_playback: fn() {  },
    close: fn() {  },
    output_latency: fn() { 0.023 },
  })
  assert_true(audio_output_latency() > 0.022)
  assert_true(audio_output_latency() < 0.024)
  reset_audio_output_hooks()
}
