#include "system.h"

extern void _start() {
    debug_log("kernel loaded");
    init();
    
    halt();
}

