#pragma once

#define VGA_WIDTH	80
#define VGA_HEIGHT	25

#define BLACK		0x0
#define BLUE		0x1
#define GREEN		0x2
#define CYAN		0x3
#define RED		0x4
#define PURPLE		0x5
#define BROWN		0x6
#define GRAY		0x7
#define DARK_GRAY	0x8
#define LIGHT_BLUE	0x9
#define LIGHT_GREEN	0xA
#define LIGHT_CYAN	0xB
#define LIGHT_RED	0xC
#define LIGHT_PURPLE	0xD
#define YELLOW		0xE
#define WHITE		0xF

typedef struct {
    char c;
    char color;
} screenchar;

typedef struct {
    screenchar cols[VGA_WIDTH];
} row;

typedef struct {
    row rows[VGA_HEIGHT];
} vgabuffer;


void puts(char* str, int color);
void putc(const char c, int color);
void putint(int i, int base, int color);

//void putshort(short int* p, int base, int color);
//void putlong(long int* p, int base, int color);
//void putlonglong(long long int* p, int base, int color);

void newline();
void backspace();
