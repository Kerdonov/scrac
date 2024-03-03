#include "memory.h"
#include "types.h"
#include "stdio.h"

struct heap heap;

void init_heap() {
    heap.start = HEAP_START;
    heap.end = HEAP_END;
    heap.next = HEAP_START;
    heap.allocations = 0;
    debug_log("heap size: %d", HEAP_END - HEAP_START);
}


void* memset(void* ptr, int value, u16 num) {
    u8* u8ptr = (u8*)ptr;
    
    for (u16 i = 0; i < num; i++)
	    u8ptr[i] = (u8)value;

    return ptr;
}

// LLLLET IT RIP!!!
void* alloc(int size) {
    if (size > heap.end - heap.next) {
        error_log("heap overflow, only %d bytes remaining", heap.end - heap.next);
        return NULL;
    }
    void* ptr = (void*)heap.next;
    heap.next = heap.next + size;
    heap.allocations++;
    return ptr;
}

void free(void* ptr) {

}
