#include "x86.h"
#include "stdio.h"
#include "vga.h"
#include "idt.h"

void test_exception();

extern void _start() {
    printf("KERNEL loaded\n");
    idt_install();
    printf("IDT loaded\n");
    
    test_exception();

    printf("test\n");

end:
    for (;;);
}


void test_exception() {
    int a = 4 / 0;
    int b = 5 / 0;
}
