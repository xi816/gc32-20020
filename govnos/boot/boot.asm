; boot.asm -- a bootloader for the GovnOS operating system
reboot: jmp boot

b_scans:
  mov %e8 $00
.lp:
  int $93
  ; pop %eax
  cmp %eax $7F
  je .back
  ; cmp %eax $1B
  ; je b_scans.lp
  ; psh %eax
  int $92
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
  int $91
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

b_dstrcpy:
  ldds %e9
  inx %esi
  cmp %eax $00
  re
  sb %egi %eax
  jmp b_dstrcpy

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
  cmp %eax 0
  je .llp
  int $92
.llp:
  lp .lp
  pop %eax
  rts

b_hputc:
  mov %egi b_hputc_sym
  div %eax 16
  mov %e10 %eax
  mov %e11 %edx
  add %e10 b_hputc_sym
  add %e11 b_hputc_sym
  lb %e10 %eax int $92
  lb %e11 %eax int $92
  rts
b_hputc_sym: bytes "0123456789ABCDEF"

b_puti:
  mov %e11 $00
  mov %egi b_puti_buf
  add %egi 10
.lp:
  div %eax 10 ; Divide and get the remainder into %edx
  add %edx 48 ; Convert to ASCII
  sb %egi %edx
  sub %egi 2
  cmp %eax $00
  jne .lp
  mov %esi b_puti_buf
  mov %ecx 11
  jsr b_write
  jsr b_puti_clr
  rts
b_puti_clr:
  mov %esi b_puti_buf
  mov %eax %e11
  mov %ecx 10 ; 11
.lp:
  sb %esi %eax
  lp .lp
  rts
b_puti_buf: reserve 11 bytes

b_scani:
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
  mov %esi bs_seq
  psh %eax
  int $91
  pop %eax
  div %eax 10
  jmp .lp

; GovnFS 2.0 driver stores frequently used information
; to a config field at bank $1F
; Entries:
;   $1F0000 -- Drive letter
;   $1F0010 -- Filesystem name
gfs2_configure:
  mov %esi $000010
  mov %egi $1F0000
  ldds %e9
  sb %egi %eax

  mov %esi $000001
  mov %egi $1F0010
  jsr b_dstrcpy
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
  ; Clear screen
  mov %esi cls_seq
  int $91

  ; Configure disk
  mov %esi gconf00_msg
  int $91
  jsr gfs2_configure

  ; Load the kernel libraries
  mov %esi gconf01_msg
  int $91

  ; Show number of disk sectors used
  mov %esi emp_sec_msg00
  int $91
  jsr fre_sectors
  jsr b_puti
  mov %esi emp_sec_msg01
  int $91

  mov %ebx krnl_file_header
  mov %egi $A00000
  jsr gfs2_read_file
  cmp %eax $00
  jne no_krnl
  jsr $A00000
  ; kmain returns here
  mov %ebx shell_file_header
  mov %egi $B00000
  jsr gfs2_read_file
  cmp %eax $00
  jne no_shell
  mov %esi welcome_msg00
  int $91
  mov %esi welcome_msg01
  int $91
  jsr $B00000
  jmp shell
no_krnl:
  mov %esi nokrnl_err
  int $91
  int $93
  hlt
no_shell:
  mov %esi noshell_err
  int $91
  int $93
  hlt
shell:
  mov %esi shellrc_msg
  int $91
.prompt:
  mov %esi env_PS
  int $91

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
  mov %egi com_curl
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_curl

  mov %esi command
  mov %egi com_time
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_time

  mov %esi command
  mov %egi com_rand
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_rand

  mov %esi command
  mov %egi com_disi
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_diski

  mov %esi command
  mov %egi com_rebo
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_reboot

  mov %esi command
  mov %egi com_prom
  mov %ecx ' '
  jsr b_pstrcmp
  cmp %eax $00
  je govnos_prompt

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
  int $91
  mov %esi command
  int $91
  mov %eax '$'
  int $92
.aftexec:
  jmp .prompt
govnos_hi:
  mov %esi hai_world
  int $91
  jmp shell.aftexec
govnos_curl:
  mov %esi command
  add %esi 5 ; hardcode
  mov %egi $01000000
  int $3C
  cmp %edx 1
  je .err
  mov %esi $01000000
  int $91
  mov %eax '$' int $92
  jmp shell.aftexec
.err:
  mov %esi curlerr
  int $91
  jmp shell.aftexec
govnos_date:
  int 3
  mov %eax %edx
  sar %eax 9
  add %eax 1970
  psh %edx
  jsr b_puti
  pop %edx
  mov %eax '-' int $92
  mov %eax %edx
  sar %eax 5
  mov %ebx $000F
  and %eax %ebx
  inx %eax
  cmp %eax 10
  jg .p0
  psh %eax
  mov %eax '0' int $92
  pop %eax
.p0:
  psh %edx
  jsr b_puti
  pop %edx
  mov %eax '-' int $92
  mov %eax %edx
  mov %ebx $001F
  and %eax %ebx
  inx %eax
  cmp %eax 10
  jg .p1
  psh %eax
  mov %eax '0' int $92
  pop %eax
.p1:
  jsr b_puti
  mov %eax '$' int $92
  jmp shell.aftexec
govnos_rand:
  int $21
  mov %eax %edx
  jsr b_puti
  mov %eax '$' int $92
  jsr shell.aftexec
govnos_diski:
  mov %esi diski_001
  int $91
  mov %esi $1F0000
  lb %esi %eax int $92
  mov %eax '/' int $92
  mov %eax '$' int $92

  mov %esi diski_002
  int $91
  mov %esi $1F0010
  int $91
  mov %eax '$' int $92

  mov %esi diski_003
  int $91
  mov %edx %e9
  int $0B
  mov %eax %edx
  div %eax 1048576
  jsr b_puti
  mov %esi diski_004
  int $91
  mov %eax '$' int $92

  jsr shell.aftexec
govnos_reboot:
  ; Clear the screen
  mov %esi cls_seq
  int $91
  ; Basically jumps back to BIOS
  jmp $00700000
govnos_time:
  int 5
  mov %ebx %edx
  mov %eax %ebx
  div %eax 3600
  jsr b_puti
  mov %eax ':' int $92
  mov %eax %ebx
  div %eax 3600
  mov %eax %edx
  div %eax 60
  jsr b_puti
  mov %eax ':' int $92
  mov %eax %ebx
  div %eax 60
  mov %eax %edx
  jsr b_puti
  mov %eax '$' int $92
  jmp shell.aftexec
govnos_cls:
  mov %esi cls_seq
  int $91
  jmp shell.aftexec
govnos_help:
  mov %esi help_msg
  int $91
  jmp shell.aftexec
govnos_exit:
  hlt
  jmp shell.aftexec
govnos_echo:
  mov %esi command
  mov %ecx ' '
  jsr b_strtok
  int $91
  mov %eax '$' int $92
  jmp shell.aftexec
govnos_prompt:
  mov %esi prompt_001
  int $91
  mov %esi env_PS
  jsr b_scans
  jmp shell.aftexec

gconf00_msg:   bytes "boot: Starting GovnOS...$boot: Configuring GFS 2.1 disk...$^@"
gconf01_msg:   bytes "boot: Starting /bin/krnl.bin at ^$00A00000...$^@"
gconf02_msg:   bytes "boot: Starting /bin/shell.bin at ^$00B00000...$^@"
welcome_msg00: bytes "boot: Finished loading GovnOS$^@"
welcome_msg01: bytes "boot: Starting shell...$^@"
shellrc_msg:   bytes "^\bP             $^\bE             $^\bB             $^\r$^@"
emp_sec_msg00: bytes "$boot: GovnFS 2.1 uses ^\fK^@"
emp_sec_msg01: bytes "^\r disk sectors$$^@"
diski_001:     bytes "^\fKDisk info^\r$  Disk letter: ^@"
diski_002:     bytes "  Filesystem: ^@"
diski_003:     bytes "  Disk size: ^@"
diski_004:     bytes "MiB^@"
curlerr:       bytes "^\fJcurl^\r: connection refused$^@"
prompt_001:    bytes "Enter PS prompt: ^@"
bad_command:   bytes "Bad command: ^@"

help_msg:    bytes "^\fM+-------------------------------------------+$"
             bytes "^\fM|^\fCGovnOS help page 1/1^\fM                       |$"
             bytes "^\fM|  ^\fKcat         ^\fLOutput file contents^\fM         |$"
             bytes "^\fM|  ^\fKcurl        ^\fLGet data from URL (beta)^\fM     |$"
             bytes "^\fM|  ^\fKcalc        ^\fLCalculator^\fM                   |$"
             bytes "^\fM|  ^\fKcls         ^\fLClear the screen^\fM             |$"
             bytes "^\fM|  ^\fKdisk-i      ^\fLGet disk info^\fM                |$"
             bytes "^\fM|  ^\fKdir         ^\fLShow files on the disk^\fM       |$"
             bytes "^\fM|  ^\fKdate        ^\fLShow current date (%Y-%m-%d)^\fM |$"
             bytes "^\fM|  ^\fKecho        ^\fLEcho text back to output^\fM     |$"
             bytes "^\fM|  ^\fKexit        ^\fLExit from the shell^\fM          |$"
             bytes "^\fM|  ^\fKfdisk       ^\fLFormat disk^\fM                  |$"
             bytes "^\fM|  ^\fKfsec        ^\fLFormat disk sector^\fM           |$"
             bytes "^\fM|  ^\fKgsfetch     ^\fLShow system info^\fM             |$"
             bytes "^\fM|  ^\fKhelp        ^\fLShow help^\fM                    |$"
             bytes "^\fM|  ^\fKmemv        ^\fLMemory viewer^\fM                |$"
             bytes "^\fM|  ^\fKprompt      ^\fLChange prompt^\fM                |$"
             bytes "^\fM|  ^\fKrand        ^\fLGet random 32-bit number^\fM     |$"
             bytes "^\fM|  ^\fKreboot      ^\fLReboot GovnOS^\fM                |$"
             bytes "^\fM|  ^\fKtime        ^\fLShow current time (%H:%M:%S)^\fM |$"
             bytes "^\fM+-------------------------------------------+^\r$^@"

com_hi:      bytes "hi "
com_cls:     bytes "cls "
com_curl:    bytes "curl "
com_date:    bytes "date "
com_time:    bytes "time "
com_help:    bytes "help "
com_echo:    bytes "echo "
com_exit:    bytes "exit "
com_rand:    bytes "rand "
com_disi:    bytes "disk-i "
com_prom:    bytes "prompt "
com_rebo:    bytes "reboot "
hai_world:   bytes "hai world :3$^@"

env_HOST:    bytes "GovnPC 32 Pro Max^@"
env_OS:      bytes "GovnOS 1.0.0 beta^@"
env_CPU:     reserve 24 bytes ; To be filled by the O.E.M.

; TODO: unhardcode file header TODO: remove this todo
com_predefined_file_header: bytes "^Afile.bin^@^@^@^@bin^@"
shell_file_header:          bytes "^Ashell.bin^@^@^@bin^@"
krnl_file_header:           bytes "^Akrnl.bin^@^@^@^@bin^@"
file_header:                reserve 16 bytes
file_tag:                   bytes "bin^@"
nokrnl_err:                 bytes "^\fJFATAL ERROR!!!!!^\fP$"
                            bytes "The file krnl.bin could not be loaded from the disk$"
                            bytes "Press any key to shutdown$"
noshell_err:                bytes "^\fJError^\fP$"
                            bytes "The file /bin/shell.bin could not be loaded from the disk$"
                            bytes "Starting GovnBoot shell...$^@"

command:     reserve 256 bytes
clen:        reserve 2 bytes

bs_seq:      bytes "^H ^H^@"
cls_seq:     bytes "^\z^@"
env_PS:      bytes "^\fLGovnBoot> ^\r^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@"
bse:         bytes $AA $55

