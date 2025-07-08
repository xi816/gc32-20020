// 8kHz is enough for everyone!
// ...and allows to fit 8 seconds (Max ADSR len) in U16
#define SPURASTFREQ 8000
U0 GAchangen(struct Gareg* gr, F32* samples, U16 period, I32 len) {
  if (!gr->freq) return;
  U32 pos = gr->pos;
  U32 i = 0;
  F32 mul = 0;
  for (; i < len; i++, pos++) {
    if (pos < gr->a) mul = ((F32)pos)/(gr->a);
    else if (pos < gr->d) mul = 1-.5*(pos-gr->a)/(gr->d-gr->a);
    else if (pos < gr->s) mul = .5;
    else if (pos < gr->r) mul = .5-.5*(pos-gr->s)/(gr->r-gr->s);
    else {
      gr->freq = 0;
      return;
    }

    F32 phase = (period + i) * gr->freq / (F32)SPURASTFREQ;
    samples[i] += SDL_sinf(phase * 2 * SDL_PI_F) * mul * gr->volume / 15;
  }
  gr->pos += len;
}


static U0 SDLCALL GAgen(U0 *userdata, SDL_AudioStream *astream, I32 needed, I32 total)
{
  gc_ga32* s32 = userdata;
  needed /= sizeof (F32);
  while (needed > 0) {
    F32 samples[128] = {0};

    const I32 total = SDL_min(needed, SDL_arraysize(samples));
    U8 chan;
    for (chan = 0; chan < SPU_CHAN; chan++)
      GAchangen(&(s32->chan[chan]), samples, s32->period, total);

    s32->period += total;
    s32->period %= SPURASTFREQ;

    SDL_PutAudioStreamData(astream, samples, total * sizeof (float));
    needed -= total;
  }
}

U0 GAinit(gc_ga32* s32) {
  SDL_AudioSpec spec;
  spec.channels = 1;
  spec.format = SDL_AUDIO_F32; // База от SDL3
  spec.freq = SPURASTFREQ;
  SDL_AudioStream* stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, GAgen, s32);
  if (!stream) return;
  SDL_ResumeAudioStreamDevice(stream);
  s32->period = 0;

  U8 chan;
  for (chan = 0; chan < SPU_CHAN; chan++) {
    s32->chan[chan].freq = 0;
  }
}

U0 GAsnd(gc_ga32* s32, U16 freq, U32 adsr, U8 volume) {

  U32 chan = volume >> 4;
  if (chan > 3) chan = 0;

  s32->chan[chan].freq = freq;
  s32->chan[chan].pos = 0;

#define TACT (8 * SPURASTFREQ / 1000) // 8ms
  // Expand ADSR
  s32->chan[chan].a = (adsr >> 24) * TACT;
  s32->chan[chan].d = s32->chan[chan].a + ((adsr >> 16) & 0xFF) * TACT;
  s32->chan[chan].s = s32->chan[chan].d + (adsr & 0xFF) * TACT;
  s32->chan[chan].r = s32->chan[chan].s + ((adsr >> 8) & 0xFF) * TACT;
#undef TACT
  s32->chan[chan].volume = (volume & 0xF) * (adsr >= 0x100 ? 1 : 2);
}
