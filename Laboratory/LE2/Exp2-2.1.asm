
; Bordario, Sid Andre P.

org 100h    

JMP START

SOURCE  DW 1234H     
DEST    DW 0000H     

START:

    MOV BX, 0000H          ; Base register points to SOURCE
    MOV SI, BX            ; Index register points to DEST


    MOV AX, [BX+DI+SOURCE]          ; Load word from SOURCE[1] into AX
    MOV [SI+BX+DEST], AX          ; Store AX into DEST[1]

    MOV AH, 4CH                    ; DOS terminate program
    INT 21H


ret


;asdlatest

