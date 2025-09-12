
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h



    MOV BX, 0B800h
    MOV DS, BX
    
    
    
    
    MOV DH, 0011_0111d
    MOV DL, 'B'
    MOV BX, 0000h;
    
    MOV AX, 22
    
    
    ; TEMP TO GET TO THE BOTTOM
    ADD BX, 0B86h
    ADD BX, 50h
    ADD BX, 50h
    ADD BX, 50h
    ADD BX, 56h
    ADD BX, 50h
    ADD BX, 50h
    
    


    
        ; LOOP
        
        DISPLAY_LETTER:
        
            

            MOV DH, 0011_0111d
            ; MOV DL,var1
            MOV DL, 'B'
            MOV [BX], DX
    

            ADD BX, 0A0h
    
            MOV DH, 0011_0111d
            ; MOV DL, var2
            MOV DL, 'B'
            MOV [BX], DX
               
            ADD BX, 0A0h           
               
            MOV DH, 0011_0111d
            ; MOV DL, var3
            MOV DL, 'M'
            MOV [BX], DX
            
            
            MOV DL, ' '
            SUB BX, 1E0h
            MOV [BX], DX
        
            DEC AX
            JZ EXIT
 
    
        LOOP DISPLAY_LETTER
    
        EXIT:
        

ret

 
 
 
var1 DB 'B', 0
var2 DB 'B', 0
var3 DB 'M', 0
 


