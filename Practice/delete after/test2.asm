org 100h

    ; Set text mode 80x25
    mov ax, 0003h
    int 10h

    ; Set ES to video memory
    mov ax, 0B800h
    mov es, ax

    ; Print name at bottom (row 24, col 37)
    mov di, 3874  ; 24*160 + 74
    call draw_name

    ; Split and move halves diagonally upward (10 steps)
    mov cx, 10
split_loop:
    push cx
    call clear_video
    ; Update left half (pos[0..2]): up 1 row, left 1 col
    mov di, OFFSET pos
    mov cl, 3
upd_left:
    mov ax, [di]
    sub ax, 162
    mov [di], ax
    add di, 2
    dec cl
    jnz upd_left
    ; Update right half (pos[3..5]): up 1 row, right 1 col
    mov cl, 3
upd_right:
    mov ax, [di]
    sub ax, 158
    mov [di], ax
    add di, 2
    dec cl
    jnz upd_right
    call draw_from_pos
    pop cx
    loop split_loop

    ; Exit to DOS
    mov ah, 4Ch
    int 21h

; Subroutines
draw_name:
    push ax
    push bx
    push cx
    push di
    mov bx, di
    mov si, OFFSET letters
    mov cx, 6
    mov ah, 0Fh  ; White text on black
draw_loop:
    mov [di], bx
    mov al, [si]
    mov es:[bx], ax
    add bx, 2
    add di, 2
    inc si
    loop draw_loop
    pop di
    pop cx
    pop bx
    pop ax
    ret

draw_from_pos:
    push ax
    push bx
    push cx
    push si
    mov di, OFFSET pos
    mov si, OFFSET letters
    mov cx, 6
    mov ah, 0Fh
draw_pos_loop:
    mov bx, [di]
    mov al, [si]
    mov es:[bx], ax
    add di, 2
    inc si
    loop draw_pos_loop
    pop si
    pop cx
    pop bx
    pop ax
    ret

clear_video:
    push ax
    push bx
    push cx
    push di
    mov di, OFFSET pos
    mov cx, 6
    mov ax, 0700h  ; Space with light gray
clear_loop:
    mov bx, [di]
    mov es:[bx], ax
    add di, 2
    loop clear_loop
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Data
letters db 'h','e','l','l','o','o'
pos dw 3874, 3876, 3878, 3880, 3882, 3884