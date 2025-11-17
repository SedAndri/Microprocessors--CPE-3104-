;====================================================================
; LCDINTERRUPT.asm - Interrupt-driven LCD marquee demo
; IR0: Toggle LCD ON/OFF
; IR1: Pause/Play the scrolling text
; IR2: Change scrolling direction (left/right)
;====================================================================

DATA SEGMENT
    ORG 03000H
    PORTA           EQU 0F0H   ; PORTA address (LCD data bus)
    PORTB           EQU 0F2H   ; PORTB address (LCD control)
    PORTC           EQU 0F4H   ; Switch inputs (optional)
    COM_REG         EQU 0F6H   ; 8255 command register
    PIC1            EQU 0F8H   ; 8259 command port (A1=0)
    PIC2            EQU 0FAH   ; 8259 data port (A1=1)
    ICW1            EQU 013H   ; edge triggered, ICW4 needed
    ICW2            EQU 080H   ; vector base 80H
    ICW4            EQU 003H   ; 8086 mode, AEOI enabled
    OCW1_MASK       EQU 0F8H   ; enable IR0-IR2
    WINDOW_WIDTH    EQU 20     ; DDRAM addresses 80H-93H (line 1)
    MODE_MAX        EQU 4      ; total scroll modes (0-3)
    LINE_COUNT      EQU 4
    NO_LINE         EQU 0FFH

    TEXT_MSG        DB ' LCD INTERRUPTS ROCK!   '
    TEXT_LEN        EQU ($ - TEXT_MSG)
    LINE_ADDRS      DB 080H,0C0H,094H,0D4H

    PROGRAM_STATE   DB 1       ; 1 = display on, 0 = off
    PAUSE_STATE     DB 0       ; 1 = paused
    MODE_INDEX      DB 0       ; scroll direction selector
    TEXT_CURSOR_FWD DB 0       ; next character from TEXT_MSG (left scroll)
    TEXT_CURSOR_REV DB 0       ; reverse cursor (right scroll)
    VERTICAL_INDEX  DB 0       ; current LCD line for vertical modes
    DISPLAY_BUFFER  DB WINDOW_WIDTH DUP(' ')
    ACTIVE_VERTICAL_INDEX DB NO_LINE
    TURN_ON_REQUEST DB 1       ; need to reinitialize LCD
    SCROLL_RESET_REQUEST DB 0  ; rebuild window after mode change
DATA ENDS

STK SEGMENT STACK
    BOS DW 64 DUP(?)           ; stack depth (bottom of stack)
    TOS LABEL WORD             ; top of stack
STK ENDS

CODE SEGMENT PUBLIC 'CODE'
ASSUME CS:CODE, DS:DATA, SS:STK
ORG 03000H

START:
    MOV AX, DATA              ; set the Data Segment address
    MOV DS, AX
    MOV AX, STK               ; set the Stack Segment address
    MOV SS, AX
    LEA SP, TOS               ; set address of SP as top of stack
    CLI                       ; clear IF during initialization
    XOR AX, AX
    MOV ES, AX                ; ES -> interrupt vector table

    ;program the 8255
    MOV DX, COM_REG
    MOV AL, 089H
    OUT DX, AL

    ;program the 8259
    MOV DX, PIC1              ; access ICW1
    MOV AL, ICW1
    OUT DX, AL
    MOV DX, PIC2              ; access ICW2/ICW4/OCW1
    MOV AL, ICW2
    OUT DX, AL
    MOV AL, ICW4
    OUT DX, AL
    MOV AL, OCW1_MASK
    OUT DX, AL

    ;install interrupt vectors (80H, 81H, 82H)
    MOV AX, OFFSET ISR_POWER
    MOV [ES:200H], AX
    MOV AX, SEG ISR_POWER
    MOV [ES:202H], AX
    MOV AX, OFFSET ISR_PAUSE
    MOV [ES:204H], AX
    MOV AX, SEG ISR_PAUSE
    MOV [ES:206H], AX
    MOV AX, OFFSET ISR_MODE
    MOV [ES:208H], AX
    MOV AX, SEG ISR_MODE
    MOV [ES:20AH], AX

    STI                       ; enable INTR pin of 8086

;----------------------------------------
; Foreground loop
;----------------------------------------

MAIN:
    CMP TURN_ON_REQUEST, 0    ; LCD reinitialization needed?
    JE SKIP_RESET
    MOV TURN_ON_REQUEST, 0
    CALL RESET_LCD_STATE

SKIP_RESET:
    CMP SCROLL_RESET_REQUEST, 0
    JE SKIP_SCROLL_RESET
    MOV SCROLL_RESET_REQUEST, 0
    CALL CLEAR_LCD_LINES
    CALL RESET_SCROLL_WINDOW
    CALL DISPLAY_FRAME

SKIP_SCROLL_RESET:
    CMP PROGRAM_STATE, 0
    JE LCD_OFF_LOOP

    CMP PAUSE_STATE, 0
    JNE PAUSE_LOOP

    CALL DISPLAY_FRAME        ; draw Line 1 window
    CALL ADVANCE_SCROLL       ; shift characters based on MODE_INDEX
    CALL FRAME_DELAY          ; pacing delay for scrolling
    JMP MAIN

LCD_OFF_LOOP:
    CALL DISPLAY_OFF          ; keep LCD dark while off
WAIT_POWER_ON:
    CALL DELAY_1MS
    CMP PROGRAM_STATE, 0
    JE WAIT_POWER_ON
    MOV TURN_ON_REQUEST, 1
    JMP MAIN

PAUSE_LOOP:
    CALL DELAY_1MS
    CMP PROGRAM_STATE, 0
    JE LCD_OFF_LOOP
    CMP PAUSE_STATE, 0
    JNE PAUSE_LOOP
    JMP MAIN

;----------------------------------------
; LCD helper routines
;----------------------------------------

RESET_LCD_STATE PROC NEAR
    CALL INIT_LCD             ; configure LCD hardware
    CALL RESET_SCROLL_WINDOW
    CALL DISPLAY_FRAME
    RET
RESET_LCD_STATE ENDP

DISPLAY_OFF PROC NEAR
    MOV AL, 08H              ; display off, cursor off, blink off
    CALL INST_CTRL
    RET
DISPLAY_OFF ENDP

DISPLAY_ON PROC NEAR
    MOV AL, 0CH              ; display on, cursor off, blink off
    CALL INST_CTRL
    RET
DISPLAY_ON ENDP

DISPLAY_FRAME PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV AL, MODE_INDEX
    CMP AL, 2
    JB HORIZONTAL_LINE

    MOV DL, VERTICAL_INDEX
    MOV AH, ACTIVE_VERTICAL_INDEX
    CMP AH, NO_LINE
    JE NO_PREV_LINE
    CMP AH, DL
    JE NO_PREV_LINE
    MOV AL, AH
    CALL CLEAR_LINE_BY_INDEX ; remove previous vertical row
NO_PREV_LINE:
    MOV ACTIVE_VERTICAL_INDEX, DL
    MOV BL, DL
    XOR BH, BH
    MOV AL, LINE_ADDRS[BX]   ; choose current LCD line address
    JMP SET_LINE_ADDR

HORIZONTAL_LINE:
    MOV ACTIVE_VERTICAL_INDEX, NO_LINE
    MOV AL, 080H             ; Line 1 Column 0 (80H)

SET_LINE_ADDR:
    CALL INST_CTRL
    ; MOV AL, 0CAH ; Middle Column Middle Row Line 1 (80H-93H), Line 2 (C0H-D3H), Line 3 (94H-A7H), Line 4 (D4H-E7H)
    ; CALL INST_CTRL ; write instruction to LCD

    MOV CX, WINDOW_WIDTH
    LEA SI, DISPLAY_BUFFER

FRAME_LOOP:
    LODSB
    CALL DATA_CTRL
    LOOP FRAME_LOOP

    POP SI
    POP DX
    POP CX
    POP AX
    RET
DISPLAY_FRAME ENDP

ADVANCE_SCROLL PROC NEAR
    MOV AL, MODE_INDEX
    CMP AL, 0
    JE SCROLL_LEFT
    CMP AL, 1
    JE SCROLL_RIGHT
    CMP AL, 2
    JE SCROLL_DOWN
    CMP AL, 3
    JE SCROLL_UP
    XOR AL, AL
    MOV MODE_INDEX, AL
    RET

SCROLL_LEFT:
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI

    MOV CX, WINDOW_WIDTH - 1 ; shift buffer toward lower DDRAM addresses
    LEA SI, DISPLAY_BUFFER + 1
    LEA DI, DISPLAY_BUFFER

SHIFT_LEFT_LOOP:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP SHIFT_LEFT_LOOP

    CALL FETCH_NEXT_CHAR
    MOV DISPLAY_BUFFER + WINDOW_WIDTH - 1, AL

    POP DI
    POP SI
    POP CX
    POP AX
    RET

SCROLL_RIGHT:
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI

    MOV CX, WINDOW_WIDTH - 1 ; shift buffer toward higher DDRAM addresses
    LEA SI, DISPLAY_BUFFER + WINDOW_WIDTH - 2
    LEA DI, DISPLAY_BUFFER + WINDOW_WIDTH - 1

SHIFT_RIGHT_LOOP:
    MOV AL, [SI]
    MOV [DI], AL
    DEC SI
    DEC DI
    LOOP SHIFT_RIGHT_LOOP

    CALL FETCH_PREV_CHAR
    MOV DISPLAY_BUFFER, AL

    POP DI
    POP SI
    POP CX
    POP AX
    RET

SCROLL_DOWN:
    MOV AL, VERTICAL_INDEX
    INC AL
    CMP AL, LINE_COUNT
    JB STORE_VERTICAL
    XOR AL, AL
STORE_VERTICAL:
    MOV VERTICAL_INDEX, AL
    RET

SCROLL_UP:
    MOV AL, VERTICAL_INDEX
    OR AL, AL
    JNE DEC_VERTICAL
    MOV AL, LINE_COUNT
DEC_VERTICAL:
    DEC AL
    MOV VERTICAL_INDEX, AL
    RET
ADVANCE_SCROLL ENDP

FRAME_DELAY PROC NEAR
    MOV CX, 0001H            ; coarse delay between frames
FRAME_WAIT:
    CALL DELAY_1MS
    LOOP FRAME_WAIT
    RET
FRAME_DELAY ENDP

INST_CTRL PROC NEAR
    PUSH AX                  ; preserve AL
    MOV DX, PORTA
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 02H              ; E=1, RS=0 (instruction register)
    OUT DX, AL
    CALL DELAY_1MS
    MOV DX, PORTB
    MOV AL, 00H              ; E=0, RS=0
    OUT DX, AL
    POP AX
    RET
INST_CTRL ENDP

DATA_CTRL PROC NEAR
    PUSH AX
    MOV DX, PORTA
    OUT DX, AL
    MOV DX, PORTB
    MOV AL, 03H              ; E=1, RS=1 (data register)
    OUT DX, AL
    CALL DELAY_1MS
    MOV DX, PORTB
    MOV AL, 01H              ; E=0, RS=1
    OUT DX, AL
    POP AX
    RET
DATA_CTRL ENDP

INIT_LCD PROC NEAR
    MOV AL, 038H             ; 8-bit interface, 2 lines
    CALL INST_CTRL
    MOV AL, 008H             ; display off
    CALL INST_CTRL
    MOV AL, 001H             ; clear display
    CALL INST_CTRL
    MOV AL, 006H             ; entry mode increment, shift off
    CALL INST_CTRL
    MOV AL, 00CH             ; display on, cursor off
    CALL INST_CTRL
    RET
INIT_LCD ENDP

DELAY_1MS PROC NEAR
    MOV BX, 02CAH
DL1:
    DEC BX
    NOP
    JNZ DL1
    RET
DELAY_1MS ENDP

RESET_SCROLL_WINDOW PROC NEAR
    CALL CLEAR_DISPLAY_BUFFER
    MOV TEXT_CURSOR_FWD, 0
    MOV TEXT_CURSOR_REV, 0
    MOV ACTIVE_VERTICAL_INDEX, NO_LINE
    MOV AL, MODE_INDEX
    CMP AL, 2
    JB RSW_EXIT             ; horizontal modes start empty
    CALL LOAD_FULL_LINE
    CMP AL, 2
    JE SET_DOWN_INDEX
    MOV VERTICAL_INDEX, LINE_COUNT - 1
    JMP RSW_EXIT
SET_DOWN_INDEX:
    XOR AL, AL
    MOV VERTICAL_INDEX, AL
RSW_EXIT:
    RET
RESET_SCROLL_WINDOW ENDP

CLEAR_DISPLAY_BUFFER PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DI
    MOV AL, ' '
    MOV CX, WINDOW_WIDTH
    LEA DI, DISPLAY_BUFFER

CLEAR_LOOP:
    MOV [DI], AL
    INC DI
    LOOP CLEAR_LOOP

    POP DI
    POP CX
    POP AX
    RET
CLEAR_DISPLAY_BUFFER ENDP

CLEAR_LCD_LINES PROC NEAR
    PUSH AX
    MOV AL, 0

CLEAR_LINES_LOOP:
    CMP AL, LINE_COUNT
    JAE CLEAR_DONE
    CALL CLEAR_LINE_BY_INDEX
    INC AL
    JMP CLEAR_LINES_LOOP

CLEAR_DONE:
    POP AX
    RET
CLEAR_LCD_LINES ENDP

CLEAR_LINE_BY_INDEX PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV BL, AL
    XOR BH, BH
    MOV AL, LINE_ADDRS[BX]
    CALL INST_CTRL
    MOV CX, WINDOW_WIDTH
    MOV AL, ' '

CLEAR_LINE_FILL:
    CALL DATA_CTRL
    LOOP CLEAR_LINE_FILL

    POP DX
    POP CX
    POP BX
    POP AX
    RET
CLEAR_LINE_BY_INDEX ENDP

LOAD_FULL_LINE PROC NEAR
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    MOV CX, WINDOW_WIDTH
    XOR SI, SI
    LEA DI, DISPLAY_BUFFER

FILL_LINE:
    MOV AL, TEXT_MSG[SI]
    STOSB
    INC SI
    CMP SI, TEXT_LEN
    JB CONT_FILL
    XOR SI, SI
CONT_FILL:
    LOOP FILL_LINE

    POP DI
    POP SI
    POP CX
    POP AX
    RET
LOAD_FULL_LINE ENDP

FETCH_NEXT_CHAR PROC NEAR
    PUSH BX
    MOV BL, TEXT_CURSOR_FWD
    XOR BH, BH
    CMP BX, TEXT_LEN
    JB HAVE_INDEX
    XOR BX, BX
HAVE_INDEX:
    MOV AL, TEXT_MSG[BX]
    INC BX
    CMP BX, TEXT_LEN
    JB STORE_CURSOR
    XOR BX, BX
STORE_CURSOR:
    MOV TEXT_CURSOR_FWD, BL
    POP BX
    RET
FETCH_NEXT_CHAR ENDP

FETCH_PREV_CHAR PROC NEAR
    PUSH BX
    MOV BL, TEXT_CURSOR_REV
    XOR BH, BH
    CMP BX, 0
    JNE HAVE_REV_INDEX
    MOV BX, TEXT_LEN
HAVE_REV_INDEX:
    DEC BX
    MOV AL, TEXT_MSG[BX]
    MOV TEXT_CURSOR_REV, BL
    POP BX
    RET
FETCH_PREV_CHAR ENDP

;----------------------------------------
; Interrupt service routines
;----------------------------------------

ISR_POWER PROC FAR           ; IR0 - toggle LCD ON/OFF
    PUSHF
    PUSH AX
    PUSH DX
    PUSH DS
    MOV AX, DATA
    MOV DS, AX
    MOV AL, PROGRAM_STATE
    XOR AL, 1
    MOV PROGRAM_STATE, AL
    CMP AL, 0
    JNE POWER_ON
    MOV PAUSE_STATE, 0       ; clear pause when powering down
    JMP POWER_DONE
POWER_ON:
    MOV TURN_ON_REQUEST, 1   ; request LCD reinit on resume
POWER_DONE:
    POP DS
    POP DX
    POP AX
    POPF
    IRET
ISR_POWER ENDP

ISR_PAUSE PROC FAR           ; IR1 - pause/play scrolling
    PUSHF
    PUSH AX
    PUSH DS
    MOV AX, DATA
    MOV DS, AX
    CMP PROGRAM_STATE, 0
    JE PAUSE_EXIT
    MOV AL, PAUSE_STATE
    XOR AL, 1
    MOV PAUSE_STATE, AL
PAUSE_EXIT:
    POP DS
    POP AX
    POPF
    IRET
ISR_PAUSE ENDP

ISR_MODE PROC FAR            ; IR2 - change scroll direction
    PUSHF
    PUSH AX
    PUSH DS
    MOV AX, DATA
    MOV DS, AX
    CMP PROGRAM_STATE, 0
    JE MODE_EXIT
    MOV AL, MODE_INDEX
    INC AL
    CMP AL, MODE_MAX
    JB STORE_MODE
    XOR AL, AL
STORE_MODE:
    MOV MODE_INDEX, AL
    MOV SCROLL_RESET_REQUEST, 1 ; rebuild window next loop
MODE_EXIT:
    POP DS
    POP AX
    POPF
    IRET
ISR_MODE ENDP

;----------------------------------------
; END OF PROGRAM
;----------------------------------------

CODE ENDS
END START