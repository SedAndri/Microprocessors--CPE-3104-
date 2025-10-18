;====================================================================
; Drink Dispenser (8086 + two 8255 PPIs + 74C922 + HD44780 LCD)
;====================================================================

DATA SEGMENT
    ; 8255 #1 (LCD + Keypad)
    PORTA    EQU 0F0H     ; LCD data D0..D7
    PORTB    EQU 0F2H     ; LCD control (PB0=RS, PB1=E)
    PORTC    EQU 0F4H     ; Keypad data (PC0..PC3) + DAVBL on PC4
    COM_REG  EQU 0F6H

    ; 8255 #2 (LEDs)
    PORTD    EQU 0F8H     ; use as LED port (7 LEDs available on D0..D6)
    ; optional: other ports of 2nd 8255 if ever needed
    PORTD_B  EQU 0FAH
    PORTD_C  EQU 0FCH
    COM_REG2 EQU 0FEH

    ; LED bit masks (adjust if wiring differs)
    LED1_MASK EQU 01H      ; D0
    LED2_MASK EQU 02H      ; D1
    LED3_MASK EQU 04H      ; D2
    LED4_MASK EQU 08H      ; D3

    ; Durations (seconds) — adjust as needed
    DUR_LARGE_S  EQU 7
    DUR_MEDIUM_S EQU 4

    ; LCD strings (20x4 DDRAM addressing is used)
    STR_MENU1  DB '[1] Coke Large',0
    STR_MENU2  DB '[2] Coke Medium',0
    STR_MENU3  DB '[3] Sprite Large',0
    STR_MENU4  DB '[4] Sprite Medium',0
    STR_DISP   DB 'Dispensing...',0
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA

START:
    ; init DS
    MOV AX, DATA
    MOV DS, AX

    ;------------------- Program 8255 #1 (LCD+Keypad) -------------------
    ; Mode 0: PA=out, PB=out, PC upper=in, PC lower=in
    MOV DX, COM_REG
    MOV AL, 089H
    OUT DX, AL

    ;------------------- Program 8255 #2 (LEDs) -------------------------
    ; Mode 0: All outputs (PA/PB/PC) -> 80h
    MOV DX, COM_REG2
    MOV AL, 080H
    OUT DX, AL
    ; LEDs OFF
    MOV DX, PORTD
    MOV AL, 00H          ; active‑high: all low = off
    OUT DX, AL

    ; Init LCD and show the menu
    CALL INIT_LCD
    CALL LCD_SHOW_MENU

;==================== Main loop ====================
MainLoop:
    ; Wait for DAVBL (PC4) == 1
WaitDAV:
    MOV DX, PORTC
    IN  AL, DX
    TEST AL, 10H
    JZ  WaitDAV

    ; Read keypad lower nibble
    IN  AL, DX
    AND AL, 0FH

    ; Decode only keys 1..4
    CMP AL, 00H          ; '1'
    JE  K1
    CMP AL, 01H          ; '2'
    JE  K2
    CMP AL, 02H          ; '3'
    JE  K3
    CMP AL, 04H          ; '4'
    JE  K4
    JMP MainLoop         ; ignore other keys

K1:
    CALL WAIT_RELEASE    ; avoid repeats
    MOV BL, LED1_MASK
    MOV CL, DUR_LARGE_S
    CALL DISPENSE_S
    JMP MainLoop

K2:
    CALL WAIT_RELEASE
    MOV BL, LED2_MASK
    MOV CL, DUR_MEDIUM_S
    CALL DISPENSE_S
    JMP MainLoop

K3:
    CALL WAIT_RELEASE
    MOV BL, LED3_MASK
    MOV CL, DUR_LARGE_S
    CALL DISPENSE_S
    JMP MainLoop

K4:
    CALL WAIT_RELEASE
    MOV BL, LED4_MASK
    MOV CL, DUR_MEDIUM_S
    CALL DISPENSE_S
    JMP MainLoop

;---------------- Subroutines ----------------

; Show 4-line menu on a 20x4 LCD
LCD_SHOW_MENU:
    CALL LCD_CLEAR_SAFE        ; reliable clear
    MOV  AL, 080H               ; Line 1
    CALL INST_CTRL
    LEA  SI, STR_MENU1
    CALL LCD_PUTS
    MOV  AL, 0C0H               ; Line 2
    CALL INST_CTRL
    LEA  SI, STR_MENU2
    CALL LCD_PUTS
    MOV  AL, 094H               ; Line 3
    CALL INST_CTRL
    LEA  SI, STR_MENU3
    CALL LCD_PUTS
    MOV  AL, 0D4H               ; Line 4
    CALL INST_CTRL
    LEA  SI, STR_MENU4
    CALL LCD_PUTS
    RET

; Busy-wait until DAVBL (PC4) returns to 0
WAIT_RELEASE:
    MOV DX, PORTC
WR_LP:
    IN  AL, DX
    TEST AL, 10H
    JNZ WR_LP
    RET

; DISPENSE: BL = LED mask, CL = duration in seconds
DISPENSE_S:
    ; LCD: "Dispensing..."
    CALL LCD_CLEAR_SAFE
    MOV  AL, 080H
    CALL INST_CTRL
    LEA  SI, STR_DISP
    CALL LCD_PUTS

    ; LED ON (active‑high: drive only selected bit high)
    MOV DX, PORTD
    MOV AL, BL           ; only that LED bit = 1
    OUT DX, AL

    ; wait CL seconds
    CALL DELAY_SECONDS

    ; LED OFF (all low)
    XOR AL, AL
    OUT DX, AL

    CALL WAIT_RELEASE
    CALL LCD_SHOW_MENU
    RET

; Send instruction in AL to LCD (RS=0, E pulse)
INST_CTRL:
    PUSH AX
    PUSH DX
    MOV DX, PORTA
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 02H          ; E=1, RS=0
    OUT DX, AL
    CALL DELAY_1MS
    MOV AL, 00H          ; E=0, RS=0
    OUT DX, AL
    POP DX
    POP AX
    RET

; Send data in AL to LCD (RS=1, E pulse)
DATA_CTRL:
    PUSH AX
    PUSH DX
    MOV DX, PORTA
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 03H          ; E=1, RS=1
    OUT DX, AL
    CALL DELAY_1MS
    MOV AL, 01H          ; E=0, RS=1
    OUT DX, AL
    POP DX
    POP AX
    RET

; Print zero-terminated string at DS:SI
LCD_PUTS:
LP_NEXT:
    LODSB
    OR  AL, AL
    JZ  LP_DONE
    CALL DATA_CTRL
    JMP LP_NEXT
LP_DONE:
    RET

INIT_LCD:
    MOV AL, 38H          ; Function set: 8-bit, 2/4-line, 5x8
    CALL INST_CTRL
    MOV AL, 08H          ; Display off
    CALL INST_CTRL
    CALL LCD_CLEAR_SAFE  ; Clear + safe delay
    MOV AL, 06H          ; Entry mode: inc, no shift
    CALL INST_CTRL
    MOV AL, 0CH          ; Display on, cursor off
    CALL INST_CTRL
    RET

; Reliable LCD clear (01h needs >=1.52 ms)
LCD_CLEAR_SAFE:
    MOV  AL, 01H
    CALL INST_CTRL
    CALL DELAY_2MS       ; >= 2 ms
    RET


TUNE_1MS EQU 20H       ; try 0x0120 first; tune up/down as needed

DELAY_1MS:
    PUSH CX
    MOV  CX, TUNE_1MS
DLY1:
    NOP
    LOOP DLY1
    POP  CX
    RET

DELAY_2MS:
    CALL DELAY_1MS
    CALL DELAY_1MS
    RET

; Delay CL seconds (uses nested loops of 1000 x 1 ms)
DELAY_SECONDS:
    PUSH AX
    PUSH BX
    PUSH CX
    MOV  BL, CL          ; seconds in BL
SEC_LOOP:
    MOV  AX, 250         ; 250 x 4 ms = 1 s (faster/safer)
QMS_LOOP:
    CALL DELAY_4MS
    DEC  AX
    JNZ  QMS_LOOP
    DEC  BL
    JNZ  SEC_LOOP
    POP  CX
    POP  BX
    POP  AX
    RET


DELAY_4MS:
    CALL DELAY_1MS
    CALL DELAY_1MS
    CALL DELAY_1MS
    CALL DELAY_1MS
    RET

CODE ENDS
END START