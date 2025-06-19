gfs2_configure:
  mov %esi $000010
  mov %egi $1F0000
  ldds %e9
  sb %egi %eax
  rts

strcpy:
  lb %esi %eax
  cmp %eax $00
  re
  sb %egi %eax
  jmp strcpy

memcpy:
  dex %ecx
.lp:
  lb %esi %eax
  sb %egi %eax
  lp .lp
  rts

b_memset:
  dex %ecx
  mov %eax $00
.lp:
  sb %esi %eax
  lp .lp
  rts

