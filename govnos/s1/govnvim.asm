; govnvim

jmp gv.main

; clear screen
gv.clear:
  mov %esi cseq
  int $91
  rts

; render panels
; assumes gv.clear is called before it
gv.panel:
  mov %esi colpan
  int $91
  mov %esi pmsg0
  int $91
  mov %esi pmsg1
  int $91
  mov %esi coldef
  int $91
  rts

gv.drbuf:
  mov %esi buf
  int $91
  rts

gv.main:
gv.loop:
  jsr gv.clear
  jsr gv.panel
  jsr gv.drbuf
  int $93
  cmp %eax $E2
  je gv.term

  ; write char to buffer
  cmp %eax $7F
  je .back

  mov %ebx %eax
  mov %esi cur
  lw %esi %eax
  mov %esi buf
  add %esi %eax
  sb %esi %ebx
  inx @cur
  jmp gv.loop
.back:
  dex @cur
  mov %esi cur
  lw %esi %eax
  mov %esi buf
  add %esi %eax
  mov %ebx $00
  sb %esi %ebx
  jmp gv.loop
gv.term:
  jsr gv.clear
  rts

cseq: bytes "^\z^@"
coldef: bytes "^\r^@"
colpan: bytes "^\bE^\fP^@"
pmsg0: bytes " -- F1=read F2=write F3=exit                                                 -- ^@"
pmsg1: bytes "^\l30 -- editing file.txt                                                         --^\l02^\c01^@"
buf: reserve 1024 bytes
cur: bytes 0 0

