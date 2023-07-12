#pragma once
#include "types.h"

#define PAGE_DIRECTORY	0x00FF8000;

typedef struct {
    usize page_table_addr: 20;
    usize free: 4;
    usize flags: 8;
} PDE;

typedef PDE PD[1024];

int enable_paging();
