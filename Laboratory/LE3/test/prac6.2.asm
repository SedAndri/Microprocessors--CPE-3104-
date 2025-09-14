; ==========================================
; BINARY (up to 8 bits) -> Decimal, Binary (8 bits), Octal, and Hex (2 digits)
; EMU8086 .COM
; ==========================================

org 100h
    jmp start

; ---------- DATA ----------
prompt      db 'Enter binary (up to 8 bits): $'
nl          db 0Dh,0Ah,'$'
msg_dec     db 0Dh,0Ah,'Decimal: $'
msg_bin     db 0Dh,0Ah,'Binary: $'
msg_oct     db 0Dh,0Ah,'Octal : $'
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

    ; -------- read & parse BINARY (up to 8 bits) --------
    xor bl, bl                 ; BL = accumulator for final value (0..255)
    xor cx, cx                 ; CX = bit count (0..8)
read_loop:
    mov ah, 1
    int 21h
    cmp al, 0Dh                ; Enter?
    je  parse_done

    ; accept only '0' and '1'; ignore spaces/underscores/others
    cmp al, '0'
    je  got_zero
    cmp al, '1'
    je  got_one
    cmp al, ' '
    je  read_loop
    cmp al, '_'
    je  read_loop
    jmp read_loop              ; ignore any other char

got_zero:
    cmp cx, 8
    jae read_loop              ; already 8 bits, ignore extras
    shl bl, 1                  ; append 0
    inc cx
    jmp read_loop

got_one:
    cmp cx, 8
    jae read_loop              ; already 8 bits, ignore extras
    shl bl, 1
    or  bl, 1                  ; append 1
    inc cx
    jmp read_loop

parse_done:
    mov [value], bl

    ; newline
    mov dx, offset nl
    mov ah, 9
    int 21h

    ; -------- print Decimal (no suffix) --------
    mov dx, offset msg_dec
    mov ah, 9
    int 21h
    call print_dec

    ; -------- print Binary (8 bits, grouped) + 'b' --------
    mov dx, offset msg_bin
    mov ah, 9
    int 21h
    call print_bin8
    mov dl, 'b'                ; suffix
    mov ah, 2
    int 21h

    ; -------- print Octal (3 digits) + 'o' --------
    mov dx, offset msg_oct
    mov ah, 9
    int 21h
    call print_oct3
    mov dl, 'o'                ; suffix
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

; print_dec: show [value] in unsigned decimal (0..255) without leading zeros
print_dec:
    mov al, [value]
    xor ah, ah            ; AX = value
    mov bl, 100
    div bl                ; AL = hundreds (0..2), AH = remainder
    mov bh, al            ; save hundreds for later
    mov ch, ah            ; preserve remainder (0..99); AH may be clobbered by int 21h
    cmp al, 0
    je  pd_skip_hund
    mov dl, al
    add dl, '0'
    mov ah, 2
    int 21h
pd_skip_hund:
    mov al, ch            ; restore remainder saved before INT 21h
    xor ah, ah
    mov bl, 10
    div bl                ; AL = tens, AH = ones
    mov cl, ah            ; preserve ones; AH may be clobbered by int 21h
    cmp bh, 0
    jne pd_print_tens
    cmp al, 0
    je  pd_skip_tens
pd_print_tens:
    mov dl, al
    add dl, '0'
    mov ah, 2
    int 21h
pd_skip_tens:
    mov dl, cl            ; ones (restored)
    add dl, '0'
    mov ah, 2
    int 21h
    ret

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

; print_oct3: show [value] in octal as exactly 3 digits (000..377)
; d2 = (value >> 6) & 3, d1 = (value >> 3) & 7, d0 = value & 7
print_oct3:
    ; d2
    mov al, [value]
    mov ah, al
    shr ah, 6
    and ah, 03h
    mov dl, ah
    add dl, '0'
    mov ah, 2
    int 21h

    ; d1
    mov al, [value]
    mov ah, al
    shr ah, 3
    and ah, 07h
    mov dl, ah
    add dl, '0'
    mov ah, 2
    int 21h

    ; d0
    mov al, [value]
    mov ah, al
    and ah, 07h
    mov dl, ah
    add dl, '0'
    mov ah, 2
    int 21h
    ret