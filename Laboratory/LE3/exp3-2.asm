
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

XOR AX, AX
MOV CL,05H
MOV SI,00H
BACK:
ADD AL,ARR[SI+0]
INC SI
DEC CL
JNZ BACK

MOV BL, 08H
NOT BL
NEG BL
SHL BL,1
RCR BL,2
DIV BL

ret  
ARR DB 01H,02H,03H,04H,05H