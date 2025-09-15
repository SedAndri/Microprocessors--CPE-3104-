;moving characters
org 100h
 
.code
    main proc 
           mov ax, 0b800h
           mov ds, ax  
           mov di, 1996    
           mov cx, 13
      
        DOWN: 
            
            mov dl, ' '
            mov [di -160], dx 
            mov [di - 158], dx
            mov [di - 156], dx
            mov [di - 154], dx
            mov dl, 'J'
            mov dh, 00001110B     
            mov ds:[di],dx
            mov dl, 'I'        
            mov ds:[di+2], dx      
            mov dl, 'C'   
            mov ds:[di+4], dx      
            mov dl, 'M'  
            mov ds:[di+6], dx 
            add di, 160     
         LOOP DOWN
         
           mov cx, 14  
           
         UP:
            mov dl, ' '
            mov [di +160], dx 
            mov [di +162], dx
            mov [di +164], dx
            mov [di +166], dx
            mov dl, 'J'
            mov dh, 00001110B     
            mov ds:[di],dx
            mov dl, 'I'        
            mov ds:[di+2], dx        
            mov dl, 'C'   
            mov ds:[di+4], dx      
            mov dl, 'M'  
            mov ds:[di+6], dx 
            
            sub di, 160
         LOOP UP
    end main
ret



