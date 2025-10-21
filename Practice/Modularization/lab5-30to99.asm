;====================================================================
;Bordario, Sid Andre P.
;====================================================================

DATA SEGMENT 
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

 ONES DB 0
 TENS DB 0
DATA ENDS 
 
CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA
 MOV AX, DATA 
 MOV DS, AX
 ORG 0000H 

START:

 MOV DX, COM_REG
 MOV AL, 10001001B         
 OUT DX, AL

 ; starts at 00
 MOV ONES, 0
 MOV TENS, 0
 CALL SHOW_TWO_DIGITS


MAIN_IDLE:
 MOV DX, PORTC


 MOV ONES, 0
 MOV TENS, 0
 CALL SHOW_TWO_DIGITS


MI_POLL:
 IN  AL, DX
 TEST AL, 00000001B         
 JNZ  MI_POLL                


RUN_LOOP:
 CALL SHOW_TWO_DIGITS
 CALL DELAY


 IN  AL, DX
 TEST AL, 00000001B
 JNZ  MAIN_IDLE

 INC ONES
 CMP ONES, 10
 JB  RUN_LOOP
 MOV ONES, 0
 INC TENS
 CMP TENS, 10
 JB  RUN_LOOP
 MOV TENS, 0
 JMP RUN_LOOP

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


DELAY:
 PUSH CX
 PUSH SI
 MOV CX, 50	;lower = faster
D1: MOV SI, 400
D2: DEC SI
    JNZ D2
    LOOP D1
 POP SI
 POP CX
 RET

CODE ENDS 
END START