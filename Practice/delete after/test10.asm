; ==========================================
; Two numbers (0�255) ? Sum, Difference, Product, Quotient, Remainder

; - Buffered input (AH=0Ah)
; - Print labels FIRST, then compute result, then print number
; ==========================================

org 100h
    jmp start

; ---------- DATA ----------
msg1    db 'Enter first number (0-255): $'
msg2    db 0Dh,0Ah,'Enter second number (0-255): $'
nl      db 0Dh,0Ah,'$'

out_sum db 0Dh,0Ah,'Sum        = $'
out_dif db 0Dh,0Ah,'Difference = $'
out_mul db 0Dh,0Ah,'Product    = $'
out_div db 0Dh,0Ah,'Quotient   = $'
out_rem db 0Dh,0Ah,'Remainder  = $'
div0    db 'division by zero$'

; DOS 0Ah input buffers (max 3 chars + CR)
buf1    db 3
len1    db 0
dat1    db 3 dup(0)

buf2    db 3
len2    db 0
dat2    db 3 dup(0)

val1    db 0
val2    db 0
quo     db 0
rem     db 0

ten     dw 10

; ---------- CODE ----------
start:
    push cs
    pop  ds

    ; ---- Read first number ----
    mov dx, offset msg1
    mov ah, 9
    int 21h

    mov dx, offset buf1
    mov ah, 0Ah
    int 21h

    mov si, offset buf1
    call parse_dec_0_255
    mov [val1], al

    ; ---- Read second number ----
    mov dx, offset msg2
    mov ah, 9
    int 21h

    mov dx, offset buf2
    mov ah, 0Ah
    int 21h

    mov si, offset buf2
    call parse_dec_0_255
    mov [val2], al

    ; newline
    mov dx, offset nl
    mov ah, 9
    int 21h

    ; -------- SUM (16-bit) --------
    mov dx, offset out_sum
    mov ah, 9
    int 21h
    xor ax, ax
    mov al, [val1]
    add al, [val2]
    adc ah, 0
    call print_u16

    ; -------- DIFFERENCE (A - B) --------
    mov dx, offset out_dif
    mov ah, 9
    int 21h
    mov al, [val1]
    cmp al, [val2]
    jae diff_nonneg
    ; negative: print '-' then (B - A)
    mov dl, '-'
    mov ah, 2
    int 21h
    xor ax, ax
    mov al, [val2]
    sub al, [val1]
    xor ah, ah
    jmp short diff_print
diff_nonneg:
    xor ax, ax
    mov al, [val1]
    sub al, [val2]
    xor ah, ah
diff_print:
    call print_u16

    ; -------- PRODUCT (8x8 -> 16) --------
    mov dx, offset out_mul
    mov ah, 9
    int 21h
    mov al, [val1]
    mov bl, [val2]
    mul bl                     ; AX = val1 * val2
    call print_u16

    ; -------- DIVISION & REMAINDER --------
    mov bl, [val2]
    cmp bl, 0
    je  div_by_zero

    ; compute once, store both quotient & remainder
    mov al, [val1]
    xor ah, ah
    div bl                     ; AL=quot, AH=rem
    mov [quo], al
    mov [rem], ah

    ; Quotient
    mov dx, offset out_div
    mov ah, 9
    int 21h
    xor ah, ah
    mov al, [quo]
    call print_u16

    ; Remainder
    mov dx, offset out_rem
    mov ah, 9
    int 21h
    xor ah, ah
    mov al, [rem]
    call print_u16
    jmp short done

div_by_zero:
    ; Quotient label + message
    mov dx, offset out_div
    mov ah, 9
    int 21h
    mov dx, offset div0
    mov ah, 9
    int 21h
    ; Remainder label + message
    mov dx, offset out_rem
    mov ah, 9
    int 21h
    mov dx, offset div0
    mov ah, 9
    int 21h

done:
    ; final newline & exit
    mov dx, offset nl
    mov ah, 9
    int 21h
    mov ax, 4C00h
    int 21h

; ---------- ROUTINES ----------

; parse_dec_0_255
; IN : SI -> DOS 0Ah buffer (len at [SI+1], digits at [SI+2..])
; OUT: AL = parsed value clamped to 255
parse_dec_0_255:
    push bx
    push cx
    push dx
    push di
    mov cl, [si+1]        ; CL = length (0..3)
    xor ch, ch
    lea di, [si+2]        ; DI -> first char
    xor bx, bx            ; BX = accumulator
pd_loop:
    cmp cx, 0
    je  pd_done
    mov al, [di]
    inc di
    ; accept only '0'..'9'
    cmp al, '0'
    jb  pd_next
    cmp al, '9'
    ja  pd_next
    sub al, '0'           ; AL = digit
    cbw                    ; AX = digit
    mov dx, bx
    mov ax, bx
    mul word ptr ten      ; DX:AX = BX * 10
    mov bx, ax            ; BX = BX*10
    add bx, ax            ; (AX had digit) <-- OOPS? No: we overwrote AX above
                          ; Fix: reload digit to AX:
pd_add_digit:
    ; reload digit from last char we read: it's in AL after 'cbw' BEFORE mul.
    ; To keep it simple, recompute digit from previous [di-1]:
    mov al, [di-1]
    sub al, '0'
    cbw
    add bx, ax            ; BX = BX*10 + digit
pd_next:
    dec cx
    jmp pd_loop
pd_done:
    cmp bx, 255
    jbe pd_ok
    mov bx, 255
pd_ok:
    mov al, bl
    pop di
    pop dx
    pop cx
    pop bx
    ret

; print_u16: prints AX (0..65535) unsigned decimal
print_u16:
    push ax
    push bx
    push cx
    push dx
    cmp ax, 0
    jne pu16_go
    mov dl, '0'
    mov ah, 2
    int 21h
    jmp pu16_done
pu16_go:
    xor cx, cx
pu16_loop:
    xor dx, dx
    mov bx, 10
    div bx                 ; AX = AX/10, DX = remainder
    push dx
    inc cx
    cmp ax, 0
    jne pu16_loop
pu16_print:
    pop dx
    add dl, '0'
    mov ah, 2
    int 21h
    loop pu16_print
pu16_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret