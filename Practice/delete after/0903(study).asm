ORG 100H

START:  
MOV AX, 0B800H
MOV DS, AX
MOV DI, 0
MOV SI, 0
MOV BL, 25

DISPLAY_LOOP:   
        CALL DISPLAY_NAME
        CALL DELAY
        CALL CLEAR_NAME
                 
        ADD SI, 160
        MOV DI, SI
        DEC BL
        CMP BL, 0
        JNE DISPLAY_LOOP

RET

DISPLAY_NAME:   
        MOV AH, 1AH
        MOV AL, 53H
        MOV [DI], AX
                        
        ADD DI, 2
        MOV AL, 49H
        MOV [DI], AX 
                        
        ADD DI, 2
        MOV AL, 44H
        MOV [DI], AX 
                
        ;ADD DI, 2
;        MOV AL, 49H
;        MOV [DI], AX 
;                
;        ADD DI, 2
;        MOV AL, 4CH
;        MOV [DI], AX 

RET

DELAY:  
MOV CX, 1FH
HERE:   
LOOP HERE
RET

CLEAR_NAME: 
MOV CX, 3
DELETE: 
MOV AX, 0
MOV [SI], AX
ADD SI, 2
LOOP DELETE
RET
