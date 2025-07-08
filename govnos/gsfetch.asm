govnos_gsfetch:
  mov %esi gsfc_000
  int $91

  ; Hostname
  mov %esi gsfc_001
  int $91
  mov %esi env_HOST
  int $91

  ; OS name
  mov %esi gsfc_002
  int $91
  mov %esi env_OS
  int $91

  ; CPU name
  mov %esi gsfc_003
  int $91
  int $A ; cpuid
  mov %egi env_CPU
  sd %egi %eax
  sd %egi %ebx
  sd %egi %ecx
  sd %egi %edx
  sd %egi %esi
  mov %esi env_CPU
  int $91

  ; Memory
  mov %esi gsfc_004
  int $91
  mov %eax bse
  sub %eax $030002
  jsr b_puti
  mov %esi gsfc_005
  int $91
  div %e8 1024
  mov %eax %e8
  jsr b_puti
  mov %esi gsfc_010
  int $91

  ; Disk space
  mov %esi gsfc_008
  int $91
  jsr fre_sectors
  mul %eax 512
  jsr b_puti
  mov %esi gsfc_009
  int $91

  mov %esi gsfc_006
  int $91
  mov %ecx 7 ; 8 colors
  mov %eax 'A'
.gsfcL1:
  mov %esi gsfc_ctx
  sb %esi %eax
  mov %esi gsfc_ct
  psh %eax
  int $91
  pop %eax
  inx %eax
  lp .gsfcL1

  mov %esi gsfc_007
  int $91
  mov %esi gsfc_006
  int $91
  mov %ecx 7 ; 8 colors
  mov %eax 'I'
.gsfcL2:
  mov %esi gsfc_ctx
  sb %esi %eax
  mov %esi gsfc_ct
  psh %eax
  int $91
  pop %eax
  inx %eax
  lp .gsfcL2
  mov %esi gsfc_007
  int $91

  mov %esi gsfc_logo
  int $91

  jmp shell.aftexec

gsfc_000:    bytes "             ^\fLgsfetch$^\r             ---------$^@"
gsfc_001:    bytes "             ^\fLHost: ^\r^@"
gsfc_002:    bytes "$             ^\fLOS: ^\r^@"
gsfc_003:    bytes "$             ^\fLCPU: ^\r^@"
gsfc_004:    bytes "$             ^\fLMemory: ^\r^@"
gsfc_005:    bytes " B/^@"
gsfc_010:    bytes " KiB$^@"
gsfc_006:    bytes "             ^@"
gsfc_007:    bytes "^\r$^@"
gsfc_008:    bytes "             ^\fLDisk space used: ^\r^@"
gsfc_009:    bytes " B/16 MiB$$^@"
gsfc_logo:   bytes "^\u10^\fD  .     . .$"
             bytes            "     A     .$"
             bytes            "    (=) .$"
             bytes            "  (=====)$"
             bytes            " (========)^\r$$$$$$^@"
gsfc_ct:     bytes "^\b"
gsfc_ctx:    bytes "A  ^@"
