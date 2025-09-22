org 100h

jmp start

; data
promptA   db 'Input A: $'
promptB   db 'Input B: $'
promptC   db 'Input C: $'
promptD   db 'Input D: $'

sep10     db 13,10,'',13,10,'$'
sep11     db '',13,10,'$'

lineA     db 'A = $'
lineB     db 'B = $'
lineC     db 'C = $'
lineD     db 'D = $'
xeq       db 'X = $'

base10    db ' (base 10)$'
base5     db ' (base 5)$'

sp_min    db ' - $'
sp_mul    db ' x $'
sp_div    db ' / $'

errD0     db 13,10,'Error: D = 00 (division by zero).$'

A1 db ?   ; ASCII digit 1 of A
A2 db ?   ; ASCII digit 2 of A
B1 db ?
B2 db ?
C1 db ?
C2 db ?
D1 db ?
D2 db ?

A_val dw ?
B_val dw ?
C_val dw ?
D_val dw ?
X_val dw ?

-
print_str:             ; DX -> $-terminated string
    mov ah, 09h
    int 21h
    ret

print_char:            ; DL -> char
    mov ah, 02h
    int 21h
    ret

print_crlf:
    mov dl, 13
    call print_char
    mov dl, 10
    call print_char
    ret

print_two:            
    push ax
    push dx
    mov dl, [di]
    call print_char
    mov dl, [di+1]
    call print_char
    pop dx
    pop ax
    ret

read_digit:
rdig:
    mov ah, 01h
    int 21h
    cmp al, '0'
    jb  rdig
    cmp al, '9'
    ja  rdig
    ret

; DI -> where to store two ASCII digits
; SI -> where to store numeric word
read_two_digits:
    push bx
    push dx
    ; first digit
    call read_digit
    mov [di], al
    ; second digit
    call read_digit
    mov [di+1], al
    ; consume until CR
.rd_flush:
    mov ah, 01h
    int 21h
    cmp al, 0Dh
    jne .rd_flush
    ; convert to number: (d1-30h)*10 + (d2-30h)
    mov al, [di]
    sub al, '0'
    xor ah, ah
    mov bl, 10
    mul bl            ; AX = (d1-30h)*10
    xor bh, bh
    mov bl, [di+1]
    sub bl, '0'
    add ax, bx
    mov [si], ax
    ; echo newline after input line
    call print_crlf
    pop dx
    pop bx
    ret

; AX -> signed value, prints in base 10
print_signed_dec:
    push ax
    push bx
    push cx
    push dx
    ; sign
    cmp ax, 0
    jge .pos
    mov dl, '-'
    call print_char
    neg ax
.pos:
    cmp ax, 0
    jne .conv
    mov dl, '0'
    call print_char
    jmp .done_digits
.conv:
    xor cx, cx
.conv_loop:
    xor dx, dx
    mov bx, 10
    div bx           ; AX = AX/10, DX = AX%10
    push dx
    inc cx
    cmp ax, 0
    jne .conv_loop
.print_loop:
    pop dx
    add dl, '0'
    call print_char
    loop .print_loop
.done_digits:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; AX -> signed value, prints in base 5
print_signed_base5:
    push ax
    push bx
    push cx
    push dx
    ; sign
    cmp ax, 0
    jge .pos5
    mov dl, '-'
    call print_char
    neg ax
.pos5:
    cmp ax, 0
    jne .conv5
    mov dl, '0'
    call print_char
    jmp .done5
.conv5:
    xor cx, cx
.conv5_loop:
    xor dx, dx
    mov bx, 5
    div bx           
    push dx
    inc cx
    cmp ax, 0
    jne .conv5_loop
.print5_loop:
    pop dx
    add dl, '0'
    call print_char
    loop .print5_loop
.done5:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; --- main ---
start:
    mov ax, cs
    mov ds, ax

    ; Input A
    mov dx, offset promptA
    call print_str
    lea di, A1
    lea si, A_val
    call read_two_digits

    ; Input B
    mov dx, offset promptB
    call print_str
    lea di, B1
    lea si, B_val
    call read_two_digits

    ; Input C
    mov dx, offset promptC
    call print_str
    lea di, C1
    lea si, C_val
    call read_two_digits

    ; Input D
    mov dx, offset promptD
    call print_str
    lea di, D1
    lea si, D_val
    call read_two_digits

    ; Guard: D == 0 ?
    mov ax, D_val
    or  ax, ax
    jnz calc
    mov dx, offset errD0
    call print_str
    call print_crlf
    jmp exit

calc:
    ; ==========
    mov dx, offset sep10
    call print_str

    ; A = ##
    mov dx, offset lineA
    call print_str
    lea di, A1
    call print_two
    call print_crlf

    ; B = ##
    mov dx, offset lineB
    call print_str
    lea di, B1
    call print_two
    call print_crlf

    ; C = ##
    mov dx, offset lineC
    call print_str
    lea di, C1
    call print_two
    call print_crlf

    ; D = ##
    mov dx, offset lineD
    call print_str
    lea di, D1
    call print_two
    call print_crlf

    ; ===========
    mov dx, offset sep11
    call print_str

    ; X = AA - BB x CC / DD
    mov dx, offset xeq
    call print_str
    lea di, A1
    call print_two
    mov dx, offset sp_min
    call print_str
    lea di, B1
    call print_two
    mov dx, offset sp_mul
    call print_str
    lea di, C1
    call print_two
    mov dx, offset sp_div
    call print_str
    lea di, D1
    call print_two
    call print_crlf

    ; ===========
    mov dx, offset sep11
    call print_str

  
    mov ax, B_val
    mov cx, C_val
    mul cx              
    mov bx, D_val
    div bx             
    mov bx, A_val
    sub bx, ax          
    mov ax, bx
    mov X_val, ax

    ; Print: X = ????10
    mov dx, offset xeq
    call print_str
    mov ax, X_val
    call print_signed_dec
    mov dx, offset base10
    call print_str
    call print_crlf

    ; Print: X = ????5
    mov dx, offset xeq
    call print_str
    mov ax, X_val
    call print_signed_base5
    mov dx, offset base5
    call print_str
    call print_crlf

exit:
    mov ax, 4C00h
    int 21h




