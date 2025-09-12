ORG 100H
    START:  MOV AX, 0B800H
            MOV DS, AX
            MOV DI, 74
            MOV SI, 74
            MOV BL, 25

    DISPLAY_LOOP:   CALL DISPLAY_NAME
                    CALL DELAY
                    CALL CLEAR_NAME
                    
                    SUB SI, 10
                    ADD SI, 160
                    MOV DI, SI
                    DEC BL
                    CMP BL, 0
                        JNE DISPLAY_LOOP
         
RET

DISPLAY_NAME:   MOV AH, 0B1H
                MOV AL, 43H
                MOV [DI], AX
                
                ADD DI, 2
                MOV AL, 59H
                MOV [DI], AX 
                
                ADD DI, 2
                MOV AL, 52H
                MOV [DI], AX 
                
                ADD DI, 2
                MOV AL, 49H
                MOV [DI], AX 
                
                ADD DI, 2
                MOV AL, 4CH
                MOV [DI], AX 
    
RET

DELAY:  MOV CX, 1FH
    HERE:   LOOP HERE
RET

CLEAR_NAME: MOV CX, 5
    DELETE: MOV AX, 0
            MOV [SI], AX
            ADD SI, 2
            LOOP DELETE
RET
