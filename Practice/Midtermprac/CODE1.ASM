;====================================================================
;Bordario, Sid Andre P.
;====================================================================

DATA SEGMENT 
   PORTA   EQU 0F0H   ; U10 PA (ones digit, output)
   PORTB   EQU 0F2H   ; U10 PB (tens digit, output)
   PORTC   EQU 0F4H   ; U10 PC (mode input)
   CTRL1   EQU 0F6H   ; U10 control reg

   PORTD   EQU 0F8H   ; U8 PA (operand 1, input)
   PORTE   EQU 0FAH   ; U8 PB (operand 2, input)
   PORTF   EQU 0FCH
   CTRL2   EQU 0FEH   ; U8 control reg
 
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
 OPERAND1 DB 0
 OPERAND2 DB 0
DATA ENDS 
 
CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA
 MOV AX, DATA 
 MOV DS, AX
 ORG 0000H 

START:

 ; Initialize U10 (display 8255): PA/PB output, PC input
 MOV DX, CTRL1
 MOV AL, 10001001B         ; PA output, PB output, PC input, Mode 0
 OUT DX, AL

 ; Initialize U8 (operand 8255): PA/PB input, PC input
 MOV DX, CTRL2
 MOV AL, 10011011B         ; PA input, PB input, PC input, Mode 0
 OUT DX, AL

 ; starts at 00
 MOV ONES, 0
 MOV TENS, 0
 CALL SHOW_TWO_DIGITS

MAIN_LOOP:
    ; Read mode from PORTC (PC0=ADD, PC1=SUB, PC2=MUL, PC3=DIV), active-high
    MOV DX, PORTC
    IN  AL, DX
    AND AL, 0FH            ; use lower 4 bits

    ; Reset when all switches are OFF (AL == 0)
    TEST AL, AL
    JZ RESET_STATE

    ; If more than one switch is ON, treat as invalid -> reset
    MOV BL, AL
    DEC BL
    AND BL, AL
    JNZ RESET_STATE

    ; Exactly one switch ON -> execute selected operation
    TEST AL, 01H
    JNZ 

    TEST AL, 02H
    JNZ SUBTRACTION

    TEST AL, 04H
    JNZ MULTIPLICATION

    TEST AL, 08H
    JNZ DIVISION

    JMP MAIN_LOOP

;-------------------------------
; Read operands from PORTD and PORTE
;-------------------------------
READ_OPERANDS:
 PUSH DX
 PUSH AX

 MOV DX, PORTD
 IN  AL, DX
 AND AL, 0FH         ; Only lower 4 bits
 MOV OPERAND1, AL

 MOV DX, PORTE
 IN  AL, DX
 AND AL, 0FH         ; Only lower 4 bits
 MOV OPERAND2, AL

 POP AX
 POP DX
 RET

;-------------------------------
; Addition
;-------------------------------
ADDITION:
 CALL READ_OPERANDS
 MOV OPERAND2, 02H	;test if it outputs
 MOV AL, OPERAND1
 ADD AL, OPERAND2
 CALL SPLIT_RESULT
 CALL SHOW_TWO_DIGITS
 JMP MAIN_LOOP

;-------------------------------
; Subtraction
;-------------------------------
SUBTRACTION:
 CALL READ_OPERANDS
 MOV AL, OPERAND1
 SUB AL, OPERAND2
 JNC SUB_OK
 XOR AL, AL          ; If negative, show 0
SUB_OK:
 CALL SPLIT_RESULT
 CALL SHOW_TWO_DIGITS
 JMP MAIN_LOOP

;-------------------------------
; Multiplication
;-------------------------------
MULTIPLICATION:
 CALL READ_OPERANDS
 MOV AL, OPERAND1
 MUL OPERAND2        ; AL = AL * OPERAND2
 CALL SPLIT_RESULT
 CALL SHOW_TWO_DIGITS
 JMP MAIN_LOOP

;-------------------------------
; Division
;-------------------------------
DIVISION:
 CALL READ_OPERANDS
 MOV AL, OPERAND1
 MOV AH, 0
 MOV BL, OPERAND2
 CMP BL, 0
 JE DIV_ZERO
 DIV BL              ; AL = AL / BL
 JMP DIV_CONT
DIV_ZERO:
 XOR AL, AL          ; If divide by zero, show 0
DIV_CONT:
 CALL SPLIT_RESULT
 CALL SHOW_TWO_DIGITS
 JMP MAIN_LOOP

;-------------------------------
; Split AL into TENS and ONES (max 99)
;-------------------------------
SPLIT_RESULT:
 CMP AL, 99
 JBE SPLIT_OK
 MOV AL, 99
SPLIT_OK:
 MOV AH, 0
 MOV BL, 10
 DIV BL              ; AL = AL / 10, AH = AL % 10
 MOV TENS, AL
 MOV ONES, AH
 RET

;-------------------------------
; Show two digits on 7-seg
;-------------------------------
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

;-------------------------------
; Delay
;-------------------------------
DELAY:
 PUSH CX
 PUSH SI
 MOV CX, 50
D1: MOV SI, 400
D2: DEC SI
    JNZ D2
    LOOP D1
 POP SI
 POP CX
 RET

RESET_STATE:
    MOV ONES, 0
    MOV TENS, 0
    CALL SHOW_TWO_DIGITS
    JMP MAIN_LOOP

CODE ENDS 
END START