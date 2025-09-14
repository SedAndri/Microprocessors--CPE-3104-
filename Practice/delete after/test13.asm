
org 100h
    jmp start

; ---------- DATA ----------
prompt          db 'Enter Celsius (0-255): $'
nl              db 0Dh,0Ah,'$'
msg_fahr        db 0Dh,0Ah,'Fahrenheit: $'
msg_bin         db 0Dh,0Ah,'Binary (C): $'
msg_oct         db 0Dh,0Ah,'Octal  (C): $'
msg_hex         db 0Dh,0Ah,'Hex    (C): $'

; Color attribute (foreground | background<<4). Example: 0x0A = light green on black
colorAttr       db 0Ah

; Tables for binary nibbles and hex digits
bin4_tbl        db '0000','0001','0010','0011'
                db '0100','0101','0110','0111'
                db '1000','1001','1010','1011'
                db '1100','1101','1110','1111'
hex_tbl         db '0123456789ABCDEF'

; Values
celsius         db 0
fahrenheit      dw 0
value           db 0                 ; reused by base-print routines
curRow          db 0
curCol          db 0

; ---------- CODE ----------
start:
    push cs
    pop  ds
    cld                   ; ensure forward string ops
    ; Set video memory segment for color text mode
    mov ax, 0B800h
    mov es, ax
    ; Initialize tracked cursor from BIOS
    mov ah, 03h
    mov bh, 0
    int 10h               ; DH=row, DL=col
    mov [curRow], dh
    mov [curCol], dl

    ; Prompt
    mov dx, offset prompt
    call print_string_color

    ; -------- read & parse decimal (0..255) into BX --------
    xor bx, bx                 ; BX = accumulator (0..65535)
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

    ; BX = BX*10 + DL
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
    ; clamp to 255
    cmp bx, 255
    jbe store_val
    mov bx, 255
store_val:
    mov [celsius], bl

    ; newline
    mov dx, offset nl
    call print_string_color

    ; -------- Convert Celsius to Fahrenheit: F = (C * 9 / 5) + 32 --------
    xor ax, ax
    mov al, [celsius]
    xor dx, dx
    mov bx, 9
    mul bx             ; DX:AX = AX * BX
    mov bx, 5
    div bx             ; AX = (C*9)/5
    add ax, 32
    mov [fahrenheit], ax

    ; Print Fahrenheit label and value (decimal)
    mov dx, offset msg_fahr
    call print_string_color
    mov ax, [fahrenheit]
    call print_number_color

    ; newline
    mov dx, offset nl
    call print_string_color

    ; -------- Show Celsius in Binary/Octal/Hex --------
    mov dx, offset msg_bin
    call print_string_color
    mov al, [celsius]
    mov [value], al
    call print_bin8
    mov al, 'b'
    call print_char_color

    mov dx, offset msg_oct
    call print_string_color
    mov al, [celsius]
    mov [value], al
    call print_oct3
    mov al, 'o'
    call print_char_color

    mov dx, offset msg_hex
    call print_string_color
    mov al, [celsius]
    mov [value], al
    call print_hex2
    mov al, 'h'
    call print_char_color

    ; final newline
    mov dx, offset nl
    call print_string_color
    ; sync hardware cursor to our tracked position
    mov ah, 02h
    mov bh, 0
    mov dh, [curRow]
    mov dl, [curCol]
    int 10h
    mov ax, 4C00h
    int 21h

; print_char_color: prints AL at ES:B800 with attribute [colorAttr], manages CR/LF
print_char_color proc near
    push ax
    push bx
    push cx
    push dx
    cmp al, 0Dh
    je  pc_cr
    cmp al, 0Ah
    je  pc_lf
    ; preserve char and compute offset = (row*80 + col)*2
    mov dl, al          ; save character
    xor ax, ax
    mov al, [curRow]
    mov bl, 80
    mul bl              ; AX = row*80
    xor bh, bh
    mov bl, [curCol]
    add ax, bx          ; AX = row*80 + col
    shl ax, 1           ; *2 bytes per cell
    ; write char and attribute
    mov bx, ax
    mov al, dl          ; restore char
    mov ah, [colorAttr]
    mov es:[bx], al     ; char
    mov es:[bx+1], ah   ; attribute
    ; advance column
    mov dl, [curCol]
    inc dl
    cmp dl, 80
    jb  pc_store
    mov dl, 0
    ; implicit line feed on wrap
pc_lf:
    mov dh, [curRow]
    inc dh
    cmp dh, 25
    jb  pc_row_ok
    dec dh               ; clamp at last row (no scroll)
pc_row_ok:
    mov [curRow], dh
    mov dl, [curCol]     ; preserve current column on LF
pc_store:
    mov [curCol], dl
    pop dx
    pop cx
    pop bx
    pop ax
    ret
pc_cr:
    mov byte ptr [curCol], 0
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_char_color endp

; print_string_color: DS:DX -> '$'-terminated string
print_string_color:
    push ax
    push si
    mov si, dx
ps_loop:
    lodsb
    cmp al, '$'
    je  ps_done
    call print_char_color
    jmp ps_loop
ps_done:
    pop si
    pop ax
    ret

; print_number_color: prints unsigned number in AX (decimal)
print_number_color:
    push ax
    push bx
    push cx
    push dx
    mov bx, 10
    xor cx, cx
    cmp ax, 0
    jne pn_div
    mov al, '0'
    call print_char_color
    jmp pn_exit
pn_div:
    xor dx, dx
pn_loop:
    div bx
    push dx
    inc cx
    xor dx, dx
    cmp ax, 0
    jne pn_loop
pn_print:
    pop dx
    mov al, dl
    add al, '0'
    call print_char_color
    loop pn_print
pn_exit:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ---------- BASE CONVERSION PRINTS (use [value]) ----------

; print_bin8: show [value] as 8 bits (4 + space + 4)
print_bin8:
    push ax
    push bx
    push si
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
    call print_4chars_color
    ; space
    mov al, ' '
    call print_char_color
    ; low nibble
    mov al, [value]
    and al, 0Fh
    mov si, offset bin4_tbl
    mov bl, al
    xor bh, bh
    shl bx, 2
    add si, bx
    call print_4chars_color
    pop si
    pop bx
    pop ax
    ret

; print_hex2: show [value] as two hex digits (uppercase)
print_hex2:
    push ax
    push si
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
    call print_char_color
    ; low nibble
    mov al, [value]
    and al, 0Fh
    xor ah, ah
    mov si, offset hex_tbl
    add si, ax
    lodsb
    call print_char_color
    pop si
    pop ax
    ret

; print_4chars_color: prints 4 ASCII chars from DS:SI
print_4chars_color:
    push cx
    mov cx, 4
p4_loop:
    lodsb
    call print_char_color
    loop p4_loop
    pop cx
    ret

; print_oct3: show [value] in octal as exactly 3 digits (000..377)
print_oct3:
    push ax
    ; d2
    mov al, [value]
    mov ah, al
    shr ah, 6
    and ah, 03h
    mov al, ah
    add al, '0'
    call print_char_color
    ; d1
    mov al, [value]
    mov ah, al
    shr ah, 3
    and ah, 07h
    mov al, ah
    add al, '0'
    call print_char_color
    ; d0
    mov al, [value]
    mov ah, al
    and ah, 07h
    mov al, ah
    add al, '0'
    call print_char_color
    pop ax
    ret