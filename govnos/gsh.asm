; gsh.asm -- a basic shell implementation, that originally was at boot.asm
; but now the RO GovnFS 2.0 driver is complete, so i seprated it to a file that
; loads at startup

  jmp gshMain
gshMain:
  mov %esi gshWelcome
  int $81
gshShell:
  mov %esi gshPS1
  int $81

  mov %esi scans_len
  mov %eax $0000
  sw %esi %eax

  mov %esi gshCommand
  jsr scans

  mov %esi gshCommand
  mov %egi gshCommExit
  jsr strcmp
  cmp %eax $00
  je gshExit

  mov %esi gshCommand
  mov %egi gshCommHelp
  jsr strcmp
  cmp %eax $00
  je gshHelp

  mov %esi gshCommand
  mov %egi gshCommHi
  jsr strcmp
  cmp %eax $00
  je gshHi

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
  jmp gshBadComm
.jsr:
  jsr $200000
  jmp gshAftexec
gshHi:
  mov %esi gshHw
  int $81
  jmp gshAftexec
gshHelp:
  mov %esi gshHelpMsg
  int $81
  jmp gshAftexec
gshExit:
  rts
gshBadComm:
  psh '"'
  int $02
  mov %esi gshCommand
  int $81
  mov %esi gshBadCommMsg
  int $81
  jmp gshAftexec

gshAftexec:
  jmp gshShell
  rts

gshHw:      bytes "Hiiiii :3$^@"
gshWelcome: bytes "Welcome to gsh, a simple GovnOS shell$^@"
gshPS1:     bytes "^$ ^@"
gshCommand: reserve 128 bytes

gshCommHi:     bytes "hi^@"
gshCommHelp:   bytes "help^@"
gshCommExit:   bytes "exit^@"
gshBadCommMsg: bytes "\": bad command or file name$^@"

gshHelpMsg:    bytes "+-------------------------------+$"
               bytes "| GovnOS help page 1/1          |$"
               bytes "|   exit    Exit from the shell |$"
               bytes "|   help    Show help           |$"
               bytes "+-------------------------------+$^@"

