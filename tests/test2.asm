main:
  mov %esi t
  zzdref
  trap
  rts

t: bytes $12 $34 $56 $78
   bytes $23 $45 $67 $89
   bytes $34 $56 $78 $90
   bytes $45 $67 $89 $01

