                    .model small
.stack 100h
.data
    celsius dw ?          ; Variable to store Celsius temperature
    kelvin dw ?          ; Variable to store Kelvin temperature
    prompt db 'Enter temperature in Celsius: $'
    result db 0dh,0ah,'Temperature in Kelvin: $'

.code
main proc
    mov ax, @data
    mov ds, ax

    ; Display prompt
    mov dx, offset prompt
    mov ah, 09h
    int 21h

    ; Read Celsius temperature (wait until Enter is pressed)
    ; Accumulate numeric input: celsius = celsius*10 + digit
    xor ax, ax
    mov celsius, ax

read_loop:
    mov ah, 01h          ; Read one char (echoed)
    int 21h
    cmp al, 0Dh          ; Enter (CR)? finish input
    je  input_done

    ; Accept only '0'..'9'; ignore other characters
    cmp al, '0'
    jb  read_loop
    cmp al, '9'
    ja  read_loop

    ; Convert ASCII to digit in BL
    sub al, '0'
    mov bl, al
    xor bh, bh

    ; celsius = celsius * 10 + digit (avoid MUL for simplicity)
    mov ax, celsius      ; AX = C
    mov dx, ax           ; DX = C
    shl ax, 1            ; AX = C*2
    shl dx, 1            ; DX = C*2
    shl dx, 1            ; DX = C*4
    shl dx, 1            ; DX = C*8
    add ax, dx           ; AX = C*10
    add ax, bx           ; AX = C*10 + digit
    mov celsius, ax
    jmp read_loop

input_done:

    ; Convert to Kelvin (K = C + 273)
    mov ax, celsius
    add ax, 273
    mov kelvin, ax

    ; Display result
    mov dx, offset result
    mov ah, 09h
    int 21h

    ; Convert Kelvin to ASCII and display
    mov ax, kelvin
    mov bx, 10
    mov cx, 0

convert:
    mov dx, 0
    div bx               ; Divide by 10
    push dx              ; Save remainder
    inc cx               ; Count digits
    cmp ax, 0
    jne convert

display:
    pop dx               ; Get digit
    add dl, 30h          ; Convert to ASCII
    mov ah, 02h
    int 21h
    loop display

    ; Exit program
    mov ah, 4ch
    int 21h
main endp
end main