;====================================================================
;Bordario, Sid Andre P.
;====================================================================

DATA SEGMENT 
 PORTA   EQU 0F0H
 PORTB   EQU 0F2H
 PORTC   EQU 0F4H
 COM_REG EQU 0F6H

 ; 8253 PIT I/O
 COUNTER0  EQU 0F8H
 COUNTER1  EQU 0FAH
 COUNTER2  EQU 0FCH
 PIT_CTRL  EQU 0FEH

 ;PIT_RELOAD EQU 064H        ; 100 -> 1 sec (tick = N / clock)
 PIT_RELOAD EQU 00AH	     ; 0.1 sec ( 10 / 100 = 0.1)

 
 SEVEN_SEG DB 10111111b  ; 0
           DB 10000110b  ; 1
           DB 11011011b  ; 2
           DB 11001111b  ; 3
           DB 11100110b  ; 4
           DB 11101101b  ; 5
           DB 11111101b  ; 6
           DB 10000111b  ; 7
           DB 11111111b  ; 8
           DB 11101111b  ; 9

 ONES DB 0
 TENS DB 0
DATA ENDS 
 
CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA
 MOV AX, DATA 
 MOV DS, AX
 ORG 0000H 

START:
 ; 8255: PA/PB output, PC lower output (drive GATE0=PC0 high), PC upper input
 MOV DX, COM_REG
 MOV AL, 10001000b         ; PA=out, PB=out, PC upper=in, PC lower=out
 OUT DX, AL

 MOV DX, PORTC
 MOV AL, 00000001b         
 OUT DX, AL

 ; 8253 PIT setup: Counter 0, Mode 2 (rate generator), LSB/MSB, binary
 ; Control = 00110100b (34h)
 MOV DX, PIT_CTRL
 MOV AL, 00110100b
 OUT DX, AL

 MOV DX, COUNTER0
 MOV AL, PIT_RELOAD      ; LSB
 OUT DX, AL
 MOV AL, 000h            ; MSB
 OUT DX, AL

 ; start at 00
 MOV ONES, 0
 MOV TENS, 0
 CALL SHOW_TWO_DIGITS

 CALL WAIT_TICK_OUT0

MAIN_LOOP:
 CALL WAIT_TICK_OUT0
 ; increment 00->99
 INC ONES
 CMP ONES, 10
 JB  SHOW_AND_LOOP
 MOV ONES, 0
 INC TENS
 CMP TENS, 10
 JB  SHOW_AND_LOOP
 MOV TENS, 0

SHOW_AND_LOOP:
 CALL SHOW_TWO_DIGITS
 JMP MAIN_LOOP


WAIT_TICK_OUT0:
  PUSH AX
  PUSH DX
  MOV DX, PORTC
WT_LOW:                   
  IN  AL, DX
  TEST AL, 00010000b      
  JNZ WT_LOW
WT_HIGH:                  
  IN  AL, DX
  TEST AL, 00010000b
  JZ  WT_HIGH
  POP DX
  POP AX
  RET

READ_C0:
 PUSH DX
 PUSH BX
 MOV DX, PIT_CTRL
 MOV AL, 00h             
 OUT DX, AL
 MOV DX, COUNTER0
 IN  AL, DX              ; LSB
 MOV BL, AL
 IN  AL, DX              ; MSB
 MOV BH, AL
 MOV AX, BX              ; AX = MSB:LSB
 POP BX
 POP DX
 RET

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

CODE ENDS 
END START