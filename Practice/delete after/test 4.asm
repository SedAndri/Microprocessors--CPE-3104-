org 100h
jmp start

; ----------------------------
; Data
; ----------------------------
prompt       db 13,10,'Enter text (max 40): $'

InMax        db 40           ; max chars to read
InLen        db 0            ; actual length read
InData       db 40 dup(0)    ; input buffer (no CR, no '$')

attr         db 1            ; starting color 1..15
col_start    db 0            ; computed centered column

; ----------------------------
; Code
; ----------------------------
start:
    ; DS = CS for .COM
    push cs
    pop  ds

    ; Clear screen
    mov ax, 0600h
    mov bh, 07h
    xor cx, cx
    mov dx, 184Fh
    int 10h

    ; Prompt
    mov dx, offset prompt
    mov ah, 09h
    int 21h

    ; Read buffered line: [InMax][InLen][InData...]
    mov dx, offset InMax
    mov ah, 0Ah
    int 21h

    ; If no input, exit
    mov al, [InLen]
    or  al, al
    jnz have_input
    jmp exit_prog

have_input:
    ; Compute centered starting column: (80 - len)/2
    mov cl, [InLen]        ; len in CL (0..40)
    mov al, 80
    sub al, cl
    shr al, 1              ; divide by 2
    mov [col_start], al

    ; ES = DS for INT 10h/AH=13h
    push ds
    pop  es

main_loop:
    ; BIOS write string, position is in DH/DL
    ; DH=row, DL=col, BL=attribute, CX=length, ES:BP=string
    mov dh, 12                 ; row = 12 (0-based)
    mov dl, [col_start]        ; computed centered col
    mov ax, 1301h              ; AH=13h write string, AL=01h update cursor
    mov bl, [attr]             ; color/attribute
    mov bh, 0                  ; page 0
    xor ch, ch
    mov cl, [InLen]            ; count
    lea bp, InData             ; ES:BP -> string bytes
    int 10h

    ; Exit if key pressed
    mov ah, 01h
    int 16h
    jz  no_key
    mov ah, 00h
    int 16h
    jmp exit_prog

no_key:
    ; Cycle color 1..15
    inc byte ptr [attr]
    cmp byte ptr [attr], 16
    jb  main_loop
    mov byte ptr [attr], 1
    jmp main_loop

; ----------------------------
; Exit
; ----------------------------
exit_prog:
    mov ax, 4C00h
    int 21h