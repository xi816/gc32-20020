calc_main:
  ; First number
  mov %esi calc_00
  int $91
  jsr scani

  ; Second number
  mov %esi calc_01
  psh %eax
  int $91
  jsr scani
  mov %ebx %eax
  pop %eax

  ; Operation
  mov %esi calc_02
  psh %eax
  int $91
  int $93
  int $92
  mov %ecx %eax
  pop %eax

  psh %eax
  mov %eax '$' int $92
  pop %eax

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
  mov %eax '$' int $92
  rts
.sub:
  sub %eax %ebx
  jsr puti
  mov %eax '$' int $92
  rts
.mul:
  mul %eax %ebx
  jsr puti
  mov %eax '$' int $92
  rts
.div:
  cmp %ebx $00
  je .div_panic
  div %eax %ebx
  jsr puti
  mov %eax '$' int $92
  rts
.div_panic:
  mov %e11 $F0000001
  jmp krnl_panic
.unk:
  mov %esi calc_03
  int $91
  rts

calc_00:     bytes "Enter first number: ^@"
calc_01:     bytes "$Enter second number: ^@"
calc_02:     bytes "$Enter operation [+-*/]: ^@"
calc_03:     bytes "Unknown operation. Make sure you typed +, -, *, /$^@"
