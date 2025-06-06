calc_main:
  ; First number
  mov %esi calc_00
  int $81
  jsr scani

  ; Second number
  mov %esi calc_01
  psh %eax
  int $81
  jsr scani
  mov %ebx %eax
  pop %eax

  ; Operation
  mov %esi calc_02
  psh %eax
  int $81
  pop %eax
  int $01
  pop %ecx
  psh %ecx
  int $02
  psh '$'
  int 2

  cmp %ecx '+'
  je .add
  cmp %ecx '-'
  je .sub
  cmp %ecx '*'
  je .mul
  cmp %ecx '/'
  je .div
  jmp .unk
.add:
  add %eax %ebx
  jsr puti
  psh '$'
  int $02
  rts
.sub:
  sub %eax %ebx
  jsr puti
  psh '$'
  int $02
  rts
.mul:
  mul %eax %ebx
  jsr puti
  psh '$'
  int $02
  rts
.div:
  cmp %ebx $00
  je .div_panic
  div %eax %ebx
  jsr puti
  psh '$'
  int $02
  rts
.div_panic:
  mov %eax $000000
  jmp krnl_panic
.unk:
  mov %esi calc_03
  int $81
  rts

calc_00:     bytes "Enter first number: ^@"
calc_01:     bytes "$Enter second number: ^@"
calc_02:     bytes "$Enter operation [+-*/]: ^@"
calc_03:     bytes "Unknown operation. Make sure you typed +, -, *, /$^@"
