org 100h

mov ax, 0B800h     
mov es, ax

; Fill entire screen with blue background
mov di, 0          ; Start from top of screen
mov cx, 2000       ; 80x25 characters = 2000 positions
mov ax, 0120h      ; Space character (20h) with blue background (10h)

fill_screen:
    mov es:[di], ax
    add di, 2
    loop fill_screen

; Now write our text
mov di, 1920       ; center of screen: row 12, column 32 = (12*80 + 32)*2
mov si, offset msg 

next_char:
    mov al, [si]
    cmp al, 0
    je done
    mov es:[di], al
    mov es:[di+1], 1Eh  ; yellow text (0Eh) on blue background (1h)
    add di, 2
    inc si
    jmp next_char

done:
    ret

msg db '                                    Sid Bordario', 0
