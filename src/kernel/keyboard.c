#include "keyboard.h"
#include "types.h"
#include "int.h"
#include "stdio.h"
#include "x86.h"
#include "vga.h"

bool shift = false;
bool ctrl = false;

void (*reboot)(void) = (void (*)())NULL;

void crash(void) {
	int x = 1 / 0;
}

char scancode_to_char(u8 scancode) {
    if (shift) {
	switch (scancode) {
	    case 0x02: return '!';
	    case 0x03: return '"';
	    case 0x04: return '#';
	    case 0x05: return '$';
	    case 0x06: return '%';
	    case 0x07: return '&';
	    case 0x08: return '/';
	    case 0x09: return '(';
	    case 0x0a: return ')';
	    case 0x0b: return '=';
	    case 0x0c: return '?';
	    // backspace
	    case 0x0e: return '\b';
	    // tab
	    case 0x0f: return '\t';
	    case 0x10: return 'Q';
	    case 0x11: return 'W';
	    case 0x12: return 'E';
	    case 0x13: return 'R';
	    case 0x14: return 'T';
	    case 0x15: return 'Y';
	    case 0x16: return 'U';
	    case 0x17: return 'I';
	    case 0x18: return 'O';
	    case 0x19: return 'P';
	    case 0x1a: return 'U';
	    case 0x1b: return 'O';
	    case 0x1c: return '\n';
	    // left ctrl
	    case 0x1d: ctrl = true;
		       return '\0';
	    case 0x1e: return 'A';
	    case 0x1f: return 'S';
	    case 0x20: return 'D';
	    case 0x21: return 'F';
	    case 0x22: return 'G';
	    case 0x23: return 'H';
	    case 0x24: return 'J';
	    case 0x25: return 'K';
	    case 0x26: return 'L';
	    case 0x27: return 'O';
	    case 0x28: return 'A';
	    case 0x29: return '*';
	    // left shift
	    case 0x2a: shift = !shift;
		       return '\0';
	    case 0x2b: return '*';
	    case 0x2c: return 'Z';
	    case 0x2d: return 'X';
	    case 0x2e: return 'C';
	    case 0x2f: return 'V';
	    case 0x30: return 'B';
	    case 0x31: return 'N';
	    case 0x32: return 'M';
	    case 0x33: return ';';
	    case 0x34: return ':';
	    case 0x35: return '_';
	    case 0x36: shift = !shift;
		       return '\0';
	    case 0x39: return ' ';
	    // caps lock
	    case 0x3a: shift = !shift;
		       return '\0';
	    // release left shift
	    case 0xaa: shift = !shift;
		       return '\0';
	    // release right shift
	    case 0xb6: shift = !shift;
		       return '\0';
	    default: return '\0';
	}
    } else {
	switch (scancode) {
	    case 0x02: return '1';
	    case 0x03: return '2';
	    case 0x04: return '3';
	    case 0x05: return '4';
	    case 0x06: return '5';
	    case 0x07: return '6';
	    case 0x08: return '7';
	    case 0x09: return '8';
	    case 0x0a: return '9';
	    case 0x0b: return '0';
	    case 0x0c: return '+';
	    case 0x0d: return '\\';
	    // backspace
	    case 0x0e: return '\b';
	    // tab (also reboot)
	    case 0x0f: crash();
		       return '\t';
	    case 0x10: return 'q';
	    case 0x11: return 'w';
	    case 0x12: return 'e';
	    case 0x13: return 'r';
	    case 0x14: return 't';
	    case 0x15: return 'y';
	    case 0x16: return 'u';
	    case 0x17: return 'i';
	    case 0x18: return 'o';
	    case 0x19: return 'p';
	    case 0x1a: return 'u';
	    case 0x1b: return 'o';
	    case 0x1c: return '\n';
	    // left ctrl
	    case 0x1d: ctrl = true;
		       return '\0';
	    case 0x1e: return 'a';
	    case 0x1f: return 's';
	    case 0x20: return 'd';
	    case 0x21: return 'f';
	    case 0x22: return 'g';
	    case 0x23: return 'h';
	    case 0x24: return 'j';
	    case 0x25: return 'k';
	    case 0x26: return 'l';
	    case 0x27: return 'o';
	    case 0x28: return 'a';
	    case 0x29: return '~';
	    // left shift
	    case 0x2a: shift = !shift;
		       return '\0';
	    case 0x2b: return '\'';
	    case 0x2c: return 'z';
	    case 0x2d: return 'x';
	    case 0x2e: return 'c';
	    case 0x2f: return 'v';
	    case 0x30: return 'b';
	    case 0x31: return 'n';
	    case 0x32: return 'm';
	    case 0x33: return ',';
	    case 0x34: return '.';
	    case 0x35: return '-';
	    case 0x36: shift = !shift;
		       return '\0';
	    case 0x39: return ' ';
	    // caps lock
	    case 0x3a: shift = !shift;
		       return '\0';
	    // release left shift
	    case 0xaa: shift = !shift;
		       return '\0';
	    // release right shift
	    case 0xb6: shift = !shift;
		       return '\0';
	    default: return '\0';
	}
    }
}

void print_keypress(struct regs *r) {
    u8 scancode = inb(0x60);
    char c = scancode_to_char(scancode);
    if (c == '\0')
	return;
    else if (c == '\n') {
	newline();
	return;
    }
    else if (c == '\b') {
	backspace();
	return;
    }
    else if (c == '\t') {
	// not right tab character ik
	printf("    ");
	return;
    }
    printf("%c", c);
}

