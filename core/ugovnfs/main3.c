#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#include <holyc-types.h>

#define FULL_FS_END 0x800000

I32 main(I32 argc, I8** argv) {
  if (argc == 1) {
    puts("ugovnfs3: no arguments given");
    return 1;
  }
  if (argc == 2) {
    puts("ugovnfs3: no disk/flag given");
    return 1;
  }
  FILE* fl = fopen(argv[2], "rb+");
  if (fl == NULL) {
    printf("ugovnfs3: \033[91mfatal error:\033[0m file `%s` not found\n", argv[1]);
    return 1;
  }
  fseek(fl, 0, SEEK_END);
  U32 flsize = ftell(fl);
  U8* disk = malloc(flsize);
  fseek(fl, 0, SEEK_SET);
  fread(disk, 1, flsize, fl);
  fseek(fl, 0, SEEK_SET);

  int i;
  for (i = 0; i < 10; i++) {
    printf("%04X\n", ((U16*)disk)[i]);
  }
  getchar();

  // Check the disk
  if (((U16*)disk)[0x000000] != 0xAE42) {
    printf("ugovnfs: \033[91mdisk corrupted:\033[0m expected magic `$42AE`, got `$%04X`\n", ((U16*)disk)[0x000000]);
    free(disk);
    return 1;
  }

  U8 ugovnfs_errno = 0xFF;
  fclose(fl);
  free(disk);
  if (ugovnfs_errno == 0xFF) {
    puts("ugovnfs: no arguments given");
    return 0;
  }
  return 0;
}
