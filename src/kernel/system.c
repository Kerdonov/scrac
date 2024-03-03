#include "system.h"
#include "memory.h"

int init() {
    idt_install();
    debug_log("idt loaded");

    irq_install();
    __asm__ __volatile__ ("sti");
    debug_log("interrupts enabled");
    
    // fuck paging, all my homies hate paging

    init_heap(HEAP_START);

    return 0;
}

void halt() {
    for(;;);
}
