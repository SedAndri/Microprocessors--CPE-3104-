org 100h

ATTR       equ 0x0F        ; bright white on black
TOP_ROW    equ 0
MID_ROW    equ 12
BOTTOM_ROW equ 24

COL_L      equ 38
COL_M      equ 39
COL_R      equ 40

letterL db '?'
letterM db '?'
letterR db '?'

curRow db 0     ; for scrolling
rL     db 0     ; left letter row
cL     db 0     ; left letter col
rR     db 0     ; right letter row
cR     db 0     ; right letter col

prompt db 'Enter 3 letters: $'

start:
    push cs
    pop  ds

    ; prompt and read exactly 3 chars
    lea  dx, prompt          ; or: mov dx, offset prompt
    mov  ah, 09h
    int  21h

    mov  ah, 01h             ; read left
    int  21h
    mov  [letterL], al

    mov  ah, 01h             ; read middle
    int  21h
    mov  [letterM], al

    mov  ah, 01h             ; read right
    int  21h
    mov  [letterR], al

    ; 1) clear screen
    call ClearScreen
    call HideCursor

    ; 2) bottom row, centered
    mov  al, [letterL]
    mov  dh, BOTTOM_ROW
    mov  dl, COL_L
    call PutCharAt

    mov  al, [letterM]
    mov  dh, BOTTOM_ROW
    mov  dl, COL_M
    call PutCharAt

    mov  al, [letterR]
    mov  dh, BOTTOM_ROW
    mov  dl, COL_R
    call PutCharAt

    ; 3) scroll up to middle (no traces)
    mov  byte [curRow], BOTTOM_ROW
scroll_up_loop:
    mov  al, [curRow]
    cmp  al, MID_ROW
    je   scroll_up_done

    call Delay

    ; erase at current row
    mov  dh, [curRow]
    mov  dl, COL_L
    call PutSpaceAt
    mov  dh, [curRow]
    mov  dl, COL_M
    call PutSpaceAt
    mov  dh, [curRow]
    mov  dl, COL_R
    call PutSpaceAt

    dec  byte [curRow]

    ; draw at new row
    mov  al, [letterL]
    mov  dh, [curRow]
    mov  dl, COL_L
    call PutCharAt

    mov  al, [letterM]
    mov  dh, [curRow]
    mov  dl, COL_M
    call PutCharAt

    mov  al, [letterR]
    mov  dh, [curRow]
    mov  dl, COL_R
    call PutCharAt

    jmp  scroll_up_loop

scroll_up_done:
    ; ensure mid row drawn
    mov  al, [letterL]
    mov  dh, MID_ROW
    mov  dl, COL_L
    call PutCharAt
    mov  al, [letterM]
    mov  dh, MID_ROW
    mov  dl, COL_M
    call PutCharAt
    mov  al, [letterR]
    mov  dh, MID_ROW
    mov  dl, COL_R
    call PutCharAt

    ; 4) freeze middle; L up-left, R down-right to edges
    mov  byte [rL], MID_ROW
    mov  byte [cL], COL_L
    mov  byte [rR], MID_ROW
    mov  byte [cR], COL_R

    mov  cx, MID_ROW          ; 12 diagonal steps
diag_out_loop:
    jcxz diag_out_done

    call Delay

    ; erase previous L and R
    mov  dh, [rL]
    mov  dl, [cL]
    call PutSpaceAt
    mov  dh, [rR]
    mov  dl, [cR]
    call PutSpaceAt

    ; update positions
    dec  byte [rL]
    dec  byte [cL]
    inc  byte [rR]
    inc  byte [cR]

    ; draw L, frozen M, R
    mov  al, [letterL]
    mov  dh, [rL]
    mov  dl, [cL]
    call PutCharAt

    mov  al, [letterM]
    mov  dh, MID_ROW
    mov  dl, COL_M
    call PutCharAt

    mov  al, [letterR]
    mov  dh, [rR]
    mov  dl, [cR]
    call PutCharAt

    loop diag_out_loop

diag_out_done:
    ; 5) move along edges to opposite ends
    mov  cx, 24
vert_swap_loop:
    jcxz vert_swap_done

    call Delay

    ; erase previous L and R
    mov  dh, [rL]
    mov  dl, [cL]
    call PutSpaceAt
    mov  dh, [rR]
    mov  dl, [cR]
    call PutSpaceAt

    ; rL falls (down) until bottom, rR rises (up) until top
    cmp  byte [rL], BOTTOM_ROW
    je   no_inc_L
    inc  byte [rL]
no_inc_L:
    cmp  byte [rR], TOP_ROW
    je   no_dec_R
    dec  byte [rR]
no_dec_R:

    ; draw L, frozen M, R
    mov  al, [letterL]
    mov  dh, [rL]
    mov  dl, [cL]
    call PutCharAt

    mov  al, [letterM]
    mov  dh, MID_ROW
    mov  dl, COL_M
    call PutCharAt

    mov  al, [letterR]
    mov  dh, [rR]
    mov  dl, [cR]
    call PutCharAt

    loop vert_swap_loop

vert_swap_done:
    ; 6) diagonally return to center
    mov  cx, MID_ROW
diag_back_loop:
    jcxz finish

    call Delay

    ; erase previous L and R
    mov  dh, [rL]
    mov  dl, [cL]
    call PutSpaceAt
    mov  dh, [rR]
    mov  dl, [cR]
    call PutSpaceAt

    ; L up-right, R down-left
    dec  byte [rL]
    inc  byte [cL]
    inc  byte [rR]
    dec  byte [cR]

    ; draw L, M, R
    mov  al, [letterL]
    mov  dh, [rL]
    mov  dl, [cL]
    call PutCharAt

    mov  al, [letterM]
    mov  dh, MID_ROW
    mov  dl, COL_M
    call PutCharAt

    mov  al, [letterR]
    mov  dh, [rR]
    mov  dl, [cR]
    call PutCharAt

    loop diag_back_loop

finish:
    ; wait for key, show cursor, exit
    mov  ah, 00h
    int  16h

    call ShowCursor

    mov  ax, 4C00h
    int  21h

; ------------ helpers ------------

ClearScreen:
    mov  ax, 0600h
    mov  bh, 07h
    mov  cx, 0000h
    mov  dx, 184Fh
    int  10h
    ret

HideCursor:
    mov  ah, 01h
    mov  ch, 20h
    mov  cl, 00h
    int  10h
    ret

ShowCursor:
    mov  ah, 01h
    mov  ch, 06h
    mov  cl, 07h
    int  10h
    ret

; AL=char, DH=row, DL=col
PutCharAt:
    push ax
    push bx
    push cx
    push dx
    mov  ah, 02h
    mov  bh, 0
    int  10h
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    push ax
    push bx
    push cx
    push dx
    mov  ah, 09h
    mov  bh, 0
    mov  bl, ATTR
    mov  cx, 1
    int  10h
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; DH=row, DL=col
PutSpaceAt:
    push ax
    mov  al, ' '
    call PutCharAt
    pop  ax
    ret

Delay:
    push cx
    mov  cx, 2500           ; tune to taste
.delay_lp:
    loop .delay_lp
    pop  cx
    ret