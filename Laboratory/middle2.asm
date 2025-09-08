org 100h

mov ax, 0B800h     
mov es, ax

mov si, offset msg

mov cx, 0
calc_len:
    mov bx, si
    add bx, cx
    mov al, [bx]
    cmp al, 0
    je len_done
    inc cx
    jmp calc_len
len_done:

mov bx, 80
sub bx, cx
shr bx, 1           


mov dx, 12          
mov ax, dx
mov dx, 80
mul dx              
add ax, bx          
shl ax, 1           
mov di, ax

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

msg db 'Sid Bordario', 0