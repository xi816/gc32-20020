jmp main
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

vputs:
  lb %esi %eax
  cmp %eax $00
  re
  jsr vputc
  jmp vputs

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

hw: bytes "$> ^@"

