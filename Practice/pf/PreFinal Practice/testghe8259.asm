
;====================================================================
; testghe8259.asm rewritten with LE7_1-style comments and 8259 control
; Processor: 8086
; Compiler:  MASM32
;====================================================================

DATA SEGMENT
   ORG 03000H
   PORTA      EQU 0F8H ; 8255 #1, port A (red LEDs)
   PORTB      EQU 0FAH ; 8255 #1, port B (blue LEDs)
   PORTC      EQU 0FCH ; 8255 #1, port C (switch inputs)
   PORT_CON   EQU 0FEH ; 8255 #1, control register
   PA         EQU 0E8H ; 8255 #2, port A (yellow LEDs)
   PB         EQU 0EAH ; 8255 #2, port B (unused)
   PC2        EQU 0ECH ; 8255 #2, port C (unused)
   P_CON      EQU 0EEH ; 8255 #2, control register
   PIC1       EQU 0F8H ; 8259 command port (A1 = 0)
   PIC2       EQU 0FAH ; 8259 data port (A1 = 1)
   ICW1       EQU 013H ; edge triggered, ICW4 required
   ICW2       EQU 080H ; vector base 80H
   ICW4       EQU 003H ; 8086 mode with AEOI
   OCW1_MASK  EQU 0F8H ; enable IR0-IR2 only
   MAX_PATTERNS EQU 2   ; forward + reverse sequences
   PROGRAM_STATE   DB 1 ; 1 = running, 0 = off
   PAUSE_STATE     DB 0 ; 1 = paused
   PATTERN_INDEX   DB 0 ; 0 = forward, 1 = reverse
   PATTERN_REQUEST DB 1 ; flag to break out of pattern
   TURN_ON_REQUEST DB 1 ; flash request when resuming
DATA ENDS

STK SEGMENT STACK
   BOS DW 80 DUP(?) ; stack storage
   TOS LABEL WORD   ; top of stack label
STK ENDS

CODE SEGMENT PUBLIC 'CODE'
   ASSUME CS:CODE, DS:DATA, SS:STK
   ORG 08000H
START:
    MOV AX, DATA           ; set the Data Segment address
    MOV DS, AX
    MOV AX, STK            ; set the Stack Segment address
    MOV SS, AX
    LEA SP, TOS            ; initialize stack pointer
    CLI                    ; block maskable interrupts during setup
    XOR AX, AX             ; prepare zero for ES
    MOV ES, AX             ; ES -> interrupt vector table

    ;program the 8255 devices
    MOV DX, PORT_CON       ; select control register of first 8255
    MOV AL, 089H           ; ports A/B/C as output
    OUT DX, AL
    MOV DX, P_CON          ; select control register of second 8255
    MOV AL, 089H
    OUT DX, AL

    ;program the 8259
    MOV DX, PIC1           ; ICW1 port
    MOV AL, ICW1
    OUT DX, AL
    MOV DX, PIC2           ; ICW2/ICW4/OCW1 port
    MOV AL, ICW2
    OUT DX, AL
    MOV AL, ICW4
    OUT DX, AL
    MOV AL, OCW1_MASK
    OUT DX, AL

    ;install interrupt vectors (80H on/off, 81H pause, 82H pattern)
    MOV AX, OFFSET ISR_ONOFF ; offset address of ISR_ONOFF
    MOV [ES:200H], AX        ; store at vector 80H (offset)
    MOV AX, SEG ISR_ONOFF    ; segment address of ISR_ONOFF
    MOV [ES:202H], AX        ; store at vector 80H (segment)
    MOV AX, OFFSET ISR_PAUSE
    MOV [ES:204H], AX        ; vector 81H offset
    MOV AX, SEG ISR_PAUSE
    MOV [ES:206H], AX        ; vector 81H segment
    MOV AX, OFFSET ISR_PATTERN
    MOV [ES:208H], AX        ; vector 82H offset
    MOV AX, SEG ISR_PATTERN
    MOV [ES:20AH], AX        ; vector 82H segment

    STI                    ; enable maskable interrupts

;foreground routine
MAIN:
    CMP TURN_ON_REQUEST, 0  ; pending flash request?
    JE MAIN_RUN_CHECK
    MOV TURN_ON_REQUEST, 0  ; clear request
    CALL TURNON             ; flash all LEDs briefly

MAIN_RUN_CHECK:
    CMP PROGRAM_STATE, 0    ; powered off?
    JNE RUNNING
    CALL TURNOFF            ; guarantee LEDs are off
WAIT_FOR_ON:
    CALL DELAY_1MS          ; idle until ON interrupt
    CMP PROGRAM_STATE, 0
    JE WAIT_FOR_ON
    MOV PATTERN_REQUEST, 1  ; restart pattern after power on
    JMP MAIN

RUNNING:
    CMP PAUSE_STATE, 0      ; pause engaged?
    JNE PAUSE_LOOP
    MOV AL, PATTERN_INDEX   ; choose pattern set
    CMP AL, 0
    JE ROTATE
    CMP AL, 1
    JE ROTATE_REVERSE
    MOV PATTERN_INDEX, 0    ; recover from invalid index
    JMP ROTATE

PAUSE_LOOP:
    CALL DELAY_1MS          ; small delay while paused
    CMP PROGRAM_STATE, 0
    JE MAIN
    CMP PAUSE_STATE, 0
    JNE PAUSE_LOOP
    JMP MAIN

; TURN ALL ON
TURNON PROC NEAR
    MOV DX, PORTB           ; blue LEDs
    MOV AL, 0FFH
    OUT DX, AL
    MOV DX, PORTA           ; red LEDs
    MOV AL, 0FFH
    OUT DX, AL
    MOV DX, PA              ; yellow LEDs
    MOV AL, 0FFH
    OUT DX, AL
    CALL DELAY_1MS          ; hold for visibility
    RET
TURNON ENDP

; TURN ALL OFF
TURNOFF PROC NEAR
    MOV DX, PORTB
    MOV AL, 00H
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00H
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00H
    OUT DX, AL
    CALL DELAY_1MS          ; allow hardware to settle
    RET
TURNOFF ENDP

; ROTATE PATTERN (forward order taken from original COUNT_SEG)
ROTATE:
    MOV PATTERN_REQUEST, 0  ; clear break flag
FWD_STEP1:
    MOV DX, PORTB
    MOV AL, 00000011B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00000001B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
FWD_STEP2:
    MOV DX, PORTB
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00000010B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00000011B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
FWD_STEP3:
    MOV DX, PORTB
    MOV AL, 00001100B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00000100B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
FWD_STEP4:
    MOV DX, PORTB
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00001000B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00001100B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
FWD_STEP5:
    MOV DX, PORTB
    MOV AL, 00110000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00010000B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
FWD_STEP6:
    MOV DX, PORTB
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00100000B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00110000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
FWD_STEP7:
    MOV DX, PORTB
    MOV AL, 11000000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 01000000B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
FWD_STEP8:
    MOV DX, PORTB
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 10000000B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 11000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
    CMP PATTERN_INDEX, 0
    JE ROTATE
    JMP ROTATE_REVERSE

; ROTATE PATTERN (reverse order)
ROTATE_REVERSE:
    MOV PATTERN_REQUEST, 0
REV_STEP8:
    MOV DX, PORTB
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 10000000B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 11000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP7:
    MOV DX, PORTB
    MOV AL, 11000000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 01000000B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP6:
    MOV DX, PORTB
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00100000B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00110000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP5:
    MOV DX, PORTB
    MOV AL, 00110000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00010000B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP4:
    MOV DX, PORTB
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00001000B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00001100B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP3:
    MOV DX, PORTB
    MOV AL, 00001100B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00000100B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP2:
    MOV DX, PORTB
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00000010B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00000011B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP1:
    MOV DX, PORTB
    MOV AL, 00000011B
    OUT DX, AL
    MOV DX, PORTA
    MOV AL, 00000001B
    OUT DX, AL
    MOV DX, PA
    MOV AL, 00000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
    CMP PATTERN_INDEX, 1
    JE ROTATE_REVERSE
    JMP ROTATE

;----------------------------------------
; Subroutines
;----------------------------------------
PATTERN_WAIT PROC NEAR
WAIT_LOOP:
    CMP PROGRAM_STATE, 0     ; exit if powered off
    JE PATTERN_WAIT_EXIT
    CMP PATTERN_REQUEST, 0   ; break when ISR requested
    JNE PATTERN_WAIT_EXIT
    CMP PAUSE_STATE, 0       ; stay here while paused
    JE DO_DELAY
PAUSED_STATE:
    CALL DELAY_1MS
    CMP PROGRAM_STATE, 0
    JE PATTERN_WAIT_EXIT
    CMP PATTERN_REQUEST, 0
    JNE PATTERN_WAIT_EXIT
    CMP PAUSE_STATE, 0
    JNE PAUSED_STATE
DO_DELAY:
    CALL DELAY_1MS           ; baseline timing between steps
PATTERN_WAIT_EXIT:
    RET
PATTERN_WAIT ENDP

CHECK_PATTERN_ABORT PROC NEAR
    CMP PROGRAM_STATE, 0
    JE EXIT_TO_MAIN
    CMP PATTERN_REQUEST, 0
    JNE EXIT_TO_MAIN
    RET
EXIT_TO_MAIN:
    JMP MAIN
CHECK_PATTERN_ABORT ENDP

; Interrupt service routines
ISR_ONOFF PROC FAR
    PUSHF
    PUSH AX
    PUSH DX
    PUSH DS
    MOV AX, DATA
    MOV DS, AX
    MOV AL, PROGRAM_STATE    ; toggle power state
    XOR AL, 1
    MOV PROGRAM_STATE, AL
    CMP AL, 0
    JNE ISR_ON_ENABLE
    MOV PAUSE_STATE, 0
    MOV PATTERN_REQUEST, 1   ; force pattern exit when turning off
    JMP ISR_ON_FINISH
ISR_ON_ENABLE:
    MOV PAUSE_STATE, 0
    MOV TURN_ON_REQUEST, 1
    MOV PATTERN_REQUEST, 1   ; restart pattern after on
ISR_ON_FINISH:
    POP DS
    POP DX
    POP AX
    POPF
    IRET
ISR_ONOFF ENDP

ISR_PAUSE PROC FAR
    PUSHF
    PUSH AX
    PUSH DX
    PUSH DS
    MOV AX, DATA
    MOV DS, AX
    CMP PROGRAM_STATE, 0
    JE ISR_PAUSE_FINISH
    MOV AL, PAUSE_STATE
    XOR AL, 1
    MOV PAUSE_STATE, AL
    CMP AL, 0
    JNE ISR_PAUSE_FINISH
ISR_PAUSE_FINISH:
    POP DS
    POP DX
    POP AX
    POPF
    IRET
ISR_PAUSE ENDP

ISR_PATTERN PROC FAR
    PUSHF
    PUSH AX
    PUSH DX
    PUSH DS
    MOV AX, DATA
    MOV DS, AX
    CMP PROGRAM_STATE, 0
    JE ISR_PATTERN_FINISH
    MOV AL, PATTERN_INDEX
    INC AL
    CMP AL, MAX_PATTERNS
    JB STORE_PATTERN
    XOR AL, AL
STORE_PATTERN:
    MOV PATTERN_INDEX, AL
    MOV PATTERN_REQUEST, 1
ISR_PATTERN_FINISH:
    POP DS
    POP DX
    POP AX
    POPF
    IRET
ISR_PATTERN ENDP

; Delay utilities
DELAY_1MS PROC NEAR
    MOV BX, 009H
DL1:
    DEC BX
    JNZ DL1
    RET
DELAY_1MS ENDP

DELAY_10MS PROC NEAR
    MOV CX, 02FH
DL10:
    CALL DELAY_1MS
    LOOP DL10
    RET
DELAY_10MS ENDP

CODE ENDS
END START
