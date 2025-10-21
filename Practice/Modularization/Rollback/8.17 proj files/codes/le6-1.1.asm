; Bordario, Sid Andre P.

DATA SEGMENT
    PORTA   EQU 0F0H
    PORTB   EQU 0F2H
    PORTC   EQU 0F4H
    COM_REG EQU 0F6H

    LP_STAR_3S  EQU 3000
    LP_HASH_5S  EQU 5000

    LCD_ON_FLAG   DB 0
    CODE_SET_FLAG DB 0
    ARMED_FLAG    DB 0

    CODE_LEN   DB 0
    CODE_BUF   DB 8 DUP(?)

    INP_LEN    DB 0
    INP_BUF    DB 8 DUP(?)

    STR_MAIN1      DB 'MAIN MENU',0
    STR_MAIN2      DB '1:Set  2:Arm ?',0

    STR_ERR_NO_CODE1 DB 'ERROR:',0
    STR_ERR_NO_CODE2 DB 'No code set!',0

    STR_WARN1      DB 'WARNING:',0
    STR_WARN2      DB 'System ARMED',0
    STR_WARN3      DB '0 to disarm',0

    STR_SET1       DB 'Input AccessCode',0
    STR_SET2       DB '[        ]  #=set',0

    STR_BADLEN1    DB 'Invalid length',0
    STR_BADLEN2    DB 'Use 4..8 digits',0

    STR_ENTER1     DB 'Enter AccessCode',0
    STR_ENTER2     DB '[        ]  #=ok',0

    STR_WRONG1     DB 'WRONG CODE!',0
    STR_WRONG2     DB 'Still ARMED',0

    STR_OK1        DB 'SUCCESS:',0
    STR_OK2        DB 'Disarmed! Press #',0

    SPACES16       DB '                ',0
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA

START:
    MOV AX, DATA
    MOV DS, AX

    MOV DX, COM_REG
    MOV AL, 089H
    OUT DX, AL

    CALL INIT_LCD
    CALL LCD_DISPLAY_OFF
    MOV  LCD_ON_FLAG, 0
    MOV  CODE_SET_FLAG, 0
    MOV  ARMED_FLAG, 0
    JMP  Standby

MainLoop:
Standby:
    CMP  LCD_ON_FLAG, 0
    JNE  ShowMenu
WaitWake:
    CALL WAIT_FOR_PRESS_ASCII
    CMP  AL, '*'
    JNE  CheckHashOff_WhileOff
    MOV  CX, LP_STAR_3S
    CALL IS_LONG_PRESS
    CMP  AL, 1
    JNE  ReleaseAndWaitWake
    CALL LCD_DISPLAY_ON
    CALL LCD_CLEAR
    MOV  LCD_ON_FLAG, 1
    CALL WAIT_KEY_RELEASE
    JMP  ShowMenu
CheckHashOff_WhileOff:
    CMP  AL, '#'
    JNE  ReleaseAndWaitWake
    MOV  CX, LP_HASH_5S
    CALL IS_LONG_PRESS
ReleaseAndWaitWake:
    CALL WAIT_KEY_RELEASE
    JMP  WaitWake

ShowMenu:
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 3
    LEA  SI, STR_MAIN1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_MAIN2
    CALL LCD_PRINT_AT

MenuChoice:
MC_Poll:
    CALL WAIT_FOR_PRESS_ASCII
    CMP  AL, '#'
    JNE  MC_NotHash
    MOV  CX, LP_HASH_5S
    CALL IS_LONG_PRESS
    CMP  AL, 1
    JNE  MC_HashShort
    CALL LCD_DISPLAY_OFF
    MOV  LCD_ON_FLAG, 0
    CALL WAIT_KEY_RELEASE
    JMP  Standby
MC_HashShort:
    CALL WAIT_KEY_RELEASE
    JMP  MC_Poll

MC_NotHash:
    CMP  AL, '1'
    JE   MC_Choose1
    CMP  AL, '2'
    JE   MC_Choose2
    CALL WAIT_KEY_RELEASE
    JMP  MC_Poll

MC_Choose1:
    CALL WAIT_KEY_RELEASE
    JMP  DoSetCode

MC_Choose2:
    CALL WAIT_KEY_RELEASE
    JMP  DoArm
    JMP  MenuChoice

DoSetCode:
    CALL UI_PROMPT_SET_CODE
    JMP  ShowMenu

DoArm:
    CMP  CODE_SET_FLAG, 0
    JNE  ArmOk
    CALL UI_FLASH_NO_CODE
    JMP  ShowMenu

ArmOk:
    MOV  ARMED_FLAG, 1
    CALL UI_ARMED_WARN_LOOP
    CALL UI_PROMPT_ENTER_CODE
    CMP  AL, '*'
    JE   ShowMenu
    CALL COMPARE_INP_WITH_CODE
    CMP  AL, 1
    JNE  WrongCode
    MOV  ARMED_FLAG, 0
    CALL UI_SUCCESS_DISARM
    JMP  ShowMenu
WrongCode:
    CALL UI_WRONG_CODE_BRIEF
    JMP  ArmOk

MAP_NIBBLE_TO_ASCII PROC
    PUSH BX
    CMP AL, 00H
    JE  M_1
    CMP AL, 01H
    JE  M_2
    CMP AL, 02H
    JE  M_3
    CMP AL, 04H
    JE  M_4
    CMP AL, 05H
    JE  M_5
    CMP AL, 06H
    JE  M_6
    CMP AL, 08H
    JE  M_7
    CMP AL, 09H
    JE  M_8
    CMP AL, 0AH
    JE  M_9
    CMP AL, 0DH
    JE  M_0
    CMP AL, 0CH
    JE  M_S
    CMP AL, 0EH
    JE  M_H
    XOR AL, AL
    JMP M_END
M_0: MOV AL, '0'
 JMP M_END
M_1: MOV AL, '1'
 JMP M_END
M_2: MOV AL, '2'
 JMP M_END
M_3: MOV AL, '3'
 JMP M_END
M_4: MOV AL, '4'
 JMP M_END
M_5: MOV AL, '5'
 JMP M_END
M_6: MOV AL, '6'
 JMP M_END
M_7: MOV AL, '7'
 JMP M_END
M_8: MOV AL, '8'
 JMP M_END
M_9: MOV AL, '9'
 JMP M_END
M_S: MOV AL, '*'
 JMP M_END
M_H: MOV AL, '#'
 JMP M_END
M_END:
    POP BX
    RET
MAP_NIBBLE_TO_ASCII ENDP

WAIT_FOR_PRESS_ASCII PROC
    PUSH DX
WFPA_Wait:
    MOV  DX, PORTC
    IN   AL, DX
    TEST AL, 10H
    JZ   WFPA_Wait
    IN   AL, DX
    AND  AL, 0FH
    CALL MAP_NIBBLE_TO_ASCII
    POP  DX
    RET
WAIT_FOR_PRESS_ASCII ENDP

GET_KEY_BLOCKING PROC
    PUSH DX
GKB_Wait:
    MOV  DX, PORTC
    IN   AL, DX
    TEST AL, 10H
    JZ   GKB_Wait
    IN   AL, DX
    AND  AL, 0FH
    CALL MAP_NIBBLE_TO_ASCII
    CMP  AL, 0
    JE   GKB_ReleaseTry
    MOV  BL, AL
    CALL WAIT_KEY_RELEASE
    MOV  AL, BL
    POP  DX
    RET
GKB_ReleaseTry:
    CALL WAIT_KEY_RELEASE
    JMP  GKB_Wait
GET_KEY_BLOCKING ENDP

WAIT_KEY_RELEASE PROC
    PUSH DX
WKR_L:
    MOV  DX, PORTC
    IN   AL, DX
    TEST AL, 10H
    JNZ  WKR_L
    CALL DELAY_1MS
    POP  DX
    RET
WAIT_KEY_RELEASE ENDP

IS_LONG_PRESS PROC
    PUSH BX
    PUSH DX
    MOV  BL, AL
    MOV  DX, PORTC
ILP_L:
    IN   AL, DX
    TEST AL, 10H
    JZ   ILP_NO
    IN   AL, DX
    AND  AL, 0FH
    CALL MAP_NIBBLE_TO_ASCII
    CMP  AL, BL
    JNE  ILP_NO
    CALL DELAY_1MS
    LOOP ILP_L
    MOV  AL, 1
    JMP  ILP_END
ILP_NO:
    XOR  AL, AL
ILP_END:
    POP  DX
    POP  BX
    RET
IS_LONG_PRESS ENDP

INST_CTRL:
    PUSH AX
    PUSH DX
    MOV DX, PORTA
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 02H
    OUT DX, AL
    CALL DELAY_1MS
    MOV AL, 00H
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
    MOV AL, 03H
    OUT DX, AL
    CALL DELAY_1MS
    MOV AL, 01H
    OUT DX, AL
    POP DX
    POP AX
    RET

INIT_LCD:
    MOV AL, 38H
    CALL INST_CTRL
    MOV AL, 08H
    CALL INST_CTRL
    MOV AL, 01H
    CALL INST_CTRL
    MOV AL, 06H
    CALL INST_CTRL
    MOV AL, 0CH
    CALL INST_CTRL
    RET

LCD_DISPLAY_OFF PROC
    MOV AL, 08H
    CALL INST_CTRL
    RET
LCD_DISPLAY_OFF ENDP

LCD_DISPLAY_ON PROC
    MOV AL, 0CH
    CALL INST_CTRL
    RET
LCD_DISPLAY_ON ENDP

LCD_CLEAR PROC
    MOV AL, 01H
    CALL INST_CTRL
    CALL DELAY_1MS
    CALL DELAY_1MS
    RET
LCD_CLEAR ENDP

LCD_SET_POS PROC
    PUSH AX
    MOV  AL, BL
    CMP  BH, 1
    JE   L1
    ADD  AL, 0C0H
    JMP  LGo
L1: ADD  AL, 080H
LGo:
    CALL INST_CTRL
    POP  AX
    RET
LCD_SET_POS ENDP

LCD_PRINT_AT PROC
    PUSH AX
    PUSH SI
    PUSH BX
    CALL LCD_SET_POS
LPA_L:
    LODSB
    CMP  AL, 0
    JE   LPA_E
    CALL DATA_CTRL
    JMP  LPA_L
LPA_E:
    POP  BX
    POP  SI
    POP  AX
    RET
LCD_PRINT_AT ENDP

LCD_CLEAR_LINE PROC
    PUSH SI
    PUSH BX
    MOV  BH, AL
    MOV  BL, 0
    LEA  SI, SPACES16
    CALL LCD_PRINT_AT
    POP  BX
    POP  SI
    RET
LCD_CLEAR_LINE ENDP

UI_FLASH_NO_CODE PROC
    PUSH CX
    MOV  CX, 5
UFNC_LOOP:
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_ERR_NO_CODE1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_ERR_NO_CODE2
    CALL LCD_PRINT_AT
    CALL DELAY_250MS
    CALL LCD_CLEAR
    CALL DELAY_250MS
    LOOP UFNC_LOOP
    POP  CX
    RET
UI_FLASH_NO_CODE ENDP

UI_ARMED_WARN_LOOP PROC
    PUSH CX
UA_WLOOP:
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_WARN1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_WARN2
    CALL LCD_PRINT_AT
    MOV  CX, 5
UA_POLL1:
    CALL POLL_FOR_ZERO_OR_POWER_OFF
    CMP  AL, '0'
    JE   UA_DONE
    LOOP UA_POLL1

    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_WARN3
    CALL LCD_PRINT_AT
    MOV  CX, 5
UA_POLL2:
    CALL POLL_FOR_ZERO_OR_POWER_OFF
    CMP  AL, '0'
    JE   UA_DONE
    LOOP UA_POLL2
    JMP  UA_WLOOP
UA_DONE:
    POP  CX
    RET
UI_ARMED_WARN_LOOP ENDP

POLL_FOR_ZERO_OR_POWER_OFF PROC
    PUSH CX
    PUSH DX
    MOV  CX, 100
PFZO_L:
    MOV  DX, PORTC
    IN   AL, DX
    TEST AL, 10H
    JZ   PFZO_TICK
    IN   AL, DX
    AND  AL, 0FH
    CALL MAP_NIBBLE_TO_ASCII

    CMP  AL, '#'
    JNE  PFZO_CHECK_ZERO
    MOV  CX, LP_HASH_5S
    MOV  AL, '#'
    CALL IS_LONG_PRESS
    CMP  AL, 1
    JNE  PFZO_NOT_LONG
    CALL LCD_DISPLAY_OFF
    MOV  LCD_ON_FLAG, 0
    CALL WAIT_KEY_RELEASE
    POP  DX
    POP  CX
    JMP  Standby
PFZO_NOT_LONG:
    CALL WAIT_KEY_RELEASE
    JMP  PFZO_TICK

PFZO_CHECK_ZERO:
    CMP  AL, '0'
    JE   PFZO_RET_ZERO
    CALL WAIT_KEY_RELEASE

PFZO_TICK:
    CALL DELAY_1MS
    LOOP PFZO_L
    XOR  AL, AL
    POP  DX
    POP  CX
    RET
PFZO_RET_ZERO:
    CALL WAIT_KEY_RELEASE
    MOV  AL, '0'
    POP  DX
    POP  CX
    RET
POLL_FOR_ZERO_OR_POWER_OFF ENDP

UI_PROMPT_SET_CODE PROC
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_SET1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_SET2
    CALL LCD_PRINT_AT
    MOV  INP_LEN, 0

UPS_LOOP:
    MOV  BH, 2
    MOV  BL, 1
    MOV  AL, INP_LEN
    ADD  BL, AL
    CALL LCD_SET_POS

    CALL GET_KEY_BLOCKING
    CMP  AL, '0'
    JB   UPS_NOT_DIG
    CMP  AL, '9'
    JA   UPS_NOT_DIG
    MOV  AH, INP_LEN
    CMP  AH, 8
    JAE  UPS_LOOP
    MOV  DL, AL
    MOV  AL, INP_LEN
    XOR  AH, AH
    MOV  DI, AX
    LEA  BX, INP_BUF
    MOV  [BX+DI], DL
    INC  INP_LEN
    MOV  AL, '*'
    CALL DATA_CTRL
    JMP  UPS_LOOP

UPS_NOT_DIG:
    CMP  AL, '#'
    JE   UPS_TRY_SAVE
    CMP  AL, '*'
    JE   UPS_CANCEL
    JMP  UPS_LOOP

UPS_TRY_SAVE:
    MOV  AL, INP_LEN
    CMP  AL, 4
    JB   UPS_BADLEN
    CMP  AL, 8
    JA   UPS_BADLEN
    MOV  CL, INP_LEN
    MOV  CODE_LEN, CL
    LEA  SI, INP_BUF
    LEA  DI, CODE_BUF
UPS_CP_LOOP:
    MOV  AL, [SI]
    MOV  [DI], AL
    INC  SI
    INC  DI
    DEC  CL
    JNZ  UPS_CP_LOOP
    MOV  CODE_SET_FLAG, 1
    RET

UPS_CANCEL:
    RET

UPS_BADLEN:
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_BADLEN1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_BADLEN2
    CALL LCD_PRINT_AT
    CALL DELAY_750MS
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_SET1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_SET2
    CALL LCD_PRINT_AT
    MOV  INP_LEN, 0
    JMP  UPS_LOOP
UI_PROMPT_SET_CODE ENDP

UI_PROMPT_ENTER_CODE PROC
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_ENTER1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_ENTER2
    CALL LCD_PRINT_AT
    MOV  INP_LEN, 0
UPE_LOOP:
    MOV  BH, 2
    MOV  BL, 1
    MOV  AL, INP_LEN
    ADD  BL, AL
    CALL LCD_SET_POS
    CALL GET_KEY_BLOCKING
    CMP  AL, '0'
    JB   UPE_NOT_DIG
    CMP  AL, '9'
    JA   UPE_NOT_DIG
    MOV  AH, INP_LEN
    CMP  AH, 8
    JAE  UPE_LOOP
    MOV  DL, AL
    MOV  AL, INP_LEN
    XOR  AH, AH
    MOV  DI, AX
    LEA  BX, INP_BUF
    MOV  [BX+DI], DL
    INC  INP_LEN
    MOV  AL, '*'
    CALL DATA_CTRL
    JMP  UPE_LOOP
UPE_NOT_DIG:
    CMP  AL, '#'
    JE   UPE_SUBMIT
    CMP  AL, '*'
    JE   UPE_CANCEL
    JMP  UPE_LOOP

UPE_SUBMIT:
    RET

UPE_CANCEL:
    MOV  AL, '*'
    RET
UI_PROMPT_ENTER_CODE ENDP

COMPARE_INP_WITH_CODE PROC
    XOR  AX, AX
    MOV  AL, INP_LEN
    CMP  AL, CODE_LEN
    JNE  CWC_NO
    MOV  CL, AL
    LEA  SI, INP_BUF
    LEA  DI, CODE_BUF
CWC_L:
    MOV  AL, [SI]
    CMP  AL, [DI]
    JNE  CWC_NO
    INC  SI
    INC  DI
    DEC  CL
    JNZ  CWC_L
    MOV  AL, 1
    RET
CWC_NO:
    XOR  AL, AL
    RET
COMPARE_INP_WITH_CODE ENDP

UI_WRONG_CODE_BRIEF PROC
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_WRONG1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_WRONG2
    CALL LCD_PRINT_AT
    CALL DELAY_750MS
    RET
UI_WRONG_CODE_BRIEF ENDP

UI_SUCCESS_DISARM PROC
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_OK1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_OK2
    CALL LCD_PRINT_AT
USD_WAIT:
    MOV  CX, 1500
USD_L:
    MOV  DX, PORTC
    IN   AL, DX
    TEST AL, 10H
    JZ   USD_TICK
    IN   AL, DX
    AND  AL, 0FH
    CALL MAP_NIBBLE_TO_ASCII
    CALL WAIT_KEY_RELEASE
    JMP  USD_DONE
USD_TICK:
    CALL DELAY_1MS
    LOOP USD_L
USD_DONE:
    RET
UI_SUCCESS_DISARM ENDP

DELAY_1MS:
    PUSH CX
    MOV  CX, 1EH
DLY1:
    NOP
    LOOP DLY1
    POP  CX
    RET

DELAY_250MS PROC
    PUSH CX
    MOV  CX, 250
D250_L:
    CALL DELAY_1MS
    LOOP D250_L
    POP  CX
    RET
DELAY_250MS ENDP

DELAY_750MS PROC
    PUSH CX
    MOV  CX, 750
D750_L:
    CALL DELAY_1MS
    LOOP D750_L
    POP  CX
    RET
DELAY_750MS ENDP

CODE ENDS
END START