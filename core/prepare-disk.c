#include <alloca.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define ptrlen(t) (sizeof(t)/sizeof(t[0]))

int32_t main(int argc, char** argv) {
  if (argc <= 1 || argc >= 4) {
    fprintf(stderr, "Error: expected 1/2 arguments, got %d\n", argc-1);
    exit(1);
  }
  char* color = "\033[32m";
  char* rcolor = "\033[0m";
  char fcom[128];
  if (strcmp(getenv("TERM"), "xterm-256color")) {
    color = "\0";
    rcolor = "\0";
  }
  // Format the disk and create it if it doesn't exist
  printf("Formatting %s%s%s...\n", color, argv[1], rcolor);
  sprintf(fcom, "touch %s", argv[1]); system(fcom);
  sprintf(fcom, "truncate %s -s 16M", argv[1]); system(fcom);
  if (argc == 2) {
    sprintf(fcom, "./mkfs.govnfs %s", argv[1]); system(fcom);
  } else {
    sprintf(fcom, "./mkfs.govnfs %s %s", argv[1], argv[2]); system(fcom);
  }
  // Compile GovnBIOS
  system("./kasm -o 700000 -e govnos/bios/govnbios.asm govnos/exp/govnbios.exp");
  system("./kasm -o 700000 govnos/bios/govnbios.asm bios.img");

  // Compile GovnOS
  // Bootloader
  system("./kasm -i govnos/exp/govnbios.exp govnos/boot/boot.asm govnos/bin/boot.bin");
  system("./kasm -e govnos/boot/boot.asm govnos/exp/boot.exp");

  // Kernel
  system("./kasm -cpp -o A00000 govnos/kernel/krnl.asm govnos/bin/krnl.bin");
  system("./kasm -cpp -o A00000 -e govnos/kernel/krnl.asm govnos/exp/krnl.exp");

  // Shell
  system("./kasm -o B00000 -i govnos/exp/boot.exp -i govnos/exp/krnl.exp govnos/shell/shell.asm govnos/bin/shell.bin");

  // Core programs
  system("./kasm -o 200000 -i govnos/boot.exp govnos/s1/gsfetch.asm govnos/bin/gsfetch.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/s1/dir.asm govnos/bin/dir.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/s1/calc.asm govnos/bin/calc.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/s1/govnvim.asm govnos/bin/govnvim.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp -i govnos/exp/boot.exp govnos/s1/cat.asm govnos/bin/cat.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/s2/memv.asm govnos/bin/memv.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/s2/diskv.asm govnos/bin/diskv.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/s2/fsec.asm govnos/bin/fsec.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/s2/fdisk.asm govnos/bin/fdisk.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/s1/snake.asm govnos/bin/snake.bin");
  system("./kasm -o 200000 govnos/s3/gtutor.asm govnos/bin/gtutor.bin");

  // Load GovnOS
  printf("\nLoading GovnOS into %s%s%s... ", color, argv[1], rcolor); fflush(stdout);
  // Bootloader
  sprintf(fcom, "./gboot C00000 %s govnos/bin/boot.bin", argv[1]); system(fcom);

  // Core programs
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/krnl.bin krnl.bin bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/s3/info.txt info txt", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/gsfetch.bin gsfetch bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/dir.bin dir bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/shell.bin shell.bin bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/calc.bin calc bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/cat.bin cat bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/memv.bin memv bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/diskv.bin diskv bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/fsec.bin fsec bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/fdisk.bin fdisk bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/gtutor.bin gtutor bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/govnvim.bin govnvim bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/bin/snake.bin snake bin", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/s3/test.txt test.txt txt", argv[1]); system(fcom);

  // Дима
  sprintf(fcom, "./ugovnfs -c %s govnos/s3/dima.txt nagiev.txt txt", argv[1]); system(fcom);
  return 0;
}

