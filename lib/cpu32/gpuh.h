#ifndef GPU32H_H
#define GPU32H_H 1

#include <SDL3/SDL.h>

#define WINW 640
#define WINH 480
#define VGASIZE WINW*WINH // 307,200

struct gc_gg32 {
  U8 status; // besplatno
  U8 scale; // platno
  SDL_Window* win;
  SDL_Renderer* rndr;
  SDL_Surface* surf;
  SDL_Palette* pal;
};
typedef struct gc_gg32 gc_gg32;

struct ggrgb {
  U8 r;
  U8 g;
  U8 b;
};
typedef struct ggrgb ggrgb;

#endif
