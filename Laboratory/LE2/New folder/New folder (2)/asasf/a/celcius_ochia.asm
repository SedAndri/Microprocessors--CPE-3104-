
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

.DATA
MSG DB "Enter temperature in Celcius: $"
MSG1 DB 0DH, 0AH, "In Degrees Farenheit is: $"
TEMP DB ?
HUNDREDS DB ?
TENS DB ?
ONES DB ?
CELCIUS DB ?
.CODE

MOV DX, OFFSET MSG
MOV AH, 9
INT 21H

MOV AH, 1
INT 21H

SUB AL, 30H
MOV CL, 10
MUL CL
MOV DL, AL
XOR AX, AX

MOV AH, 1
INT 21H
CMP AL, 0DH
JE NEXT:
SUB AL, 30H
XOR AH, AH
ADD DL, AL
XOR DH, DH
MOV AX, DX
XOR DX, DX
MOV TEMP, AL
JMP CALCULATE

NEXT:
XOR DH, DH
XOR AX, AX
MOV AX, DX
MOV CL, 10
DIV CL

CALCULATE:
ADD DL, AL
MOV BX, 9
MUL BX
MOV BX, 5
DIV BX
MOV AH, 0
ADD AL, 32

CONVERT:
MOV BL, 100
DIV BL
MOV AL, AH
XOR AH, AH
MOV BL, 10
DIV BL
MOV TENS, AL
MOV ONES, AH
JMP DISPLAY

DISPLAY:
MOV DX, OFFSET MSG1
MOV AH, 9
INT 21H

MOV DX, 0
MOV DL, HUNDREDS
ADD DL, 30H
MOV AH, 2
INT 21H

MOV DX, 0
MOV DL, TENS
ADD DL, 30H
MOV AH, 2
INT 21H

MOV DX, 0
MOV DL, ONES
ADD DL, 30H
MOV AH, 2
INT 21H
 

ret