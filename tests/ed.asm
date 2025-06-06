  jmp start

strcpy:
  lb %esi %eax
  cmp %eax $00
  re
  sb %egi %eax
  jmp strcpy

strtok:
  lb %esi %eax
  cmp %eax %ebx
  re
  jmp strtok

start:
  ; Инициализация буфера
  mov %esi buf_start
  mov %eax 0        ; Нулевой байт
  sb %esi %eax    ; [buf_start] = 0 (пустая строка)

main_loop:
  ; Вывод приглашения
  mov %esi prompt
  jsr puts
  
  ; Ввод команды (2 символа)
  mov %esi cmd_buf
  mov %ecx 10
  jsr scans
  mov %esi cmd_buf
  
  ; Проверка команды
  lb %esi %eax     ; Первый символ
  lb %esi %ebx     ; Второй символ
  
  ; Команда выхода (q)
  cmp %eax 'q'
  re
  
  ; Команда вывода (p)
  cmp %ebx 'p'
  je .print_cmd
  
  ; Команда добавления текста (a)
  cmp %ebx 'a'
  je .add_cmd_real
  
  jmp main_loop

.print_cmd:
  ; Вывод содержимого буфера
  mov %esi buf_start
  jsr puts
  psh '$'
  int 2
  jmp main_loop

.add_cmd_real:
  mov %egi buf_start
  mov %ebx $0A
  jsr strtok
.add_cmd:
  mov %esi insert_buf
  mov %ecx 256
  jsr scans
  
  ; Добавление перевода строки
  mov %eax '$'
  sb %esi %eax
  mov %eax '^@'
  sb %esi %eax

  ; Проверка на точку (конец ввода)
  mov %esi insert_buf
  lb %esi %eax
  cmp %eax '.'
  je main_loop
  dex %esi
  jsr strcpy
  jmp .add_cmd
  
; Функция вывода строки
puts:
  lb %esi %eax
  cmp %eax 0
  re
  psh %eax
  int 2
  jmp puts

; Функция ввода строки
scans:
  cmp %ecx 0
  re
  int 1
  pop %eax
  psh %eax
  int 2
  cmp %eax '$'      ; Проверка на перевод строки
  re
  sb %esi %eax
  dex %ecx
  jmp scans

; Данные
prompt: bytes "ed> ^@"
cmd_buf: reserve 16 bytes            ; Буфер для команды (2 байта)
buf_start: reserve 1024 bytes ; Основной буфер
buf_end: bytes 0              ; Маркер конца буфера
insert_buf: reserve 256 bytes

