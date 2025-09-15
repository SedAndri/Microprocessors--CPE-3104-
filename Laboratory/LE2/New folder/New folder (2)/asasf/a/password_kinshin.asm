org 100h

MOV AX, 0B800H
MOV ES, AX

CALL DISPLAY_INPUT
CALL CHECK_PASSWORD

ret

USER_INPUT DB 15,?,15 DUP(0)
INPUT_MSG DB "ENTER PASSWORD: $"
CORRECT_PASSWORD DB "password$",  ; Predefined password
ACCESS_GRANTED_MSG DB 0DH,0AH,"Access Granted! $"
ACCESS_DENIED_MSG DB 0DH,0AH,"Access Denied! $"

DISPLAY_INPUT:
    MOV AH, 9
    LEA DX, INPUT_MSG
    INT 21H
    
    XOR CX, CX  
    MOV BX, 2   

INPUT_LOOP:
    MOV AH, 7  
    INT 21H
    
    CMP AL, 13      ; Detect if USER inputted an ENTER key
    JE END_INPUT    
    
    MOV [USER_INPUT + BX], AL ; Store AL into USER_INPUT 
    
    MOV AH, 2      ; Write character without echoing
    MOV DL, '*' 
    INT 21H
    
    INC BX
    INC CX
    CMP CX, 15  
    JC INPUT_LOOP

END_INPUT:
    MOV [USER_INPUT + 1], CL  
    
   
 
RET

CHECK_PASSWORD:
    LEA SI, CORRECT_PASSWORD
    LEA DI, USER_INPUT + 2
    MOV CL, [USER_INPUT + 1]  ; Get length of user input
    MOV CH, 0

COMPARE_LOOP:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JNE ACCESS_DENIED
    INC SI
    INC DI
    LOOP COMPARE_LOOP

    CMP [SI], '$'  ; Check if we've reached the end of the correct password
    JNE ACCESS_DENIED

ACCESS_GRANTED:
    MOV AH, 9
    LEA DX, ACCESS_GRANTED_MSG
    INT 21H
    RET

ACCESS_DENIED:
    MOV AH, 9
    LEA DX, ACCESS_DENIED_MSG
    INT 21H
    RET