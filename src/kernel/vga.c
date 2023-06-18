#include "vga.h"
#include "x86.h"


vgabuffer* buffer = (vgabuffer*)0xb8000;
const row empty_row;


void puts(char* str, int color) {
    while (*str)
	putc(*str++, color);
}

void putc(const char c, int color) {
    u16 pos = get_cursor_position();
    int x = pos % VGA_WIDTH;
    int y = pos / VGA_WIDTH;

    if (c == '\n') {
	newline();
    } else {
	buffer->rows[y].cols[x].c = c;
	buffer->rows[y].cols[x].color = color;
	if (x++ >= VGA_WIDTH)
	    newline();
	else
	    update_cursor(x, y);
    }
}

// 2 <= base <= 36
void putint(int i, int base, int color) {
    if (!(base >= 2 && base <= 36))
	return;
    if (i < 0) {
	putc('-', color);
	putint(-i, base, color);
	return;
    }
    if (i >= base)
	putint(i / base, base, color);
    putc("0123456789abcdefghijklmnopqrstuvwxyz"[i % base], color);
}

void newline() {
    u16 pos = get_cursor_position();
    int x = 0;
    int y = (pos / VGA_WIDTH) + 1;

    if (y >= VGA_HEIGHT) {
	for (int i = 0; i <= VGA_HEIGHT - 2; i++) {
	    buffer->rows[i] = buffer->rows[i+1];
	}
	y--;
	buffer->rows[y] = empty_row;
    }
    update_cursor(x, y);
}

void backspace() {
    u16 pos = get_cursor_position();
    int x = pos % VGA_WIDTH;
    int y = pos / VGA_WIDTH;

    // can't go back one line (for now?)
    if (x == 0)
	return;

    x--;
    buffer->rows[y].cols[x].c = '\0';
    buffer->rows[y].cols[x].color = 0x0F;

    update_cursor(x, y);
}
