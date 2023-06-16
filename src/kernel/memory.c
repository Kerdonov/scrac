#include "memory.h"
#include "types.h"

void* memset(void* ptr, int value, u16 num) {
    u8* u8ptr = (u8*)ptr;
    
    for (u16 i = 0; i < num; i++)
	u8ptr[i] = (u8)value;

    return ptr;
}
