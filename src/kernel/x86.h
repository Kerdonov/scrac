#pragma once
#include "types.h"

#define PIC1		0x20
#define PIC2		0xa0
#define PIC1_COMMAND	PIC1
#define PIC1_DATA	(PIC1+1)
#define PIC2_COMMAND	PIC2
#define PIC2_DATA	(PIC2+1)

#define PIC_EOI		0x20

char __attribute__((cdecl)) x86_testchar();

void __attribute__((cdecl)) outb(u16 port, u8 value);
u8 __attribute__((cdecl)) inb(u16 port);

void enable_cursor(u8 cursor_start, u8 cursor_end);
void disable_cursor();
void update_cursor(int x, int y);
u16 get_cursor_position(void);

