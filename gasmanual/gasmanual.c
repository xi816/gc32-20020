#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>

#define kb *1024
#define SELFNAME "gasmanual 0.1 for GovnoCore 32-20020 Gen 1 Tiger"
#define CLEAR printf("\033[48;5;232m\033[H\033[2J")
#define TEXT "\033[48;5;34m"
#define SW LINES-4

short LINES, COLS, CENTER;
struct termios oldt;
struct termios newt;
typedef enum Topic_t {
  BASE = 0, REGS, MEMLAYOUT
} Topic;
Topic topic;
char* tnames[] = {
  "Instructions", "Registers", "Memory layout"
};
char* tfiles[] = {
  "introduction.txt", "regs.txt", "memlayout.txt"
};
short ln[1000];
char* filebuf;
int fp, lp, lnl;

int readfile() {
  FILE* f = fopen(tfiles[topic], "r");
  if (!f) {
    fprintf(stderr, "gasmanual files missing or corrupted\n");
    return 1;
  }
  fread(filebuf, 1, 100 kb, f);
  fclose(f);
  fp = lnl = 0;
  lp = 1;
  while (filebuf[fp]) {
    if (filebuf[fp] == 10) { ln[lp++] = fp+1; lnl++; }
    fp++;
  }
  return 0;
}

int main(void) {
  struct winsize w;
  int fsize;
  char c;
  short scroll;
  char* errs;

  ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
  LINES = w.ws_row;
  COLS = w.ws_col;
  CENTER = COLS/2;

  filebuf = malloc(100 kb);
  topic = BASE;
  ln[0] = 0;
  scroll = 0;
  errs = "";
  readfile();

  tcgetattr(STDIN_FILENO, &oldt);
  memcpy(&newt, &oldt, sizeof(oldt));
  newt.c_iflag &= ~(IXON);
  newt.c_lflag &= ~(ICANON | ECHO | /*ISIG |*/ IEXTEN);
  tcsetattr(STDIN_FILENO, TCSANOW, &newt);

  while (1) {
    CLEAR;
    printf("\033[?25l\033[48;5;20m\033[37m\033[K\n\033[K\033[%dC%s\n\033[K\033[48;5;232m\n\033[s", CENTER-(strlen(tnames[topic])/2), tnames[topic]);
    printf("\033[200B\033[48;5;20m\033[37m"SELFNAME"\033[K\033[48;5;232m\033[u\033[38;5;34m");
    fflush(stdout);
    write(1, filebuf+ln[scroll], ln[scroll+SW] - ln[scroll]);
    c = getchar();
    switch (c) {
      case 'q': goto exit;
      case '\t':
        topic = (topic+1)%3;
        if (readfile()) {
          errs = "\033[91mFatal error lol\033[0m";
          goto exit;
        } break;
      case '\033':
        getchar(); c = getchar();
        switch (c) {
          case 'A': if (scroll > 0) scroll--; break;
          case 'B': if (scroll < lnl-SW) scroll++; break;
        }; break;
    }
  }

exit:
  printf("\033[0m\033[H\033[2J\033[?25h");
  puts(errs);
  tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
  free(filebuf);
  return 0;
}

