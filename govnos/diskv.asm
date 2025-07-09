diskv_main:
  mov %esi diskv001
  int $91
  jsr scani
  mov %ebx %eax
  mov %eax '$' int $92
  mov %ecx 511

  mov %esi %ebx
  mul %esi 512
.diskvl:
  ldds %e9
  inx %esi
  jsr hputc
  mov %eax ' ' int $92
  mov %egi %esi
  div %egi 16
  cmp %edx 0
  je .newline
.n:
  lp .diskvl
.newline:
  mov %eax '$' int $92
  lp .diskvl
  rts
diskv001: bytes "Enter LBA (dec): ^@"

