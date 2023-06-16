#include "x86.h"
#include "stdio.h"
#include "vga.h"
#include "int.h"

void clock(struct regs *r);

extern void _start() {
    printf("--kernel loaded\n");

    idt_install();
    printf("--idt loaded\n");

    irq_install_handler(0, *clock);
    irq_install();
    __asm__ __volatile__ ("sti");
    printf("--interrupts enabled\n");
    

end:
    for (;;);
}


void clock(struct regs *r) {
    printf(".");
}
