
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

    
    
    
    

    MOV AX, 0B800h
    MOV ES, AX 
    
    MOV DH, 0011_0111d
    MOV AX, 0000h
    
    
    LEA SI, TEXT1
    CALL PRINT_TEXT
    
    
    ADD DI, 07Ah
   
    
    LEA SI, TEXT2
    CALL PRINT_TEXT
    
    
    
    ADD DI, 084h
    
    LEA SI, TEXT3
    CALL PRINT_TEXT

    
    
    PRINT_TEXT:
        
        CMP [SI], 0
        JZ EXIT
            
        MOVSB
        INC DI
        
        

    LOOP PRINT_TEXT
    
    
    EXIT:
    
     
     
     
     
     
     
     
    CONVERT_TO_DECIMAL:
    
                    
                    
                    
                    
                    
    
    
    
    CONVERT_TO_HEX:
    
    
    
    
    
    
    
    
    
    
    

   RETURN_OS:

ret


TEXT1 DB 'Decimal value is: 8', 0 
TEXT2 DB 'In binary is: ', 0
TEXT3 DB 'In hexadecimal is: ', 0


