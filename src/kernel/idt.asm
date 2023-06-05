[bits 32]
global idt_load
extern idtp
idt_load:
    lidt [idtp]
    ret


;
; ISR-s
;
global isr0
global isr1
global isr2
global isr3
global isr4
global isr5
global isr6
global isr7
global isr8
global isr9
global isr10
global isr11
global isr12
global isr13
global isr14
global isr15
global isr16
global isr17
global isr18
global isr19
global isr20
global isr21
global isr22
global isr23
global isr24
global isr25
global isr26
global isr27
global isr28
global isr29
global isr30
global isr31

isr0:
    cli
    push 1
    push 0x0
    jmp ISR_common_stub

isr1:
    cli
    push 1
    push 0x1
    jmp ISR_common_stub

isr2:
    cli
    push 1
    push 0x2
    jmp ISR_common_stub

isr3:
    cli
    push 1
    push 0x3
    jmp ISR_common_stub

isr4:
    cli
    push 1
    push 0x4
    jmp ISR_common_stub

isr5:
    cli
    push 1
    push 0x5
    jmp ISR_common_stub

isr6:
    cli
    push 1
    push 0x6
    jmp ISR_common_stub

isr7:
    cli
    push 1
    push 0x7
    jmp ISR_common_stub

isr8:
    cli
    push 0x8
    jmp ISR_common_stub

isr9:
    cli
    push 1
    push 0x9
    jmp ISR_common_stub

isr10:
    cli
    push 0xa
    jmp ISR_common_stub

isr11:
    cli
    push 0xb
    jmp ISR_common_stub

isr12:
    cli
    push 0xc
    jmp ISR_common_stub

isr13:
    cli
    push 0xd
    jmp ISR_common_stub

isr14:
    cli
    push 0xe
    jmp ISR_common_stub

isr15:
    cli
    push 1
    push 0xf
    jmp ISR_common_stub

isr16:
    cli
    push 1
    push 0x10
    jmp ISR_common_stub

isr17:
    cli
    push 0x11
    jmp ISR_common_stub

isr18:
    cli
    push 1
    push 0x12
    jmp ISR_common_stub

isr19:
    cli
    push 1
    push 0x13
    jmp ISR_common_stub

isr20:
    cli
    push 1
    push 0x14
    jmp ISR_common_stub

isr21:
    cli
    push 0x15
    jmp ISR_common_stub

isr22:
    cli
    push 1
    push 0x16
    jmp ISR_common_stub

isr23:
    cli
    push 1
    push 0x17
    jmp ISR_common_stub

isr24:
    cli
    push 1
    push 0x18
    jmp ISR_common_stub

isr25:
    cli
    push 1
    push 0x19
    jmp ISR_common_stub

isr26:
    cli
    push 1
    push 0x1a
    jmp ISR_common_stub

isr27:
    cli
    push 1
    push 0x1b
    jmp ISR_common_stub

isr28:
    cli
    push 1
    push 0x1c
    jmp ISR_common_stub

isr29:
    cli
    push 0x1d
    jmp ISR_common_stub

isr30:
    cli
    push 0x1e
    jmp ISR_common_stub

isr31:
    cli
    push 1
    push 0x1f
    jmp ISR_common_stub


extern fault_handler


ISR_common_stub:
    pusha
    push ds
    push es
    push fs
    push gs
    mov ax, 0x10   ; Load the Kernel Data Segment descriptor!
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov eax, esp   ; Push us the stack
    push eax
    mov eax, fault_handler
    call eax       ; A special call, preserves the 'eip' register
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    popa
    add esp, 8     ; Cleans up the pushed error code and pushed ISR number
    iret           ; pops 5 things at once: CS, EIP, EFLAGS, SS, and ESP!
