
; Bordario, Sid Andre P.

org 100h 

MOV BX, 0123H
MOV AX, 0456H
ADD AX, BX
SUB AX, BX
PUSH AX
PUSH BX
POP CX
POP DX

ret




