#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define ptrlen(t) (sizeof(t)/sizeof(t[0]))

int32_t main(int argc, char** argv) {
  char* color = "\033[32m";
  char* rcolor = "\033[0m";

  char com[128];
  char* term = getenv("TERM");
  char* cc = getenv("CC");
  char* cflags = getenv("CFLAGS");
  if (!cc)     cc = "gcc";
  if (!cflags) cflags = "-Wall --std=gnu89";

  if (strcmp(term, "xterm-256color") && strcmp(term, "xterm")) {
    color = "\0";
    rcolor = "\0";
  }
  char* targets[]         = {"gc32-20020", "gboot", "mkfs.govnfs", "ugovnfs", "prepare-disk"};
  char* install_targets[] = {"gc32-20020", "gboot", "mkfs.govnfs", "ugovnfs", "prepare-disk", "kasm"};
  char* build_commands[] = {
    "%s %s core/main.c -Ilib/ -lm -lSDL2 -o gc32-20020",
    "%s %s core/gboot/main.c -o gboot",
    "%s %s core/mkfs.govnfs/main.c -o mkfs.govnfs",
    "%s %s core/ugovnfs/main2.c -Ilib/ -lm -o ugovnfs",
    "%s %s core/prepare-disk.c -o prepare-disk"
  };
  char* install_commands[] = {
    "install gc32-20020 /usr/local/bin/",
    "install gboot /usr/local/bin/",
    "install mkfs.govnfs /usr/local/bin/",
    "install ugovnfs /usr/local/bin/",
    "install prepare-disk /usr/local/bin/",
    "install asm/kasm /usr/local/bin/"
  };
  char* clean_commands[] = {
    "rm -f gc32-20020",
    "rm -f gboot",
    "rm -f mkfs.govnfs",
    "rm -f ugovnfs",
    "rm -f prepare-disk",
  };

  if (argc == 1) {
    printf("rebuilding %sball%s\n", color, rcolor);
    system("gcc core/ball.c -o ball");
    for (uint16_t i = 0; i < ptrlen(targets); i++) {
      printf("building %s%s%s\n", color, targets[i], rcolor);
      fflush(stdout);
      sprintf(com, build_commands[i], cc, cflags);
      system(com);
    }
    return 0;
  }
  else if ((argc == 2) && (!strcmp(argv[1], "install"))) {
    for (uint16_t i = 0; i < ptrlen(install_targets); i++) {
      printf("installing %s%s%s\n", color, install_targets[i], rcolor);
      system(install_commands[i]);
    }
    puts("done!");
    return 0;
  }
  else if ((argc == 2) && (!strcmp(argv[1], "clean"))) {
    for (uint16_t i = 0; i < ptrlen(targets); i++) {
      printf("removing %s%s%s\n", color, targets[i], rcolor);
      system(clean_commands[i]);
    }
    puts("removing .bin files...");
    system("find . -name \"*.bin\" | xargs rm -f");
    puts("removing .exp files...");
    system("find . -name \"*.exp\" | xargs rm -f");
    puts("done!");
    return 0;
  }
  else {
    printf("ball: unknown argument `%s`\n", argv[1]);
  }
  return 0;
}

