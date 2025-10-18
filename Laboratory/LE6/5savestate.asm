;====================================================================
; AccessControl.asm
; Processor: 8086, Assembler: MASM
; Hardware: 8255 (PA: LCD data, PB: LCD control [E,RS], PC: keypad + DAVBL on PC4)
;====================================================================

DATA SEGMENT
    PORTA   EQU 0F0H      ; 8255 PORT A (LCD data)
    PORTB   EQU 0F2H      ; 8255 PORT B (LCD control)
    PORTC   EQU 0F4H      ; 8255 PORT C (keypad + DAVBL on PC4)
    COM_REG EQU 0F6H      ; 8255 Control Register

    ; Long-press thresholds (milliseconds)
    LP_STAR_3S  EQU 3000
    LP_HASH_5S  EQU 5000

    ; State/flags
    LCD_ON_FLAG   DB 0
    CODE_SET_FLAG DB 0
    ARMED_FLAG    DB 0

    ; Code storage
    CODE_LEN   DB 0
    CODE_BUF   DB 8 DUP(?)

    ; Temp input buffer
    INP_LEN    DB 0
    INP_BUF    DB 8 DUP(?)

    ; UI strings (null-terminated)
    STR_MAIN1      DB 'MAIN MENU',0
    STR_MAIN2      DB '1:Set  2:Arm ?',0

    STR_ERR_NO_CODE1 DB 'ERROR:',0
    STR_ERR_NO_CODE2 DB 'No code set!',0

    STR_WARN1      DB 'WARNING:',0
    STR_WARN2      DB 'System ARMED',0
    STR_WARN3      DB '0 to disarm',0

    STR_SET1       DB 'Input AccessCode',0  ; 16 chars
    STR_SET2       DB '[        ]  #=set',0

    STR_BADLEN1    DB 'Invalid length',0
    STR_BADLEN2    DB 'Use 4..8 digits',0

    STR_ENTER1     DB 'Enter AccessCode',0
    STR_ENTER2     DB '[        ]  #=ok',0

    STR_WRONG1     DB 'WRONG CODE!',0
    STR_WRONG2     DB 'Still ARMED',0

    STR_OK1        DB 'SUCCESS:',0
    STR_OK2        DB 'Disarmed! Press #',0

    SPACES16       DB '                ',0  ; 16 spaces
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA

START:
    ; init DS
    MOV AX, DATA
    MOV DS, AX

    ; Program 8255: PA=out, PB=out, PC upper=in, PC lower=in (Mode 0)
    MOV DX, COM_REG
    MOV AL, 089H
    OUT DX, AL

    ; Init LCD then start powered-off (display off)
    CALL INIT_LCD
    ;CALL LCD_DISPLAY_OFF              ; disabled for testing
    CALL LCD_DISPLAY_ON                ; force ON for testing
    MOV  LCD_ON_FLAG, 1                ; force ON
    MOV  CODE_SET_FLAG, 0
    MOV  ARMED_FLAG, 0
    JMP  ShowMenu                      ; skip Standby/hold logic

MainLoop:
    ; Standby (LCD off) -> wait for '*' long-press (3s) to power on
Standby:
    ; disabled hold-to-wake for testing
    JMP  ShowMenu
    CMP  LCD_ON_FLAG, 0
    JNE  ShowMenu
WaitWake:
    CALL WAIT_FOR_PRESS_ASCII   ; returns AL = ascii of pressed key (does not wait release)
    CMP  AL, '*'
    JNE  CheckHashOff_WhileOff
    ; Check 3s long-press on '*'
    MOV  CX, LP_STAR_3S
    CALL IS_LONG_PRESS          ; AL=1 if sustained
    CMP  AL, 1
    JNE  ReleaseAndWaitWake
    ; Power ON
    CALL LCD_DISPLAY_ON
    CALL LCD_CLEAR
    MOV  LCD_ON_FLAG, 1
    JMP  ShowMenu
CheckHashOff_WhileOff:
    CMP  AL, '#'
    JNE  ReleaseAndWaitWake
    MOV  CX, LP_HASH_5S         ; Ignore (already off), just consume
    CALL IS_LONG_PRESS
ReleaseAndWaitWake:
    CALL WAIT_KEY_RELEASE
    JMP  WaitWake

; --- Main menu ---
ShowMenu:
    CALL LCD_CLEAR
    ; Line 1 centered-ish
    MOV  BH, 1
    MOV  BL, 3
    LEA  SI, STR_MAIN1
    CALL LCD_PRINT_AT
    ; Line 2
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_MAIN2
    CALL LCD_PRINT_AT

MenuChoice:
    CALL GET_KEY_BLOCKING       ; AL = ascii
    JMP  CheckMenuChoice        ; go handle '1' or '2' (ignore '#' elsewhere)
; If you want long-press '#' power-off later, do it in a polling context
; where the key is still held (WAIT_FOR_PRESS_ASCII + IS_LONG_PRESS), not
; after GET_KEY_BLOCKING which already waited for release.

CheckMenuChoice:
    CMP  AL, '1'
    JE   DoSetCode
    CMP  AL, '2'
    JE   DoArm
    JMP  MenuChoice

; --- Set code flow ---
DoSetCode:
    CALL UI_PROMPT_SET_CODE     ; sets CODE_SET_FLAG if OK
    JMP  ShowMenu

; --- Arm flow ---
DoArm:
    CMP  CODE_SET_FLAG, 0
    JNE  ArmOk
    ; Flash error: no code set
    CALL UI_FLASH_NO_CODE
    JMP  ShowMenu

ArmOk:
    MOV  ARMED_FLAG, 1
    CALL UI_ARMED_WARN_LOOP     ; returns when '0' pressed
    ; After '0' pressed -> prompt for code
    CALL UI_PROMPT_ENTER_CODE
    ; allow cancel back to menu with '*'
    CMP  AL, '*'
    JE   ShowMenu
    ; Compare with saved code
    CALL COMPARE_INP_WITH_CODE  ; AL=1 if match
    CMP  AL, 1
    JNE  WrongCode
    ; Success: disarm and show success message until short '#'
    MOV  ARMED_FLAG, 0
    CALL UI_SUCCESS_DISARM
    JMP  ShowMenu
WrongCode:
    ; Show wrong code notice briefly, then return to flashing warn loop
    CALL UI_WRONG_CODE_BRIEF
    JMP  ArmOk

; ---------------- Subroutines ----------------

; Map lower-nibble to ASCII (AL in -> AL out, 0 if unknown)
MAP_NIBBLE_TO_ASCII PROC
    PUSH BX
    CMP AL, 00H     ; '1'
    JE  M_1
    CMP AL, 01H     ; '2'
    JE  M_2
    CMP AL, 02H     ; '3'
    JE  M_3
    CMP AL, 04H     ; '4'
    JE  M_4
    CMP AL, 05H     ; '5'
    JE  M_5
    CMP AL, 06H     ; '6'
    JE  M_6
    CMP AL, 08H     ; '7'
    JE  M_7
    CMP AL, 09H     ; '8'
    JE  M_8
    CMP AL, 0AH     ; '9'
    JE  M_9
    CMP AL, 0DH     ; '0'
    JE  M_0
    CMP AL, 0CH     ; '*'
    JE  M_S
    CMP AL, 0EH     ; '#'
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

; Wait until DAVBL=1 then return current ASCII in AL (do not wait release)
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

; Wait for key press, decode ASCII, then wait release (debounced). AL=ascii
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

; Wait for DAVBL to go low (key release) + small debounce
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

; Check that the currently pressed key remains held for CX ms
; Input:  expected ASCII in AL, threshold in CX
; Output: AL=1 if sustained for full duration, AL=0 otherwise (returns early on change/release)
IS_LONG_PRESS PROC
    PUSH BX
    PUSH DX
    MOV  BL, AL             ; expected ascii
    MOV  DX, PORTC
ILP_L:
    ; still pressed?
    IN   AL, DX
    TEST AL, 10H
    JZ   ILP_NO
    ; same key?
    IN   AL, DX
    AND  AL, 0FH
    CALL MAP_NIBBLE_TO_ASCII
    CMP  AL, BL
    JNE  ILP_NO
    ; 1ms tick
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

; -------------- LCD low-level --------------

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
    ; extra settling
    CALL DELAY_1MS
    CALL DELAY_1MS
    RET
LCD_CLEAR ENDP

; Set cursor by (BH=line 1..2, BL=col 0..15)
LCD_SET_POS PROC
    PUSH AX
    MOV  AL, BL
    CMP  BH, 1
    JE   L1
    ADD  AL, 0C0H        ; line 2 base
    JMP  LGo
L1: ADD  AL, 080H        ; line 1 base
LGo:
    CALL INST_CTRL
    POP  AX
    RET
LCD_SET_POS ENDP

; Print null-terminated string at (BH,BL)
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

; Print 16 spaces on given line
LCD_CLEAR_LINE PROC
    PUSH SI
    PUSH BX
    MOV  BH, AL          ; AL=line
    MOV  BL, 0
    LEA  SI, SPACES16
    CALL LCD_PRINT_AT
    POP  BX
    POP  SI
    RET
LCD_CLEAR_LINE ENDP

; -------------- UI helpers --------------

; Flash "no code" error a few times
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

; Arming warning flashing; returns when '0' pressed
UI_ARMED_WARN_LOOP PROC
    PUSH CX
UA_WLOOP:
    ; show message
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_WARN1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_WARN2
    CALL LCD_PRINT_AT
    ; poll ~500ms for '0'
    MOV  CX, 5
UA_POLL1:
    CALL POLL_FOR_ZERO_OR_POWER_OFF
    CMP  AL, '0'
    JE   UA_DONE
    LOOP UA_POLL1

    ; show prompt line
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_WARN3
    CALL LCD_PRINT_AT
    ; poll ~500ms again
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

; Poll 100ms chunks x1 (returns AL='0' if got zero, or 0 otherwise)
; Also handles long-press '#' to power off (returns to Standby immediately)
POLL_FOR_ZERO_OR_POWER_OFF PROC
    PUSH CX
    PUSH DX
    MOV  CX, 100
PFZO_L:
    ; Is a key pressed?
    MOV  DX, PORTC
    IN   AL, DX
    TEST AL, 10H
    JZ   PFZO_TICK
    ; read ascii
    IN   AL, DX
    AND  AL, 0FH
    CALL MAP_NIBBLE_TO_ASCII
    ; disable '#' long-press power-off during testing
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

; Prompt to set code (4..8 digits, '#' to save)
UI_PROMPT_SET_CODE PROC
    ; Draw UI
    CALL LCD_CLEAR
    MOV  BH, 1
    MOV  BL, 0
    LEA  SI, STR_SET1
    CALL LCD_PRINT_AT
    MOV  BH, 2
    MOV  BL, 0
    LEA  SI, STR_SET2
    CALL LCD_PRINT_AT
    ; init buffer
    MOV  INP_LEN, 0

UPS_LOOP:
    ; Place cursor at bracket start col=1 on line 2 + current len
    MOV  BH, 2
    MOV  BL, 1
    MOV  AL, INP_LEN
    ADD  BL, AL
    CALL LCD_SET_POS

    CALL GET_KEY_BLOCKING
    ; digits?
    CMP  AL, '0'
    JB   UPS_NOT_DIG
    CMP  AL, '9'
    JA   UPS_NOT_DIG
    ; max 8
    MOV  AH, INP_LEN
    CMP  AH, 8
    JAE  UPS_LOOP
    ; store digit (DL = digit, DI = INP_LEN)
    MOV  DL, AL
    MOV  AL, INP_LEN
    XOR  AH, AH              ; FIX: make AX = 00LL
    MOV  DI, AX
    LEA  BX, INP_BUF
    MOV  [BX+DI], DL
    INC  INP_LEN
    ; show '*'
    MOV  AL, '*'
    CALL DATA_CTRL
    JMP  UPS_LOOP

UPS_NOT_DIG:
    ; '#' => attempt save
    CMP  AL, '#'
    JE   UPS_TRY_SAVE
    ; '*' => cancel set-code, return to menu
    CMP  AL, '*'
    JE   UPS_CANCEL
    JMP  UPS_LOOP

UPS_TRY_SAVE:
    ; Validate length 4..8
    MOV  AL, INP_LEN
    CMP  AL, 4
    JB   UPS_BADLEN
    CMP  AL, 8
    JA   UPS_BADLEN
    ; Save to CODE_BUF/CODE_LEN
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
    ; brief notice then redraw UI
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
    ; redraw
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

; Prompt to enter code into INP_BUF/INP_LEN (same rules, '#' to submit)
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
    ; digits
    CMP  AL, '0'
    JB   UPE_NOT_DIG
    CMP  AL, '9'
    JA   UPE_NOT_DIG
    MOV  AH, INP_LEN
    CMP  AH, 8
    JAE  UPE_LOOP
    MOV  DL, AL
    MOV  AL, INP_LEN
    XOR  AH, AH              ; FIX: avoid DI = 0xLLLL
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
    ; signal cancel to caller
    MOV  AL, '*'
    RET
UI_PROMPT_ENTER_CODE ENDP

; Compare INP vs CODE (exact match). AL=1 if equal, else 0
COMPARE_INP_WITH_CODE PROC
    XOR  AX, AX
    MOV  AL, INP_LEN
    CMP  AL, CODE_LEN
    JNE  CWC_NO
    MOV  CL, AL
    ; fix: compare using SI/DI pointers (avoid [DI+SI])
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

; Show wrong code briefly
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

; Success -> disarmed, wait for short '#'
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
    ; Return to menu on any key or after ~1.5s
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
    ; accept any key as confirm
    JMP  USD_DONE
USD_TICK:
    CALL DELAY_1MS
    LOOP USD_L
USD_DONE:
    RET
UI_SUCCESS_DISARM ENDP

; ------------ Delays ------------

DELAY_1MS:
    ; Simple approximate delay (adjust CX for your clock)
    PUSH CX
    MOV  CX, 64H  ; former 2CAH
DLY1:
    NOP
    LOOP DLY1
    POP  CX
    RET

DELAY_250MS PROC
    PUSH CX
    MOV  CX, 100 ;adj
D250_L:
    CALL DELAY_1MS
    LOOP D250_L
    POP  CX
    RET
DELAY_250MS ENDP

DELAY_750MS PROC
    PUSH CX
    MOV  CX, 300    ;adj
D750_L:
    CALL DELAY_1MS
    LOOP D750_L
    POP  CX
    RET
DELAY_750MS ENDP

CODE ENDS
END START