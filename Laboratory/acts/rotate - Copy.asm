org 100h                ; COM program origin

    ; Initialize DS (data variables stored near STR1)
    mov ax, seg STR1
    mov ds, ax
    mov es, ax            ; <<< added: make ES same as DS so rep movsb writes into data segment

    ; Compute length of null-terminated STR1 and copy it to ORIG
    lea si, STR1
    xor cx, cx
FindLen:
    mov al, [si]          ; <<< changed: use SI and advance it instead of unsupported [si+cx]
    cmp al, 0
    je LenFound
    inc cx
    inc si
    jmp FindLen
LenFound:
    ; CX = length
    mov [LEN], cl          ; save length (byte)
    lea si, STR1
    lea di, ORIG
    xor ch, ch
    cld
    rep movsb
    mov byte ptr [di], 0   ; null-terminate ORIG

    ; Prepare video memory (text mode) and set line pointer at top-left
    mov ax, 0B800h
    mov es, ax
    xor dx, dx            ; DX = video offset for current line (bytes)

    ; Display the label then the original string on the first line
    lea si, MSG_LABEL+1
    mov cl, [MSG_LABEL]
    xor ch, ch
    mov di, dx            ; DI = current video start
    call DisplayString

    lea si, ORIG          ; ORIG contains the saved original characters
    mov cl, [LEN]
    xor ch, ch
    call DisplayString
    add dx, 160           ; move to next line (80 cols * 2 bytes)

; --- Main rotation loop: rotate right until the string equals the original ---
NextRotation:
    mov cl, [LEN]
    xor ch, ch
    cmp cx, 1
    jbe DoneRotation      ; nothing to do for length <= 1

    ; Rotate right by one: move last byte to front, shift others right
    lea si, STR1          ; SI -> first character
    mov bx, cx
    dec bx                ; BX = length - 1
    lea di, STR1
    add di, bx            ; DI -> last character
    mov al, [di]          ; save last char
    mov cx, bx            ; CX = number of moves
ShiftLoop:
    mov dl, [di-1]
    mov [di], dl
    dec di
    loop ShiftLoop
    mov [si], al          ; place last char at first position

    ; Display rotated string at current video line
    mov di, dx            ; DI = current video start
    lea si, STR1
    mov cl, [LEN]
    xor ch, ch
    call DisplayString
    add dx, 160           ; advance to next output line

    ; Compare rotated string with ORIG; if any char differs, continue rotating
    lea si, STR1
    lea bx, ORIG
    mov cl, [LEN]
    xor ch, ch
CompareLoop:
    mov al, [si]
    cmp al, [bx]
    jne NextRotation
    inc si
    inc bx
    dec cx
    jnz CompareLoop

DoneRotation:
    ret

; ---------------------
; DisplayString: writes CX characters from DS:SI to ES:DI (text mode)
; Input: SI -> source string, CX = length, ES:DI = video offset
; Clobbers: AL, AH, DL, DI, SI, CX
DisplayString:
    push bp
    push si
    push di
    push bx
    push cx            ; save original count

    ; Clear entire text line (80 columns) to avoid leftover characters
    mov bx, di         ; use BX to walk the line so DI stays as line start
    mov cx, 80
ClearLoop:
    mov al, ' '
    mov ah, 07h
    mov es:[bx], ax
    add bx, 2
    loop ClearLoop

    pop cx             ; restore original count

DisplayLoop:
    mov al, [si]
    mov ah, 07h
    mov es:[di], ax
    inc si
    add di, 2
    loop DisplayLoop

    pop bx
    pop di
    pop si
    pop bp
    ret

.data
    ; STR1 is now a null-terminated string (you can change this to any string)
    STR1  db 'brownfox',0
    ORIG  db 256 dup(0)
    LEN   db 0

    MSG_LABEL db 14,'Input string: '
    MSG2  db 0Dh,0Ah,' $'
    MSG1  db 0Dh,0Ah,'Output: $'
.code