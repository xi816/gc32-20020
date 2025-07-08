#ifndef SPU32H_H
#define SPU32H_H 1

struct Gareg {
  U16 freq;
  U8 volume;
  U16 pos;

  U16 a;
  U16 d; // A+D
  U16 s; // A+D+S
  U16 r; // A+D+S+R, length
};

#define SPU_CHAN 4
struct gc_ga32 {
  U16 period;
  struct Gareg chan[SPU_CHAN];
};
typedef struct gc_ga32 gc_ga32;

#endif
