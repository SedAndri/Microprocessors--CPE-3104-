
DATA SEGMENT 
 PORTA EQU 0F0H
 PORTB EQU 0F2H
 PORTC EQU 0F4H
 
 ;============== 7-SEG LUT (abcdefg) ==============
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

 DIGIT DB 0              ; current digit 0..9
DATA ENDS 
 
CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA
 MOV AX, DATA 
 MOV DS, AX
 ORG 0000H 


START: 
 ; show 0 initially (writes both PORTB and PORTA)
 MOV DIGIT, 0
 CALL SHOW_DIGIT


MAIN_IDLE:                        ; wait while switch is OFF
 MOV DX, PORTC
MI_POLL:
 IN  AL, DX
 TEST AL, 00000001B              ; A0 high?
 JZ   MI_POLL                    ; stay idle until ON


 CALL GET_INPUT


RUN_LOOP:
 CALL STEP_COUNT_LEVEL           ; steps once; exits early if switch goes OFF

 ; still ON?
 IN  AL, DX
 TEST AL, 00000001B
 JNZ  RUN_LOOP
 JMP  MAIN_IDLE


STEP_COUNT_LEVEL:
 ; Update displays once per step
 CALL SHOW_DIGIT

 ; Delay while switch remains ON (sets ZF if it turned OFF)
 CALL DELAY_WHILE_SWITCH_ON
 JZ   SC_DONE                    ; switch went OFF: keep digit and return

 ; Advance digit 0..9, but on wrap reseed from PORTC (A4..A7)
 MOV AL, DIGIT
 INC AL
 CMP AL, 10
 JB  SC_STORE
 ; wrapped past 9: read DIP and update displays immediately
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
 MOV CX, 10000                   ; adjust speed
DWS_LOOP:
 IN  AL, DX
 TEST AL, 00000001B
 JZ   DWS_EXIT                  ; switch went OFF (ZF=1)
 NOP
 LOOP DWS_LOOP                  ; if loop ends, last TEST had ZF=0
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
 AND AL, 11110000B              ; keep A7..A4
 MOV CL, 4
 SHR AL, CL                     ; move to bits 3..0


 ; clamp to 9
 CMP AL, 9
 JBE LSI_STORE
 MOV AL, 9
LSI_STORE:
 MOV DIGIT, AL

 ; Update both displays
 CALL SHOW_DIGIT

 POP DX
 POP CX
 POP AX
 RET


SHOW_DIGIT:
 PUSH AX
 PUSH BX
 PUSH DX

 ; 7-seg out via LUT using XLAT
 LEA BX, SEVEN_SEG
 MOV AL, DIGIT
 XLAT                          ; AL = SEVEN_SEG[AL]
 MOV DX, PORTB
 OUT DX, AL

 ; LEDs show binary of digit (lower 4 bits)
 MOV AL, DIGIT
 MOV DX, PORTA
 OUT DX, AL

 POP DX
 POP BX
 POP AX
 RET

CODE ENDS 
END START