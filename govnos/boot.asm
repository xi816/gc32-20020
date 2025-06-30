; boot.asm -- a bootloader for the GovnOS operating system
reboot: jmp boot

b_scans:
  mov %e8 $00
.lp:
  int 1
  pop %eax
  cmp %eax $7F
  je .back
  ; cmp %eax $1B
  ; je b_scans.lp
  psh %eax
  int 2
  cmp %eax $0A
  je .end
  sb %esi %eax
  inx @clen
  jmp b_scans.lp
.back:
  mov %egi clen
  lw %egi %eax
  cmp %eax $00
  je b_scans.lp
.back_strict:
  psh %esi
  mov %esi bs_seq
  int $81
  pop %esi
  sb %esi %e8
  sub %esi 2
  dex @clen
  jmp b_scans.lp
.end:
  mov %eax $00
  sb %esi %eax
  rts

b_strcmp:
  lb %esi %eax
  lb %egi %ebx
  cmp %eax %ebx
  jne .fail
  cmp %eax $00
  je .eq
  jmp b_strcmp
.eq:
  mov %eax $00
  rts
.fail:
  mov %eax $01
  rts

b_pstrcmp:
  lb %esi %eax
  lb %egi %ebx
  cmp %eax %ebx
  jne .fail
  cmp %eax %ecx
  je .eq
  jmp b_pstrcmp
.eq:
  mov %eax $00
  rts
.fail:
  mov %eax $01
  rts

b_dmemcmp:
  dex %ecx
.lp:
  ldds %e9
  inx %esi
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

b_strtok:
  lb %esi %eax
  cmp %eax %ecx
  re
  jmp b_strtok

b_strnul:
  lb %esi %eax
  cmp %eax $00
  je .nul
  mov %eax $01
  rts
.nul:
  mov %eax $00
  rts

b_strcpy:
  lb %esi %eax
  cmp %eax $00
  re
  sb %egi %eax
  jmp b_strcpy

b_memcpy:
  dex %ecx
.lp:
  lb %esi %eax
  sb %egi %eax
  lp .lp
  rts

b_memset:
  dex %ecx
  mov %eax $00
.lp:
  sb %esi %eax
  lp .lp
  rts

b_write:
  psh %eax
  dex %ecx
.lp:
  lb %esi %eax
  psh %eax
  int $02
  lp .lp
  pop %eax
  rts

b_puti:
  mov %egi b_puti_buf
  add %egi 7
.lp:
  div %eax 10 ; Divide and get the remainder into %edx
  add %edx 48 ; Convert to ASCII
  sb %egi %edx
  sub %egi 2
  cmp %eax $00
  jne .lp
  mov %esi b_puti_buf
  mov %ecx 8
  jsr b_write
  jsr b_puti_clr
  rts
b_puti_clr:
  mov %esi b_puti_buf
  mov %eax $00
  mov %ecx 7 ; 8
.lp:
  sb %esi %eax
  lp .lp
  rts
b_puti_buf: reserve 8 bytes

b_scani:
  mov %eax $00
.lp:
  int $01
  pop %ebx

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
  psh %ebx
  int $02
  sub %ebx 48
  add %eax %ebx
  jmp .lp
.back: ; Backspace handler
  cmp %eax 0
  jne .back_strict
  jmp .lp
.back_strict:
  mov %esi bs_seq
  psh %eax
  int $81
  pop %eax
  div %eax 10
  jmp .lp

; GovnFS 2.0 driver stores frequently used information
; to a config field at bank $1F
; Entries:
;   $1F0000 -- Drive letter
gfs2_configure:
  mov %esi $000010
  mov %egi $1F0000
  ldds %e9
  sb %egi %eax
  rts

gfs2_read_file:
  mov %edx $0001 ; Starting search at sector 1 (sector 0 is for header data)
  mov %esi $0200 ; Precomputed starting address (sector*512)
.lp:
  ldds %e9      ; Read the first byte from a sector to get its type
                ;   00 -- Empty sector
                ;   01 -- File start
                ;   02 -- File middle/end
                ;   F7 -- Disk end
  cmp %eax $01
  je .flcheck   ; Check filename and tag
  cmp %eax $00
  je .skip      ; Skip
  cmp %eax $F7
  je .fail
.flcheck:
  inx %esi       ; Get to the start of filename
  mov %ecx 15    ; Check 15 bytes
  psh %egi
  psh %ebx
  mov %egi %ebx
  inx %egi
  jsr b_dmemcmp
  pop %ebx
  pop %egi
  cmp %eax $00
  je flcpy
  inx %edx
  mov %esi %edx
  mul %esi $0200
  jmp .lp
.skip:
  add %esi $0200
  jmp .lp
.fail:
  mov %eax $01
  rts

flcpy:
  ; mov %egi $200000 ; should be configured by the jsrer
.read:
  cmp %edx $0000
  je .end
  mov %esi %edx
  mul %esi $0200
  add %esi 16  ; Skip the processed header
  mov %ecx 494 ; Copy 494 bytes (sectorSize(512) - sectorHeader(16) - sectorFooter(2))
  dex %ecx
.lp:
  ldds %e9
  inx %esi
  sb %egi %eax
  lp .lp
  ; inx %esi
  ldds %e9
  mov %ebx %eax
  inx %esi
  ldds %e9
  mul %eax $100
  add %eax %ebx
  cmp %eax $00
  je .end
  mov %esi %eax
  mul %esi $200
  add %esi 16
  mov %ecx 494
  ; dex %ecx
  lp .lp
.end:
  mov %eax $00
  rts

fre_sectors:
  mov %ebx 0
  mov %esi $000200
.lp:
  ldds %e9
  add %esi $200
  cmp %eax $01
  je .inc
  cmp %eax $F7
  je .end
  cmp %esi $800000
.inc: ; RIP GovnDate 2.025e3-04-13-2.025e3-04-13
  inx %ebx
  jmp .lp
.end:
  mov %eax %ebx
  rts

boot:
  ; Load the kernel libraries
  jsr gfs2_configure
  mov %esi welcome_msg
  int $81
  mov %esi krnl_load_msg
  int $81
  mov %esi emp_sec_msg00
  int $81
  jsr fre_sectors
  jsr b_puti
  mov %esi emp_sec_msg01
  int $81

  mov %ebx krnl_file_header
  mov %egi $A00000
  jsr gfs2_read_file
  cmp %eax $00
  jne shell
  jsr $A00000
shell:
.prompt:
  mov %esi env_PS
  int $81

  mov %esi clen
  mov %eax $0000
  sw %esi %eax
  mov %esi command
  jsr b_scans
  dex %esi
  mov %eax $0020
  sw %esi %eax
.process:
  mov %esi command
  lw %esi %eax
  cmp %eax $0020
  je .aftexec

  mov %esi command
  mov %egi com_hi
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_hi

  mov %esi command
  mov %egi com_date
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_date

  mov %esi command
  mov %egi com_time
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_time

  mov %esi command
  mov %egi com_echo
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_echo

  mov %esi command
  mov %egi com_exit
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_exit

  mov %esi command
  mov %egi com_cls
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_cls

  mov %esi command
  mov %egi com_help
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_help

  ; MAGIC CODE BEGIN
  mov %esi command
  mov %eax $20
  jsr b_strtok
  dex %esi
  mov %eax $00
  sb %esi %eax

  ; mov %esi command
  ; mov %eax $00
  ; jsr b_strtok
  ; dex %esi
  ; mov %eax $0020
  ; sw %esi %eax

  ; MAGIC CODE END
  ; fuck you string manipulation :]

  ; mov %esi command
  mov %esi file_header
  mov %ecx 16
  jsr b_memset
  mov %esi command
  mov %egi file_header
  inx %egi
  jsr b_strcpy
  mov %esi file_tag
  mov %egi file_header
  add %egi 13
  mov %ecx 3
  jsr b_memcpy

  mov %ebx file_header
  mov %egi $200000
  jsr gfs2_read_file
  cmp %eax $00
  je .jsr
  jmp .bad
.jsr:

  mov %r12 command ; Pass a pointer to command-line arguments via %r12
  psh %e9 ; Save disk id
  jsr $200000
  pop %e9
  jmp .aftexec
.bad:
  mov %esi bad_command
  int $81
  mov %esi command
  int $81
  psh '$'
  int $02
.aftexec:
  jmp .prompt
govnos_hi:
  mov %esi hai_world
  int $81
  jmp shell.aftexec
govnos_date:
  int 3
  mov %eax %edx
  sar %eax 9
  add %eax 1970
  psh %edx
  jsr b_puti
  pop %edx
  psh '-'
  int 2
  mov %eax %edx
  sar %eax 5
  mov %ebx $000F
  and %eax %ebx
  inx %eax
  cmp %eax 10
  jg .p0
  psh '0'
  int 2
.p0:
  psh %edx
  jsr b_puti
  pop %edx
  psh '-'
  int 2
  mov %eax %edx
  mov %ebx $001F
  and %eax %ebx
  inx %eax
  cmp %eax 10
  jg .p1
  psh '0'
  int 2
.p1:
  jsr b_puti
  psh '$'
  int 2
  jmp shell.aftexec
govnos_time:
  int 5
  mov %ebx %edx
  mov %eax %ebx
  div %eax 3600
  jsr b_puti
  psh ':' int 2
  mov %eax %ebx
  div %eax 3600
  mov %eax %edx
  div %eax 60
  jsr b_puti
  psh ':' int 2
  mov %eax %ebx
  div %eax 60
  mov %eax %edx
  jsr b_puti
  psh '$' int 2
  jmp shell.aftexec
govnos_cls:
  mov %esi cls_seq
  int $81
  jmp shell.aftexec
govnos_help:
  mov %esi help_msg
  int $81
  jmp shell.aftexec
govnos_exit:
  hlt
  jmp shell.aftexec
govnos_echo:
  mov %esi command
  mov %ecx ' '
  jsr b_strtok
  int $81
  psh $0A
  int 2
  jmp shell.aftexec

welcome_msg:   bytes "Welcome to ^[[33mGovnOS^[[0m$^@"
krnl_load_msg: bytes "Loading ^[[38;5;136m:/krnl.bin/com^[[0m...$^@"
emp_sec_msg00: bytes "$Disk sectors used: ^[[93m^@"
emp_sec_msg01: bytes "^[[0m$$^@"
bad_command:   bytes "Bad command: ^@"

help_msg:    bytes "^[[38;5;69m+-------------------------------------------+$"
             bytes "^[[38;5;69m|^[[96mGovnOS help page 1/1^[[38;5;69m                       |$"
             bytes "^[[38;5;69m|  ^[[92mcat         ^[[93mOutput file contents^[[38;5;69m         |$"
             bytes "^[[38;5;69m|  ^[[92mcalc        ^[[93mCalculator^[[38;5;69m                   |$"
             bytes "^[[38;5;69m|  ^[[92mcls         ^[[93mClear the screen^[[38;5;69m             |$"
             bytes "^[[38;5;69m|  ^[[92mdir         ^[[93mShow files on the disk^[[38;5;69m       |$"
             bytes "^[[38;5;69m|  ^[[92mdate        ^[[93mShow current date (%Y-%m-%d)^[[38;5;69m |$"
             bytes "^[[38;5;69m|  ^[[92mtime        ^[[93mShow current time (%H:%M:%S)^[[38;5;69m |$"
             bytes "^[[38;5;69m|  ^[[92mecho        ^[[93mEcho text back to output^[[38;5;69m     |$"
             bytes "^[[38;5;69m|  ^[[92mexit        ^[[93mExit from the shell^[[38;5;69m          |$"
             bytes "^[[38;5;69m|  ^[[92mgsfetch     ^[[93mShow system info^[[38;5;69m             |$"
             bytes "^[[38;5;69m|  ^[[92mhelp        ^[[93mShow help^[[38;5;69m                    |$"
             bytes "^[[38;5;69m+-------------------------------------------+^[[0m$^@"

com_hi:      bytes "hi "
com_cls:     bytes "cls "
com_date:    bytes "date "
com_time:    bytes "time "
com_help:    bytes "help "
com_echo:    bytes "echo "
com_exit:    bytes "exit "
hai_world:   bytes "hai world :3$^@"

env_HOST:    bytes "GovnPC 32 Pro Max^@"
env_OS:      bytes "GovnOS 0.8.0^@"
env_CPU:     reserve 24 bytes ; To be filled by the O.E.M.

; TODO: unhardcode file header TODO: remove this todo
com_predefined_file_header: bytes "^Afile.bin^@^@^@^@com^@"
krnl_file_header:           bytes "^Akrnl.bin^@^@^@^@com^@"
file_header:                reserve 16 bytes
file_tag:                   bytes "com^@"

command:     reserve 64 bytes
clen:        reserve 2 bytes

bs_seq:      bytes "^H ^H^@"
cls_seq:     bytes "^[[H^[[2J^@"
env_PS:      bytes "> ^@"

bse:         bytes $AA $55

