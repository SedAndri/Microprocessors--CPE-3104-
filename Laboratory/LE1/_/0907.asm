
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

    
    
    
    

    MOV AX, 0B800h
    MOV ES, AX 
    
    MOV DH, 0011_0111d
    MOV AX, 0000h
    
    
    LEA SI, TEXT1
    CALL PRINT_TEXT
    MOV AX, [SI - 01h]
    
    
    ADD DI, 062h
   
    
    LEA SI, TEXT2
    CALL PRINT_TEXT

    
    
    PRINT_TEXT:
        
        CMP [SI], 0
        JZ EXIT
            
        MOVSB
        INC DI
        
        

    LOOP PRINT_TEXT
    
        
        
    
    
     
     
     
     
     
     
     
    CONVERT_TO_DECIMAL:
    
    
    
    EXIT: 
    
    
    
    
    
    

    

ret


TEXT1 DB 'Inputted deg. Celsius is (C): 5', 0 
TEXT2 DB 'Therefore, deg. Fahrenheit (F): ', 0


