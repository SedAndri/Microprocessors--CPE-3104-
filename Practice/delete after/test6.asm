; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

jmp start

prompt      db 'Enter Celsius (integer): $'
err_msg     db 13,10,'Invalid input. Try again.',13,10,'$'
res_label   db 13,10,'Fahrenheit: $'
done_msg    db 13,10,13,10,'Press any key to exit...$'

; DOS 0Ah input buffer
InMax       db 16           ; maximum chars
InLen       db 0            ; actual chars typed (no CR)
InData      db 16 dup(0)    ; input chars

start:
    ; DS = CS for .COM
    push cs
    pop  ds

get_input:
    ; prompt
    mov dx, offset prompt
    mov ah, 09h
    int 21h

    ; read line (0Ah)
    mov dx, offset InMax
    mov ah, 0Ah
    int 21h

    ; parse signed integer into AX
    call parse_int
    jc   bad_input

    ; AX = Celsius
    ; Fahrenheit = C*9/5 + 32 (signed)
    cwd                 ; sign-extend C into DX
    mov bx, 9
    imul bx             ; DX:AX = C*9
    mov bx, 5
    idiv bx             ; AX = (C*9)/5
    add ax, 32          ; AX = Fahrenheit

    ; print label + result
    push ax
    mov dx, offset res_label
    mov ah, 09h
    int 21h
    pop  ax
    call print_int

    ; finish message
    mov dx, offset done_msg
    mov ah, 09h
    int 21h

    ; wait for key and exit
    mov ah, 08h
    int 21h
    mov ax, 4C00h
    int 21h

bad_input:
    mov dx, offset err_msg
    mov ah, 09h
    int 21h
    jmp get_input

parse_int:
    push bx
    push cx
    push dx
    push si
    push di

    lea si, InData
    xor cx, cx
    mov cl, [InLen]
    jcxz pi_err              ; empty

; skip leading spaces
pi_skip_lead:
    cmp byte ptr [si], ' '
    jne pi_sign
    inc si
    loop pi_skip_lead
    jmp pi_err               ; all spaces

; optional sign
pi_sign:
    xor dl, dl               ; 0=+, 1=-
    jcxz pi_err
    cmp byte ptr [si], '+'
    jne pi_chk_minus
    inc si
    dec cx
    jmp pi_need_digit

pi_chk_minus:
    cmp byte ptr [si], '-'
    jne pi_need_digit
    mov dl, 1
    inc si
    dec cx

; first must be digit
pi_need_digit:
    jcxz pi_err
    mov bl, [si]
    cmp bl, '0'
    jb  pi_err
    cmp bl, '9'
    ja  pi_err

    xor ax, ax               ; result = 0

; read digits
pi_digits:
    jcxz pi_after_digits
    mov bl, [si]
    cmp bl, '0'
    jb  pi_after_digits
    cmp bl, '9'
    ja  pi_after_digits

    ; ax = ax*10 + (bl-'0')
    mov di, ax
    shl di, 1                ; *2
    shl di, 1                ; *4
    shl di, 1                ; *8
    shl ax, 1                ; *2
    add ax, di               ; *10
    sub bl, '0'
    xor bh, bh
    add ax, bx

    inc si
    dec cx
    jmp pi_digits

; allow trailing spaces only
pi_after_digits:
    jcxz pi_apply_sign
pi_trim_trail:
    cmp byte ptr [si], ' '
    jne pi_check_leftover
    inc si
    loop pi_trim_trail

pi_check_leftover:
    jcxz pi_apply_sign
    jmp pi_err               ; leftover junk

; apply sign
pi_apply_sign:
    test dl, dl
    jz   pi_ok
    neg  ax

pi_ok:
    clc
    jmp  pi_exit

pi_err:
    stc

pi_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

print_int:
    push bx
    push cx
    push dx

    ; sign handling
    cmp ax, 0
    jge p_abs

    ; handle -32768 specially
    cmp ax, 8000h
    jne p_neg_normal
    mov dl, '-'
    mov ah, 02h
    int 21h
    mov dl, '3'  ;
    int 21h
    mov dl, '2'
    int 21h
    mov dl, '7'
    int 21h
    mov dl, '6'
    int 21h
    mov dl, '8'
    int 21h
    jmp p_done

p_neg_normal:
    mov dl, '-'
    mov ah, 02h
    int 21h
    neg ax

p_abs:
    ; zero special-case
    cmp ax, 0
    jne p_conv
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp p_done

; push digits
p_conv:
    xor cx, cx
    mov bx, 10
p_div:
    xor dx, dx
    div bx                  
    push dx
    inc cx
    test ax, ax
    jnz p_div

; pop/print digits
p_out:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop p_out

p_done:
    pop dx
    pop cx
    pop bx
    ret