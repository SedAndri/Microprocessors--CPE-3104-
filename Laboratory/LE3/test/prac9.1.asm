org 100h

jmp start


    PASSWORD DB 'fling'   ; pls disply
    PASS EQU ($-PASSWORD)
    MSG1 DB 10, 13, 'Enter passcode: $'
    MSG2 DB 10, 13, 'Login successful. $'
    MSG3 DB 10, 13, 'Login failed. $'
    NEW DB 10, 13, '$'
    INSTLEN EQU 10
    INST DB INSTLEN DUP(0)

    
START:
   
    MOV AX, CS
    MOV DS, AX
    LEA DX, MSG1           ; display message to ask for password input
    MOV AH, 09H
    INT 21H
    MOV SI, 00
    
INPUT:
    MOV AH, 08H            ; reads password input by character
    INT 21H
    CMP AL, 0DH
    JE VERIFY              ; proceed to verification when Enter is pressed
    
    ; immediately echo the character
    MOV DL, AL
    MOV AH, 02H
    INT 21H

    ; store only if buffer has space
    CMP SI, INSTLEN
    JAE SKIP_STORE
    MOV [INST+SI], AL
    INC SI
SKIP_STORE:
    ; backspace, then overwrite with '*'
    MOV DL, 8               ; backspace
    MOV AH, 02H
    INT 21H
    MOV DL, '*'
    INT 21H
    MOV DL, 8               ; backspace again to keep cursor on masked position
    INT 21H
    JMP INPUT
    
VERIFY:
    ; quick length check first (must match exactly)
    CMP SI, PASS
    JNE DENIED

    ; string compare: compare INST (user input) with PASSWORD
    LEA SI, INST
    LEA DI, PASSWORD
    MOV CX, PASS
    MOV AX, DS
    MOV ES, AX             ; ES = DS so CMPSB compares within same segment
    CLD                    ; ensure forward direction
    REPE CMPSB             ; repeat while equal and CX > 0
    JNE DENIED             ; mismatch -> deny

    LEA DX, MSG2           ; success message
    MOV AH, 09H
    INT 21H
    JMP EXIT               ; terminate program
    
DENIED:
    LEA DX, MSG3           ; failure message
    MOV AH, 09H
    INT 21H
    
EXIT:                      ; terminate to DOS
    MOV AH, 4CH
    INT 21H
    
END START