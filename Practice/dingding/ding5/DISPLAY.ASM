mov dx, 0f2h
    mov al, 00111111b
    out dx, al
    call delay_1ms
    
    mov dx, 0f2h          ; 1
    mov al, 00000110b
    out dx, al
    call delay_1ms
    
    mov dx, 0f2h          ; 2
    mov al, 01011011b
    out dx, al
    call delay_1ms  
    
    mov dx, 0f2h          ; 3
    mov al, 01001111b
    out dx, al
    call delay_1ms
                    
    mov dx, 0f2h          ; 4
    mov al, 01100110b
    out dx, al
    call delay_1ms
                    
    mov dx, 0f2h          ; 5
    mov al, 01101101b
    out dx, al
    call delay_1ms
                   
    mov dx, 0f2h          ; 6
    mov al, 01111101b
    out dx, al
    call delay_1ms           
    
    mov dx, 0f2h          ; 7
    mov al, 00000111b
    out dx, al
    call delay_1ms  
    
    mov dx, 0f2h          ; 8
    mov al, 01111111b
    out dx, al
    call delay_1ms  
    
    mov dx, 0f2h          ; 9
    mov al, 01101111b
    out dx, al
    call delay_1ms  
    
    jmp START

; 1 ms delay (given)
delay_1ms:
   mov bx, 02cah
l1:
   dec bx
   nop
   jnz l1
   ret
   