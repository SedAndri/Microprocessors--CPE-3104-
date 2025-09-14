; helloo_word_row_split_fixed.asm   - .COM style (ORG 100h)
; Prints "helloo" as a whole word per row (horizontal), moves it down, then splits halves diagonally up

org 100h

DELAY_OUTER  EQU  0002h   ; tune delay length here (outer loop)
DELAY_INNER  EQU  0008h   ; tune delay length here (inner loop)

    ; --- ensure DS points to our code/data segment (COM starts with DS=PSP) ---
    push cs
    pop ds

    ; --- ensure text mode 80x25 and clear screen (optional but helpful) ---
    mov ax, 0003h
    int 10h

    ; Some BIOS calls may not preserve DS reliably; re-establish DS=CS
    push cs
    pop ds

    ; --- set ES to video memory, keep DS as program/data ---
    mov ax, 0B800h
    mov es, ax

    ; starting position: offset 74 (row0, column 37)
    mov si, 74          ; SI = current leftmost letter offset (in bytes)
    mov bl, 24          ; number of downward moves (0..23 via loop) + final draw at row 24
                        ; adjust if you want fewer/more steps

main_move_down:
    ; Draw the whole word on a single row starting at SI
    call DRAW_NAME      ; draw horizontal "helloo" at offsets SI, SI+2, ..., SI+10
    call DELAY

    call CLEAR_VIDEO    ; clear the just-drawn characters on screen (pos[] still holds offsets)
    add si, 160         ; move the top one row down
    dec bl
    jnz main_move_down

    ; final draw at bottom position (do not clear this time)
    ; Final draw at bottom position (SI already at bottom)
    call DRAW_NAME
    call DELAY

    ; --- split & animate halves upward diagonally ---
    mov cx, 10          ; number of diagonal steps (adjust as desired)

split_loop:
    push cx             ; preserve outer counter while subroutines use CX
    call CLEAR_VIDEO    ; clear current characters on screen

    ; update left half (pos[0..2]) : pos = pos - (160 + 2)  (up one row, left one column)
    mov di, OFFSET pos
    mov cl, 3
upd_left:
    mov ax, [di]
    sub ax, 160
    sub ax, 2
    mov [di], ax
    add di, 2
    dec cl
    jnz upd_left

    ; update right half (pos[3..5]) : pos = pos -160 + 2 (up one row, right one column)
    mov cl, 3
upd_right:
    mov ax, [di]
    sub ax, 160
    add ax, 2
    mov [di], ax
    add di, 2
    dec cl
    jnz upd_right

    call DRAW_FROM_POS  ; draw letters using updated pos[] values
    call DELAY
    pop cx
    loop split_loop

    ; exit
    mov ah, 4Ch
    xor al, al
    int 21h

; ------------------------------------------------------------
; Subroutines
; ------------------------------------------------------------

; DRAW_NAME: uses SI as start offset, stores the 6 offsets into pos[] and draws letters
; expects ES = video segment, DS = program/data
DRAW_NAME:
    push ax
    push di

    ; Row-wise horizontal word: each next char is +2 bytes (next column)
    ; pos[0] = si, char 'h'
    mov di, OFFSET pos
    mov ax, si
    mov [di], ax
    mov di, ax
    mov ah, 0Fh
    mov al, 'h'
    mov es:[di], ax

    ; pos[1] = si+2, char 'e'
    mov di, OFFSET pos+2
    mov ax, si
    add ax, 2
    mov [di], ax
    mov di, ax
    mov ah, 0Fh
    mov al, 'e'
    mov es:[di], ax

    ; pos[2] = si+4, char 'l'
    mov di, OFFSET pos+4
    mov ax, si
    add ax, 4
    mov [di], ax
    mov di, ax
    mov ah, 0Fh
    mov al, 'l'
    mov es:[di], ax

    ; pos[3] = si+6, char 'l'
    mov di, OFFSET pos+6
    mov ax, si
    add ax, 6
    mov [di], ax
    mov di, ax
    mov ah, 0Fh
    mov al, 'l'
    mov es:[di], ax

    ; pos[4] = si+8, char 'o'
    mov di, OFFSET pos+8
    mov ax, si
    add ax, 8
    mov [di], ax
    mov di, ax
    mov ah, 0Fh
    mov al, 'o'
    mov es:[di], ax

    ; pos[5] = si+10, char 'o'
    mov di, OFFSET pos+10
    mov ax, si
    add ax, 10
    mov [di], ax
    mov di, ax
    mov ah, 0Fh
    mov al, 'o'
    mov es:[di], ax

    pop di
    pop ax
    ret

; DRAW_FROM_POS: draw letters using the offsets stored in pos[]
DRAW_FROM_POS:
    push ax
    push di

    ; pos[0] -> 'h'
    mov di, OFFSET pos
    mov ax, [di]
    mov di, ax
    mov ah, 0Fh
    mov al, 'h'
    mov es:[di], ax

    ; pos[1] -> 'e'
    mov di, OFFSET pos+2
    mov ax, [di]
    mov di, ax
    mov ah, 0Fh
    mov al, 'e'
    mov es:[di], ax

    ; pos[2] -> 'l'
    mov di, OFFSET pos+4
    mov ax, [di]
    mov di, ax
    mov ah, 0Fh
    mov al, 'l'
    mov es:[di], ax

    ; pos[3] -> 'l'
    mov di, OFFSET pos+6
    mov ax, [di]
    mov di, ax
    mov ah, 0Fh
    mov al, 'l'
    mov es:[di], ax

    ; pos[4] -> 'o'
    mov di, OFFSET pos+8
    mov ax, [di]
    mov di, ax
    mov ah, 0Fh
    mov al, 'o'
    mov es:[di], ax

    ; pos[5] -> 'o'
    mov di, OFFSET pos+10
    mov ax, [di]
    mov di, ax
    mov ah, 0Fh
    mov al, 'o'
    mov es:[di], ax

    pop di
    pop ax
    ret

; CLEAR_VIDEO: clears the 6 positions stored in pos[] on the screen (writes zero to ES)
CLEAR_VIDEO:
    push ax
    push di
    push cx

    mov di, OFFSET pos
    mov cx, 6
cv_loop:
    mov ax, [di]        ; offset to clear
    push di
    mov di, ax
    ; write space with light grey attribute for clean clear
    mov al, ' '
    mov ah, 07h
    mov es:[di], ax     ; clear cell with space
    pop di
    add di, 2
    loop cv_loop

    pop cx
    pop di
    pop ax
    ret

; Simple delay (small)
DELAY:
    push cx
    mov cx, DELAY_OUTER
d_outer:
    push cx
    mov cx, DELAY_INNER
d_inner:
    nop
    dec cx
    jnz d_inner
    pop cx
    dec cx
    jnz d_outer
    pop cx
    ret

; ------------------------------------------------------------
; Data (DS -> program/data)
; ------------------------------------------------------------
letters db 'h','e','l','l','o','o'
pos     dw 6 dup(0)

; end of file
