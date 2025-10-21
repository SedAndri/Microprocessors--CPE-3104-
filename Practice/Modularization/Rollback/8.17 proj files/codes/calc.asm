;====================================================================
; Bordario, Sid Andre P.
;====================================================================

DATA SEGMENT
    PORTA        EQU 0F0H   ; U10 PA0-7 (PA3-0 for ONES, PA7-4 for TENS)
    PORTB        EQU 0F2H   ; U10 PB (operands input)
    PORTC        EQU 0F4H   ; U10 PC (mode input)
    CTRL1        EQU 0F6H   ; U10 control reg

    ONES     DB 0
    TENS     DB 0
    OPERAND1 DB 0
    OPERAND2 DB 0
DATA ENDS
 
CODE SEGMENT PARA 'CODE'
ASSUME CS:CODE, DS:DATA
ORG 0000H 

START:
    ; Initialize DS
    MOV AX, DATA
    MOV DS, AX

    ; Initialize U10 (display 8255): PA output, PB input, PC input
    MOV DX, CTRL1
    MOV AL, 10001011B         ; PA output, PB input, PC input, Mode 0
    OUT DX, AL

    ; starts at 00
    MOV ONES, 0
    MOV TENS, 0
    CALL SHOW_TWO_DIGITS

MAIN_LOOP:
    ; Read mode from PORTC (PC0=ADD, PC1=SUB, PC2=MUL, PC3=DIV), active-low
    MOV DX, PORTC
    IN  AL, DX
    NOT AL                 ; Invert bits for active-low switches
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
    JNZ ADDITION

    TEST AL, 02H
    JNZ SUBTRACTION

    TEST AL, 04H
    JNZ MULTIPLICATION

    TEST AL, 08H
    JNZ DIVISION

    JMP MAIN_LOOP

;-------------------------------
; Read operands from PORTB (lower nibble = OPERAND1, upper nibble = OPERAND2)
;-------------------------------
READ_OPERANDS:
    PUSH DX
    PUSH AX

    MOV DX, PORTB
    IN  AL, DX
    NOT AL                 ; Invert bits for active-low switches
    MOV AH, AL           ; Save input in AH

    AND AL, 0FH          ; Lower nibble = OPERAND1
    MOV OPERAND1, AL

    MOV AL, AH           ; Restore original input from PORTB
    MOV CL, 4
    SHR AL, CL           ; Upper nibble to lower
    AND AL, 0FH          ; Not strictly necessary after SHR, but good practice
    MOV OPERAND2, AL

    POP AX
    POP DX
    RET

;-------------------------------
; Addition
;-------------------------------
ADDITION:
    CALL READ_OPERANDS
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
    JNC SUB_OK          ; If result is positive or zero, proceed
    ; Handle negative result (underflow)
    MOV TENS, 0AH       ; Display pattern for negative result
    MOV ONES, 0AH
    CALL SHOW_TWO_DIGITS
    JMP MAIN_LOOP
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
    MOV BL, OPERAND2
    MUL BL                ; AL = AL * BL
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
    ; Handle overflow (result > 99)
    MOV TENS, 0BH       ; Display pattern for overflow
    MOV ONES, 0BH
    RET                 ; Return with overflow values set
SPLIT_OK:
    MOV AH, 0
    MOV BL, 10
    DIV BL                ; AL = quotient, AH = remainder
    MOV TENS, AL
    MOV AL, AH
    MOV ONES, AL
    RET

;-------------------------------
; Show two digits on 7-seg via 74LS48
;-------------------------------
SHOW_TWO_DIGITS:
    PUSH AX
    PUSH DX

    ; Combine TENS and ONES for Port A
    ; PA3-0 = ONES digit (BCD)
    ; PA7-4 = TENS digit (BCD)
    MOV AL, TENS         ; Get TENS digit (e.g., 5)
    MOV CL, 4
    SHL AL, CL           ; Shift to upper nibble (e.g., 01010000b)
    OR AL, ONES          ; Combine with ONES digit (e.g., 01010011b for 53)

    MOV DX, PORTA        ; Load Port A address
    OUT DX, AL           ; Send combined BCD to both 74LS48 decoders

    POP DX
    POP AX
    RET

;-------------------------------
; Reset state
;-------------------------------
RESET_STATE:
    MOV ONES, 0
    MOV TENS, 0
    CALL SHOW_TWO_DIGITS
    JMP MAIN_LOOP

CODE ENDS
END START