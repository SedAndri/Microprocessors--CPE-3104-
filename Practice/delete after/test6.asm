.model small
.stack 100h
.data
    prompt db 'Fahrenheit: $'
    result_msg db 0Dh, 0Ah, 'Celsius: $'
    newline db 0Dh, 0Ah, '$'
    celsius dw ?
    fahrenheit dw ?
    sign db 0
    buffer db 6, ?, 6 dup('$') ; Buffer for input (max 5 digits + sign)

.code
main proc
    mov ax, @data
    mov ds, ax

    ; Display prompt
    mov ah, 09h
    lea dx, prompt
    int 21h

    ; Read input string
    mov ah, 0Ah
    lea dx, buffer
    int 21h

    ; Convert ASCII input to signed number
    xor ax, ax
    xor bx, bx
    lea si, buffer + 2 ; Point to start of input string
    mov cl, buffer + 1 ; Get length of input
    xor ch, ch
    mov di, 10         ; Multiplier constant for base-10
    mov byte ptr sign, 0  ; 0 = positive, 1 = negative
    cmp cl, 0
    je convert_done    ; Empty input -> treat as 0
    cmp byte ptr [si], '-'
    jne check_plus
    mov byte ptr sign, 1 ; negative
    inc si
    dec cl
    jmp after_sign
check_plus:
    cmp byte ptr [si], '+'
    jne after_sign
    inc si
    dec cl
after_sign:

convert_loop:
    cmp cl, 0
    je convert_done
    mov bl, [si]
    sub bl, '0'        ; Convert ASCII digit to number
    mul di             ; AX = AX * 10 (using DI as multiplier)
    add ax, bx         ; Add current digit
    inc si
    dec cl
    jmp convert_loop

convert_done:
    cmp byte ptr sign, 0
    je store_pos
    neg ax             ; Apply negative sign if needed
store_pos:
    mov fahrenheit, ax ; Store Fahrenheit value

    ; Convert Fahrenheit to Celsius: C = (F - 32) * 5 / 9
    mov ax, fahrenheit
    sub ax, 32         ; AX = F - 32
    mov bx, 5
    imul bx            ; DX:AX = (F - 32) * 5  (signed)
    mov bx, 9
    idiv bx            ; AX = ((F - 32) * 5) / 9 (signed)
    mov celsius, ax    ; Store Celsius value

    ; Display result message
    mov ah, 09h
    lea dx, result_msg
    int 21h

    ; Convert Celsius to ASCII and display
    mov ax, celsius
    call print_number

    ; Print newline
    mov ah, 09h
    lea dx, newline
    int 21h

    ; Exit program
    mov ah, 4Ch
    int 21h

main endp

; Procedure to print number in AX
print_number proc
    push ax
    push bx
    push cx
    push dx

    mov bx, 10
    xor cx, cx         ; Clear digit counter

    ; Handle sign
    test ax, ax
    jns pn_check_zero
    ; print '-'
    push ax
    mov dl, '-'
    mov ah, 02h
    int 21h
    pop ax
    neg ax

pn_check_zero:
    cmp ax, 0
    jne divide_loop
    ; print single '0'
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp pn_done

divide_loop:
    xor dx, dx
    div bx             ; Divide AX by 10, quotient in AX, remainder in DX
    push dx            ; Save remainder (digit)
    inc cx             ; Increment digit counter
    cmp ax, 0
    jne divide_loop

print_loop:
    pop dx
    add dl, '0'        ; Convert digit to ASCII
    mov ah, 02h
    int 21h
    loop print_loop

pn_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number endp

end main