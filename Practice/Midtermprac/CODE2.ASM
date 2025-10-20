;====================================================================
; Bordario, Sid Andre P.
;====================================================================

;====================================================================
; DATA SEGMENT
; This segment defines constants for the 8255 PPI port addresses and
; variables to hold the two operands and the two digits (TENS and ONES)
; of the result.
;====================================================================
DATA SEGMENT
    PORTA        EQU 0F0H   ; Assigns the label PORTA to the hexadecimal address 0F0H for Port A.
    PORTB        EQU 0F2H   ; Assigns the label PORTB to the hexadecimal address 0F2H for Port B.
    PORTC        EQU 0F4H   ; Assigns the label PORTC to the hexadecimal address 0F4H for Port C.
    CTRL1        EQU 0F6H   ; Assigns the label CTRL1 to the hexadecimal address 0F6H for the Control Register.

    ONES     DB 0           ; Defines a byte-sized variable named ONES and initializes it to 0.
    TENS     DB 0           ; Defines a byte-sized variable named TENS and initializes it to 0.
    OPERAND1 DB 0           ; Defines a byte-sized variable named OPERAND1 and initializes it to 0.
    OPERAND2 DB 0           ; Defines a byte-sized variable named OPERAND2 and initializes it to 0.
DATA ENDS

CODE SEGMENT PARA 'CODE'    ; Declares the beginning of the code segment.
ASSUME CS:CODE, DS:DATA     ; Tells the assembler that CS points to CODE segment and DS points to DATA segment.
ORG 0000H                   ; Sets the starting address of the code to 0000H.

;====================================================================
; INITIALIZATION
; This section sets up the Data Segment (DS) register and configures
; the 8255 Programmable Peripheral Interface (PPI). Port A is set as
; an output for the 7-segment displays, while Port B and Port C are
; set as inputs for the operands and operation mode, respectively.
; It also initializes the display to show "00".
;====================================================================

START:
    ; Initialize DS
    MOV AX, DATA            ; Load the starting address of the DATA segment into AX.
    MOV DS, AX              ; Copy the address from AX to the Data Segment (DS) register.

    ; Initialize U10 (display 8255): PA output, PB input, PC input
    MOV DX, CTRL1           ; Load the address of the control register (0F6H) into DX.
    MOV AL, 10001011B       ; Load the control word into AL to configure Port A as output, Port B and C as input.
    OUT DX, AL              ; Send the control word from AL to the control register addressed by DX.

    ; starts at 00
    MOV ONES, 0             ; Set the ONES variable to 0.
    MOV TENS, 0             ; Set the TENS variable to 0.
    CALL SHOW_TWO_DIGITS    ; Call the procedure to display the current TENS and ONES values ("00").

;====================================================================
; MAIN PROGRAM LOOP
; This is the core of the program. It continuously reads the mode from
; PORTC to determine which arithmetic operation to perform (ADD, SUB,
; MUL, DIV). It handles cases where no switch or multiple switches are
; pressed by jumping to a reset state.
;====================================================================
MAIN_LOOP:
    ; Read mode from PORTC (PC0=ADD, PC1=SUB, PC2=MUL, PC3=DIV), active-low
    MOV DX, PORTC           ; Load the address of Port C (0F4H) into DX.
    IN  AL, DX              ; Read the byte from Port C into the AL register.
    NOT AL                  ; Invert the bits in AL because the input switches are active-low.
    AND AL, 0FH             ; Mask the upper 4 bits of AL, keeping only the lower 4 bits (for PC0-PC3).

    ; Reset when all switches are OFF (AL == 0)
    TEST AL, AL             ; Perform a logical AND of AL with itself to check if it's zero.
    JZ RESET_STATE          ; If the result is zero (Zero Flag is set), jump to RESET_STATE.

    ; If more than one switch is ON, treat as invalid -> reset
    MOV BL, AL              ; Copy the value of AL to BL.
    DEC BL                  ; Decrement BL by 1.
    AND BL, AL              ; Perform a logical AND between the original value (in AL) and the decremented value (in BL).
    JNZ RESET_STATE         ; If the result is not zero (more than one bit was set), jump to RESET_STATE.

    ; Exactly one switch ON -> execute selected operation
    TEST AL, 01H            ; Check if the first bit (PC0) is set.
    JNZ ADDITION            ; If it is, jump to the ADDITION routine.

    TEST AL, 02H            ; Check if the second bit (PC1) is set.
    JNZ SUBTRACTION         ; If it is, jump to the SUBTRACTION routine.

    TEST AL, 04H            ; Check if the third bit (PC2) is set.
    JNZ MULTIPLICATION      ; If it is, jump to the MULTIPLICATION routine.

    TEST AL, 08H            ; Check if the fourth bit (PC3) is set.
    JNZ DIVISION            ; If it is, jump to the DIVISION routine.

    JMP MAIN_LOOP           ; If no valid single switch is pressed, loop back to the start of MAIN_LOOP.

;====================================================================
; READ OPERANDS
; This procedure reads the 8-bit value from PORTB. The lower 4 bits
; are treated as OPERAND1 and the upper 4 bits are treated as
; OPERAND2. The inputs are active-low, so the bits are inverted.
;====================================================================
READ_OPERANDS:
    PUSH DX                 ; Save the current value of DX on the stack.
    PUSH AX                 ; Save the current value of AX on the stack.

    MOV DX, PORTB           ; Load the address of Port B (0F2H) into DX.
    IN  AL, DX              ; Read the byte from Port B into the AL register.
    NOT AL                  ; Invert the bits in AL because the inputs are active-low.
    MOV AH, AL              ; Save a copy of the inverted input in AH.

    AND AL, 0FH             ; Mask the upper 4 bits of AL to isolate the lower nibble.
    MOV OPERAND1, AL        ; Store the result (lower nibble) in the OPERAND1 variable.

    MOV AL, AH              ; Restore the full inverted input from AH back to AL.
    MOV CL, 4               ; Load the value 4 into CL for the shift operation.
    SHR AL, CL              ; Shift the bits in AL four positions to the right, moving the upper nibble to the lower nibble position.
    AND AL, 0FH             ; Mask the upper 4 bits (good practice, though they are already zero after SHR).
    MOV OPERAND2, AL        ; Store the result (original upper nibble) in the OPERAND2 variable.

    POP AX                  ; Restore the original value of AX from the stack.
    POP DX                  ; Restore the original value of DX from the stack.
    RET                     ; Return from the procedure.

;====================================================================
; ARITHMETIC OPERATIONS
; These procedures perform the selected arithmetic operation. Each one
; first calls READ_OPERANDS, performs the calculation, processes the
; result for display, shows it, and then jumps back to the main loop.
; Subtraction handles underflow, and Division handles division by zero.
;====================================================================
ADDITION:
    CALL READ_OPERANDS      ; Call the procedure to get the two operands from Port B.
    MOV AL, OPERAND1        ; Load the first operand into AL.
    ADD AL, OPERAND2        ; Add the second operand to AL.
    CALL SPLIT_RESULT       ; Call the procedure to split the 8-bit result in AL into TENS and ONES.
    CALL SHOW_TWO_DIGITS    ; Call the procedure to display the result on the 7-segment displays.
    JMP MAIN_LOOP           ; Jump back to the main program loop.

;-------------------------------
; Subtraction
;-------------------------------
SUBTRACTION:
    CALL READ_OPERANDS      ; Call the procedure to get the two operands from Port B.
    MOV AL, OPERAND1        ; Load the first operand into AL.
    SUB AL, OPERAND2        ; Subtract the second operand from AL.
    JNC SUB_OK              ; If the Carry Flag is not set (result is not negative), jump to SUB_OK.
    ; Handle negative result (underflow)
    MOV TENS, 0AH           ; If result is negative, set TENS to 10 (displays a negative sign pattern).
    MOV ONES, 0AH           ; Set ONES to 10 (displays a negative sign pattern).
    CALL SHOW_TWO_DIGITS    ; Display the negative pattern.
    JMP MAIN_LOOP           ; Jump back to the main program loop.
SUB_OK:
    CALL SPLIT_RESULT       ; If result is positive, split the result in AL into TENS and ONES.
    CALL SHOW_TWO_DIGITS    ; Display the result.
    JMP MAIN_LOOP           ; Jump back to the main program loop.

;-------------------------------
; Multiplication
;-------------------------------
MULTIPLICATION:
    CALL READ_OPERANDS      ; Call the procedure to get the two operands from Port B.
    MOV AL, OPERAND1        ; Load the first operand into AL.
    MOV BL, OPERAND2        ; Load the second operand into BL.
    MUL BL                  ; Multiply AL by BL. The 16-bit result is stored in AX (AH:AL).
    CALL SPLIT_RESULT       ; Call the procedure to split the 8-bit result in AL into TENS and ONES.
    CALL SHOW_TWO_DIGITS    ; Display the result.
    JMP MAIN_LOOP           ; Jump back to the main program loop.

;-------------------------------
; Division
;-------------------------------
DIVISION:
    CALL READ_OPERANDS      ; Call the procedure to get the two operands from Port B.
    MOV AL, OPERAND1        ; Load the dividend (OPERAND1) into AL.
    MOV AH, 0               ; Clear AH to make the dividend a 16-bit number (0000:OPERAND1).
    MOV BL, OPERAND2        ; Load the divisor (OPERAND2) into BL.
    CMP BL, 0               ; Compare the divisor with 0.
    JE DIV_ZERO             ; If the divisor is zero, jump to the DIV_ZERO handler.
    DIV BL                  ; Divide AX by BL. The quotient is stored in AL, and the remainder in AH.
    JMP DIV_CONT            ; Jump to continue processing the result.
DIV_ZERO:
    XOR AL, AL              ; If dividing by zero, set the result (AL) to 0.
DIV_CONT:
    CALL SPLIT_RESULT       ; Call the procedure to split the quotient in AL into TENS and ONES.
    CALL SHOW_TWO_DIGITS    ; Display the result.
    JMP MAIN_LOOP           ; Jump back to the main program loop.

;====================================================================
; SPLIT RESULT
; This procedure takes an 8-bit result in the AL register and splits
; it into two BCD digits for the TENS and ONES places. It also handles
; overflow if the result is greater than 99.
;====================================================================
SPLIT_RESULT:
    CMP AL, 99              ; Compare the result in AL with 99.
    JBE SPLIT_OK            ; If AL is Below or Equal to 99, jump to SPLIT_OK.
    ; Handle overflow (result > 99)
    MOV TENS, 0BH           ; If result > 99, set TENS to 11 (displays an overflow pattern).
    MOV ONES, 0BH           ; Set ONES to 11 (displays an overflow pattern).
    RET                     ; Return from the procedure.

SPLIT_OK:
    MOV AH, 0               ; Clear AH.
    MOV BL, 10              ; Load the value 10 into BL for division.
    DIV BL                  ; Divide AX by BL. AL gets the quotient (tens digit), AH gets the remainder (ones digit).
    MOV TENS, AL            ; Store the quotient in the TENS variable.
    MOV AL, AH              ; Move the remainder from AH to AL.
    MOV ONES, AL            ; Store the remainder in the ONES variable.
    RET                     ; Return from the procedure.

;====================================================================
; SHOW TWO DIGITS
; This procedure takes the BCD values in the TENS and ONES variables,
; combines them into a single byte, and sends them to PORTA. The upper
; nibble of PORTA controls the TENS display, and the lower nibble
; controls the ONES display.
;====================================================================
SHOW_TWO_DIGITS:
    PUSH AX                 ; Save the current value of AX on the stack.
    PUSH DX                 ; Save the current value of DX on the stack.

    ; Combine TENS and ONES for Port A
    ; PA3-0 = ONES digit (BCD)
    ; PA7-4 = TENS digit (BCD)
    MOV AL, TENS            ; Get the TENS digit and load it into AL.
    MOV CL, 4               ; Load the value 4 into CL for the shift operation.
    SHL AL, CL              ; Shift the bits in AL four positions to the left, moving the TENS digit to the upper nibble.
    OR AL, ONES             ; Combine the upper nibble (TENS) with the ONES digit using a logical OR.

    MOV DX, PORTA           ; Load the address of Port A (0F0H) into DX.
    OUT DX, AL              ; Send the combined byte from AL to Port A to be displayed.

    POP DX                  ; Restore the original value of DX from the stack.
    POP AX                  ; Restore the original value of AX from the stack.
    RET                     ; Return from the procedure.

;====================================================================
; RESET STATE
; This procedure is called when no operation is selected or an invalid
; combination of operations is selected. It resets the TENS and ONES
; variables to 0 and updates the display to show "00".
;====================================================================
RESET_STATE:
    MOV ONES, 0             ; Set the ONES variable to 0.
    MOV TENS, 0             ; Set the TENS variable to 0.
    CALL SHOW_TWO_DIGITS    ; Call the procedure to display "00".
    JMP MAIN_LOOP           ; Jump back to the main program loop to wait for new input.

CODE ENDS                   ; Marks the end of the CODE segment.
END START                   ; Marks the end of the program and specifies the entry point (START label).