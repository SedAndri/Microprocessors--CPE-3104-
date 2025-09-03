
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt


ORG 100h       ; required for .COM programs in emu8086

DATA1 DB 25H 
DATA2 DW 1234H  
DATA3 DB 0H  
DATA4 DW 0H 
DATA5 DW 2345H,6789H 

START: 
    MOV AL,25H  
    MOV AX,2345H  
    MOV BX,AX  
    MOV CL,AL  
    
    MOV AL,[DATA1]    ; corrected
    MOV AX,[DATA2]    ; corrected
    
    MOV [DATA3],AL    ; corrected
    MOV [DATA4],AX    ; corrected
    
    MOV BX,OFFSET DATA5
    MOV AX,[BX]  
    MOV DI,02H  
    MOV AX,[BX+DI]  
    MOV AX,[BX+0002H] 
    MOV AL,[DI+2]    
    MOV AX,[BX+DI+0002H]   
    
    MOV AH,4Ch        ; safe program exit
    INT 21h


ret




