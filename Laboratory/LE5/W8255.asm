;====================================================================
; 8255: Count 00..99 while PC0 (A0) is HIGH. Pause when LOW.
; Ones -> PORTA, Tens -> PORTB. Raw 7-seg via LUT (common-cathode).
;====================================================================

DATA SEGMENT 
 PORTA   EQU 0F0H
 PORTB   EQU 0F2H
 PORTC   EQU 0F4H
 COM_REG EQU 0F6H
 
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

 ONES DB 0
 TENS DB 0
DATA ENDS 
 
CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA
 MOV AX, DATA 
 MOV DS, AX
 ORG 0000H 

;============== INIT 8255 ==============
START:
 ; Mode 0: PA=OUT, PB=OUT, PC=IN (PC0 is the run switch, active-LOW)
 MOV DX, COM_REG
 MOV AL, 10001001B          ; 89h
 OUT DX, AL

 ; start at 00
 MOV ONES, 0
 MOV TENS, 0
 CALL SHOW_TWO_DIGITS

;============== MAIN (PC0: 0=RUN, 1=STOP/RESET) ==============
MAIN_IDLE:
 MOV DX, PORTC

 ; reset to 00 and show it
 MOV ONES, 0
 MOV TENS, 0
 CALL SHOW_TWO_DIGITS

 ; wait while PC0 is HIGH (switch OFF)
MI_POLL:
 IN  AL, DX
 TEST AL, 00000001B         ; mask PC0
 JNZ  MI_POLL                ; stay idle while HIGH

;============== RUN while PC0 is LOW ==============
RUN_LOOP:
 CALL SHOW_TWO_DIGITS
 CALL DELAY

 ; if PC0 went HIGH, stop and reset
 IN  AL, DX
 TEST AL, 00000001B
 JNZ  MAIN_IDLE

 ; increment 00..99 then wrap
 INC ONES
 CMP ONES, 10
 JB  RUN_LOOP
 MOV ONES, 0
 INC TENS
 CMP TENS, 10
 JB  RUN_LOOP
 MOV TENS, 0
 JMP RUN_LOOP

;============== SHOW_TWO_DIGITS: ONES->PORTA, TENS->PORTB ==============
SHOW_TWO_DIGITS:
 PUSH AX
 PUSH BX
 PUSH DX

 ; Ones -> PORTA
 LEA BX, SEVEN_SEG
 MOV AL, ONES
 XLAT
 MOV DX, PORTA
 OUT DX, AL

 ; Tens -> PORTB
 LEA BX, SEVEN_SEG
 MOV AL, TENS
 XLAT
 MOV DX, PORTB
 OUT DX, AL

 POP DX
 POP BX
 POP AX
 RET

;============== Delay (adjust speed) ==============
DELAY:
 PUSH CX
 PUSH SI
 MOV CX, 5000
D1: MOV SI, 400
D2: DEC SI
    JNZ D2
    LOOP D1
 POP SI
 POP CX
 RET

CODE ENDS 
END START