#include "stdio.h"
#include "vga.h"

#define PRINTF_STATE_NORMAL		0
#define PRINTF_STATE_MODE		1


int BG_COLOR = BLACK;
int FG_COLOR = WHITE;

void setbg(int color) {
    BG_COLOR = color;
}

void setfg(int color) {
    FG_COLOR = color;
}


void __attribute__((cdecl)) printf(const char* fmt, ...) {

    int* argp = (int*)&fmt;
    int state = PRINTF_STATE_NORMAL;
    int color = (BG_COLOR << 1) + FG_COLOR;

    argp++;

    while (*fmt) {
	switch (state) {
	    case PRINTF_STATE_NORMAL:
		switch (*fmt) {
		    case '%':
			state = PRINTF_STATE_MODE;
			break;
		    default:
			putc(*fmt, color);
			break;
		}
		break;

	    case PRINTF_STATE_MODE:
	    MODE_:
		switch (*fmt) {
		    case 'c':
			putc((const char)*argp, color);
			argp++;
			break;

		    case 's':
			puts(*(char**)argp, color);
			argp++;
			break;

		    case '%':
			putc('%', color);
			break;

		    case 'd':
		    case 'i':
			putint(*(int*)argp, 10, color);
			break;

		    case 'x':
			putint(*(int*)argp, 16, color);
			break;
		    
		    case 'b':
			putint(*(int*)argp, 2, color);
			break;

		    case 'o':
			putint(*(int*)argp, 8, color);
			break;

		    default:
			break;
		}
	    state = PRINTF_STATE_NORMAL;
	    break;
	}

	fmt += sizeof(fmt) / sizeof(int);
    }
}
