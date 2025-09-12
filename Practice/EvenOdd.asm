; Bordario, Sid Andre P.

org 100h

.code
    mov ax, 0B800h        
    mov es, ax

    mov di, 0             

    mov al, [VALUE]       
    mov ah, 0             
    mov bl, 2             
    div bl                

    mov si, offset num_msg
    mov al, [VALUE]       
    add al, 30h           
    mov [si+14], al       

    call print_msg        

    add di, 130 ;spacing          

    cmp ah, 0
    je show_even

    mov si, offset odd_msg
    call print_msg
    jmp end_label

show_even:
    mov si, offset even_msg
    call print_msg

end_label:
    ret

print_msg:                
    mov cx, 0
.next_char:
    mov al, [si]
    cmp al, '$'
    je .done
    mov es:[di], al       
    mov al, 0x07          
    mov es:[di+1], al
    add di, 2
    inc si
    jmp .next_char
.done:
    ret
;==============================================================
VALUE db 9  
;==============================================================                    
num_msg db "The number is X$"
even_msg db "The value is an even number!$"
odd_msg  db "The value is an odd number!$"