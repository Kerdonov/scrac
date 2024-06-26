#include "system.h"

extern void _start() {
    char* loadmsg = "kernel loaded";
    debug_log(loadmsg);
    init();
    
    halt();
}

