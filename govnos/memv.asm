memv_main:
  mov %esi memv001
  int $91
  jsr scani
  mov %ebx %eax
  mov %eax '$' int $92
  mov %ecx 255

  mov %esi %ebx
  mul %esi 256
.memvl:
  lb %esi %eax
  jsr hputc
  mov %eax ' ' int $92
  mov %egi %esi
  div %egi 16
  cmp %edx 0
  je .newline
.n:
  lp .memvl
.newline:
  mov %eax '$' int $92
  lp .memvl
  rts
memv001: bytes "Enter page number (dec): ^@"

