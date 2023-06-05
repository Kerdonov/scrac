#pragma once
#include "stdint.h"

char __attribute__((cdecl)) x86_testchar();

void __attribute__((cdecl)) outb(u16 port, u8 value);
u8 __attribute__((cdecl)) inb(u16 port);

void enable_cursor(u8 cursor_start, u8 cursor_end);
void disable_cursor();
void update_cursor(int x, int y);
u16 get_cursor_position(void);

