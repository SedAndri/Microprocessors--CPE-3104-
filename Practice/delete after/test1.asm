; TASM program to display a string vertically 
; in the center of 80x25 text screen

.MODEL small
.STACK 100h
.DATA
    msg      DB 'HELLO WORLD$',0   ; String to display (terminated by '$')
    msglen   DB 0                 ; length excluding '$'
    startcol DB 0                 ; starting column to center the string

.CODE
MAIN PROC
    mov ax, @data
    mov ds, ax

    ; Compute string length (exclude '$')
    mov si, offset msg
    xor cx, cx
len_loop:
    mov al, [si]
    cmp al, '$'
    je  len_done
    inc cx
    inc si
    jmp len_loop
len_done:
    mov [msglen], cl         ; save length (<=255)

    ; Compute centered start column: (80 - len) / 2
    mov bl, 80
    sub bl, cl               ; BL = 80 - len
    shr bl, 1                ; BL = (80 - len) / 2
    mov [startcol], bl

    ; Prepare ES:BP to point to the string
    mov ax, @data
    mov es, ax
    mov bp, offset msg

    ; Animate: clear screen, draw string at row DH, move down, repeat
    xor dh, dh               ; DH = row = 0
    mov bl, 0Eh              ; attribute: light yellow on black

animate_loop:
    ; Clear entire screen: INT 10h AH=06h (scroll up), AL=0 clears window
    push dx                 ; preserve DH=row across clear
    mov ah, 06h              ; scroll up / clear window
    xor al, al               ; AL=0 => clear
    mov bh, bl               ; BH = attribute for blank lines
    xor cx, cx               ; CH=0, CL=0 (upper-left corner)
    mov dx, 184Fh            ; DH=24, DL=79 (lower-right corner)
    int 10h
    pop dx                  ; restore DH=row

    ; Draw the full string at current row DH, centered at startcol
    mov ah, 13h              ; BIOS: write string
    mov al, 01h              ; use BL attribute for all chars
    xor bh, bh               ; page = 0
    mov dl, [startcol]       ; starting column
    xor ch, ch
    mov cl, [msglen]         ; CX = length
    int 10h

    ; Exit if key pressed (non-blocking check)
    mov ah, 01h              ; INT 16h: check keystroke
    int 16h
    jnz done                 ; key pressed -> exit

    ; Advance row and wrap
    inc dh
    cmp dh, 25
    jb  animate_loop
    ; reached bottom -> exit
    jmp done

done:
    mov ah, 4Ch
    int 21h

MAIN ENDP
END MAIN
