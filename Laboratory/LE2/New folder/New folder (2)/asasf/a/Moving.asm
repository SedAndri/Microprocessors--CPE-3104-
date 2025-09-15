;moving characters
org 100h
 
.code
    main proc 
           mov ax, 0b800h
           mov ds, ax  
           mov di, 0    
           mov cx, 77
        MOVE: 
            mov [di-2], ' '
            mov dl, 'J'
            mov dh, 00001110B     
            mov [di],dx
            mov dl, 'I'
            mov [di+2],dx       
            mov dl, 'C'
            mov [di+4], dx      
            mov dl, 'M'  
            mov [di+6], dx 
            add di, 2     
        LOOP MOVE
    end main
ret




