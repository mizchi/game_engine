// Shared audio backend for kagura — used by both JS-target (via globalThis.__kaguraAudio)
// and WASM-target (via ES module import)

const WORKLET_CODE = [
  'class KaguraProcessor extends AudioWorkletProcessor {',
  '  constructor() {',
  '    super();',
  '    this.ring = null; this.ringSize = 0; this.channels = 2;',
  '    this.readPos = 0; this.writePos = 0;',
  '    this.port.onmessage = (e) => {',
  '      const m = e.data;',
  '      if (m.t === "i") {',
  '        this.ringSize = m.s; this.channels = m.c;',
  '        this.ring = new Float32Array(m.s * m.c);',
  '        this.readPos = 0; this.writePos = 0;',
  '      } else if (m.t === "w") {',
  '        const d = m.d, len = this.ring.length;',
  '        let wi = this.writePos * this.channels;',
  '        for (let i = 0; i < d.length; i++) this.ring[(wi + i) % len] = d[i];',
  '        this.writePos = (this.writePos + d.length / this.channels) % this.ringSize;',
  '      }',
  '    };',
  '  }',
  '  process(inputs, outputs) {',
  '    if (!this.ring) return true;',
  '    const o = outputs[0], f = o[0].length;',
  '    for (let c = 0; c < this.channels && c < o.length; c++) {',
  '      const cd = o[c];',
  '      for (let i = 0; i < f; i++) cd[i] = this.ring[((this.readPos + i) % this.ringSize) * this.channels + c];',
  '    }',
  '    this.readPos = (this.readPos + f) % this.ringSize;',
  '    return true;',
  '  }',
  '}',
  'registerProcessor("kagura-processor", KaguraProcessor);',
].join("\n");

/**
 * Create an audio backend with ScriptProcessorNode (immediate) + AudioWorklet (async upgrade).
 * Returns an audio state object.
 */
export function createAudioBackend(sampleRate, channels) {
  const AC = globalThis.AudioContext || globalThis.webkitAudioContext;
  if (!AC) return null;
  const ctx = new AC({ sampleRate });
  const ch = Number(channels) || 2;
  const bufSize = 4096;
  const ringSize = bufSize * 8;
  const ring = new Float32Array(ringSize * ch);
  let readPos = 0;
  const node = ctx.createScriptProcessor(bufSize, 0, ch);
  node.onaudioprocess = (e) => {
    const out = e.outputBuffer;
    const frames = out.length;
    for (let c = 0; c < ch; c++) {
      const chData = out.getChannelData(c);
      for (let i = 0; i < frames; i++) {
        const idx = ((readPos + i) % ringSize) * ch + c;
        chData[i] = ring[idx];
      }
    }
    readPos = (readPos + frames) % ringSize;
  };
  node.connect(ctx.destination);
  const audio = {
    ctx, node, ring, ringSize, writePos: 0,
    readPos: () => readPos,
    channels: ch, workletNode: null, useWorklet: false,
  };
  // Async AudioWorklet upgrade
  if (ctx.audioWorklet) {
    const blob = new Blob([WORKLET_CODE], { type: "application/javascript" });
    const url = URL.createObjectURL(blob);
    ctx.audioWorklet.addModule(url).then(() => {
      URL.revokeObjectURL(url);
      const wn = new AudioWorkletNode(ctx, "kagura-processor", { outputChannelCount: [ch] });
      wn.port.postMessage({ t: "i", s: ringSize, c: ch });
      wn.connect(ctx.destination);
      node.disconnect();
      audio.workletNode = wn;
      audio.useWorklet = true;
    }).catch(() => {});
  }
  return audio;
}

/**
 * Transfer frames from the ring buffer to the AudioWorklet (if active),
 * then advance writePos.
 */
export function advanceAudioWrite(audio, frames) {
  if (!audio) return;
  const f = Number(frames) | 0;
  if (audio.useWorklet && audio.workletNode) {
    const count = f * audio.channels;
    const buf = new Float32Array(count);
    const ringLen = audio.ringSize * audio.channels;
    const start = (audio.writePos % audio.ringSize) * audio.channels;
    for (let i = 0; i < count; i++) buf[i] = audio.ring[(start + i) % ringLen];
    audio.workletNode.port.postMessage({ t: "w", d: buf }, [buf.buffer]);
  }
  audio.writePos = (audio.writePos + f) % audio.ringSize;
}

/**
 * Close the audio backend: disconnect worklet, ScriptProcessor, and AudioContext.
 */
export function closeAudio(audio) {
  if (!audio) return;
  if (audio.workletNode) { audio.workletNode.disconnect(); audio.workletNode = null; }
  if (audio.node) { audio.node.disconnect(); audio.node = null; }
  if (audio.ctx) { audio.ctx.close(); audio.ctx = null; }
}

/**
 * Install audio helpers on globalThis for use from MoonBit extern "js" inline code.
 */
export function installAudioHelpers() {
  globalThis.__kaguraAudio = {
    create: createAudioBackend,
    advance: advanceAudioWrite,
    close: closeAudio,
  };
}
