#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define HEADER_SIZE 32
#define ENTRY_SIZE  32

int main(int argc, char** argv) {
  uint8_t i;
  uint8_t HEADER[HEADER_SIZE] = "B\xAEGOVNFS3.0 \0\0\0\0\x10\0\0\x01GOVNOS  \0\0\0\0";
  uint8_t ROOT[ENTRY_SIZE] = "/\0\0\0\0\0\0\0\0\0\0\x01\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";
  srand(time(NULL));
  for (i = 0x0C; i < 0x10; i++) {
    HEADER[i] = rand() % 256;
  }

  puts("mkfs.govnfs 2.1 for GovnFS 2.1");
  if (argc == 1) {
    fprintf(stderr, "mkfs.govnfs: \033[91mfatal error:\033[0m no disk given\n");
    return 1;
  }
  FILE* drv = fopen(argv[1], "r+b");
  if (!drv) {
    fprintf(stderr, "mkfs.govnfs: \033[91mfatal error:\033[0m disk `%s` not found\n", argv[1]);
    return 1;
  }
  fseek(drv, 0, SEEK_END);
  uint32_t drvlen = ftell(drv);
  uint8_t* drvbuf = (uint8_t*)malloc(drvlen);
  fseek(drv, 0, SEEK_SET);
  fread(drvbuf, 1, drvlen, drv);
  fseek(drv, 0, SEEK_SET);
  U16* s = (short*)drvbuf;

  printf("mkfs.govnfs: erasing the header (%d bytes ROM)\n", drvlen);
  memcpy(drvbuf, HEADER, 32);
  memset(drvbuf+HEADER_SIZE, 0x00, drvlen-HEADER_SIZE);
  memcpy(drvbuf+0x2200, ROOT, 32);
  if (argc == 3) {
    drvbuf[0x00001C] = argv[2][0]; // copy letter
  }
  s[0x000100] = 0xFFFF;
  fwrite(drvbuf, 1, drvlen, drv);
  fclose(drv);
  return 0;
}

