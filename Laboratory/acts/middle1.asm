org 100h

mov ax, 0B800h     
mov es, ax

mov di, 1920       ; center of screen: row 12, column 32 ? (12*80 + 32)*2
                   

mov si, offset msg 

next_char:
    mov al, [si]
    cmp al, 0
    je done
    mov es:[di], al
    mov es:[di+1], 1Eh  
    add di, 2
    inc si
    jmp next_char

done:
    ret              

msg db '                                 Sid Bordario', 0
