
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h
    
    MOV SI, 1234H
    MOV AX, 1200H   ;IMMEDIATE ADDRESSING MODES
                    ;COPIES 1200H TO A, AX = 1200H
    MOV BX, 4567H   ;IMMEDIATE ADDRESSING MODES, BX = 4567H
    MOV CX, 9876H   ;IMMEDIATE ADDRESSING MODES, CX = 9876H
    MOV AX, CX      ;REGISTER ADDRESSING MODES
                    ;COPIES DATA STORED FROM CX TO AX, CX = AX = 1200H
    MOV CL,[1200H]  ;DIRECT ADDRESSING MODE
                    ;OFFSET ADDRESS = 1200H, PA = SEGMENT ADDRESS*10H + OFFSET ADDRESS
    MOV CL, [BX]    ;REGISTER INDIRECT ADDRESSING MODE
                    ;PA = DS*10H + BX
    MOV [BP], CX
    MOV AX, [SI]
  

ret




