org 100h

jmp start
;angsarapmopia copy
; ----------------------------
; Config/Constants
; ----------------------------
ATTR        db 1Ah              ; bright yellow on black
CENTER_COL  equ 40              ; center column (0..79)
COLS        equ 80
ROWS        equ 25
MAXLEN      equ 31              ; max allowed input length

; ----------------------------
; Prompts
; ----------------------------
PROMPT      db 'Enter text (1..31), then Enter:',0
ERRMSG      db 'Length must be between 1 and 31. Try again.',0

; ----------------------------
; DOS 0Ah input buffer (max, len, data...)
; ----------------------------
InBufMax    db MAXLEN
InBufLen    db 0
InBufData   db MAXLEN dup(0)

; ----------------------------
; String + meta
; ----------------------------
STR         db MAXLEN dup(0)
LEN         db 0
MID         db 0
LEFTLEN     db 0
RIGHTLEN    db 0

; ----------------------------
; Animation state
; ----------------------------
CURROW      db 0
STARTCOL    db 0
LCOL        db 0
RCOL        db 0
RTARGET     db 0

; ----------------------------
; Code
; ----------------------------
start:
    ; setup DS/ES
    push cs
    pop  ds
    mov  ax, 0B800h
    mov  es, ax

    ; clear screen (BIOS scroll up full)
    mov ax, 0600h
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184Fh
    int 10h

input_loop:
    ; print prompt at row 1, col 10
    mov al, 1
    mov dl, 10
    call SETDI
    lea si, PROMPT
    call PRINT_Z

    ; set cursor row 2, col 10 for DOS input echo
    mov ah, 02h
    mov bh, 0
    mov dh, 2
    mov dl, 10
    int 10h

    ; read line (buffered)
    mov dx, offset InBufMax
    mov ah, 0Ah
    int 21h

    ; AL = length
    mov al, [InBufLen]
    cmp al, 0
    je  bad_input

    ; copy to STR safely (ES=DS), and ensure CX uses 8-bit length
    mov [LEN], al
    mov cl, al
    xor ch, ch
    lea si, InBufData
    lea di, STR
    push es
    push ds
    pop  es
    rep movsb
    pop  es
    ; zero-terminate STR[LEN] to avoid reading past end
    xor bh, bh
    mov bl, [LEN]
    mov byte [STR+bx], 0

    ; compute MID = floor(LEN/2)
    mov al, [LEN]
    mov ah, 0
    shr al, 1
    mov [MID], al

    ; compute LEFTLEN/RIGHTLEN with left priority when odd
    ; RIGHTLEN = MID; LEFTLEN = MID (+1 if LEN is odd)
    mov al, [MID]
    mov [RIGHTLEN], al
    mov al, [LEN]
    test al, 1
    jz  @even_len
    mov al, [MID]
    inc al
    mov [LEFTLEN], al
    jmp @lens_done
@even_len:
    mov al, [MID]
    mov [LEFTLEN], al
@lens_done:

    ; STARTCOL = CENTER_COL - MID
    mov al, CENTER_COL
    sub al, [MID]
    mov [STARTCOL], al

    ; RTARGET = 80 - RIGHTLEN   (right part start col so last char ends at col 79)
    mov al, COLS
    sub al, [RIGHTLEN]
    mov [RTARGET], al

    ; replace slow per-line erase with instant full-screen clear
    call CLEAR_SCREEN

    ; clear CX so debugger doesn't show stale value (e.g., 0x50)
    xor cx, cx

    jmp animate

bad_input:
    ; show error at row 3, col 10
    mov al, 3
    mov dl, 10
    call SETDI
    lea si, ERRMSG
    call PRINT_Z
    jmp input_loop

animate:
    ; ----------------------------
    ; Stage 1: move full string down from top (row 0) to bottom (row 24)
    ; ----------------------------
    mov [CURROW], 0
    ; draw first position
    mov al, [CURROW]
    call DRAW_FULL_AT_ROW

move_down_full:
    cmp [CURROW], 24
    je  at_bottom
    ; move down one row
    inc [CURROW]
    ; clear entire screen then draw new row
    call CLEAR_SCREEN
    mov al, [CURROW]
    call DRAW_FULL_AT_ROW
    jmp move_down_full

at_bottom:
    ; ----------------------------
    ; Stage 2: split into left/mid/right and move outward to edges on bottom row
    ; ----------------------------
    ; clear screen then draw initial split
    call CLEAR_SCREEN

    ; initialize left/right start columns
    mov al, [STARTCOL]
    mov [LCOL], al
    ; RCOL starts at CENTER_COL (+1 if LEN is odd)
    mov al, CENTER_COL
    mov bl, [LEN]
    test bl, 1
    jz  @rc_even
    inc al
@rc_even:
    mov [RCOL], al

    ; draw initial split at row 24
    mov al, 24
    call DRAW_SPLIT_AT_ROW

move_outward:
    ; move L and R one step (if not at targets)
    mov al, [LCOL]
    cmp al, 0
    je  skip_left_out
    dec [LCOL]
skip_left_out:
    mov al, [RCOL]
    cmp al, [RTARGET]
    jae after_out_step
    inc [RCOL]
after_out_step:
    ; redraw frame on cleared screen
    call CLEAR_SCREEN
    mov al, 24
    call DRAW_SPLIT_AT_ROW
    ; loop while either still moving
    mov al, [LCOL]
    cmp al, 0
    jne move_outward
    mov al, [RCOL]
    cmp al, [RTARGET]
    jb  move_outward

    ; ----------------------------
    ; Stage 3: move both parts up to top row
    ; ----------------------------
    mov [CURROW], 24

move_up_three:
    cmp [CURROW], 0
    je  at_top_three
    ; previous row
    dec [CURROW]
    ; redraw frame on cleared screen
    call CLEAR_SCREEN
    mov al, [CURROW]
    call DRAW_SPLIT_AT_ROW
    jmp move_up_three

at_top_three:
    ; ----------------------------
    ; Stage 4: merge at top by moving left->right and right->left
    ; target LCOL = STARTCOL, RCOL = CENTER_COL (+1 if LEN is odd)
    ; ----------------------------
merge_horiz:
    ; move left part right if needed
    mov al, [LCOL]
    cmp al, [STARTCOL]
    jae  skip_left_merge
    inc [LCOL]
skip_left_merge:
    ; move right part left if needed
    mov al, [RCOL]
    mov bl, CENTER_COL
    mov bh, [LEN]
    test bh, 1
    jz  @mrg_r_even
    inc bl
@mrg_r_even:
    cmp al, bl
    jbe after_merge_step
    dec [RCOL]
after_merge_step:
    ; redraw frame on cleared screen at row 0
    call CLEAR_SCREEN
    mov al, 0
    call DRAW_SPLIT_AT_ROW
    ; loop until LCOL==STARTCOL and RCOL==CENTER_COL(+1 if odd)
    mov al, [LCOL]
    cmp al, [STARTCOL]
    jne merge_horiz
    mov al, [RCOL]
    mov bl, CENTER_COL
    mov bh, [LEN]
    test bh, 1
    jz  @mrg_chk_even
    inc bl
@mrg_chk_even:
    cmp al, bl
    jne merge_horiz

    ; ----------------------------
    ; Stage 5: move merged full string down to middle row (row 12)
    ; ----------------------------
    ; clear screen then draw full string at top
    call CLEAR_SCREEN
    mov al, 0
    call DRAW_FULL_AT_ROW
    mov [CURROW], 0

move_down_to_center:
    cmp [CURROW], 12
    je  done
    ; move down
    inc [CURROW]
    ; redraw frame on cleared screen
    call CLEAR_SCREEN
    mov al, [CURROW]
    call DRAW_FULL_AT_ROW
    jmp move_down_to_center

done:
    mov ax, 4C00h
    int 21h

; ----------------------------
; Helpers
; ----------------------------
; SETDI: AL=row, DL=col -> DI = ((row*80)+col)*2
SETDI:
    push ax
    push bx
    push dx
    xor ah, ah
    mov bl, 80
    mul bl           ; AX = row*80
    xor dh, dh
    add ax, dx       ; AX += col
    shl ax, 1
    mov di, ax
    pop dx
    pop bx
    pop ax
    ret

; PRINT_Z: ES:DI set by SETDI, DS:SI -> zero-terminated
PRINT_Z:
    push ax
pz_lp:
    lodsb
    cmp al, 0
    je  pz_dn
    mov es:[di], al
    mov al, [ATTR]
    mov es:[di+1], al
    add di, 2
    jmp pz_lp
pz_dn:
    pop ax
    ret

; DRAW_SEG: draw CX chars from DS:SI at row AL, start col DL
DRAW_SEG:
    push ax
    push bx
    push cx
    push dx
    push si
    xor ch, ch
    call SETDI
    cmp cx, 0
    je  ds_done
    ; optimize: use AH=ATTR and STOSW for each char
    mov ah, [ATTR]
    cld
ds_loop:
    lodsb              ; AL = next char
    stosw              ; write AX (char+attr), DI+=2
    loop ds_loop
ds_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; DRAW_FULL_AT_ROW: draw whole STR (LEN) centered at row AL
; Uses: STARTCOL, STR, LEN
DRAW_FULL_AT_ROW:
    push bx
    push cx
    push dx
    push si
    mov dl, [STARTCOL]
    lea si, STR
    mov cl, [LEN]
    call DRAW_SEG
    pop si
    pop dx
    pop cx
    pop bx
    ret

; DRAW_SPLIT_AT_ROW: draw left/right pieces at row AL
; Uses: LCOL, RCOL, STR, LEFTLEN, RIGHTLEN
DRAW_SPLIT_AT_ROW:
    push bx
    push cx
    push dx
    push si
    ; left part
    mov dl, [LCOL]
    lea si, STR
    mov cl, [LEFTLEN]
    call DRAW_SEG
    ; right part
    mov dl, [RCOL]
    lea si, STR
    mov bl, [LEFTLEN]
    xor bh, bh
    add si, bx
    mov cl, [RIGHTLEN]
    call DRAW_SEG
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Clear entire screen (80x25), fill with attribute 07h
CLEAR_SCREEN:
    push ax
    push bx
    push cx
    push dx
    mov ax, 0600h       ; scroll up 0 lines = clear
    mov bh, 07h         ; blank attribute
    mov cx, 0000h       ; upper-left (row 0, col 0)
    mov dx, 184Fh       ; lower-right (row 24, col 79)
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
