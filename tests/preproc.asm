#define getc(reg) \
  int $2 \
  pop %reg

#define puts(msg) \
  mov %esi msg \
  int $2

#define save(reg)    psh %reg
#define restore(reg) pop %reg
#define void
#define fun(name)    name:
#define end          rts
#define exit()       hlt

void fun(main)
  puts(hw)
  exit()
end

hw: bytes "Hello, World!$^@"

