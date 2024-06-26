[bits 16]

%define ENDL 0x0D, 0x0A

global _start
_start:
    cli
    mov ax, ds
    mov ss, ax
    mov sp, 0
    mov bp, sp
    sti

    jmp $


started_stage2_msg:     db 'from stage2', ENDL, 0