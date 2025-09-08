org 100h                   

mov ax, 0B800h             ; Video memory segment address (color text mode)
mov es, ax                 ; Set ES to point to video memory

mov si, offset msg         ; SI points to start of message

mov cx, 0                  ; CX will hold message length
calc_len:
    mov bx, si             ; BX = start of message
    add bx, cx             ; BX = current character offset
    mov al, [bx]           ; Load character at BX
    cmp al, 0              ; Check for null terminator
    je len_done            ; If null, end of string
    inc cx                 ; Increment length counter
    jmp calc_len           ; Repeat for next character
len_done:

mov bx, 80                 ; BX = screen width (columns)
sub bx, cx                 ; BX = remaining columns after message
shr bx, 1                  ; BX = half of remaining columns (center offset)

mov dx, 12                 ; DX = row number (13th row, zero-based)
mov ax, dx                 ; AX = row number
mov dx, 80                 ; DX = screen width
mul dx                     ; AX = row offset in characters
add ax, bx                 ; AX = final column offset (centered)
shl ax, 1                  ; Multiply by 2 (each char = 2 bytes) / shift left by 1
mov di, ax                 ; DI = video memory offset for start position

mov si, offset msg         ; SI points to start of message

next_char:
    mov al, [si]           ; Load next character from message
    cmp al, 0              ; Check for null terminator
    je done                ; If null, end loop
    mov es:[di], al        ; Write character to video memory
    mov es:[di+1], 1Eh     ; Set attribute (yellow on blue)
    add di, 2              ; Move to next character cell
    inc si                 ; Move to next character in message
    jmp next_char          ; Repeat for next character

done:
    ret                    ; Return to DOS

msg db 'Sid Andre P. Bordario', 0 ; Message to display