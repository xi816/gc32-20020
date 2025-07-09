fsec_main:
  mov %esi fsec001
  int $91
  jsr scani
  mov %ebx %eax
  mov %eax '$' int $92
  mov %ecx 511

  mov %esi %ebx
  mul %esi 512
  mov %eax $00
.fsecl:
  stds %e9
  inx %esi
  lp .fsecl
  rts
fsec001: bytes "Enter LBA number (dec): ^@"

