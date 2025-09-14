; ==========================================
; DECIMAL (0–255) -> Binary (8 bits) & Hex (2 digits)
; EMU8086 .COM
; ==========================================

org 100h
    jmp start

; ---------- DATA ----------
prompt      db 'Enter decimal (0-255): $'
nl          db 0Dh,0Ah,'$'
msg_bin     db 0Dh,0Ah,'Binary: $'
msg_hex     db 0Dh,0Ah,'Hex   : $'

value       db 0                 ; final parsed number 0..255

; nibble ? 4-bit ASCII strings (16 * 4 chars)
bin4_tbl    db '0000','0001','0010','0011'
            db '0100','0101','0110','0111'
            db '1000','1001','1010','1011'
            db '1100','1101','1110','1111'

; hex digits table
hex_tbl     db '0123456789ABCDEF'

; ---------- CODE ----------
start:
    push cs
    pop  ds

    ; prompt
    mov dx, offset prompt
    mov ah, 9
    int 21h

    ; -------- read & parse decimal (0..255) --------
    xor bx, bx                 ; BX = accumulator (0..255)
read_loop:
    mov ah, 1
    int 21h
    cmp al, 0Dh                ; Enter?
    je  parse_done
    cmp al, '0'
    jb  read_loop              ; ignore non-digits
    cmp al, '9'
    ja  read_loop
    sub al, '0'                ; AL = digit 0..9
    mov dl, al                 ; save digit in DL

    ; BX = BX*10 + DL   (use shifts to multiply by 10)
    mov ax, bx                 ; AX = prev
    mov cx, bx
    shl ax, 3                  ; prev * 8
    shl cx, 1                  ; prev * 2
    add ax, cx                 ; prev * 10
    xor cx, cx
    mov cl, dl                 ; CX = digit
    add ax, cx                 ; AX = prev*10 + digit
    mov bx, ax
    jmp read_loop

parse_done:
    ; clamp to 255 just in case
    cmp bx, 255
    jbe store_val
    mov bx, 255
store_val:
    mov [value], bl

    ; newline
    mov dx, offset nl
    mov ah, 9
    int 21h

    ; -------- print Binary (8 bits, grouped) + 'b' --------
    mov dx, offset msg_bin
    mov ah, 9
    int 21h
    call print_bin8
    mov dl, 'b'                ; suffix
    mov ah, 2
    int 21h

    ; -------- print Hex (2 digits) + 'h' --------
    mov dx, offset msg_hex
    mov ah, 9
    int 21h
    call print_hex2
    mov dl, 'h'                ; suffix
    mov ah, 2
    int 21h

    ; newline and exit
    mov dx, offset nl
    mov ah, 9
    int 21h
    mov ax, 4C00h
    int 21h

; ---------- ROUTINES ----------

; print_bin8: show [value] as 8 bits (4 + space + 4)
print_bin8:
    ; high nibble
    mov al, [value]
    mov ah, al
    shr ah, 4
    and ah, 0Fh
    mov si, offset bin4_tbl
    mov bl, ah
    xor bh, bh
    shl bx, 2                  ; index = nibble * 4
    add si, bx
    call print_4chars

    ; space
    mov dl, ' '
    mov ah, 2
    int 21h

    ; low nibble
    mov al, [value]
    and al, 0Fh
    mov si, offset bin4_tbl
    mov bl, al
    xor bh, bh
    shl bx, 2
    add si, bx
    call print_4chars
    ret

; print_hex2: show [value] as two hex digits (uppercase)
print_hex2:
    ; high nibble
    mov al, [value]
    mov ah, al
    shr ah, 4
    and ah, 0Fh
    mov al, ah
    xor ah, ah
    mov si, offset hex_tbl
    add si, ax
    lodsb
    mov dl, al
    mov ah, 2
    int 21h

    ; low nibble
    mov al, [value]
    and al, 0Fh
    xor ah, ah
    mov si, offset hex_tbl
    add si, ax
    lodsb
    mov dl, al
    mov ah, 2
    int 21h
    ret

; print_4chars: prints 4 ASCII chars from DS:SI
print_4chars:
    mov cx, 4
p4_loop:
    lodsb
    mov dl, al
    mov ah, 2
    int 21h
    loop p4_loop
    ret