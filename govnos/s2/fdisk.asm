fdisk_main:
  mov %esi fdisk001
  int $91
.again:
  int $93
  int $92
  cmp %eax 'y'
  je .format
  cmp %eax 'Y'
  je .format
  cmp %eax 'n'
  je .term
  cmp %eax 'N'
  je .term
  mov %esi fdisk002
  int $91
  jmp .again
.term:
  mov %eax '$' int $92
  rts
.format:
  mov %esi fdisk005
  int $91
  mov %egi header
  add %egi $10
  int $93
  int $92
  sb %egi %eax
  mov %eax '$' int $92
  mov %esi fdisk004
  int $91

  mov %esi $00000000
  mov %edx %e9
  int $0B
  mov %ecx %edx
  dex %ecx
  mov %eax $00
.erloop:
  stds %e9
  inx %esi
  lp .erloop

  ; copy the header (half lba)
  mov %egi header
  mov %esi $00000000
  mov %ecx 255
.hloop:
  lb %egi %eax
  stds %e9
  inx %esi
  lp .hloop

  mov %esi fdisk003
  int $91
  rts

header: bytes $42 "GOVNFS2.0  " $12 $34 $56 $78
        bytes "Z" $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        bytes $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00

fdisk001: bytes "Are you sure you want to format your disk?$^\fJWarning^\r: after reboot you will not be able to boot without re-burning GovnOS into your disk$Format? [yn]: ^@"
fdisk002: bytes "$Invalid option, try again [yn]: ^@"
fdisk003: bytes "^\fJYour disk has been reset.^\r$^@"
fdisk004: bytes "Formatting disk...$^@"
fdisk005: bytes "$Enter disk letter: ^@"

