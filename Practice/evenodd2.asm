org 100h

.code
    mov ax, 0B800h        ; Video segment for text mode
    mov es, ax

    mov di, 0             ; Start at top-left (row 0, col 0)

    mov al, 7             ; Hard-coded number
    mov ah, 0             ; Clear AH for division
    mov bl, 2             ; Divisor
    div bl                ; AL/2, remainder in AH

    cmp ah, 0
    je show_even

    ; Show "Odd" message
    mov si, odd_msg
    call print_msg
    jmp end_label

show_even:
    mov si, even_msg
    call print_msg

end_label:
    ret

print_msg:                ; Print string at ES:DI
    mov cx, 0
.next_char:
    mov al, [si]
    cmp al, '$'
    je .done
    mov [es:di], al       ; Character
    mov [es:di+1], byte 0x07 ; Attribute (light gray on black)
    add di, 2
    inc si
    jmp .next_char
.done:
    ret

even_msg db "The value is an even number!$"
odd_msg  db "The value is an odd number!$"