; gsh.asm -- a basic shell implementation, that originally was at boot.asm
; but now the RO GovnFS 2.0 driver is complete, so i separated it to a file
; that loads at startup (true only after 07/18/25)

  jmp gshMain
gshMain:
  mov %esi gshWelcome
  int $91
  jsr gListEnv

gshShell:
  mov %esi gshPS1
  int $91

  mov %esi scans_len
  mov %eax $0000
  sw %esi %eax

  mov %esi gshCommand
  jsr scans
  dex %esi
  mov %eax $0020
  sw %esi %eax
gshFind:
  mov %edx 0
  mov %ebx gshList
.loop:
  mov %esi gshCommand
  mov %ecx ' '
  ld %ebx %egi
  cmp %egi 0 ; null-terminator, try to execute file
  je gshRead
  jsr pstrcmp
  cmp %eax $00 ; command found
  je gshExec
  add %edx 4
  jmp .loop
gshExec:
  mov %esi gshFunc
  add %esi %edx
  ld %esi %eax
  jmp %eax
gshRead:
  ; Remove space added for arg parsing
  mov %esi gshCommand
  mov %eax $20
  jsr b_strtok
  dex %esi
  mov %eax $00
  sb %esi %eax

  ; Make file header out of the filename
  mov %esi file_header
  mov %ecx 16
  jsr b_memset
  mov %esi gshCommand
  mov %egi file_header
  inx %egi
  jsr b_strcpy
  mov %esi file_tag
  mov %egi file_header
  add %egi 13
  mov %ecx 3
  jsr b_memcpy

  ; Read the file
  mov %ebx file_header
  mov %egi $200000
  jsr gfs2_read_file
  cmp %eax $00
  je .jsr
  jmp gshBadComm
.jsr:
  mov %r12 gshCommand ; Pass a pointer to command-line arguments via %r12
  psh %e9 ; Save disk id
  jsr $200000
  pop %e9
  jmp gshAftexec
gshHi:
  mov %esi gshHw
  int $91
  jmp gshAftexec
gshCls:
  mov %esi cls_seq
  int $91
  jmp gshAftexec
gshDate:
  int 3
  mov %eax %edx
  sar %eax 9
  add %eax 1970
  psh %edx psh %ecx psh %ebx psh %edx psh %esi psh %egi
  jsr puti
  pop %egi pop %esi pop %eax pop %ebx pop %ecx pop %edx
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
  psh %edx psh %ecx psh %ebx psh %edx psh %esi psh %egi
  jsr puti
  pop %egi pop %esi pop %eax pop %ebx pop %ecx pop %edx
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
  psh %edx psh %ecx psh %ebx psh %edx psh %esi psh %egi
  jsr puti
  pop %egi pop %esi pop %eax pop %ebx pop %ecx pop %edx
  mov %eax '$' int $92
  jmp gshAftexec
gshTime:
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
  jmp gshAftexec
gshHelp:
  mov %esi gshHelpMsg
  int $91
  jmp gshAftexec
gshEcho:
  mov %esi gshCommand
  mov %ecx ' '
  jsr strtok
  int $91
  mov %eax '$' int $92
  jmp gshAftexec
gshCurl:
  mov %esi gshCommand
  add %esi 5 ; hardcode
  mov %egi $01000000
  int $3C
  cmp %edx 1
  je .err
  mov %esi $01000000
  int $91
  mov %eax '$' int $92
  jmp gshAftexec
.err:
  mov %esi curlerr
  int $91
  jmp gshAftexec
gshRand:
  int $21
  mov %eax %edx
  jsr puti
  mov %eax '$' int $92
  jsr gshAftexec
gshDiski:
  mov %esi diski001
  int $91
  mov %esi $1F0000
  lb %esi %eax int $92
  mov %eax '/' int $92
  mov %eax '$' int $92

  mov %esi diski002
  int $91
  mov %esi $1F0010
  int $91
  mov %eax '$' int $92

  mov %esi diski003
  int $91
  mov %edx %e9
  int $0B
  mov %eax %edx
  div %eax 1048576
  jsr puti
  mov %esi diski004
  int $91
  mov %eax '$' int $92

  jsr gshAftexec
gshReboot:
  ; Reset stack pointer
  mov %esp $00FF0000
  mov %ebp %esp
  ; Clear the screen
  mov %esi cls_seq
  int $91
  ; Basically jumps back to BIOS
  jmp $00700000
gshShutdown:
  hlt
gshPrompt:
  mov %esi prompt001
  int $91
  mov %esi scans_len
  mov %eax $0000
  sw %esi %eax

  mov %esi gshPS1
  jsr scans
  jmp gshAftexec
gshExit:
  rts
gshBadComm:
  mov %eax '"' int $92
  mov %esi gshCommand
  int $91
  mov %esi gshBadCommMsg
  int $91
  jmp gshAftexec

gshAftexec:
  jmp gshShell

; getenv -- Get environment variable
; char* esi -- name
; char* edx -- buffer to store value
gGetEnv:
  mov %e8 gshENV
  mov %ebx '='
  jsr strext
.find:
  mov %egi %e8
  psh %esi
  jsr pstrcmp
  pop %esi
  cmp %eax $00
  je .get
  add %e8 32
  jmp .find
  mov %esi %egi
.get:
  dex %egi
  mov %e10 %egi
  mov %egi %edx
  mov %esi %e10
  psh %egi
  jsr strcpy
  pop %egi
  mov %esi %egi
  mov %ecx '='
  jsr strtok
  mov %eax $00
  sb %esi %eax
  rts

; setenv -- Set environment variable
; char* esi -- name
; char* edx -- new value
gSetEnv:
  mov %e8 gshENV
  mov %ebx '='
  jsr strext
.find:
  mov %egi %e8
  psh %esi
  jsr pstrcmp
  pop %esi
  cmp %eax $00
  je .set
  add %e8 32
  jmp .find
.set:
  dex %egi
  mov %esi %edx
  psh %egi
  jsr strcpy
  pop %egi
  mov %esi %egi
  mov %ecx '='
  jsr strtok
  mov %eax $00
  sb %esi %eax
  rts

gListEnv:
  mov %esi gshENV
  mov %ecx 31
.lp:
  psh %esi psh %ecx
  int $91
  pop %ecx pop %esi
  lb %esi %eax dex %esi
  cmp %eax '^@'
  je .n
  mov %eax '$' int $92
.n:
  add %esi 32
  lp .lp
  rts

; $14 $A6 $71 $AE $4F $0F $73 $0F $32 $BD $61 $FB $2A $D8 $56 $D7 $29 $6C $71 $AE $4F $0F $73 $0F $32 $BD $61 $FB $2A $D8

gshHw:      bytes "Hiiiii :3$^@"
gshWelcome: bytes "$gshell: Initializing ENV...$Dumping ENV:$^@"
gshPS1:     bytes "^$ ^@"
gshCommand: reserve 128 bytes
prompt001: bytes "New prompt: ^@"
diski001:  bytes "^\fKDisk info^\r$  Disk letter: ^@"
diski002:  bytes "  Filesystem: ^@"
diski003:  bytes "  Disk size: ^@"
diski004:  bytes "MiB^@"

gshChi:      bytes "hi "
gshCcls:     bytes "cls "
gshCexit:    bytes "exit "
gshCdate:    bytes "date "
gshCtime:    bytes "time "
gshCcurl:    bytes "curl "
gshChelp:    bytes "help "
gshCecho:    bytes "echo "
gshCrand:    bytes "rand "
gshCdisi:    bytes "disk-i "
gshCprom:    bytes "prompt "
gshCrebo:    bytes "reboot "
gshCshut:    bytes "shutdown "

gshe00: bytes "CPU^@"
gshe01: bytes "Setenv test^@"
gshe02: bytes "SHELL_FULL^@"

gshList: bytes gshChi
         bytes gshCcls
         bytes gshCexit
         bytes gshCdate
         bytes gshCtime
         bytes gshCcurl
         bytes gshChelp
         bytes gshCecho
         bytes gshCrand
         bytes gshCdisi
         bytes gshCprom
         bytes gshCrebo
         bytes gshCshut
         bytes 0 0 0 0

gshFunc: bytes gshHi
         bytes gshCls
         bytes gshExit
         bytes gshDate
         bytes gshTime
         bytes gshCurl
         bytes gshHelp
         bytes gshEcho
         bytes gshRand
         bytes gshDiski
         bytes gshPrompt
         bytes gshReboot
         bytes gshShutdown
         bytes 0 0 0 0

gshBadCommMsg: bytes "\": bad command or file name$^@"

gshHelpMsg:  bytes "^\fM+-------------------------------------------+$"
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

; 32 entries, 32 bytes each
gshENV:
  bytes "CUR=bin^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@"
  bytes "SHELL=gsh2^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@"
  bytes "SHELL_FULL=GovnShell 2.0.1^@^@^@^@^@^@"
  bytes "CPU=^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@"
  bytes "GPU=^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@"
  reserve 864 bytes ; 27 entries left

