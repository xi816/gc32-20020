// GPU identificator: GovnGraphics 69-4932
#include <cpu32/gpuh.h>
#include <cpu32/gpufont.h>

ggrgb rgbv[] = {
  (ggrgb){.r = 0x00, .g = 0x00, .b = 0x00},
  (ggrgb){.r = 0xAA, .g = 0x00, .b = 0x00},
  (ggrgb){.r = 0x00, .g = 0xAA, .b = 0x00},
  (ggrgb){.r = 0xAA, .g = 0x55, .b = 0x00},
  (ggrgb){.r = 0x00, .g = 0x00, .b = 0xAA},
  (ggrgb){.r = 0xAA, .g = 0x00, .b = 0xAA},
  (ggrgb){.r = 0x00, .g = 0xAA, .b = 0xAA},
  (ggrgb){.r = 0xAA, .g = 0xAA, .b = 0xAA},

  (ggrgb){.r = 0x55, .g = 0x55, .b = 0x55},
  (ggrgb){.r = 0xFF, .g = 0x55, .b = 0x55},
  (ggrgb){.r = 0x55, .g = 0xFF, .b = 0x55},
  (ggrgb){.r = 0xFF, .g = 0xFF, .b = 0x55},
  (ggrgb){.r = 0x55, .g = 0x55, .b = 0xFF},
  (ggrgb){.r = 0xFF, .g = 0x55, .b = 0xFF},
  (ggrgb){.r = 0x55, .g = 0xFF, .b = 0xFF},
  (ggrgb){.r = 0xFF, .g = 0xFF, .b = 0xFF},
};

enum ggcolors {
  BLACK    = 0, // Standard 8 colors
  RED      = 1,
  GREEN    = 2,
  YELLOW   = 3,
  BLUE     = 4,
  MAGENTA  = 5,
  CYAN     = 6,
  WHITE    = 7,

  EBLACK   = 8, // Bright 8 colors
  ERED     = 9,
  EGREEN   = 10,
  EYELLOW  = 11,
  EBLUE    = 12,
  EMAGENTA = 13,
  ECYAN    = 14,
  EWHITE   = 15,
};

U0 GGinit(U8* mem, gc_gg32* gg, U8 scale) {
  memcpy(mem+0x004A1000, CHARSET, 2048);
  memcpy(mem+0x004A1800, CHARSET816, 4096);
  SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO);
  SDL_SetAppMetadata("GovnoCore 32-20020", "32-20020", "io.github.xi816.gc32-20020");
  gg->scale = scale;
  gg->win = SDL_CreateWindow("Gravno Display Pro", WINW * scale, WINH * scale, SDL_WINDOW_HIGH_PIXEL_DENSITY);
  gg->surf = SDL_CreateSurface(WINW, WINH, SDL_PIXELFORMAT_INDEX8);
  gg->pal = SDL_CreatePalette(256);
  SDL_SetSurfacePalette(gg->surf, gg->pal);
  gg->status = 0b00000000;
  SDL_HideCursor();
  SDL_UpdateWindowSurface(gg->win);
}

U0 GGstop(gc_gg32* gg) {
  SDL_DestroyPalette(gg->pal);
  SDL_DestroySurface(gg->surf);
  SDL_DestroyRenderer(gg->rndr);
  SDL_DestroyWindow(gg->win);
  SDL_Quit();
}

U0 GGupload(GC* gc) {
  gc->gg.surf->pixels = gc->mem + 0x400000;
  SDL_SetSurfacePalette(gc->gg.surf, gc->gg.pal);
  SDL_BlitSurfaceScaled(gc->gg.surf, 0, SDL_GetWindowSurface(gc->gg.win), 0, SDL_SCALEMODE_NEAREST);
  SDL_UpdateWindowSurface(gc->gg.win);
}

U0 GGflush(GC* gc) {
  U8 byte = gc->mem[0x450000];
  //U16 palitro = (gc->mem[0x4A0000+2*byte]) + (gc->mem[0x4A0001+2*byte] << 8);
  byte = gc->mem[0x450000];
  // SDL_SetRenderDrawColor(gc->renderer,
  //   ((palitro&0b0111110000000000)>>10)*8, // R
  //   ((palitro&0b0000001111100000)>>5)*8,  // G
  //   ((palitro&0b0000000000011111))*8,     // B
  //   0xFF);
  memset(gc->mem+0x400000, byte, VGASIZE);
  // SDL_RenderPresent(gc->renderer);
}

U0 GGpage_CGA16(GC* gc) {
  U16 i;
  for (i = 0; i < 256; i++) {
    gc->gg.pal->colors[i].r = rgbv[i%16].r;
    gc->gg.pal->colors[i].g = rgbv[i%16].g;
    gc->gg.pal->colors[i].b = rgbv[i%16].b;
    gc->gg.pal->colors[i].a = 0xFF;
  }
  GGupload(gc);
}

U0 GGpage_RGB555LE(GC* gc) {
  U16 i;
  U16 palitro;
  for (i = 0; i < 256; i++) {
    palitro = (gc->mem[0x4A0000+2*i]) + (gc->mem[0x4A0001+2*i] << 8);
    gc->gg.pal->colors[i].r = ((palitro&0b0111110000000000)>>10)*8;
    gc->gg.pal->colors[i].g = ((palitro&0b0000001111100000)>>5)*8;
    gc->gg.pal->colors[i].b = ((palitro&0b0000000000011111))*8;
    gc->gg.pal->colors[i].a = 0xFF;
  }
  GGupload(gc);

}

U0 GGpage_text(GC* gc) {
  U8* b = gc->mem + 0x004F0000;
  U8* sb = gc->mem + 0x00400000;
  U8 x, y, ch, col, fg, bg, r, c;
  U8* fontdata;
  for (y = 0; y < 60; y++) {
    for (x = 0; x < 80; x++) {
      ch = b[(y * 80 + x) * 2];
      col = b[(y * 80 + x) * 2 + 1];
      fg = col & 0x0F;
      bg = (col >> 4) & 0x0F;
      fontdata = gc->mem+0x004A1000+(ch*8);
      for (r = 0; r < 8; r++) for (c = 0; c < 8; c++)
        sb[(y * 8 + r) * 640 + (x * 8 + c)] = ((fontdata[r] >> (7 - c)) & 1) ? fg : bg;
    }
  }
  GGpage_RGB555LE(gc);
}

U0 GGpage_text816(GC* gc) {
  U8* b = gc->mem + 0x004F0000;
  U8* sb = gc->mem + 0x00400000;
  U8 x, y, ch, col, fg, bg, r, c;
  U8* fontdata;
  for (y = 0; y < 30; y++) {
    for (x = 0; x < 80; x++) {
      ch = b[(y * 80 + x) * 2];
      col = b[(y * 80 + x) * 2 + 1];
      fg = col & 0x0F;
      bg = (col >> 4) & 0x0F;
      fontdata = gc->mem+0x004A1800+(ch*16);
      for (r = 0; r < 16; r++) for (c = 0; c < 8; c++)
        sb[(y * 16 + r) * 640 + (x * 8 + c)] = ((fontdata[r] >> (7 - c)) & 1) ? fg : bg;
    }
  }
  GGpage_RGB555LE(gc);
}

U0 (*GGPAGE[4])(GC*) = {&GGpage_CGA16, &GGpage_RGB555LE, &GGpage_text, &GGpage_text816};
U0 GGpage(GC* gc) {
  GGPAGE[gc->mem[0x49FF00]%4](gc);
}

// PPU functions
U0 GGsprite_256(GC* gc) {
  U32 to = gc->reg[0x04];   // ESI
  U32 from = gc->reg[0x05]; // EGI
  U8 x,y;
  for (y = 0; y < 8; y++) {
    for (x = 0; x < 8; x++) {
      if ((gc->mem[from+(y*8)+x])) gc->mem[to+(y*640)+x] = (gc->mem[from+(y*8)+x]);
    }
  }
}

U0 GGsprite_read_256(GC* gc) {
  U32 to = gc->reg[0x05];   // EGI
  U32 from = gc->reg[0x04]; // ESI
  U8 x,y;
  for (y = 0; y < 8; y++) {
    for (x = 0; x < 8; x++) {
      gc->mem[to+(y*8)+x] = gc->mem[from+(y*640)+x];
    }
  }
}

U0 GGsprite_mono(GC* gc) {
  U32 to = gc->reg[0x04];   // ESI
  U32 from = gc->reg[0x05]; // EGI
  U8 color = gc->reg[0x00]; // EAX
  U8 x,y;
  for (y = 0; y < 8; y++) {
    for (x = 0; x < 8; x++) {
      gc->mem[to+(y*640)+x] = color*((gc->mem[from+y] & (1<<(7-x))) >> (7-x));
    }
  }
}

