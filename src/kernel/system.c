#include "system.h"

int init() {
    idt_install();
    debug_log("idt loaded");

    irq_install();
    __asm__ __volatile__ ("sti");
    debug_log("interrupts enabled");

    return 0;
}

void halt() {
    for(;;);
}
