;====================================================================
; Count while A0 switch is ON. Pause when OFF.
; 7-seg on PORTB, LEDs (binary of digit) on PORTA.
;====================================================================

DATA SEGMENT 
 PORTA EQU 0F0H
 PORTB EQU 0F2H
 PORTC EQU 0F4H
 
 ; 7-segment display patterns for digits 0-9 (abcdefg)
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

;============== INIT ==============
START: 
 ; Clear outputs
 MOV DX, PORTA
 MOV AL, 00000000B
 OUT DX, AL
 
 MOV DX, PORTB
 MOV AL, 00000000B
 OUT DX, AL

 ; Initialize display to 0
 MOV DIGIT, 0
 ; show on 7-seg
 MOV AL, SEVEN_SEG
 OUT DX, AL
 ; show on LEDs (binary 0)
 MOV DX, PORTA
 MOV AL, 00000000B
 OUT DX, AL

;============== MAIN (level-controlled by A0) ==============
MAIN_IDLE:                 ; wait while switch is OFF
 MOV DX, PORTC
MI_POLL:
 IN  AL, DX
 TEST AL, 00000001B       ; A0 high?
 JZ   MI_POLL             ; stay idle until ON

; running while A0 is ON
RUN_LOOP:
 CALL STEP_COUNT_LEVEL    ; steps once; exits early if switch goes OFF
 ; still ON?
 MOV DX, PORTC
 IN  AL, DX
 TEST AL, 00000001B
 JNZ  RUN_LOOP
 JMP  MAIN_IDLE

;============== STEP: show digit, delay-with-poll, maybe advance ==============
STEP_COUNT_LEVEL:
 PUSH SI
 PUSH BX
 PUSH DX
 PUSH AX

 ; 7-seg out
 MOV BL, DIGIT
 XOR BH, BH
 MOV SI, BX
 MOV AL, SEVEN_SEG[SI]
 MOV DX, PORTB
 OUT DX, AL

 ; LEDs show binary of digit (lower 4 bits)
 MOV DX, PORTA
 MOV AL, DIGIT
 OUT DX, AL

 ; Delay while switch remains ON
 CALL DELAY_WHILE_SWITCH_ON

 ; If switch turned OFF during delay, keep digit and return
 MOV DX, PORTC
 IN  AL, DX
 TEST AL, 00000001B
 JZ   SC_DONE

 ; Advance digit 0..9
 MOV AL, DIGIT
 INC AL
 CMP AL, 10
 JB  SC_STORE
 XOR AL, AL
SC_STORE:
 MOV DIGIT, AL

SC_DONE:
 POP AX
 POP DX
 POP BX
 POP SI
 RET

;============== Delay that keeps polling A0 and exits if it turns OFF ==============
DELAY_WHILE_SWITCH_ON:
 PUSH CX
 PUSH DX
 MOV DX, PORTC
 MOV CX, 6000            ; adjust for desired speed
DWS_LOOP:
 IN  AL, DX
 TEST AL, 00000001B
 JZ   DWS_EXIT           ; switch went OFF
 NOP
 LOOP DWS_LOOP
DWS_EXIT:
 POP DX
 POP CX
 RET

CODE ENDS 
END START