gtutor_main:
  mov %esi gtutor_msg00
  int $91

  int $93

  rts

gtutor_msg00: bytes "^\fCWelcome to GovnOS tutorial! Press Return to start^\fH$^\fB  will be available tomorrow (05.0B.E9)^\fH$^@"
gtutor_msg01: bytes "^[[H^[[2JThe gsfetch command shows your computer characteristics$> gsfetch$$^@"

