DATA SEGMENT 

 PORTA EQU 0F0H
 PORTB EQU 0F4H


 ;============== LED  ==============
 LED0 DB 10000000B  ; LED 0
 LED1 DB 01000000B  ; LED 1
 LED2 DB 00100000B  ; LED 2
 LED3 DB 00010000B  ; LED 3
 LED4 DB 00001000B  ; LED 4
 LED5 DB 00000100B  ; LED 5
 LED6 DB 00000010B  ; LED 6
 LED7 DB 00000001B  ; LED 7

DATA ENDS 
 
CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA
 ORG 0000H

START:
    ; Init DS
    MOV AX, DATA 
    MOV DS, AX

INPUT_WAIT:                        
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL               ; Uncomment if switches are active-low
    AND AL, 00000111B      ; Use only lower 3 bits

    CMP AL, 001B
    JE  ALL
    CMP AL, 010B
    JE  WIRL
    CMP AL, 100B
    JE  SNAKE

    ; Default: all OFF
    MOV DX, PORTA
    MOV AL, 00H
    OUT DX, AL
    JMP INPUT_WAIT

; ================= ALL ON =================
ALL:
    MOV DX, PORTA
ALL_LOOP:
    MOV AL, 0FFH
    OUT DX, AL

    ; small hold
    MOV CX, 30000
ALL_DLY:
    NOP
    LOOP ALL_DLY

    ; stay here while input remains 001
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 001B
    JE  ALL_LOOP
    JMP INPUT_WAIT

; ================= WIRL =================
WIRL:
    ; Loop while input remains 010
WIRL_LOOP:
    MOV DX, PORTA

    MOV AL, 00001001B
    OUT DX, AL
    MOV CX, 15000
WDL1: NOP
    LOOP WDL1

    MOV AL, 00000110B
    OUT DX, AL
    MOV CX, 15000
WDL2: NOP
    LOOP WDL2

    MOV AL, 01100000B
    OUT DX, AL
    MOV CX, 15000
WDL3: NOP
    LOOP WDL3

    MOV AL, 10010000B
    OUT DX, AL
    MOV CX, 15000
WDL4: NOP
    LOOP WDL4

    ; check selection
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 010B
    JE  WIRL_LOOP
    JMP INPUT_WAIT

; ================= SNAKE =================
SNAKE:
SNAKE_LOOP:
    MOV DX, PORTA

    MOV AL, 00000001B
    OUT DX, AL
    MOV CX, 12000
SDL1: NOP
    LOOP SDL1

    MOV AL, 00000010B
    OUT DX, AL
    MOV CX, 12000
SDL2: NOP
    LOOP SDL2

    MOV AL, 00000100B
    OUT DX, AL
    MOV CX, 12000
SDL3: NOP
    LOOP SDL3

    MOV AL, 00001000B
    OUT DX, AL
    MOV CX, 12000
SDL4: NOP
    LOOP SDL4

    MOV AL, 10000000B
    OUT DX, AL
    MOV CX, 12000
SDL5: NOP
    LOOP SDL5

    MOV AL, 01000000B
    OUT DX, AL
    MOV CX, 12000
SDL6: NOP
    LOOP SDL6

    MOV AL, 00100000B
    OUT DX, AL
    MOV CX, 12000
SDL7: NOP
    LOOP SDL7

    MOV AL, 00010000B
    OUT DX, AL
    MOV CX, 12000
SDL8: NOP
    LOOP SDL8

    ; check selection
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 100B
    JE  SNAKE_LOOP
    JMP INPUT_WAIT

CODE ENDS
END START