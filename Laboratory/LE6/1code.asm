DATA SEGMENT
PORTA      EQU 0F0H
PORTB      EQU 0F2H
PORTC      EQU 0F4H
COM_REG    EQU 0F6H
DATA ENDS

CODE SEGMENT PARA PUBLIC 'CODE'
ASSUME CS:CODE, DS:DATA

START:
    ; init 8255: PA=out, PB=out, PC upper/lower in (unused)
    MOV DX, COM_REG
    MOV AL, 89H
    OUT DX, AL

    CALL INIT_LCD
   

    MOV AL, 88H
    CALL INST_CTRL
    ; print "HELLO"
    MOV AL, 'H'          ; H
    CALL DATA_CTRL
    MOV AL, 'E'          ; E
    CALL DATA_CTRL
    MOV AL, 'L'          ; L
    CALL DATA_CTRL
    MOV AL, 'L'          ; L
    CALL DATA_CTRL
    MOV AL, 'O'          ; O
    CALL DATA_CTRL
    MOV AL, '!'
    CALL DATA_CTRL

INST_CTRL:
    PUSH AX
    PUSH DX
    MOV DX, PORTA
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 02H          ; E=1, RS=0
    OUT DX, AL
    CALL DELAY_1MS
    MOV DX, PORTB
    MOV AL, 00H          ; E=0, RS=0
    OUT DX, AL
    POP DX
    POP AX
    RET

DATA_CTRL:
    PUSH AX
    PUSH DX
    MOV DX, PORTA
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 03H          ; E=1, RS=1
    OUT DX, AL
    CALL DELAY_1MS
    MOV DX, PORTB
    MOV AL, 01H          ; E=0, RS=1
    OUT DX, AL
    POP DX
    POP AX
    RET

INIT_LCD:
    MOV AL, 38H          ; 8-bit, 2-line, 5x8
    CALL INST_CTRL
    MOV AL, 08H          ; display off
    CALL INST_CTRL
    MOV AL, 01H          ; clear display
    CALL INST_CTRL
    MOV AL, 06H          ; entry mode: increment, no shift
    CALL INST_CTRL
    MOV AL, 0CH          ; display on, cursor off, blink off
    CALL INST_CTRL
    RET

DELAY_1MS:
    PUSH CX
    MOV CX, 02CAH
DLY1:
    NOP
    LOOP DLY1
    POP CX
    RET

CODE ENDS
END START