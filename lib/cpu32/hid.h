#define HID_ADDR 0x480000
// struct { U16 x; U16 y; U8 sy; U8 keys[MAX_KEYS];}
// todo: cpu32h?
U0 WriteWord(GC* gc, U32 addr, U16 val);
U0 move_mouse(GC* gc, U16 x, U16 y) {
    WriteWord(gc, HID_ADDR, x);
    WriteWord(gc, HID_ADDR + 2, y);
}
U0 scroll_mouse(GC* gc, I8 y) {
    gc->mem[HID_ADDR + 4] = y;
}
U0 mouse_btn(GC* gc, U8 id, U8 val) {
  U8 flag = gc->mem[HID_ADDR + 4];
  if (val) {
    flag |= 1 << id;
  } else {
    flag &= ~(1 << id);
  }
  gc->mem[HID_ADDR + 4] = flag;
}
// Keyboard is basically an api for USB-HID
// https://wiki.libsdl.org/SDL2/SDL_Scancode
#define MAX_KEYS 6
U0 kbd_btn(GC* gc, U16 id, U8 val) {
  U8 i;
  if (val) {
    for (i = 0; i < MAX_KEYS; i++) {
      if (gc->mem[HID_ADDR + 5 + i] == 0) {
        gc->mem[HID_ADDR + 5 + i] = id;
        return;
      }
    }
  } else {
    for (i = 0; i < MAX_KEYS; i++) {
      if (gc->mem[HID_ADDR + 5 + i] == id) {
        gc->mem[HID_ADDR + 5 + i] = 0;
        return;
      }
    }
  }
}
U8 hid_events(GC* gc) {
  SDL_Event event;
  scroll_mouse(gc, 0);
  while (SDL_PollEvent(&event)) {
    switch(event.type) {
      case SDL_EVENT_QUIT:
        return 1;
      case SDL_EVENT_MOUSE_MOTION:
        move_mouse(gc, event.motion.x / gc->gg.scale, event.motion.y / gc->gg.scale);
        break;
      case SDL_EVENT_MOUSE_BUTTON_DOWN:
      case SDL_EVENT_MOUSE_BUTTON_UP:
        mouse_btn(gc, event.button.button, event.type == SDL_EVENT_MOUSE_BUTTON_DOWN);
        break;
      case SDL_EVENT_MOUSE_WHEEL:
        scroll_mouse(gc, event.wheel.integer_y);
        break;
      case SDL_EVENT_KEY_DOWN:
      case SDL_EVENT_KEY_UP:
        if (!event.key.repeat)
          kbd_btn(gc, event.key.scancode, event.type == SDL_EVENT_KEY_DOWN);
        break;
    }
  }
  return 0;
}
