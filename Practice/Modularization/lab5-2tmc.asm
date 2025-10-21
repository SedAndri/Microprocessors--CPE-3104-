DATA SEGMENT
    ; 8255 I/O map (even addresses: A1:A0 = 00/01/10/11 -> F0/F2/F4/F6)
    PORTA   EQU 0F0H
    PORTB   EQU 0F2H
    PORTC   EQU 0F4H
    COM_REG EQU 0F6H

    SEVEN_SEG DB 00111111B  ; 0
              DB 00000110B  ; 1
              DB 01011011B  ; 2
              DB 01001111B  ; 3
              DB 01100110B  ; 4
              DB 01101101B  ; 5
              DB 01111101B  ; 6
              DB 00000111B  ; 7
              DB 01111111B  ; 8
              DB 01101111B  ; 9

    DIGIT DB 0             
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA

START:
    ; set DS
    MOV AX, DATA
    MOV DS, AX
    ORG 0000H

    ; D7=1(mode), GA mode0, PA=out, PC upper=in, PB=out, PC lower=in
    ; 1000 1001b = 89h
    MOV DX, COM_REG
    MOV AL, 10000000B
    OUT DX, AL

    ; show 0 initially 
    MOV BYTE PTR DIGIT, 0
    CALL SHOW_DIGIT

MAIN_IDLE:                 ; wait while switch is OFF (PC0 = 0)
    MOV DX, PORTC
MI_POLL:
    IN   AL, DX
    TEST AL, 00000001B     ; PC0 high?
    JZ   MI_POLL           ; stay idle until ON

    CALL GET_INPUT

RUN_LOOP:
    CALL STEP_COUNT_LEVEL  

    
    IN   AL, DX
    TEST AL, 00000001B
    JNZ  RUN_LOOP
    JMP  MAIN_IDLE


STEP_COUNT_LEVEL:
    CALL SHOW_DIGIT

    CALL DELAY_WHILE_SWITCH_ON
    JZ   SC_DONE           

   
    MOV AL, DIGIT
    INC AL
    CMP AL, 10
    JB  SC_STORE

    CALL GET_INPUT
    JMP  SC_DONE

SC_STORE:
    MOV DIGIT, AL

SC_DONE:
    RET

DELAY_WHILE_SWITCH_ON:
    PUSH CX
    PUSH DX
    MOV DX, PORTC
    MOV CX, 10000          ; adjust for speed 
DWS_LOOP:
    IN   AL, DX
    TEST AL, 00000001B
    JZ   DWS_EXIT         
    NOP
    LOOP DWS_LOOP         
DWS_EXIT:
    POP DX
    POP CX
    RET

GET_INPUT:
    PUSH AX
    PUSH CX
    PUSH DX

    MOV DX, PORTC
    IN  AL, DX
    AND AL, 11110000B    
    MOV CL, 4
    SHR AL, CL            

   
    CMP AL, 9
    JBE LSI_STORE
    MOV AL, 9
LSI_STORE:
    MOV DIGIT, AL

  
    CALL SHOW_DIGIT

    POP DX
    POP CX
    POP AX
    RET

SHOW_DIGIT:
    PUSH AX
    PUSH BX
    PUSH DX

   
    LEA BX, SEVEN_SEG
    MOV AL, DIGIT
    XLAT                   ; AL = SEVEN_SEG[AL]
    MOV DX, PORTB
    OUT DX, AL

    MOV AL, DIGIT
    MOV DX, PORTA
    OUT DX, AL

    POP DX
    POP BX
    POP AX
    RET

CODE ENDS
END START