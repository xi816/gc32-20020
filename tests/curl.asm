// use curl

main:
  mov %esi waddr
  mov %egi $400000
  int $3C

  mov %esi $400000
  int $91

  int $1
  hlt

waddr: bytes "google.com^@"

