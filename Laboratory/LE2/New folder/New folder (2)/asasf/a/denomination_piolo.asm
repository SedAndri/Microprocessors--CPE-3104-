
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

.DATA
MSG1 DB "INPUT 3-DIGIT VALUE: $" 
MSG2 DB 0DH, 0AH, "P100 $"
MSG3 DB 0DH, 0AH, "P50 $"
MSG4 DB 0DH, 0AH, "P20 $"
MSG5 DB 0DH, 0AH, "P10 $"
MSG6 DB 0DH, 0AH, "P5 $"
MSG7 DB 0DH, 0AH, "P1 $"
BUFFER DB 4,?, 4 DUP(' ')
DIGIT DB 10,?, 10 DUP(' ') 


.CODE
LEA DX, MSG1
MOV AH, 09H
INT 21H
 
MOV CX, 0
LEA DX, BUFFER
MOV AH, 0AH
INT 21H

MOV BL, BUFFER[1]              ;STRING LENGTH
MOV [BUFFER + BX + 2], '$'     ; ADDS DOLLAR SIGN TO END OF A STRING
MOV CH, BL 

FIRST_DIGIT:
XOR BX, BX
MOV SI, OFFSET BUFFER + 2
MOV AL, [SI]
SUB AL, 30H
MOV BL, 64H
MUL BL
MOV DX, AX
XOR AX, AX

SECOND_DIGIT:
INC SI
MOV AL, [SI]
SUB AL, 30H
MOV BL, 0AH
MUL BL
ADD DX, AX
XOR AX, AX

THIRD_DIGIT:
INC SI
MOV AL, [SI]
SUB AL, 30H
ADD DX, AX

LEA DI, DIGIT + 2

;DENOMINATION

HUNDRED:
MOV AX, DX
MOV CL, 64H
DIV CL
ADD AL, 30H
MOV [DI], AL
MOV AL, AH
MOV AH, 0H
INC DI

FIFTY:
MOV CL, 32H
DIV CL
ADD AL, 30H
MOV [DI], AL
MOV AL, AH
MOV AH, 0H
INC DI

TWENTY:
MOV CL, 14H
DIV CL
ADD AL, 30H
MOV [DI], AL
MOV AL, AH
MOV AH, 0H
INC DI     

TEN:
MOV CL, 0AH
DIV CL
ADD AL, 30H
MOV [DI], AL
MOV AL, AH
MOV AH, 0H
INC DI

FIVE:
MOV CL, 05H
DIV CL
ADD AL, 30H
MOV [DI], AL
MOV AL, AH
MOV AH, 0H
INC DI

ONE:
MOV CL, 01H
DIV CL
ADD AL, 30H
MOV [DI], AL
MOV AL, AH
MOV AH, 0H
INC DI

DISPLAY:
;MOV DIGIT
LEA DI, DIGIT + 2
;MOV [DIGIT + BX + 2], '$'                                 

; Display P100
LEA DX, MSG2
MOV AH, 09H
INT 21H
MOV DL, [DI]       ; Get the value from DIGIT for P100
MOV AH, 02H
INT 21H
INC DI

; Display P50
LEA DX, MSG3
MOV AH, 09H
INT 21H
MOV DL, [DI]       ; Get the value from DIGIT for P50
MOV AH, 02H
INT 21H
INC DI

; Display P20
LEA DX, MSG4
MOV AH, 09H
INT 21H
MOV DL, [DI]       ; Get the value from DIGIT for P20
MOV AH, 02H
INT 21H
INC DI  

; Display P10
LEA DX, MSG5
MOV AH, 09H
INT 21H
MOV DL, [DI]       ; Get the value from DIGIT for P10
MOV AH, 02H
INT 21H
INC DI   

; Display P5
LEA DX, MSG6
MOV AH, 09H
INT 21H
MOV DL, [DI]       ; Get the value from DIGIT for P5
MOV AH, 02H
INT 21H
INC DI  

; Display P1
LEA DX, MSG7
MOV AH, 09H
INT 21H
MOV DL, [DI]       ; Get the value from DIGIT for P1
MOV AH, 02H
INT 21H

ret




