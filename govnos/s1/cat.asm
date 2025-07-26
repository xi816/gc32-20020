cat_main:
  mov %esi %r12
  mov %eax $00
  jsr strtok
  mov %r13 %esi
  lb %r13 %e8
  dex %r13
  cmp %e8 $00 ; If no CLI arguments
  je .no_args
  mov %esi %r13
  mov %eax $20
  jsr strtok
  sub %esi 2
  mov %eax $00
  sb %esi %eax
.open:
; mov %esi command
  mov %esi txt_header
  mov %ecx 16
  jsr b_memset
  psh %r13
  mov %esi %r13
  mov %egi txt_header
  inx %egi
  jsr b_strcpy
  pop %r13
  mov %esi txt_tag
  mov %egi txt_header
  add %egi 13
  mov %ecx 3
  jsr b_memcpy

  mov %ebx txt_header
  mov %egi $280000
  jsr gfs2_read_file
  cmp %eax $00
  je .output
  jmp .failed
.output:
  mov %esi $280000
  int $91
  rts
.failed:
  mov %esi cat_msg01
  int $91
  mov %esi %r13
  int $91
  mov %esi cat_msg02
  int $91
  rts
.no_args:
  mov %esi cat_msg00
  int $91
  rts

cat_msg00: bytes "No tag given. Try `cat test.txt` to see the test.txt file's contents.$^@"
cat_msg01: bytes "cat: file `^@"
cat_msg02: bytes "` not found$^@"
txt_header:                reserve 16 bytes
txt_tag:                   bytes "txt^@"
