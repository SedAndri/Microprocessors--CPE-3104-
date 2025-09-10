org 100h            


LEA DX, MSG           
MOV AH, 9            
INT 21H              


LEA DX, BUFFER       
CALL INPUT_MSG       

CALL CLEAR_SCREEN     

INIT_PRINT:
    MOV BH, 0         
    MOV DH, 0         
    MOV DL, 39        
    MOV AL, 1         
    MOV CL, BUFFER[1] 
    LEA BP, BUFFER+2  

PRINT_TEXT:
    CMP DH, 25        
    JE EXIT           
    MOV AH, 13H       
    INT 10H           
    INC DH            
    JMP PRINT_TEXT    

INPUT_MSG:
    MOV AH, 0AH       
    INT 21H           

    MOV BL, BUFFER[1] 
    MOV BUFFER[BX+2], '$' 
    RET               

CLEAR_SCREEN: 
    MOV AL, 00H       
    MOV AH, 07H       
    MOV BL, 0000_0110b
    XOR CX, CX        
    MOV DH, 24        
    MOV DL, 79        
    INT 10H          

EXIT:                 
    RET               

.DATA
MSG DB 'input $' 
BUFFER DB 50, 50 DUP(' ')  
.CODE