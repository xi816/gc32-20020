#include "../fs/govnfs.asm"

jmp kmain

; write -- Write n characters to the screen
; Arguments:
;   ecx -- count
;   esi -- string
write:
  psh %eax
  dex %ecx
.lp:
  lb %esi %eax
  cmp %eax 0
  je .z
  int $92
.z:
  lp .lp
  pop %eax
  rts

; hputc -- put a hex character 00-FF
; Arguments:
;   eax -- number
hputc:
  mov %egi xsyms
  div %eax 16
  mov %e10 %eax
  mov %e11 %edx
  add %e10 xsyms
  add %e11 xsyms
  lb %e10 %eax int $92
  lb %e11 %eax int $92
  rts
xsyms: bytes "0123456789ABCDEF"

; puti -- Write a 32-bit unsigned number to the screen
; Arguments:
;   eax -- number
puti:
  mov %egi puti_buf
  add %egi 9
.lp:
  div %eax 10 ; Divide and get the remainder into %edx
  add %edx 48 ; Convert to ASCII
  sb %egi %edx
  sub %egi 2
  cmp %eax $00
  jne .lp
  mov %esi puti_buf
  mov %ecx 10
  jsr write
  jsr puti_clr
  rts
puti_clr:
  mov %esi puti_buf
  mov %eax $00
  mov %ecx 9 ; 10 == floor(log(U32_MAX))+1;
.lp:
  sb %esi %eax
  lp .lp
  rts
puti_buf: reserve 10 bytes

; putx -- Write a 32-bit unsigned hex number to the screen
; Arguments:
;   eax -- number
putx:
  jsr putx_clr
  mov %egi putx_buf
  add %egi 7
.lp:
  div %eax 16 ; Divide and get the remainder into %edx
  mov %e10 xsyms
  add %e10 %edx
  lb %e10 %edx
  sb %egi %edx
  sub %egi 2
  cmp %eax $00
  jne .lp
  mov %esi putx_buf
  mov %ecx 8
  jsr write
  rts
putx_clr:
  psh %eax
  mov %esi putx_buf
  mov %eax %e8
  mov %ecx 7 ; 8 == floor(log16(U32_MAX))+1;
.lp:
  sb %esi %eax
  lp .lp
  pop %eax
  rts
putx_buf: reserve 8 bytes

strtok:
  lb %esi %eax
  cmp %eax %ecx
  re
  jmp strtok

; strcmp -- Compare two strings
; Arguments:
;   esi -- string 1
;   egi -- string 2
; Returns:
;   eax -- result (0 for equal, 1 for not equal)
strcmp:
  lb %esi %eax
  lb %egi %ebx
  cmp %eax %ebx
  jne .fail
  cmp %eax $00
  je .eq
  jmp strcmp
.eq:
  mov %eax $00
  rts
.fail:
  mov %eax $01
  rts

; strcpy -- Copy string
; Arguments:
;   esi -- source
;   egi -- destination
; Returns:
;   eax -- result (0 for equal, 1 for not equal)
strcpy:
  lb %esi %eax
  cmp %eax $00
  re
  sb %egi %eax
  jmp strcpy

; scani -- Read a 32-bit unsigned integer stdout and save to ax
; Returns:
;   eax -- number
scani:
  mov %eax $00
.lp:
  psh %eax
  int $93
  mov %ebx %eax
  pop %eax

  cmp %ebx $0A ; Check for Enter
  re
  cmp %ebx $20 ; Check for space
  re
  cmp %ebx $7F ; Check for Backspace
  je .back
  cmp %ebx $30 ; Check if less than '0'
  jl .lp
  cmp %ebx $3A ; Check if greater than '9'+1
  jg .lp

  mul %eax 10

  psh %eax
  mov %eax %ebx
  int $92
  pop %eax

  sub %ebx 48
  add %eax %ebx
  jmp .lp
.back: ; Backspace handler
  cmp %eax 0
  jne .back_strict
  jmp .lp
.back_strict:
  mov %esi krnl_bksp_seq
  psh %eax
  int $91
  pop %eax
  div %eax 10
  jmp .lp

; scans -- Read a string from stdout and save to a buffer
; Arguments:
;   esi -- buffer address
scans:
  int $93
  cmp %eax $7F
  je .back
  cmp %eax $1B
  je scans
  int $92
  cmp %eax $0A
  je .end
  sb %esi %eax
  inx @scans_len
  jmp scans
.back:
  mov %egi scans_len
  lw %egi %eax
  cmp %eax $00
  je scans
.back_strict:
  psh %esi
  mov %esi krnl_bksp_seq
  int $91
  pop %esi
  dex %esi
  dex @scans_len
  jmp scans
.end:
  mov %eax $00
  sb %esi %eax
  rts
scans_len: reserve 2 bytes

; memsub -- Substitute one character to another in a string
; Arguments:
;   eax -- from character
;   ebx -- to character
;   esi -- string
memsub:
  dex %ecx
.lp:
  lb %esi %eax
  cmp %eax %ebx
  je .sub
  lp .lp
  rts
.sub:
  dex %esi
  sb %esi %edx
  lp .lp
  rts

memcmp:
  dex %ecx
.lp:
  lb %esi %eax
  lb %egi %ebx
  cmp %eax %ebx
  jne .fail
  lp .lp
.eq:
  mov %eax $00
  rts
.fail:
  mov %eax $01
  rts

; dmemcpy -- Load n bytes from disk to memory
; Arguments:
;   esi -- from address (disk)
;   egi -- to address (memory)
dmemcpy:
  dex %ecx
.lp:
  ldds %e9
  inx %esi
  sb %egi %eax
  lp .lp
  rts

; pstrcmp -- Compare two strings until predicate
; Arguments:
;   ecx -- predicate
;   esi -- string 1
;   egi -- string 2
pstrcmp:
  psh %eax
  psh %ebx
.loop:
  lb %esi %eax
  lb %egi %ebx
  cmp %eax %ebx
  jne .fail
  cmp %eax %ecx
  je .eq
  jmp .loop
.eq:
  pop %ebx
  pop %eax
  mov %eax $00
  rts
.fail:
  pop %ebx
  pop %eax
  mov %eax $01
  rts

; strext -- Add new character after the first NUL terminator
; ebx -- char
; esi -- string
strext:
  psh %eax
  psh %esi
  ; and %ebx $FF
.lp:
  lb %esi %eax
  cmp %eax 0
  jne .lp
  dex %esi
  sw %esi %ebx
  pop %esi
  pop %eax
  rts

; Panic error codes:
;   $F0000000         Unknown error
;   $F0000001         Math domain error
krnl_panic:
  mov %esi $004A0008
  mov %eax $01FB
  sw %esi %eax
  mov %esi krnl_panic00
  int $91
  psh %eax
  mov %eax %e11
  mov %e8 '0'
  jsr putx
  pop %eax
  mov %esi krnl_panic03
  int $91

  mov %eax 0
  mov %ecx 7
.lp:
  psh %eax psh %ecx
  psh %eax mov %eax ' ' int $92 int $92 int $92 pop %eax
  jsr puti
  mov %esi krnl_panic01
  int $91
  pop %ecx pop %eax
  add %eax 14
  mov %edx 600
  int $22
  lp .lp
  ; Clear the screen and reboot
  mov %esi krnl_panic02
  int $91
  int $11
  jmp $00700000

; kmain executes when the kernel loads
kmain:
  ; map syscalls
  mov %esi krnlmsg00
  int $91
  mov %esi kint
  sti $80
  mov %esi krnlmsgdone
  int $91
  mov %esi krnlmsg02
  int $91
  mov %esi $01000000
  jsr scans
  mov %esi krnlmsg03
  int $91
  mov %esi $01000000
  jsr scans
  mov %esi krnlmsg01
  int $91
  rts

;; KERNEL API START ;;

; Arguments:
;   eax -- syscall number,
;   ebx, ecx, edx, esi, egi, e8

; $00 -- write
; Arguments:
;   ebx -- string
;   ecx -- count
ksys_write:
  psh %ebx psh %ecx psh %edx psh %esi psh %egi psh %e8
  dex %ecx
.lp:
  lb %ebx %eax
  cmp %eax 0
  je .z
  int $92
.z:
  lp .lp
  pop %e8 pop %egi pop %esi pop %edx pop %ecx pop %ebx
  rts

; $01 -- read
; Arguments:
;   ebx -- buffer
;   ecx -- max char count
ksys_read:
  psh %ebx psh %ecx psh %edx psh %esi psh %egi psh %e8
.loop:
  cmp %edx %ecx
  je .end
  int $93
  cmp %eax $7F
  je .back
  cmp %eax $1B
  je .loop
  int $92
  cmp %eax $0A
  je .end
  sb %ebx %eax
  inx %edx
  jmp .loop
.back:
  cmp %edx $00
  je .loop
.back_strict:
  psh %ebx
  mov %ebx krnl_bksp_seq
  int $91
  pop %ebx
  dex %ebx
  dex %edx
  jmp .loop
.end:
  mov %eax %edx
  pop %e8 pop %egi pop %esi pop %edx pop %ecx pop %ebx
  rts

; kint -- call a system call by number
; Arguments:
;   eax      -- syscall number
;   ebx - e8 -- passed arguments
kint:
  mul %eax 4
  mov %esi kmap
  add %esi %eax
  ld %esi %eax
  jsr %eax
  irts

kmap:
  bytes ksys_write        ; $00
  bytes ksys_read         ; $01
  reserve 1016 bytes      ; 254 unused dwords

;; KERNEL API END ;;

; Constants/data
krnla00: bytes "lol lets try to output 57005 using putx ^@"
krnla01: bytes "$what about 5256? ^@"
krnlmsg00:     bytes "kernel: Initializing system calls... ^@"
krnlmsg01:     bytes "$kmain done, returning$^@"
krnlmsg02:     bytes "GovnOS 1.0.0 beta$$govnos login: ^@"
krnlmsg03:     bytes "Password: ^@"
krnlmsgdone:   bytes "done$^@"
krnl_bksp_seq: bytes "^H ^H^@"
krnl_panic00:  bytes "^\bE^\z^\fP$"
               bytes "                xNNd$"
               bytes "              :KMWo$"
               bytes "     odo:     KMMl$"
               bytes "    oMMM0    OMMx$"
               bytes "    :0K0o   cMMN$"
               bytes "            xMMO$"
               bytes "            OMMd$"
               bytes "            OMMx$"
               bytes "            dMMO$"
               bytes "    :O0Ol   :WMW:$"
               bytes "    dMMM0    xMMO$"
               bytes "     oxd:     OMMx$"
               bytes "               OMMk$"
               bytes "                l00d$$"
               bytes "   Your PC ran into a problem and needs to restart. We're$"
               bytes "   not collecting any error info, GovnOS will soon$"
               bytes "   restart for you.$$$$$$$*** STOP: ^$^@"
krnl_panic01:  bytes "% complete^\u02$^@"
krnl_panic02:  bytes "^\r^\z^@"
krnl_panic03:  bytes "^\u05^@"
krnl_show_cursor: bytes "^[[0m^[[H^[[2J^[[?25h^@"

