#pragma once
#include "types.h"

#define HEAP_START  0x8000
#define HEAP_END    0xFFFF
// #define HEAP_SIZE   0xFF7FFF    // heap end is at 0xFFFFFF

// fuck it, bump allocator
struct heap {
    u32 start;
    u32 end;
    u32 next;
    u32 allocations;
};


void* memset(void* ptr, int value, u16 num);

void init_heap();

void* alloc(int size);
void free(void* ptr);
