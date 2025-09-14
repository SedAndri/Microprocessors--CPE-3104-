.model small
.stack 100h
.data
    prompt db 'Celsius: $'
    result_msg db 0Dh, 0Ah, 'Fahrenheit: $'
    kelvin_msg db 0Dh, 0Ah, 'Kelvin: $'
    newline db 0Dh, 0Ah, '$'
    celsius dw ?
    fahrenheit dw ?
    kelvin dw ?
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

    ; Convert ASCII input to number
    xor ax, ax
    xor bx, bx
    lea si, buffer + 2 ; Point to start of input string
    mov cl, buffer + 1 ; Get length of input
    xor ch, ch
    mov di, 10         ; Multiplier constant for base-10

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
    mov celsius, ax    ; Store Celsius value

    ; Convert Celsius to Fahrenheit: F = (C * 9/5) + 32
    mov ax, celsius
    mov bx, 9
    mul bx             ; AX = Celsius * 9
    mov bx, 5
    div bx             ; AX = (Celsius * 9) / 5
    add ax, 32         ; AX = (Celsius * 9/5) + 32
    mov fahrenheit, ax ; Store Fahrenheit value

    ; Convert Celsius to Kelvin: K = C + 273 (integer)
    mov ax, celsius
    add ax, 273
    mov kelvin, ax

    ; Display result message
    mov ah, 09h
    lea dx, result_msg
    int 21h

    ; Convert Fahrenheit to ASCII and display
    mov ax, fahrenheit
    call print_number

    ; Print newline
    mov ah, 09h
    lea dx, newline
    int 21h

    ; Display Kelvin result message
    mov ah, 09h
    lea dx, kelvin_msg
    int 21h

    ; Convert Kelvin to ASCII and display
    mov ax, kelvin
    call print_number

    ; Final newline
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

    ; Handle zero explicitly so 0 prints as '0'
    cmp ax, 0
    jne divide_loop
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp print_number_exit

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

print_number_exit:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number endp

end main