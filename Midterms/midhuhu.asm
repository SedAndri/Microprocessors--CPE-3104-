DATA SEGMENT 
 
 PORTA EQU 0F0H
 PORTB EQU 0F2H
 PORTC EQU 0F4H
 COM_REG EQU 0F6H
 
 PORTD EQU 0FCH
 COM_REG2 EQU 0FEH

 ; key codes (mask 3 LSBs of PORTD)
 KEY_MASK       EQU 00000111B
 KEY_ALL_ON     EQU 001B
 KEY_PLAY_TOGGLE EQU 010B
 KEY_SNAKE      EQU 100B

 ;============== LED  ==============
 LED0 DB 10000000B  ; LED 0
 LED1 DB 01000000B  ; LED 1
 LED2 DB 00100000B  ; LED 2
 LED3 DB 00010000B  ; LED 3
 LED4 DB 00001000B  ; LED 4
 LED5 DB 00000100B  ; LED 5
 LED6 DB 00000010B  ; LED 6
 LED7 DB 00000001B  ; LED 7

 ; runtime state
 PLAY_STATE DB 1      ; start in playing state so snake runs on 100b
 LAST_KEY   DB 0FFH   ; for edge-detect of 010
 TMP_KEY    DB 00H

DATA ENDS 
 
CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA
 ORG 0000H

START:
    MOV DX, COM_REG
    ;MOV AL, 10001000b          ; PA=out, PB=out, PC upper=in, PC lower=out
    MOV AL, 10001001B
    ;MOV AL, 10001011b         ; PA=out, PB=in, PC upper=in, PC lower=in
    ; 8255 #1: PA=out, PB=out, PC upper=out, PC lower=out (mode 0)
    MOV AL, 10000000B
    OUT DX, AL 
     
    MOV DX, COM_REG2
    MOV AL, 10001000B		 ; PA=out, PB=out, PC upper=in, PC lower=out
    ; 8255 #2: PC lower=input (keys on D0..D2), others outputs (mode 0)
    MOV AL, 10001001B
    OUT DX, AL
     
    ; Init DS
    MOV AX, DATA 
    MOV DS, AX
+
+   ; Clear LEDs on start
+   MOV DX, PORTA
+   XOR AL, AL
+   OUT DX, AL
+   MOV DX, PORTB
+   XOR AL, AL
+   OUT DX, AL
+   MOV DX, PORTC
+   XOR AL, AL
+   OUT DX, AL

; --------------- Main loop: read keys and dispatch ---------------
INPUT_LOOP:
    ; read keys
    MOV DX, PORTD
    IN  AL, DX
    AND AL, KEY_MASK
    MOV [TMP_KEY], AL

    ; play/pause toggle on 010 (edge-triggered)
    CMP AL, KEY_PLAY_TOGGLE
    JNE NO_TOGGLE_MAIN
    CMP [LAST_KEY], AL
    JE  SKIP_TOGGLE_MAIN
    MOV AH, [PLAY_STATE]
    XOR AH, 1
    MOV [PLAY_STATE], AH
SKIP_TOGGLE_MAIN:
NO_TOGGLE_MAIN:
    ; update LAST_KEY
    MOV AL, [TMP_KEY]
    MOV [LAST_KEY], AL

    ; handle modes
    CMP AL, KEY_ALL_ON
    JE  ALL_ON_MODE
    CMP AL, KEY_SNAKE
    JE  SNAKE_MODE
-
-    ; default: do nothing, keep current outputs
-    JMP INPUT_LOOP
+    ; default: all OFF when no recognized key
+    MOV DX, PORTA
+    XOR AL, AL
+    OUT DX, AL
+    MOV DX, PORTB
+    XOR AL, AL
+    OUT DX, AL
+    JMP INPUT_LOOP

; --------------- All ON while key == 001 ---------------
ALL_ON_MODE:
    MOV DX, PORTA
    MOV AL, 0FFH
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 0FFH
    OUT DX, AL
    ; keep PORTC low (upper nibble is input per config)
    MOV DX, PORTC
    MOV AL, 00H
    OUT DX, AL
    JMP INPUT_LOOP

; --------------- Snake mode (key == 100, honor play/pause) ---------------
SNAKE_MODE:
    ; if paused, wait here until play or mode change
    MOV AL, [PLAY_STATE]
    CMP AL, 0
    JNE SNAKE_PLAY

PAUSE_LOOP:
    MOV DX, PORTD
    IN  AL, DX
    AND AL, KEY_MASK
    MOV [TMP_KEY], AL

    ; 001 -> all-on
    CMP AL, KEY_ALL_ON
    JE  ALL_ON_MODE

    ; toggle on 010 edge
    CMP AL, KEY_PLAY_TOGGLE
    JNE PL_NO_TOGGLE
    CMP [LAST_KEY], AL
    JE  PL_SKIP_TOGGLE
    MOV AH, [PLAY_STATE]
    XOR AH, 1
    MOV [PLAY_STATE], AH
PL_SKIP_TOGGLE:
PL_NO_TOGGLE:
    ; update LAST_KEY
    MOV AL, [TMP_KEY]
    MOV [LAST_KEY], AL

    ; leave snake mode if key not 100 or 010
    CMP AL, KEY_SNAKE
    JE  PL_CHECK_RESUME
    CMP AL, KEY_PLAY_TOGGLE
    JE  PL_CHECK_RESUME
    JMP INPUT_LOOP

PL_CHECK_RESUME:
    MOV AL, [PLAY_STATE]
    CMP AL, 1
    JE  SNAKE_PLAY
    JMP PAUSE_LOOP

; --------------- Snake pattern steps (repeat) ---------------
SNAKE_PLAY:
    ; step 1
    MOV DX, PORTA
    MOV AL, 00000010B
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 00000001B
    OUT DX, AL
    CALL DELAY_S
    CALL SNAKE_CHECK_CONT

    ; step 2
    MOV DX, PORTA
    MOV AL, 00000001B
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 00000010B
    OUT DX, AL
    CALL DELAY_S
    CALL SNAKE_CHECK_CONT

    ; step 3
    MOV DX, PORTA
    MOV AL, 10000000B
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 00000100B
    OUT DX, AL
    CALL DELAY_S
    CALL SNAKE_CHECK_CONT

    ; step 4
    MOV DX, PORTA
    MOV AL, 01000000B
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 00001000B
    OUT DX, AL
    CALL DELAY_S
    CALL SNAKE_CHECK_CONT

    ; step 5
    MOV DX, PORTA
    MOV AL, 00100000B
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 00010000B
    OUT DX, AL
    CALL DELAY_S
    CALL SNAKE_CHECK_CONT

    ; step 6
    MOV DX, PORTA
    MOV AL, 00010000B
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 00100000B
    OUT DX, AL
    CALL DELAY_S
    CALL SNAKE_CHECK_CONT

    ; step 7
    MOV DX, PORTA
    MOV AL, 00001000B
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 01000000B
    OUT DX, AL
    CALL DELAY_S
    CALL SNAKE_CHECK_CONT

    ; step 8
    MOV DX, PORTA
    MOV AL, 00000100B
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 10000000B
    OUT DX, AL
    CALL DELAY_S
    CALL SNAKE_CHECK_CONT

    JMP SNAKE_PLAY

; --------------- Helpers ---------------
DELAY_S:
    PUSH CX
    MOV CX, 12000
DS_L: NOP
    LOOP DS_L
    POP CX
    RET

; Check keys between steps to honor mode changes and play/pause
SNAKE_CHECK_CONT:
    PUSH AX
    PUSH DX
    MOV DX, PORTD
    IN  AL, DX
    AND AL, KEY_MASK
    MOV [TMP_KEY], AL

    ; 001 -> all-on
    CMP AL, KEY_ALL_ON
    JE  SC_TO_ALL_ON

    ; toggle on 010 edge
    CMP AL, KEY_PLAY_TOGGLE
    JNE SC_NO_TOGGLE
    CMP [LAST_KEY], AL
    JE  SC_SKIP_TOGGLE
    MOV AH, [PLAY_STATE]
    XOR AH, 1
    MOV [PLAY_STATE], AH
SC_SKIP_TOGGLE:
SC_NO_TOGGLE:
    ; update LAST_KEY
    MOV AL, [TMP_KEY]
    MOV [LAST_KEY], AL

    ; if not in snake anymore (and not 010), return to main
    CMP AL, KEY_SNAKE
    JE  SC_CHECK_PLAY
    CMP AL, KEY_PLAY_TOGGLE
    JE  SC_CHECK_PLAY
    POP DX
    POP AX
    JMP INPUT_LOOP

SC_CHECK_PLAY:
    ; if paused, go to pause loop
    MOV AL, [PLAY_STATE]
    CMP AL, 0
    POP DX
    POP AX
    JE  PAUSE_LOOP
    RET

SC_TO_ALL_ON:
    POP DX
    POP AX
    JMP ALL_ON_MODE

CODE ENDS
END START