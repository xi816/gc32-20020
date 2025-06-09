/* GovnBIOS -- a basic input/output system for Govno Core 32-20020.
   BIOS is loaded into $700000 in memory.
*/
GovnBIOS_Reset:
  mov %esi puts
  sti $81
  mov %esi CLEARSCR
  int $81
  mov %esi WELCOMEMSG
  int $81

  mov %egi 0
.loop:
  mov %esi 0
  mov %eax $DEAF
  ldds %egi
  cmp %eax $DEAF
  je .ascan
  mov %esi DISKMSG
  int $81
  mov %eax %egi
  add %eax $31
  psh %eax
  int 2
  psh $0A
  int 2
  inx %egi
  jmp .loop

.ascan:
  cmp %egi 0
  jne .hazdisk
  mov %esi NO_DISKS
  int $81
  int $1
  mov %esi CLEARSCR
  int $81
  hlt
.hazdisk:
  mov %esi PROMPT
  int $81
.query:
  int 1
  pop %eax
  cmp %eax '0'
  je .quit
  cmp %eax $31
  jn .err
  cmp %eax $3A
  js .err
  sub %eax $31
  cmp %eax %egi
  js .err
  add %eax $31
  psh %eax
  int 2
  psh $0A
  int 2
  sub %eax $31

  psh %eax
  mov %esi CLEARSCR
  int $81
  pop %e9
  jmp GovnBIOS_Boot

.err:
  psh '?'
  int 2
  psh $8
  int 2
  js .query
.quit:
  mov %esi CLEARSCR
  int $81
  hlt

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
  ; Artificial boot delay so that user sees drive number echo
  mov %edx 128
  int $22
  ; clear registers
  xor %edx %edx
  xor %eax %eax
  xor %esi %esi
  xor %egi %egi
  ; E9 is not cleared so that os knows what disk it is booting from :D
  jmp $030000

puts:
  lb %esi %eax
  cmp %eax 0
  je .iend
  psh %eax
  int 2
  jmp puts
.iend:
  irts

; ANSI MAGIC HAPPENS HERE
CLEARSCR:      bytes "^[[0m^[[H^[[2J^@"
WELCOMEMSG:    bytes "^[[48;5;17m^[[H^[[2J^[[30m^[[48;5;253m^[[KGovnBIOS 7E9        Choose a disk to boot from$"
               bytes "^[[s^[[999B^[[30m^[[48;5;253m^[[K^[[999D1-8=Choose          0=Shutdown^[[48;5;232m^[[u^[[48;5;17m^[[97m^@"
DISKMSG:       bytes "  Disk #^@"
NO_DISKS:      bytes "^[[48;5;17m^[[97m^[[H^[[2JGovnOS 0.8$Copyright 7E8-7E9 © Xi816$$"
               bytes "Error -24 reading 1 sectors at 0, disk fd0$"
               bytes "The boot device could not be identified$"
               bytes "Initialization failed. Press any key (or the \"reset\" button) to shutdown.$^@"
PROMPT:        bytes "> ^@"
; biosBSE:     bytes $AA $55 - ne nado!

