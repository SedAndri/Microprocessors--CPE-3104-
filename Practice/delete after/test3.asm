org 100h

DELAY_OUTER EQU 0002h
DELAY_INNER EQU 0003h

    ; set video memory
    mov ax, 0B800h
    mov es, ax

    ; start pos (row 0, col 37)
    mov si, 74
    mov bl, 24           ; 24 rows to fall

fall_loop:
    call draw_name
    call delay
    call clear_video
    add si, 160          ; move one row down
    dec bl
    jnz fall_loop

    ; final draw at bottom
    call draw_name
    call delay

    ; split diagonally upward
    mov cx, 10
split_loop:
    call clear_video

    ; left half (3 chars): up 1 row, left 1 col
    mov di, offset pos
    mov cl, 3
left_half:
    mov ax, [di]
    sub ax, 162          ; up-left
    mov [di], ax
    add di, 2
    loop left_half

    ; right half (3 chars): up 1 row, right 1 col
    mov cl, 3
right_half:
    mov ax, [di]
    sub ax, 158          ; up-right
    mov [di], ax
    add di, 2
    loop right_half

    call draw_from_pos
    call delay
    loop split_loop

    ; exit
    mov ah, 4Ch
    int 21h

; ===== subroutines =====

draw_name:              ; draw "helloo" at SI
    mov di, offset pos
    mov bx, si
    mov si, offset letters
    mov cx, 6
    mov ah, 0Fh
dloop:
    mov [di], bx
    mov al, [si]
    mov es:[bx], ax
    add bx, 2
    add di, 2
    inc si
    loop dloop
    ret

draw_from_pos:          ; draw using stored pos[]
    mov di, offset pos
    mov si, offset letters
    mov cx, 6
    mov ah, 0Fh
ploop:
    mov bx, [di]
    mov al, [si]
    mov es:[bx], ax
    add di, 2
    inc si
    loop ploop
    ret

clear_video:            ; erase letters
    mov di, offset pos
    mov cx, 6
    mov ax, 0720h       ; space w/ gray attr
cloop:
    mov bx, [di]
    mov es:[bx], ax
    add di, 2
    loop cloop
    ret

delay:
    mov cx, DELAY_OUTER
d1: push cx
        mov cx, DELAY_INNER
    d2: loop d2
    pop cx
    loop d1
    ret

; ===== data =====
letters db 'h','e','l','l','o','o'
pos     dw 6 dup(?)
