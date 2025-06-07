  jmp main
puts:
  lb %esi %eax
  cmp %eax $00
  re
  psh %eax
  int $2
  jmp puts

main:
  int $A ; cpuid
  mov %egi name
  sd %egi %eax
  sd %egi %ebx
  sd %egi %ecx
  sd %egi %edx
  sd %egi %esi
  mov %esi name
  jsr puts
  psh '$'
  int $2
  rts
name: reserve 24 bytes

