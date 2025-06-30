// Basic processor functions
struct govnodate {
  char year;
  char month;
  char day;
};
typedef struct govnodate govnodate;

struct govnotime {
  char hour;
  char minute;
  char second;
};
typedef struct govnotime govnotime;

govnodate govnodate_convert(unsigned short date) {
  return (govnodate){
    .year = ((date & 0b1111111000000000)>>9) + 1970,
    .month = ((date & 0b0000000111100000)>>5) + 1,
    .day = (date & 0b0000000000011111) + 1
  };
}

govnotime govnotime_convert(unsigned short date) {
  return (govnotime){
    .hour   = (date / 3600) % 24,
    .minute = (date % 3600) % 60,
    .second = date % 60
  };
}

U16 GC_GOVNODATE() {
  time_t rawtm;
  struct tm* localtm;

  /*             Year   Mon  Day    */
  /*             /-----\/--\/---\   */
  /* Govndate 2: 0000000000000000   */
  time(&rawtm);
  localtm = localtime(&rawtm);
  return ((localtm->tm_year-70)<<9) + (localtm->tm_mon<<5) + (localtm->tm_mday-1);
}

U32 GC_GOVNOTIME() {
  time_t rawtm;
  struct tm* localtm;

  time(&rawtm);
  localtm = localtime(&rawtm);
  return (localtm->tm_hour*3600) + (localtm->tm_min*60) + (localtm->tm_sec);
}

U0 fatal(char* msg) {
  printf("gc32: \033[91mcannot operate\033[0m, error:\n  %s", msg);
}

