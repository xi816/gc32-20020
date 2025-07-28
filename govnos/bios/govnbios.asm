/* GovnBIOS -- a basic input/output system for Govno Core 32-20020.
   BIOS is loaded into $700000 in memory.

Interrupts:
   $81 - Output string %esi to console. Uses %eax
   $91 - Output formatted string %esi to Gravno. Uses %eax, %edx
   $92 - Output character %eax to Gravno. Uses %edx
   $93 - Get character from Gravno. Uses %eax-%egi, outputs in %eax

   TODO: Interrupt for disk size? Expose puti?
*/
GovnBIOS_reset:
; Set video mode to text
  mov %esi $49FF00
  mov %eax $03 ; 8x16L $02
  sb %esi %eax
; Set up palette
  mov %esi $4A0000
  mov %egi GovnBIOS_palette
  mov %ecx 15
.pal:
  lw %egi %eax
  sw %esi %eax
  lp .pal

; Set up interrupts
  mov %esi GovnBIOS_puts
  sti $81

  mov %esi GovnBIOS_vputc
  sti $92
  mov %esi GovnBIOS_vputs
  sti $91
  mov %esi GovnBIOS_vgetc
  sti $93

  jmp GovnBIOS_post

; Serial I/O
GovnBIOS_puts:
  lb %esi %eax
  cmp %eax 0
  je .iend
  psh %eax
  int 2
  jmp GovnBIOS_puts
.iend:
  irts

; BEGIN Gravno text mode
GovnBIOS_vputs:
  lb %esi %eax
  cmp %eax 0
  je .iend
  cmp %eax $1C
  je .esc
  int $92
  jmp GovnBIOS_vputs
.iend:
  ; int $11
  irts
.esc:
  lb %esi %eax
  cmp %eax 'f'
  je .setfg
  cmp %eax 'b'
  je .setbg
  cmp %eax 'r'
  je .reset
  cmp %eax 'u'
  je .up
  cmp %eax 'c'
  je .setcol
  cmp %eax 'l'
  je .setline
  cmp %eax 'z'
  je .zeroscr
  jmp GovnBIOS_vputs

.setfg:
  mov %edx $F0
  bytes $D0 $00 GovnBIOS_cur.c
  and %eax %edx
  lb %esi %edx
  sub %edx 'A'
  ora %eax %edx
  bytes $E0 $00 GovnBIOS_cur.c
  jmp GovnBIOS_vputs

.setbg:
  mov %edx $0F
  bytes $D0 $00 GovnBIOS_cur.c
  and %eax %edx
  lb %esi %edx
  sub %edx 'A'
  sal %edx 4
  ora %eax %edx
  bytes $E0 $00 GovnBIOS_cur.c
  jmp GovnBIOS_vputs

.setcol:
  jsr .getnum
  cmp %eax 80
  jn .colok
  mov %eax 59
.colok:
  psh %eax
  bytes $D8 $00 GovnBIOS_cur.posh
  div %eax 80
  mul %eax 80
  pop %edx
  add %eax %edx
  bytes $E8 $00 GovnBIOS_cur.posh
  jmp GovnBIOS_vputs

.setline:
  jsr .getnum
  cmp %eax 60
  jn .lineok
  mov %eax 59
.lineok:
  psh %eax
  bytes $D8 $00 GovnBIOS_cur.posh
  div %eax 80
  pop %eax
  mul %eax 80
  add %eax %edx
  bytes $E8 $00 GovnBIOS_cur.posh
  jmp GovnBIOS_vputs

.up:
  jsr .getnum
  psh %eax
  bytes $D8 $00 GovnBIOS_cur.posh
  div %eax 80
  pop %edx
  sub %eax %edx
  cmp %eax 0
  js .okup
  mov %eax 0
.okup:
  mul %eax 80
  bytes $E8 $00 GovnBIOS_cur.posh
  jmp GovnBIOS_vputs

.reset:
  mov %eax $07
  bytes $E0 $00 GovnBIOS_cur.c
  jmp GovnBIOS_vputs

.zeroscr:
  mov %edx $4F0000
  bytes $D0 $00 GovnBIOS_cur.c
  sal %eax 8
.loop:
  sw %edx %eax
  cmp %edx $4F12C0 ; 8x16: $4F2580
  jne .loop
  mov %eax 0
  bytes $E8 $00 GovnBIOS_cur.posh
  jmp GovnBIOS_vputs
.getnum:
  lb %esi %eax
  sub %eax '0'
  mul %eax 10
  lb %esi %edx
  sub %edx '0'
  add %eax %edx
  dex %eax
  cmp %eax 0
  rs
  pop %eax
  jmp GovnBIOS_vputs

GovnBIOS_vputi:
  psh 0
  mov %ebx 10
.l:
  div %eax %ebx
  add %edx '0'
  psh %edx
  cmp %eax 0
  jne .l
  mov %ebx 0
.l2:
  pop %eax
  cmp %eax 0
  re
  inx %ebx
  int $92
  jmp .l2

GovnBIOS_vputc:
  psh %eax
  cmp %eax '$'
  je .nl
  cmp %eax $08
  je .bs
  ; mov %edx (U16)...
  bytes $D8 $03 GovnBIOS_cur.posh
  add %edx %edx
  add %edx $4F0000
  ; draw
  sb %edx %eax
  ; mov %eax (U8)...
  bytes $D0 $00 GovnBIOS_cur.c
  sb %edx %eax

  ; Increment
  bytes $D8 $03 GovnBIOS_cur.posh
  inx %edx
  ; mov (U16)... %edx
  cmp %edx 2400 ; 8x16: 4800
  js .scroll
  bytes $E8 $03 GovnBIOS_cur.posh
  pop %eax
  irts
.nl:
  bytes $D8 $00 GovnBIOS_cur.posh
  div %eax 80
  inx %eax
  mul %eax 80
  cmp %eax 2400 ; 8x16: 4800
  js .scroll
  bytes $E8 $00 GovnBIOS_cur.posh
  int $11
  pop %eax
  irts
.bs:
  bytes $D8 $00 GovnBIOS_cur.posh
  cmp %eax 0
  je .end
  dex %eax
  bytes $E8 $00 GovnBIOS_cur.posh
.end:
  pop %eax
  irts
.scroll:
; Uh oh!
  mov %edx $4F00A0
.sloop:
  ld %edx %eax
  sub %edx 164
  sd %edx %eax
  add %edx 160
  cmp %edx $4F12C0 ; 8x16: $4F2580
  jn .sloop
; Erase last line
  sub %edx 160
  bytes $D0 $00 GovnBIOS_cur.c
  sal %eax 8
.eloop:
  sw %edx %eax
  cmp %edx $4F12C0 ; 8x16: $4F2580
  jn .eloop

  mov %eax 2320 ; 8x16: 4720
  bytes $E8 $00 GovnBIOS_cur.posh
  pop %eax
  irts

GovnBIOS_vgetc:
  psh %ebx psh %ecx psh %esi psh %egi
  mov %egi 0 ; 0 - cell clear
  jsr .invert
  mov %ebx 0 ; 0 - wait for press, >=1 - key, wait for unpress
  mov %ecx 0
.loop:
  jsr GovnBIOS_getnorkey
  cmp %ebx 0
  je .waiter
  cmp %eax 0
  jne .achk
  cmp %egi 0
  je .dontclear
  jsr .invert
.dontclear:
  mov %eax %ebx
  pop %egi pop %esi pop %ecx pop %ebx
  irts
.waiter:
  cmp %eax 0
  je .achk
  cmp %eax $39
  jn .txtkey
  sub %eax $39
  mov %esi .extra
  add %esi %eax
  lb %esi %ebx
  jmp .achk
.txtkey:
  sub %eax 4
  jsr GovnBIOS_getmodkey
  mul %edx 53
  mov %esi .layout
  add %esi %edx
  add %esi %eax
  lb %esi %ebx
.achk:
  mov %edx 33
  int $22
  inx %ecx
  cmp %ecx 15
  jne .loop

.blink:
  psh .loop
; flasher 3000
.invert:
  bytes $D8 $02 GovnBIOS_cur.posh
  add %ecx %ecx
  add %ecx $4F0001
  lb %ecx %eax
  mov %edx %eax
  not %eax
  dex %ecx
  sb %ecx %eax
  int $11
  not %egi
  mov %ecx 0
  rts
.layout: bytes "abcdefghijklmnopqrstuvwxyz1234567890" $0A $1B $7F $09 " -=[]\`;'`,./"
.shiftd: bytes "ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#^$%^^&*()" $0A $1B $7F $09 " _+{}|~:\"~<>?"
.extra:  bytes $13 $E0 $E1 $E2 $E3 $E4 $E5 $E6 $E7 $E8 $E9 $EA $EB $14 $17 $12 $07 $C3 $C2 $FE $B4 $C1 $10 $11 $1F $1E

GovnBIOS_getmodkey: ; %edx - Mod bitmask
  mov %esi $480005
.sloop:
  lb %esi %edx
; Shift only for now
  cmp %edx $E1
  je .setshift
  cmp %edx $E5
  je .setshift
  cmp %esi $48000B
  jne .sloop
  mov %edx 0
  rts
.setshift:
  mov %edx 1
  rts

GovnBIOS_getnorkey: ; %eax - Key
  mov %eax 0
  mov %esi $480005
.loop:
  lb %esi %eax
  cmp %eax 4
  jn .aloop
; *Lock keys
  cmp %eax $39
  je .aloop
  cmp %eax $47
  je .aloop
  cmp %eax $53
  rn
.aloop:
  cmp %esi $48000B
  jne .loop
  rts
; END Gravno text mode

; BEGIN Info screen
GovnBIOS_post:
  ; Output first 3 lines
  mov %esi INTROMSG
  int $91

  ; Get CPU info
  int $A
  mov %egi CPUMSGDAT
  sd %egi %eax
  sd %egi %ebx
  sd %egi %ecx
  sd %egi %edx
  sd %egi %esi
; Find end and replace it
  mov %egi CPUMSGDAT
  mov %ecx 19
.nonul:
  lb %egi %eax
  cmp %eax 0
  je .cidend
  lp .nonul
.cidend:
  dex %egi
  mov %eax $204F661C ; "^\fO "
  sd %egi %eax
  mov %eax ']'
  sb %egi %eax

  mov %esi RAMMSGPRE
  int $91
  mov %eax %e8
  div %eax $100000
  jsr GovnBIOS_vputi
  mov %esi RAMMSGSUF
  int $91

  mov %esi VIDMSG
  int $91

  mov %esi CPUMSGPRE
  int $91

  jsr GovnBIOS_showdisks
  ; Disk initialization does take a long time
  ; So beep...
  mov %edx $0C00
  mov %esi 1000
  mov %eax 7
  int $23

  cmp %egi 0
  jne .z
  mov %esi NODISKSMSG
  int $91

.z:
  mov %esi PROMPT
  int $91

.query:
  int $93
  cmp %eax '0'
  je .shut
  cmp %eax '1'
  jn .beep
  cmp %eax '9'
  js .beep
; Check if bootloader OK
  mov %egi %eax
  sub %egi '1'

  mov %eax 0
  mov %esi $C00000
  ldds %egi
  cmp %eax 0
  je .beep

; Echo
  mov %eax %egi
  add %eax '1'
  int $92
  mov %eax '$'
  int $92
  int $11
; boot
  mov %e9 %egi
  jmp GovnBIOS_Boot
.beep:
  mov %esi 262
  mov %edx $0C00
  mov %eax 15
  int $23
  jmp .query
.shut:
  hlt

.smartsleep:
  psh %edx
  mov %edx 8
  int $22
  pop %edx
  sub %edx 8
  cmp %edx 0
  js .smartsleep
  rts

GovnBIOS_showdisks:
  mov %egi 0
  mov %ecx 0
.loop:
  mov %esi 0
  mov %eax $100
  ldds %ecx
  cmp %eax $100
  jne .fnd
.aloop:
  inx %ecx
  cmp %ecx 8
  jne .loop
  rts
.fnd:
  inx %egi
  mov %esi .diskprefix
  int $91
  mov %eax '1'
  add %eax %ecx
  int $92

; GovnFS 2 detector
  mov %esi 0
  ldds %ecx
  cmp %eax $42
  jne .notgfs2
  mov %eax ' '
  int $92
  mov %esi $10
  ldds %ecx
  int $92
  mov %eax '/'
  int $92
.notgfs2:

  mov %esi .diskinfix
  int $91

; .binsearch:
;   mov %ebx 0
;   mov %edx $7FFFFFFF
; .iter:
;   mov %esi %ebx
;   add %esi %edx
;   sar %esi 1
;   mov %eax $100
;   ldds %ecx
;   cmp %eax $100
;   je .nah
;   mov %ebx %esi
;   jmp .chk
; .nah:
;   mov %edx %esi
;   inx %edx
; .chk:
;   psh %esi
;   mov %esi %edx
;   sub %esi %ebx
;   cmp %esi 3
;   pop %esi
;   js .iter
;   mov %eax %esi
  psh %edx
  mov %edx %ecx
  int $0B
  mov %eax %edx
  pop %edx
  ; inx %eax ; %esi is last byte on disk
  div %eax $100000
  jsr GovnBIOS_vputi
  mov %esi .disksuffix
  int $91
  jmp .aloop

.diskprefix: bytes " Disk ^@"
.diskinfix: bytes ": ^@"
.disksuffix: bytes "MiB$^@"
; END Info screen

; booter
GovnBIOS_Boot:
  mov %esi $C00000
  mov %egi $030000
.loop:
  ldds %e9
  inx %esi
  cmp %eax $AA
  jne .notbs
  ldds %e9
  cmp %eax $55
  je .boot    ; Jump to the boot sector loaded
              ; from the primary disk
  mov %eax $AA
.notbs:
  sb %egi %eax
  jmp .loop
.boot:
  ; clear registers
  xor %eax %eax
  xor %ebx %ebx
  xor %ecx %ecx
  xor %edx %edx
  xor %esi %esi
  xor %egi %egi
  xor %e8 %e8 ; From cpuid
  ; E9 is not cleared so that os knows what disk it is booting from :D
  jmp $030000

; Uncomment this for the default CGA-16 palette
GovnBIOS_palette: bytes $00 $00 $00 $54 $A0 $02 $40 $55 $15 $00 $15 $54 $B5 $02 $B5 $56 $4A $29 $4A $7D $EA $2B $EA $7F $5F $29 $5F $7D $FF $2B $FF $7F

; Uncomment this to have One Dark
; GovnBIOS_palette: bytes $A6 $14 $AE $71 $0F $4F $0F $73 $BD $32 $FB $61 $D8 $2A $D7 $56 $6C $29 $AE $71 $0F $4F $0F $73 $BD $32 $FB $61 $D8 $2A $FF $7F

; Uncomment this to have Gruvbox
; GovnBIOS_palette: bytes $A5 $14 $83 $64 $43 $4E $64 $6A $11 $22 $90 $59 $6D $36 $70 $56 $0E $4A $26 $7D $E4 $5E $E5 $7E $93 $42 $13 $6A $0F $47 $76 $77

; Uncomment this for Solarized Dark
; GovnBIOS_palette: bytes $A6 $00 $C5 $6C $60 $42 $20 $5A $3A $12 $D0 $68 $93 $16 $BA $77 $C8 $00 $22 $65 $AE $2D $F0 $31 $52 $42 $D8 $35 $94 $4A $DC $7F  

; Uncomment this for Everforest
; GovnBIOS_palette: bytes $C7 $14 $F0 $71 $10 $53 $EF $6E $F6 $3E $76 $6A $12 $43 $15 $6B $08 $19 $F0 $71 $10 $53 $EF $6E $F6 $3E $76 $6A $12 $43 $FD $7F  

; Uncomment this for Rose Pine
; GovnBIOS_palette: bytes $44 $0C $B2 $75 $3B $4F $0E $7B $D1 $19 $9C $62 $F7 $76 $7E $73 $87 $10 $B2 $75 $3B $4F $0E $7B $D1 $19 $9C $62 $F7 $76 $7E $73  

; Uncomment this for Monokai
; GovnBIOS_palette: bytes $A5 $14 $91 $7D $6E $57 $6C $7F $6C $7E $7E $56 $7D $3F $FF $7F $CE $39 $91 $7D $6E $57 $6C $7F $6C $7E $7E $56 $7D $3F $FF $7F  

; Uncomment this for Tango
; GovnBIOS_palette: bytes $63 $0C $00 $50 $60 $26 $80 $62 $94 $19 $4F $39 $60 $65 $F7 $5E $4A $29 $A5 $74 $86 $47 $A9 $7F $79 $3A $F5 $55 $A7 $7E $BD $77  

GovnBIOS_cur: .posh: reserve 2 bytes .c: reserve 1 bytes

INTROMSG:
  bytes "^\rGovnBIOS [" $FB "] Gravno power we need but don't implement$"
  bytes $9B " 2025 " $F0 "816 & ^\bP ^\bA Roma$$"
  bytes "^\fOBoot   [ ^\fLHOLY^\fO ]$^@"

RAMMSGPRE: bytes "RAM    [ ^\fK^@"
RAMMSGSUF: bytes " MiB OK^\fO ]^@"
VIDMSG:    bytes "^\c35Video  [ ^\fKGG69-4932 (mode 2)^\fO ]$^@"
CPUMSGPRE: bytes "CPU    [ ^\fK"
CPUMSGDAT: bytes "                         "

  bytes "^\c35FPU    [ ^\fKFlot^\fO ]$"
  bytes "HDD    [ ^\fLTODO^\fO ]^\c35Color  [ ^\fAA^\fBB^\fCC^\fDD^\fEE^\fFF^\fGG^\fHH^\fII^\fJJ^\fKK^\fLL^\fMM^\fNN^\fOO^\fPP^\fO ]$$^\r^@"

NODISKSMSG:
  bytes "^\fL" $20 $20 $DB $DB " ^\fPTBo" $96 " gucK -- B c " $89 "$"
  bytes "^\fL" $20 $DB $DF $20 " ^\fP$"
  bytes "^\fL" $DB $DB $DB $DB " ^\fHGovnFloppy " $E3 "og" $E3 "uca" $EF" ykaZ. Te" $E3 "epb HE" $EF "b3A.$"
  bytes "^\fL" $20 $20 $DB $20 " ^\fP$"
  bytes "^\fL" $20 $DB $20 $20 " ^\fMKu" $EB "ep" $E2 "oBno2. " $E3 "og" $E3 "uca" $E7 "ca^\r$^@"

PROMPT:        bytes "$Choose disk by number or press 0 to shutdown:$^\bJ^\fA^P^\bE^\fJ^P^\bP^\fE^P^\bA^\fP^P^\r^@"
