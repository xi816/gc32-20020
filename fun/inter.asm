inter_main:
  ; Set up Palitro mode
  mov %eax $01
  mov #49FF00 %eax
  mov %eax $02
  mov #450000 %eax

  mov %esi $4A0000
  mov %eax $01FF
  sw %esi %eax
  mov %eax $318C
  sw %esi %eax
  mov %eax $01BA
  sw %esi %eax
  mov %eax $7FFF
  sw %esi %eax
  int $12

  mov %esi $447180
  mov %ecx 15999
  mov %eax $01
.draw_panel:
  sb %esi %eax
  lp .draw_panel
  int $11

  ; int $01
  ; pop %edx

alp:
; Check key state
  mov %eax $480005
  mov %ecx 5
.kbdloop:
  lb %eax %edx
  cmp %edx 0
  jne .noCur
  lp .kbdloop
  ; Hehe
.check_serial:
  int $9
  cmp %edx 0
  jne .popi
  ; Clear old cursor
  mov %eax old_cur_pos
  lw %eax %ebx
  lw %eax %ecx
  mov %egi old_on_cur
  jsr spr

  mov %eax $480000
  lw %eax %ebx
  lw %eax %ecx
  lb %eax %edx ; Mouse state
  mov %e8 old_mouse_pos
  lb %e8 %e9
  cmp %edx %e9
  jne .first_mouse_check
  jmp .mouse_checked
.first_mouse_check:
  mov %e8 old_mouse_pos
  sb %e8 %edx
  cmp %edx 2
  je .pressedc
  jmp .pressedca
.pressedc:
  jsr .pressed
.pressedca:
.mouse_checked:
  mov %egi old_on_cur
  jsr read_spr
  mov %egi cursor
  jsr spr
  mov %esi old_cur_pos
  sw %esi %ebx
  sw %esi %ecx
.noCur:
  int $11
  mov %edx 8
  int $22
  jmp alp
.popi:
  int $1
  pop %edx
  jmp .check_serial
.pressed:
  mov %e9 $4A0000
  lw %e9 %e10
  lw %e9 %e11
  lw %e9 %e12
  lw %e9 %e13
  inx %e10 inx %e11 inx %e12
  mov %e9 $4A0000
  sw %e9 %e10
  sw %e9 %e11
  sw %e9 %e12
  sw %e9 %e13
  psh 'a'
  int 2
  rts

spr:
  mov %esi %ecx
  mul %esi 640
  add %esi %ebx
  add %esi $400000
  int $13
  rts

read_spr:
  mov %esi %ecx
  mul %esi 640
  add %esi %ebx
  add %esi $400000
  int $15
  rts

old_cur_pos:   reserve 4 bytes
old_mouse_pos: reserve 1 bytes
cursor:
  bytes $FF $FF $FF $FF $00 $00 $00 $00
  bytes $FF $FF $00 $00 $00 $00 $00 $00
  bytes $FF $00 $FF $00 $00 $00 $00 $00
  bytes $FF $00 $00 $FF $00 $00 $00 $00
  bytes $00 $00 $00 $00 $FF $00 $00 $00
  bytes $00 $00 $00 $00 $00 $FF $00 $00
  bytes $00 $00 $00 $00 $00 $00 $FF $00
  bytes $00 $00 $00 $00 $00 $00 $00 $FF

; cursor:
;   bytes $FF $FF $00 $00 $00 $00 $00 $00
;   bytes $FF $03 $FF $00 $00 $00 $00 $00
;   bytes $FF $03 $03 $FF $00 $00 $00 $00
;   bytes $FF $03 $03 $03 $FF $00 $00 $00
;   bytes $FF $03 $03 $03 $03 $FF $00 $00
;   bytes $FF $03 $03 $03 $FF $FF $00 $00
;   bytes $FF $03 $FF $03 $FF $00 $00 $00
;   bytes $FF $FF $FF $03 $FF $00 $00 $00

old_on_cur: reserve 256 bytes
