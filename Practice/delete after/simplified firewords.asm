org 100h

DELAY_OUTER EQU 0002h
DELAY_INNER EQU 0008h

    ; Initialize stack explicitly for Emu8086
    mov ax, cs
    mov ss, ax
    mov sp, 0FFFEh ; Set stack pointer to top of segment

    ; Set DS=CS for data access
    push cs
    pop ds

    ; Set text mode 80x25 (mode 03h)
    mov ax, 0003h
    int 10h

    ; Set ES to video memory (B800h)
    mov ax, 0B800h
    mov es, ax

    ; Start at offset 74 (row 0, col 37), move down 24 rows
    mov si, 74
    mov bl, 24
main_move_down:
    call draw_name
    call delay
    call clear_video
    add si, 160
    dec bl
    jnz main_move_down

    ; Final draw at bottom
    call draw_name
    call delay

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
    call delay
    pop cx
    loop split_loop

    ; Exit to DOS
    mov ah, 4Ch
    mov al, 00h
    int 21h

; Subroutines
draw_name:
    push ax
    push bx
    push cx
    push si
    mov di, OFFSET pos
    mov bx, si         ; BX = video offset for first letter
    mov si, OFFSET letters
    mov cx, 6
    mov ah, 0Fh ; White text on black background
draw_loop:
    mov [di], bx      ; store video offset in pos[]
    mov al, [si]      ; get letter
    mov es:[bx], ax   ; write letter+attr
    add bx, 2         ; next video column
    add di, 2         ; next pos[]
    inc si            ; next letter
    loop draw_loop
    pop si
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
    mov ax, 0700h ; Space with light gray attribute
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

delay:
    push cx
    mov cx, DELAY_OUTER
d_outer:
    push cx
    mov cx, DELAY_INNER
d_inner:
    dec cx
    jnz d_inner
    pop cx
    dec cx
    jnz d_outer
    pop cx
    ret

; Data
letters db 'h','e','l','l','o','o'
pos dw 6 dup(0)