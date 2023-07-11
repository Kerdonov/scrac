[org 0x7c00]
[bits 16]
KERNEL_LOCATION equ 0x1000

BOOT_DISK: db 0
mov [BOOT_DISK], dl

; init stack
xor ax, ax
mov es, ax
mov ds, ax
mov bp, 0x8000
mov sp, bp

; load kernel
mov bx, KERNEL_LOCATION
mov dh, 20		; head

mov ah, 0x02
mov al, dh		; sector count
mov ch, 0x00		; cylinder
mov dh, 0x00		; head
mov cl, 0x02		; sector
mov dl, [BOOT_DISK]	; drive
int 0x13

; print boot message
pusha
mov ah, 0x0e
mov bx, boot_msg

.puts:
    mov al, [bx]
    cmp al, 0
    je .end

    int 0x10
    inc bl
    jmp .puts

.end:
    ;mov ah, 0
    ;int 0x16
    popa

; switch to text mode
mov ah, 0x0
mov al, 0x3
int 0x10

; switch to 32-bit protected mode
CODE_SEG equ code_descriptor - GDT_Start
DATA_SEG equ data_descriptor - GDT_Start

cli
lgdt [GDT_Descriptor]
mov eax, cr0
or eax, 1
mov cr0, eax
jmp CODE_SEG:start_protected_mode

;
; GDT
;

GDT_Start:
    null_descriptor:
	dd 0		; four times 00000000
	dd 0		; four times 00000000
    code_descriptor:
	dw 0xffff	; first 16 bits of limit
	dw 0
	db 0		; first 24 bytes of base
	db 0b10011010	; pres, priv, type
	db 0b11001111	; other flags + last 4 bytes of limit
	db 0		; last 8 bits of base
    data_descriptor:
	dw 0xffff
	dw 0
	db 0
	db 0b10010010
	db 0b11001111
	db 0
GDT_End:

GDT_Descriptor:
    dw GDT_End - GDT_Start - 1	; size
    dd GDT_Start		; start


[bits 32]
start_protected_mode:
    mov ax, DATA_SEG		; set up segment registers and stack
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ebp, 0x90000
    mov esp, ebp

    

    jmp KERNEL_LOCATION		; jump to kernel location


boot_msg: db "kernel loaded, press any key to boot...", 0

times 510-($-$$) db 0
dw 0xaa55
