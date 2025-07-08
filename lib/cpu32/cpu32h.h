// Header include file for lib/cpu32/cpu32.h
#ifndef CPU32H_H
#define CPU32H_H 1

/*
  The memory size is set to 32 MiB or 33,554,432 bytes.
*/
#define ROMSIZE 16777216
#define MEMSIZE 33554432
#define DISKS 8

// Register cluster
struct gcrc {
  U8 x;
  U8 y;
};
typedef struct gcrc gcrc_t;

struct GCF32 {
  U32 size; // If 0 then it is free
  U8* ptr;
  I8* name;
};

typedef struct GCF32 GCF;

struct GC32 {
  // Govno Core 32's 32 addressable registers, but only 16 can be used without a swap.
  U32 reg[32];
  U8 PS;           // -I---ZNC                 Unaddressable
  U32 EPC;         // Program counter (32-bit) Unaddressable

  // Memory and ROM
  U8* mem;
  GCF rom[DISKS];
  U8 pin;

  // GPU
  gc_gg32 gg;

  // SPU
  gc_ga32 ga;
};
typedef struct GC32 GC;
void PlayBeep(double frequency);
gcrc_t ReadRegClust(U8 clust);

U0 WriteByte(GC* gc, U32 addr, U8 val);
U0 WriteWord(GC* gc, U32 addr, U16 val);
U0 Write32(GC* gc, U32 addr, U32 val);

U0 InitGC(GC* gc) {
  gc->mem = (U8*)malloc(MEMSIZE);
  U8 i;
  for (i = 0; i < DISKS; i++) {
    gc->rom[i].size = 0;
    gc->rom[i].ptr = 0;
    gc->rom[i].name = "(null)";
  }
}

#endif
