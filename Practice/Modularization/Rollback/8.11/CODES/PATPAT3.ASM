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

; ================= ZIGZAG (replaces ALL ON) =================
ALL:
    ; Ping-pong a single LED from LSB to MSB and back
    MOV BL, 00000001B    ; BL = current LED mask
    MOV BH, 1            ; BH = direction (1 = forward to MSB, 0 = backward to LSB)
ZIGZAG_LOOP:
    MOV DX, PORTA
    MOV AL, BL
    OUT DX, AL

    ; small hold
    MOV CX, 15000
ZZ_DLY:
    NOP
    LOOP ZZ_DLY

    ; stay here while input remains 001
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 001B
    JNE INPUT_WAIT

    ; advance zigzag
    CMP BH, 1
    JE  ZZ_FWD

ZZ_BWD:
    CMP BL, 00000001B
    JE  ZZ_SET_FWD
    SHR BL, 1
    JMP ZIGZAG_LOOP

ZZ_SET_FWD:
    MOV BH, 1
    SHL BL, 1
    JMP ZIGZAG_LOOP

ZZ_FWD:
    CMP BL, 10000000B
    JE  ZZ_SET_BWD
    SHL BL, 1
    JMP ZIGZAG_LOOP

ZZ_SET_BWD:
    MOV BH, 0
    SHR BL, 1
    JMP ZIGZAG_LOOP

; ================= PARALLEL RUNNING LIGHTS (replaces WIRL) =================
WIRL:
    ; Two LEDs move in parallel across both nibbles:
    ; 1000_1000 -> 0100_0100 -> 0010_0010 -> 0001_0001 -> repeat
WIRL_LOOP:
    MOV DX, PORTA
    MOV AL, 10001000B
    OUT DX, AL
    MOV CX, 15000
WDL1: NOP
    LOOP WDL1
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 010B
    JNE INPUT_WAIT

    MOV DX, PORTA
    MOV AL, 01000100B
    OUT DX, AL
    MOV CX, 15000
WDL2: NOP
    LOOP WDL2
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 010B
    JNE INPUT_WAIT

    MOV DX, PORTA
    MOV AL, 00100010B
    OUT DX, AL
    MOV CX, 15000
WDL3: NOP
    LOOP WDL3
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 010B
    JNE INPUT_WAIT

    MOV DX, PORTA
    MOV AL, 00010001B
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

; ================= CHRISTMAS LIGHTS-LIKE (replaces SNAKE) =================
SNAKE:
    ; Alternating festive patterns: checker, halves, stripes
XMAS_LOOP:
    MOV DX, PORTA
    MOV AL, 10101010B
    OUT DX, AL
    MOV CX, 12000
SDL1: NOP
    LOOP SDL1
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 100B
    JNE INPUT_WAIT

    MOV DX, PORTA
    MOV AL, 01010101B
    OUT DX, AL
    MOV CX, 12000
SDL2: NOP
    LOOP SDL2
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 100B
    JNE INPUT_WAIT

    MOV DX, PORTA
    MOV AL, 11110000B
    OUT DX, AL
    MOV CX, 12000
SDL3: NOP
    LOOP SDL3
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 100B
    JNE INPUT_WAIT

    MOV DX, PORTA
    MOV AL, 00001111B
    OUT DX, AL
    MOV CX, 12000
SDL4: NOP
    LOOP SDL4
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 100B
    JNE INPUT_WAIT

    MOV DX, PORTA
    MOV AL, 11001100B
    OUT DX, AL
    MOV CX, 12000
SDL5: NOP
    LOOP SDL5
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 100B
    JNE INPUT_WAIT

    MOV DX, PORTA
    MOV AL, 00110011B
    OUT DX, AL
    MOV CX, 12000
SDL6: NOP
    LOOP SDL6

    ; check selection
    MOV DX, PORTB
    IN  AL, DX
    ; NOT AL
    AND AL, 00000111B
    CMP AL, 100B
    JE  XMAS_LOOP
    JMP INPUT_WAIT

CODE ENDS
END START