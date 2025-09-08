.model small
.stack 100h

.data
    message db 'Sid Andre Bordrio', '$'

.code
main:
    mov ax, @data
    mov ds, ax

    ; --- Calculate center position ---
    ; Screen width = 80 columns
    ; Screen height = 25 rows
    ; Center row = 25 / 2 = 12
    ; Center column = (80 - message length) / 2

    mov ah, 0Ah           ; Function to get string length
    lea dx, message
    mov cx, 0             ; Clear CX
    mov si, dx
    call get_length       ; Get string length in CX

    mov bl, 80
    sub bl, cl            ; BL = 80 - string length
    shr bl, 1             ; BL = (80 - string length) / 2

    mov dh, 12            ; Row = 12 (center)
    mov dl, bl            ; Column = calculated center
    mov ah, 02h           ; Set cursor position
    mov bh, 0             ; Page number
    int 10h

    ; --- Print the string ---
    lea dx, message
    mov ah, 09h
    int 21h

    ; --- Wait for key press before exit ---
    mov ah, 00h
    int 16h

    mov ah, 4Ch
    int 21h

; --- Subroutine to get string length ---
get_length:
    mov cl, 0
.next_char:
    mov al, [si]
    cmp al, '$'
    je .done
    inc si
    inc cl
    jmp .next_char
.done:
    ret

end main
