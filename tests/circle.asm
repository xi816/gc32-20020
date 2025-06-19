main:
  mov %e8 0
.L1:
  mov %e9 0
.L2:
  mov %esi $400000
  mov %e10 %e8
  mul %e10 640
  add %esi %e10
  add %esi %e9

  ; x = e8. y = e9
  ; x*x + y*y < 64;
  ;
  mov %e10 %e8
  mov %e11 %e9
  sub %e10 240
  sub %e11 320
  mul %e10 %e10
  mul %e11 %e11
  add %e10 %e11
  cmp %e10 6400
  jl .yes
  jmp .no
.yes:
  mov %eax $4
  sb %esi %eax
  jmp .yesf
.no:
  mov %eax $0
  sb %esi %eax
.yesf:
  inx %e9
  cmp %e9 640
  jl .L2
; .L1f:
  inx %e8
  cmp %e8 480
  jl .L1
.L3:
  mov %e9 0
.L4:
  mov %esi $400000
  mov %e10 %e8
  mul %e10 640
  add %esi %e10
  add %esi %e9
  mov %eax $F
  sb %esi %eax
  int $11
  trap
  inx %e9
  cmp %e9 120
  jl .L3
  inx %e8
  cmp %e8 200
  jl .L4
end:
  int $11
  int $1
  hlt

