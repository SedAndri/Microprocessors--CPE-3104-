DATA SEGMENT
        PORTA EQU 0F0H    ; Define PORTA address (used for LED control)
        PORTB EQU 0F2H    ; Define PORTB address (used for 7-segment display)
        PORTC EQU 0F4H    ; Define PORTC address (used for input detection)
DATA ENDS

CODE SEGMENT 
        MOV AX, DATA    
        MOV DS, AX       
        ORG 0000H       

START:
        ; Initialize PORTA (LED control port) to 0
        MOV DX, PORTA     
        MOV AL, 00000000B ; Clear all LEDs initially
        OUT DX, AL      

        ; Initialize PORTB (7-segment display control port) to 0
        MOV DX, PORTB     
        MOV AL, 00000000B 
        OUT DX, AL

HERE:
        MOV DX, PORTC     
        IN AL, DX         ; Read input from PORTC

	 ; If equal, jump to LED control
        CMP AL, 01H   
        JE ON_LED        

	 ; If equal, jump to 7-segment display control
        CMP AL, 02H     
        JE ON_SEG         

        NOP               ; Do nothing if no input match
        JMP HERE          ; Repeat the loop

ON_LED:
        ; LED control sequence (shifts a single lit LED across PORTA)
        MOV CX, 08H      
        MOV DX, PORTA     
        MOV AL, 10000000B ; Start with the leftmost LED turned on
        OUT DX, AL       

        CALL DELAY     

DISPLAY:
        ; Shift LED to the right by one bit
        SHR AL, 1H        ; Shift right one position
        MOV DX, PORTA     
        OUT DX, AL
        CALL DELAY      
        LOOP DISPLAY      ; Repeat until all LEDs have shifted

        JMP HERE        

ON_SEG:
        ; 7-segment display control sequence (cycles through digits 0 to 9)
        MOV DX, PORTB     ; Set up PORTB for display control

        ; Display 0
        MOV AL, 00111111B
        OUT DX, AL      
        CALL DELAY

        ; Display 1
        MOV DX, PORTB
        MOV AL, 00000110B
        OUT DX, AL
        CALL DELAY

        ; Display 2
        MOV DX, PORTB
        MOV AL, 01011011B 
        OUT DX, AL
        CALL DELAY

        ; Display 3
        MOV DX, PORTB
        MOV AL, 01001111B 
        OUT DX, AL
        CALL DELAY

        ; Display 4
        MOV DX, PORTB
        MOV AL, 01100110B
        OUT DX, AL
        CALL DELAY

        ; Display 5
        MOV DX, PORTB
        MOV AL, 01101101B
        OUT DX, AL
        CALL DELAY

        ; Display 6
        MOV DX, PORTB
        MOV AL, 01111101B
        OUT DX, AL
        CALL DELAY

        ; Display 7
        MOV DX, PORTB
        MOV AL, 00000111B 
        OUT DX, AL
        CALL DELAY

        ; Display 8
        MOV DX, PORTB
        MOV AL, 01111111B
        OUT DX, AL
        CALL DELAY

        ; Display 9
        MOV DX, PORTB
        MOV AL, 01101111B 
        OUT DX, AL
        CALL DELAY

        ; Clear the 7-segment display
        MOV DX, PORTB
        MOV AL, 00000000B ; Turn off all segments
        OUT DX, AL

        JMP HERE          

; Delay subroutine
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