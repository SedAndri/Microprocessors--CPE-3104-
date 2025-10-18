;====================================================================
; Main.asm (simple, cleaned)
; Processor: 8086, Assembler: MASM
;====================================================================

DATA SEGMENT
    PORTA   EQU 0F0H      ; 8255 PORT A (LCD data)
    PORTB   EQU 0F2H      ; 8255 PORT B (LCD control)
    PORTC   EQU 0F4H      ; 8255 PORT C (keypad + DAVBL on PC4)   ; CHANGED to match schematic
    COM_REG EQU 0F6H      ; 8255 Control Register                  ; CHANGED to match schematic
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA

START:
    ; init DS
    MOV AX, DATA          ; CHANGED: avoid @DATA (no .MODEL in this file)
    MOV DS, AX

    ; Program 8255: PA=out, PB=out, PC upper=in, PC lower=in (Mode 0)
    MOV DX, COM_REG
    MOV AL, 089H
    OUT DX, AL

    ; Init LCD
    CALL INIT_LCD

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

    ; Decode keypad
    CMP AL, 00H  ; '1'
    JE  K1
    CMP AL, 01H  ; '2'
    JE  K2
    CMP AL, 02H  ; '3'
    JE  K3
    CMP AL, 04H  ; '4'
    JE  K4
    CMP AL, 05H  ; '5'
    JE  K5
    CMP AL, 06H  ; '6'
    JE  K6
    CMP AL, 08H  ; '7'
    JE  K7
    CMP AL, 09H  ; '8'
    JE  K8
    CMP AL, 0AH  ; '9'
    JE  K9
    CMP AL, 0DH  ; '0'
    JE  K0
    CMP AL, 0CH  ; '*'
    JE  KSTAR
    CMP AL, 0EH  ; '#'
    JE  KHASH
    JMP MainLoop

K0:
    MOV AL, '0'
    JMP Show
K1:
    MOV AL, '1'
    JMP Show
K2:
    MOV AL, '2'
    JMP Show
K3:
    MOV AL, '3'
    JMP Show
K4:
    MOV AL, '4'
    JMP Show
K5:
    MOV AL, '5'
    JMP Show
K6:
    MOV AL, '6'
    JMP Show
K7:
    MOV AL, '7'
    JMP Show
K8:
    MOV AL, '8'
    JMP Show
K9:
    MOV AL, '9'
    JMP Show
KSTAR:
    MOV AL, '*'
    JMP Show
KHASH:
    MOV AL, '#'
    JMP Show

Show:
    ; Position cursor at 2nd line, col 8 (0xC7), then write char
    PUSH AX
    MOV  AL, 0C7H
    CALL INST_CTRL
    POP  AX
    CALL DATA_CTRL

    ; Wait for DAVBL release to avoid repeats
WaitRel:
    MOV DX, PORTC
    IN  AL, DX
    TEST AL, 10H
    JNZ  WaitRel

    CALL DELAY_1MS
    JMP MainLoop

; ---------------- Subroutines ----------------

INST_CTRL:
    ; Send instruction in AL to LCD (RS=0, E pulse)
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

DATA_CTRL:
    ; Send data in AL to LCD (RS=1, E pulse)
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

INIT_LCD:
    MOV AL, 38H          ; Function set: 8-bit, 2-line, 5x8
    CALL INST_CTRL
    MOV AL, 08H          ; Display off
    CALL INST_CTRL
    MOV AL, 01H          ; Clear display
    CALL INST_CTRL
    MOV AL, 06H          ; Entry mode: inc, no shift
    CALL INST_CTRL
    MOV AL, 0CH          ; Display on, cursor off
    CALL INST_CTRL
    RET

DELAY_1MS:
    ; Simple approximate delay (adjust CX for your clock)
    PUSH CX
    MOV  CX, 02CAH
DLY1:
    NOP
    LOOP DLY1
    POP  CX
    RET

CODE ENDS
END START