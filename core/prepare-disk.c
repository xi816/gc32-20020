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
  system("./kasm -o 700000 -e govnos/govnbios.asm govnos/govnbios.exp");
  system("./kasm -o 700000 govnos/govnbios.asm bios.img");

  // Compile GovnOS
  // Bootloader
  system("./kasm -i govnos/govnbios.exp govnos/boot.asm govnos/boot.bin");
  system("./kasm -e govnos/boot.asm govnos/boot.exp");

  // Kernel
  system("./kasm -o A00000 govnos/krnl.asm govnos/krnl.bin");
  system("./kasm -o A00000 -e govnos/krnl.asm govnos/krnl.exp");

  // Core programs
  system("./kasm -o 200000 -i govnos/boot.exp govnos/gsfetch.asm govnos/gsfetch.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/dir.asm govnos/dir.bin");
  system("./kasm -o 200000 -i govnos/boot.exp -i govnos/krnl.exp govnos/gsh.asm govnos/gsh.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/calc.asm govnos/calc.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp -i govnos/boot.exp govnos/cat.asm govnos/cat.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/memv.asm govnos/memv.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/diskv.asm govnos/diskv.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/fsec.asm govnos/fsec.bin");
  system("./kasm -o 200000 -i govnos/krnl.exp govnos/fdisk.asm govnos/fdisk.bin");
  system("./kasm -o 200000 govnos/gtutor.asm govnos/gtutor.bin");

  // Load GovnOS
  printf("\nLoading GovnOS into %s%s%s... ", color, argv[1], rcolor); fflush(stdout);
  // Bootloader
  sprintf(fcom, "./gboot C00000 %s govnos/boot.bin", argv[1]); system(fcom);

  // Core programs
  sprintf(fcom, "./ugovnfs -c %s govnos/krnl.bin krnl.bin com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/info.txt info txt", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/gsfetch.bin gsfetch com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/dir.bin dir com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/gsh.bin gsh com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/calc.bin calc com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/cat.bin cat com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/memv.bin memv com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/diskv.bin diskv com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/fsec.bin fsec com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/fdisk.bin fdisk com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/gtutor.bin gtutor com", argv[1]); system(fcom);
  sprintf(fcom, "./ugovnfs -c %s govnos/test.txt test.txt txt", argv[1]); system(fcom);

  // Дима
  sprintf(fcom, "./ugovnfs -c %s govnos/dima.txt nagiev.txt txt", argv[1]); system(fcom);
  return 0;
}

