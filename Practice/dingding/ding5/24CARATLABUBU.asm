DATA SEGMENT
        PORTA EQU 0F0H
        PORTB EQU 0F2H
        PORTC EQU 0F4H
DATA ENDS

CODE SEGMENT 
        MOV AX, DATA    
        MOV DS, AX       
        ORG 0000H       

START:
        MOV DX, PORTA     
        MOV AL, 00000000B
        OUT DX, AL      

        MOV DX, PORTB     
        MOV AL, 00000000B 
        OUT DX, AL

HERE:
        MOV DX, PORTC     
        IN AL, DX

        CMP AL, 01H   
        JE ON_LED        

        CMP AL, 02H     
        JE ON_SEG         

        NOP
        JMP HERE

ON_LED:
        MOV CX, 08H      
        MOV DX, PORTA     
        MOV AL, 10000000B
        OUT DX, AL       

        CALL DELAY     

DISPLAY:
        SHR AL, 1H
        MOV DX, PORTA     
        OUT DX, AL
        CALL DELAY      
        LOOP DISPLAY

        JMP HERE        

ON_SEG:
        MOV DX, PORTB

        MOV AL, 00111111B
        OUT DX, AL      
        CALL DELAY

        MOV DX, PORTB
        MOV AL, 00000110B
        OUT DX, AL
        CALL DELAY

        MOV DX, PORTB
        MOV AL, 01011011B 
        OUT DX, AL
        CALL DELAY

        MOV DX, PORTB
        MOV AL, 01001111B 
        OUT DX, AL
        CALL DELAY

        MOV DX, PORTB
        MOV AL, 01100110B
        OUT DX, AL
        CALL DELAY

        MOV DX, PORTB
        MOV AL, 01101101B
        OUT DX, AL
        CALL DELAY

        MOV DX, PORTB
        MOV AL, 01111101B
        OUT DX, AL
        CALL DELAY

        MOV DX, PORTB
        MOV AL, 00000111B 
        OUT DX, AL
        CALL DELAY

        MOV DX, PORTB
        MOV AL, 01111111B
        OUT DX, AL
        CALL DELAY

        MOV DX, PORTB
        MOV AL, 01101111B 
        OUT DX, AL
        CALL DELAY

        MOV DX, PORTB
        MOV AL, 00000000B
        OUT DX, AL

        JMP HERE          

DELAY PROC
        MOV BX, 9FFFH    
   L1:     
     DEC BX          
        NOP               
        JNZ L1            
        RET           
DELAY ENDP

CODE ENDS
END