DATA SEGMENT

           PORTA EQU 0F0H
           PORTB EQU 0F2H
           PORTC EQU 0F4H
           COM_REG EQU 0F6H
           NUMB0 EQU 00111111B
           NUMB1 EQU 00000110B
           NUMB2 EQU 01011011B
           NUMB3 EQU 01001111B
           NUMB4 EQU 01100110B
           NUMB5 EQU 01101101B
           NUMB6 EQU 01111101B
           NUMB7 EQU 00000111B
           NUMB8 EQU 01111111B
           NUMB9 EQU 01101111B
           
DATA ENDS

CODE SEGMENT

           MOV AX, DATA
           MOV DS, AX
           ORG 0000H
           
START:
           MOV DX, COM_REG
           MOV AL, 89H
           OUT DX, AL
           
RESET:
           MOV DX, PORTA
           MOV AL, NUMB0
           OUT DX, AL
           
           MOV DX, PORTB
           MOV AL, NUMB0
           OUT DX, AL
           
           MOV CX, 0000H

HERE:
           MOV DX, PORTC
           IN AL, DX
           CMP AL, 01H
           JE LSDIG_A
           JMP HERE

LSDIG_A:
           CALL DELAY
           CALL DELAY
           CMP CX, 0909H
           JE RESET

           CMP CL, 09H
           JE MSDIG_B

           INC CL

           LSDIG_A1:
           CMP CL, 01H
           JNE LSDIG_A2
           MOV DX, PORTA
           MOV AL, NUMB1
           OUT DX, AL
           JMP HERE

           LSDIG_A2:
           CMP CL, 02H
           JNE LSDIG_A3
           MOV DX, PORTA
           MOV AL, NUMB2
           OUT DX, AL
           JMP HERE
         
           LSDIG_A3:
           CMP CL, 03H
           JNE LSDIG_A4
           MOV DX, PORTA
           MOV AL, NUMB3
           OUT DX, AL
           JMP HERE

           LSDIG_A4:
           CMP CL, 04H
           JNE LSDIG_A5
           MOV DX, PORTA
           MOV AL, NUMB4
           OUT DX, AL
           JMP HERE

           LSDIG_A5:
           CMP CL, 05H
           JNE LSDIG_A6
           MOV DX, PORTA
           MOV AL, NUMB5
           OUT DX, AL
           JMP HERE

           LSDIG_A6:
           CMP CL, 06H
           JNE LSDIG_A7
           MOV DX, PORTA
           MOV AL, NUMB6
           OUT DX, AL
           JMP HERE

           LSDIG_A7:
           CMP CL, 07H
           JNE LSDIG_A8
           MOV DX, PORTA
           MOV AL, NUMB7
           OUT DX, AL
           JMP HERE

           LSDIG_A8:
           CMP CL, 08H
           JNE LSDIG_A9
           MOV DX, PORTA
           MOV AL, NUMB8
           OUT DX, AL
           JMP HERE

           LSDIG_A9:
           CMP CL, 09H
           MOV DX, PORTA
           MOV AL, NUMB9
           OUT DX, AL
           JMP HERE

MSDIG_B:
           MOV CL, 00H
           MOV DX, PORTA
           MOV AL, NUMB0
           OUT DX, AL
           
           INC CH

           HLSDIG_A1:
           CMP CH, 01H
           JNE HLSDIG_A2
           MOV DX, PORTB
           MOV AL, NUMB1
           OUT DX, AL
           JMP HERE

           HLSDIG_A2:
           CMP CH, 02H
           JNE HLSDIG_A3
           MOV DX, PORTB
           MOV AL, NUMB2
           OUT DX, AL
           JMP HERE

           HLSDIG_A3:
           CMP CH, 03H
           JNE HLSDIG_A4
           MOV DX, PORTB
           MOV AL, NUMB3
           OUT DX, AL
           JMP HERE

           HLSDIG_A4:
           CMP CH, 04H
           JNE HLSDIG_A5
           MOV DX, PORTB
           MOV AL, NUMB4
           OUT DX, AL
           JMP HERE

           HLSDIG_A5:
           CMP CH, 05H
           JNE HLSDIG_A6
           MOV DX, PORTB
           MOV AL, NUMB5
           OUT DX, AL
           JMP HERE

           HLSDIG_A6:
           CMP CH, 06H
           JNE HLSDIG_A7
           MOV DX, PORTB
           MOV AL, NUMB6
           OUT DX, AL
           JMP HERE

           HLSDIG_A7:
           CMP CH, 07H
           JNE HLSDIG_A8
           MOV DX, PORTB
           MOV AL, NUMB7
           OUT DX, AL
           JMP HERE

           HLSDIG_A8:
           CMP CH, 08H
           JNE HLSDIG_A9
           MOV DX, PORTB
           MOV AL, NUMB8
           OUT DX, AL
           JMP HERE

           HLSDIG_A9:
           CMP CH, 09H
           MOV DX, PORTB
           MOV AL, NUMB9
           OUT DX, AL
           JMP HERE

DELAY PROC
          MOV BX, 1BE4H
           L1:
          DEC BX
          NOP
          JNZ L1
          RET
DELAY ENDP

CODE ENDS  
END