#pragma once
#include "types.h"

typedef struct { int pStart; int pEnd; } chunk;

struct heapDescriptor {
    chunk currentChunk;
    struct heapDescriptor* nextChunk;
};

void* memset(void* ptr, int value, u16 num);

void init_heap();

int malloc(int size);
