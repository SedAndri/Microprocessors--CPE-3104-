DATA SEGMENT

    PORTA     EQU 0F0H
    PORTB     EQU 0F4H

    MASK_SEL  EQU 00000111B
    SEL_ALL   EQU 001B
    SEL_WIRL  EQU 010B
    SEL_SNAKE EQU 100B

    ; WIRL pattern sequence
    WIRL_TBL  DB 00001001B, 00000110B, 01100000B, 10010000B

DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA
    ORG 0000H

START:
    ; Init DS
    MOV AX, DATA
    MOV DS, AX

MAIN_LOOP:
    CALL READ_SEL
    CMP AL, SEL_ALL
    JE  MODE_ALL
    CMP AL, SEL_WIRL
    JE  MODE_WIRL
    CMP AL, SEL_SNAKE
    JE  MODE_SNAKE

    ; Default: all OFF
    MOV DX, PORTA
    XOR AL, AL
    OUT DX, AL
    JMP MAIN_LOOP

; ================= ALL ON =================
MODE_ALL:
    MOV DX, PORTA
ALL_LOOP:
    MOV AL, 0FFH
    OUT DX, AL
    MOV CX, 30000
    CALL DELAY_CX

    CALL READ_SEL
    CMP AL, SEL_ALL
    JE  ALL_LOOP
    JMP MAIN_LOOP

; ================= WIRL =================
MODE_WIRL:
    XOR SI, SI                ; start at index 0
WIRL_LOOP:
    MOV DX, PORTA
    MOV AL, [WIRL_TBL + SI]
    OUT DX, AL
    MOV CX, 15000
    CALL DELAY_CX

    CALL READ_SEL
    CMP AL, SEL_WIRL
    JNE MAIN_LOOP

    INC SI
    AND SI, 0003H             ; wrap to 0..3
    JMP WIRL_LOOP

; ================= SNAKE =================
MODE_SNAKE:
    MOV BL, 00000001B         ; start from LSB (one-hot)
// Circular snake: 00000001 -> ... -> 10000000 -> 00000001
SNAKE_LOOP:
    MOV DX, PORTA
    MOV AL, BL
    ; If LEDs are active-low, invert: NOT AL
    OUT DX, AL
    MOV CX, 12000
    CALL DELAY_CX

    CALL READ_SEL
    CMP AL, SEL_SNAKE
    JNE MAIN_LOOP

    ROL BL, 1                 ; circular rotate within 8 bits
    JMP SNAKE_LOOP

; ================= Helpers =================
; READ_SEL -> AL = masked 3-bit selection from PORTB
READ_SEL:
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL                  ; Uncomment if switches are active-low
    AND AL, MASK_SEL
    RET

; DELAY_CX: busy-wait for CX iterations (destroys CX, preserves AX)
DELAY_CX:
    PUSH AX
DL_LOOP:
    NOP
    LOOP DL_LOOP
    POP AX
    RET

CODE ENDS
END START