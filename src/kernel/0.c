#include "x86.h"
#include "stdio.h"
#include "vga.h"
#include "int.h"


extern void _start() {
    debug_log("kernel loaded");

    idt_install();
    debug_log("idt loaded");

    irq_install();
    __asm__ __volatile__ ("sti");
    debug_log("interrupts enabled");

end:
    for (;;);
}

