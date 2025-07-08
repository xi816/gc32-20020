#include <time.h>
#include <math.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <stdbool.h>
#include <termios.h>

#include <sterm-control.h>
new_st;
#include <holyc-types.h>
#include <cpu32/bpf.h>
#include <cpu32/cli.h>
#include <cpu32/cpu32.h>

/* usage -- Show usage of the emulator */
U8 usage() {
  puts("gc32-20020: a Govno Core 32 emulator");
  puts("Syntax: gc32-20020 [OPTIONS] <file>");
  puts("  gc32-20020 <file>   Load the file directly to memory");
  puts("Options:");
  puts("  bios      <file>   Load the file as BIOS");
  puts("  cli                Start the emulator in CLI mode");
  puts("  disk      <file>   Load the file as ROM");
  puts("  help               Show help");
  return 0;
}

/* loadBootSector -- loads a block of data from one pointer to
   another, until it finds an $AA$55 */
U8 loadBootSector(U8* drive, U8* mem, U32 start, U32 to) {
  U32 oto = to;
  while (1) {
    if ((*(drive+start) == 0xAA) && (*(drive+start+1) == 0x55)) break;
    *(mem+to) = *(drive+start);
    to++; start++;
  }
  printf("gc32-20020: read %d bytes from ROM\n", to-oto+1);
  return 0;
}

// fy -Wall :(
I32 main(I32 argc, I8** argv) {
  set_st;
  srand(time(NULL));
  U8 driveboot = 0;
  U8 climode = 0;
  U8 verbosemode = 0;
  U8 scale = 1;
  U8 argp = 1; // 256 arguments is enough for everyone

  // Create a virtual CPU
  GC gc;
  gc.pin = 0b00000000; // Reset the pin
  InitGC(&gc);
  Reset(&gc);

  if (argc == 1) {
    old_st;
    usage();
    fprintf(stderr, "gc32-20020: fatal error: no arguments given\n");
    return 1;
  }
  while (argp < argc) {
    // Load from the disk
    if ((!strcmp(argv[argp], "disk")) || (!strcmp(argv[argp], "-d")) || (!strcmp(argv[argp], "--disk"))) {
      // find free disk
      U8 did = 0;
      while (gc.rom[did].size) {
        did++;
        if (did == DISKS) {
          fprintf(stderr, "gc32-20020: \033[91mfatal error:\033[0m too many disks\n");
          old_st;
          return 1;
        }
      }

      FILE* fl = fopen(argv[argp+1], "rb");
      if (fl == NULL) {
        fprintf(stderr, "gc32-20020: \033[91mfatal error:\033[0m disk `%s` not found\n", argv[argp+1]);
        old_st;
        return 1;
      }
      fseek(fl, 0, SEEK_END);
      U32 flsize = ftell(fl);
      U8* disk = malloc(flsize);
      fseek(fl, 0, SEEK_SET);
      fread(disk, 1, flsize, fl);
      fseek(fl, 0, SEEK_SET);
      fclose(fl);
      gc.rom[did].size = flsize;
      gc.rom[did].ptr = disk;
      gc.rom[did].name = argv[argp+1];
      // Setup the pin bit 7 to 1 (drive)
      gc.pin |= 0b10000000;
      argp+=2;
    }
    else if ((!strcmp(argv[argp], "bios")) || (!strcmp(argv[argp], "-b")) || (!strcmp(argv[argp], "--bios"))) {
      FILE* fl = fopen(argv[argp+1], "rb");
      if (fl == NULL) {
        fprintf(stderr, "gc32-20020: \033[91mfatal error:\033[0m bios `%s` not found\n", argv[argp+1]);
        old_st;
        return 1;
      }
      fread(gc.mem + 0x00700000, 1, BIOSNOBNK*BANKSIZE, fl);
      fclose(fl);
      argp += 2;
    }
    else if ((!strcmp(argv[argp], "verbose")) || (!strcmp(argv[argp], "-v")) || (!strcmp(argv[argp], "--verbose"))) {
      verbosemode = 1;
      argp++;
    }
    else if ((!strcmp(argv[argp], "cli")) || (!strcmp(argv[argp], "-c")) || (!strcmp(argv[argp], "--cli"))) {
      climode = 1;
      argp++;
    }
    else if ((!strcmp(argv[argp], "help")) || (!strcmp(argv[argp], "-h")) || (!strcmp(argv[argp], "--help"))) {
      old_st;
      usage();
      exit(1);
    }
    else if ((!strcmp(argv[argp], "scale")) || (!strcmp(argv[argp], "-s")) || (!strcmp(argv[argp], "--scale"))) {
      scale = atoi(argv[argp+1]);
      argp += 2;
    }
    else {
      if (driveboot) {
        fprintf(stderr, "gc32-20020: can't load program when disk is attached\n");
        old_st;
        return 1;
      }
      // Load a memory dump
      FILE* fl = fopen(argv[argp], "rb");
      if (!fl) {
        fprintf(stderr, "gc32-20020: \033[91mfatal error:\033[0m program `%s` not found\n", argv[argp]);
        old_st;
        free(gc.mem);
        return 1;
      }
      fread(gc.mem+0x030000, 1, MEMSIZE, fl);
      fclose(fl);
      // No drives for you, govnos doesnt work without govnbios
      gc.EPC = 0x00030000;
      // bye lmao
      if (argc > argp + 1) {
        fprintf(stderr, "gc32-20020: \033[91mwarning:\033[0m some arguments not parsed\n");
      }
      break;
    }
  }

  // GPU
  GGinit(&(gc.gg), scale);
  GAinit(&(gc.ga));

  int runcode = 0xFF;
  tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
  if (climode) runcode = ExecD(&gc, 0);
  if (runcode == 0) {
    return 0;
  }
  tcsetattr(STDIN_FILENO, TCSANOW, &newt);
  U8 exec_errno = Exec(&gc, verbosemode);
  GGstop(&(gc.gg));
  old_st;
  // Saving shit? oh yeah
  U8 did;
  for (did = 0; did < DISKS && gc.rom[did].size; did++) {
    FILE* fl = fopen(gc.rom[did].name, "wb");
    if (!fl) {
      fprintf(stderr, "\033[31mError\033[0m while saving %s\n", gc.rom[did].name);
    } else {
      fwrite(gc.rom[did].ptr, 1, gc.rom[did].size, fl);
      fclose(fl);
    }
  }
  free(gc.mem);
  return exec_errno;
}
