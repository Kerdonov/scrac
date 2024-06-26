[org 0x7c00]
[bits 16]
STAGE2_LOCATION             equ 0x0
STAGE2_OFFSET               equ 0x500
STACK_BASE                  equ 0x8000

%define ENDL 0x0D, 0x0A

;
; BPB (bios parameter block)
;
jmp short start
nop
bdb_oem:                    db 'MSWIN4.1'   ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 224          ; 0xe0
bdb_total_sectors:          dw 2880         ; 2880 * 512 = 1.44 MB  0x0b40
bdb_media_descriptor_type:  db 0xF0         ; F0 - 3.5" floppy disk
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0
                            db 0            ; reserved
ebr_signature:              db 0x29
ebr_volume_id:              dd 0x6B657274
ebr_volume_label:           db 'SCRACOS    '
ebr_system_id:              db 'FAT12   '



start:
    call vad
    ; init stack
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov bp, STACK_BASE
    mov sp, bp
    
    ; drive parameters
    mov ah, 0x08
    stc
    int 0x13                                ; * this works 🤔
    jc floppy_read_error
    

    and cl, 0x3F
    xor ch, ch
    mov [bdb_sectors_per_track], cx         ; sectors per track

    inc dh
    mov [bdb_heads], dh                     ; head count

    ; compute lba of root dir
    mov ax, [bdb_sectors_per_fat]           ; lba of root = reserved + fats * sectors per fat
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx                                  ; ax = fats * sectors per fat
    add ax, [bdb_reserved_sectors]          ; ax = lba of root
    push ax                                 ; lba of root dir is on the stack

    ; compute size of root dir = (32 * root dir entries) / bytes per sector
    mov ax, [bdb_dir_entries_count]
    shl ax, 5                               ; ax *= 32
    xor dx, dx                              ; dx = 0
    div word [bdb_bytes_per_sector]         ; ax = root dir size in sectors

    test dx, dx                             ; if dx != 0, add 1 (a sector is only partially filled -> round up)
    jz .bdb_done
    inc dx

.bdb_done:
    ; read root dir
    mov cl, al                              ; num of sectors to read = size of root dir
    pop ax                                  ; lba of root dir (from earlier)
    mov dl, [BOOT_DISK]                     
    mov bx, buffer                          ; es:bx = buffer to write to

    call disk_read                          ; ! disk read fails thrice
    

    ; search for stage2.bin
    xor bx, bx
    mov di, buffer

.search_stage2:
    mov si, stage2_filename
    mov cx, 11                              ; compare up to 11 chars
    push di
    repe cmpsb                              ; compare ds:si and es:di for up to cx times (11 bytes - 11 characters to compare)
    pop di
    je .found_stage2                        ; if strings are equal, we found the stage2
    
    add di, 32                              ; next dir entry (dir entry is 32 bytes)
    inc bx                                  ; increment checked dir entry count
    cmp cx, [bdb_dir_entries_count]         ; check if all entries are checked
    jl .search_stage2

    jmp stage2_not_found_error

.found_stage2:
    ; di should have address to entry, which contains stage2.bin
    mov ax, [di + 26]                       ; dir entry offset 26 has the low 16 bits of the first cluster
    mov [stage2_cluster], ax

    ; load fat from disk to memory
    mov ax, [bdb_reserved_sectors]          ; reserved sectors = 1, fat starts there
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [BOOT_DISK]
    call disk_read

    
    ; load stage2
    mov bx, STAGE2_LOCATION
    mov es, bx
    mov bx, STAGE2_OFFSET

.load_stage2_loop:
    ; read next cluster
    mov ax, [stage2_cluster]
    times 2 dec ax
    mul word [bdb_sectors_per_cluster]
    add ax, [bdb_reserved_sectors]
    add ax, [bdb_fat_count]
    add ax, [bdb_dir_entries_count]
    


    mov cl, 1
    mov dl, [BOOT_DISK]
    call disk_read
    
    add bx, [bdb_bytes_per_sector]
    
    ; compute location of next cluster
    mov ax, [stage2_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx                                  ; ax = index of entry in fat, dx = cluster mod 2
    
    mov si, buffer
    add si, ax
    mov ax, [ds:si]                         ; read entry from fat at index ax

    or dx, dx
    jz .even

.odd:
    shr ax, 4
    jmp .next_cluster_after

.even:
    and ax, 0x0FFF

.next_cluster_after:
    cmp ax, 0x0FF8                          ; end of chain
    jae .read_finish

    mov [stage2_cluster], ax
    jmp .load_stage2_loop

.read_finish:
    ; set up segment registers
    mov dl, [BOOT_DISK]
    mov ax, STAGE2_LOCATION
    mov ds, ax
    mov es, ax


    ; print boot message
    mov bx, boot_msg
    call printstr
    call wait_keypress


; misc functions

; parameters:
;   bx: string label
printstr:
    push ax
    push bx
    
    mov ah, 0x0E
.printloop:
    mov al, [bx]
    cmp al, 0
    je .end

    int 0x10
    inc bl
    jmp .printloop

.end:
    pop bx
    pop ax
    ret

wait_keypress:
    push ax

    mov ah, 0
    int 0x16

    pop ax
    ret


; ERROR HANDLERS

vad:                            ; very advanced debugger
    push bx

    mov bx, debug
    call printstr
    call wait_keypress

    pop bx
    ret

floppy_read_error:
    mov bx, floppy_read_error_msg
    jmp error_common_stub

stage2_not_found_error:
    mov bx, stage2_not_found_error_msg
    jmp error_common_stub

error_common_stub:
    call printstr
    call wait_keypress
    jmp 0xFFFF:0        ; jump to bios


; Disk routines (please don't overflow)

; lba to chs
; parameters:
;   - ax - lba address
; return:
;   cx [bits 0-5]: sector
;   cx [bits 6-15]: cylinder
;   dh: head
; ! PLEASE save registers, which are used, but are not apart of the output
; * i didn't save dl, which contained the drive number in disk_read function
; * and proceeded to fucking DIE of confusion for the next couple of days
lba_to_chs:
    push ax
    push dx

    xor dx, dx

    div word [bdb_sectors_per_track]    ; ax = LBA / sectors per track
                                        ; dx = LBA % sectors per track
    inc dx                              ; dx = LBA % sectors per track + 1 = sector
    mov cx, dx                          ; cx = sector

    xor dx, dx                          ; dx = 0
    div word [bdb_heads]                ; ax = (LBA / sectors per track) / heads = cylinder
                                        ; dx = (LBA / sectors per track) % heads = head

    mov dh, dl                          ; dh = head
    mov ch, al                          ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax

    ret

; read sectors from a disk
; parameters:
;   ax: lba address
;   cl: number of sectors to read (1...127)
;   dl: drive number 
;   es:bx: memory addr where to store read data
disk_read:
    push eax                             ; input: lba addr
    push bx                             ; input: output addr
    push cx                             ; input: num of sectors to read
    push dx                             ; input: drive number
    push si
    push di                             ; i just use it

    push cx
    call lba_to_chs                     ; cx = sector + cylinder
                                        ; dh = head
    
    pop ax                              ; al = number of sectors to read

    mov ah, 0x02                        ; int 0x13 read sectors
    mov di, 3                           ; read retry count

.retry:
    pusha
    stc                                 ; set carry flag
    call vad
    int 0x13                            ; carry flag cleared = success
                                        ; ! program halts here, what the fuck
                                        ; todo fuck around and find out what the fuck is wrong with this interrupt
    jnc .done

    ; read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; all attempts failed
    jmp floppy_read_error

.done:
    popa
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop eax
    ret


; resets disk controller
; parameters:
;   dl: drive number
disk_reset:
    pusha
    mov ah, 0
    stc
    int 0x13
    jc floppy_read_error
    popa
    ret


boot_msg:                   db 'OK', 0
debug:                      db 'B', 0
floppy_read_error_msg:      db 'DRE', 0
stage2_not_found_error_msg: db 'NOS2', 0

stage2_filename:            db "STAGE2  BIN"
stage2_cluster:             dw 0

BOOT_DISK: db 0

times 510-($-$$) db 0
dw 0xaa55

buffer: