CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CODE

START:

MAIN_LOOP:
        ; Read input from port F4h
        MOV     DX, 0F4H
        IN      AL, DX

        ; Check bit 0 (change mask if needed)
        TEST    AL, 01H
        JZ      SW_OFF

SW_ON:
        MOV     DX, 0F0H
        MOV     AL, 01H
        OUT     DX, AL
        JMP     MAIN_LOOP

SW_OFF:
        MOV     DX, 0F0H
        XOR     AL, AL        ; 00h
        OUT     DX, AL
        JMP     MAIN_LOOP

CODE    ENDS
        END     START