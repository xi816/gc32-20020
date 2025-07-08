vidinit:
  mov %esi $49FF00
  mov %eax $02
  sb %esi %eax
  mov %esi $4A0000
  mov %egi palitro
  mov %ecx 15
.pal:
  lw %egi %eax
  sw %esi %eax
  lp .pal
  jmp debug
palitro: bytes $00 $00 $00 $54 $A0 $02 $40 $55 $15 $00 $15 $54 $B5 $02 $B5 $56 $4A $29 $4A $7D $EA $2B $EA $7F $5F $29 $5F $7D $FF $2B $FF $7F
debug:
  mov %egi $480000
  mov %edx 0 ; Shift flag
.l1:
  lb %egi %eax
  cmp %eax $E1
  jne .l1
debug:
  mov %esi $4F0000
  mov %egi $480000
  mov %ebx $10
  mov %ecx 10
  mov %edx $0F
.l1:
  lb %egi %eax
  sb %esi %eax
  sb %esi %edx
  lp .l1

  int $11
  mov %edx 16
  int $22
  jmp debug

vputs:
  lb %esi %eax
  cmp %eax $00
  re
  psh vputs
vputc:
  cmp %eax '$' ; newline
  je .newline
.n:
  add %eax $0100
  sw %e14 %eax
  rts
.newline:
  div %e14 160
  mul %e14 160
  add %e14 224
  rts

main:
  mov %esi $49FF00
  mov %eax $02
  sb %esi %eax

  mov %esi $4A0000
  mov %eax $0000
  sw %esi %eax
  mov %eax $7FFF
  sw %esi %eax

  mov %e14 $4F0000
.nl:
  mov %esi hw
  jsr vputs
  int $11
.loop:
  int $9
  cmp %edx 0
  jne .recv
  mov %edx 8
  int $22
  jmp .loop
.recv:
  int $1
  pop %eax
  cmp %eax '$'
  je .nl
  cmp %eax $7F
  je .back
  cmp %eax $04 // Ctrl+D
  je .term
.n:
  jsr vputc
  int $11
  jmp .loop
.back:
  sub %e14 2
  mov %e8 $0100
  sw %e14 %e8
  sub %e14 2
  int $11
  jmp .loop
.term:
  hlt

hw: bytes "$^$ ^@"

