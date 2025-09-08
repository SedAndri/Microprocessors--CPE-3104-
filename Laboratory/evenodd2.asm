org 100h

.code
    mov ax, 0B800h         ; Video buffer segment
    mov es, ax

    mov di, 0              ; Start at top-left (row 0, col 0)

    ; Display "Value: "
    mov si, msg_value
next_char:
    lodsb                  ; Load byte from [SI] into AL
    cmp al, 0
    je show_number
    mov ah, 0x07           ; Attribute: light gray on black
    mov es:[di], ax
    add di, 2
    jmp next_char

show_number:
    mov al, 7              ; Hard-coded value
    mov bl, al
    add al, 30h            ; Convert to ASCII
    mov ah, 0x07
    mov es:[di], ax
    add di, 2

    ; Display " is "
    mov si, msg_is
next_is:
    lodsb
    cmp al, 0
    je check_even
    mov ah, 0x07
    mov es:[di], ax
    add di, 2
    jmp next_is

check_even:
    mov al, bl             ; Restore value
    mov ah, 0
    mov bl, 2
    div bl                 ; AL/BL, remainder in AH

    cmp ah, 0
    je print_even

    ; Print "odd"
    mov si, msg_odd
    jmp print_result

print_even:
    mov si, msg_even

print_result:
next_result:
    lodsb
    cmp al, 0
    je done
    mov ah, 0x07
    mov es:[di], ax
    add di, 2
    jmp next_result

done:
    ret

msg_value db 'Value: ',0
msg_is   db ' is ',0
msg_even db 'even',0
msg_odd  db 'odd',0