#include "keyboard.h"
#include "types.h"
#include "int.h"
#include "stdio.h"
#include "x86.h"

bool shift = false;
bool capsLock = false;

void print_keypress(struct regs *r) {
    u8 value = inb(0x60);
    printf("%d", value);
}
