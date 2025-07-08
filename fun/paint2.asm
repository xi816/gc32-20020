loop: ._:
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
    ; mov %eax old_cur_pos
    ; lw %eax %ebx
    ; lw %eax %ecx
    ; mov %egi nul
    ; call spr

    mov %eax $480000
    lw %eax %ebx
    lw %eax %ecx
    ; lb %eax %edx - Mouse state
    mov %egi cursor
    jsr spr
    mov %esi old_cur_pos
    sw %esi %ebx
    sw %esi %ecx
.noCur:
    int $11
    mov %edx 8
    int $22
    jmp ._
.popi:
    int $1
    pop %edx
    jmp .check_serial

spr:
    mov %esi %ecx
    mul %esi 640
    add %esi %ebx
    add %esi $400000
    int $13
    rts

old_cur_pos: reserve 4 bytes
cursor:
    bytes $FF $FF $00 $00 $00 $00 $00 $00 $FF $00 $FF $00 $00 $00 $00 $00 $FF $00 $00 $FF $00 $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $00 $FF $00 $00 $FF $00 $00 $00 $FF $FF $00 $00 $FF $00 $FF $00 $FF $00 $00 $00 $FF $FF $FF $00 $FF $00 $00 $00

nul:
