;***************************************************************************;
; An assembly language program that displays running string "BCM" diagonally                       ;
;***************************************************************************;  


org 100h

    mov ax, 0b800h
    mov ds, ax
    mov di, (0*160)+(0*2)  
    
    call disp  
    call delay 
    mov si, (0*160)+(0*2) 
    call clear
     
    add di, 162 
    call disp
    call delay
    mov si,(1*160)+(3*2)
    call clear    
    
    add di, 162 
    call disp
    call delay  
    mov si,(2*160)+(6*2)
    call clear 
    
    add di, 162 
    call disp
    call delay  
    mov si,(3*160)+(9*2)
    call clear
    
    add di, 162 
    call disp
    call delay 
    mov si,(4*160)+(12*2)
    call clear
    
    add di, 162 
    call disp
    call delay
    mov si,(5*160)+(15*2)
    call clear  
    
    add di, 162 
    call disp
    call delay    
    mov si,(6*160)+(18*2)
    call clear
    
    add di, 162 
    call disp
    call delay    
    mov si,(7*160)+(21*2)
    call clear
    
    add di, 162 
    call disp
    call delay 
    mov si,(8*160)+(24*2)
    call clear
    
    add di, 162 
    call disp
    call delay
    mov si,(9*160)+(27*2)
    call clear
    
    add di, 162 
    call disp
    call delay
    mov si,(10*160)+(30*2)
    call clear
    
    add di, 162 
    call disp
    call delay
    mov si,(11*160)+(33*2)
    call clear
    
    add di, 162 
    call disp
    call delay 
    mov si,(12*160)+(36*2)
    call clear
    
    add di, 162 
    call disp
    call delay  
    mov si,(13*160)+(39*2)
    call clear
    
    add di, 162 
    call disp
    call delay 
    mov si,(14*160)+(42*2)
    call clear
    
    add di, 162 
    call disp
    call delay   
    mov si,(15*160)+(45*2)
    call clear 
    
    add di, 162 
    call disp
    call delay 
    mov si,(16*160)+(48*2)
    call clear
    
    add di, 162 
    call disp
    call delay 
    mov si,(17*160)+(51*2)
    call clear
    
    add di, 162 
    call disp
    call delay
    mov si,(18*160)+(54*2)
    call clear
    
    add di, 162 
    call disp
    call delay 
    mov si,(19*160)+(57*2)
    call clear
    
    add di, 162 
    call disp
    call delay
    mov si,(20*160)+(60*2)
    call clear
    
    add di, 162 
    call disp
    call delay  
    mov si,(21*160)+(63*2)
    call clear
    
    add di, 162 
    call disp
    call delay    
    mov si,(22*160)+(66*2)
    call clear
    
    add di, 162 
    call disp
    call delay 
    mov si,(23*160)+(69*2)
    call clear
    
    add di, 162 
    call disp
    call delay 
    mov si,(24*160)+(72*2)
    call clear 
    
    add di, 162 
    call disp
    call delay  
    mov si,(25*160)+(75*2)
    call clear 
    
ret


disp:
    mov ah, 0ach
    mov al, 42h
    mov ds:[di], ax  
    add di, 2
    mov al, 43h  
    mov ds:[di], ax     
    add di, 2
    mov al, 4dh
    mov ds:[di], ax
    ret


delay:
    mov cx, 1fh
    here: 
        loop here
    ret    
        
        
clear: 
        mov cx, 3
    del_char:
        xor ax, ax
        mov [si], ax   
        add si, 2
        loop del_char
        ret






































































































