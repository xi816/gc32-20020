testmain:
  mov %eax 0 ; sys_write
  mov %ebx superhw
  mov %ecx 22
  int $80
  int $11

  mov %eax 1 ; sys_read
  mov %ebx buf
  mov %ecx 4
  int $80

  mov %eax 0 ; sys_write
  mov %ebx buf
  mov %ecx 4
  int $80

  rts

superhw: bytes "reading 4 bytes$read> ^@"
buf:     reserve 5 bytes

