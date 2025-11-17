;====================================================================
; Midterm8259.asm rebuilt with LE7_1-style comments
; Processor: 8086
; Compiler:  MASM32
;====================================================================

DATA SEGMENT
   ORG 03000H
   PORTA_1     EQU 0C8H ; 8255 #1 PORTA address
   PORTB_1     EQU 0CAH ; 8255 #1 PORTB address
   PORTC_1     EQU 0CCH ; 8255 #1 PORTC address
   COM_REG_1   EQU 0CEH ; 8255 #1 Command Register
   PORTA_2     EQU 0D8H ; 8255 #2 PORTA address
   PORTB_2     EQU 0DAH ; 8255 #2 PORTB address
   PORTC_2     EQU 0DCH ; 8255 #2 PORTC address
   COM_REG_2   EQU 0DEH ; 8255 #2 Command Register
   PIC1        EQU 0F8H ; 8259 command port (A1 = 0)
   PIC2        EQU 0FAH ; 8259 data port (A1 = 1)
   ICW1        EQU 013H ; edge triggered, ICW4 required
   ICW2        EQU 080H ; vector base 80H
   ICW4        EQU 003H ; AEOI enabled, 8086 mode
   OCW1_MASK   EQU 0F8H ; enable IR0-IR2 only
   MAX_PATTERNS EQU 2   ; forward + reverse sequences
   PROGRAM_STATE   DB 1 ; 1 = running, 0 = off
   PAUSE_STATE     DB 0 ; 1 = paused
   PATTERN_INDEX   DB 0 ; 0 = forward, 1 = reverse
   PATTERN_REQUEST DB 1 ; flag to restart pattern
   TURN_ON_REQUEST DB 1 ; flash request after ON interrupt
DATA ENDS

STK SEGMENT STACK
   BOS DW 80 DUP(?)      ; stack storage
   TOS LABEL WORD        ; top of stack label
STK ENDS

CODE SEGMENT PUBLIC 'CODE'
   ASSUME CS:CODE, DS:DATA, SS:STK
   ORG 08000H
START:
    MOV AX, DATA           ; set the Data Segment address
    MOV DS, AX
    MOV AX, STK            ; set the Stack Segment address
    MOV SS, AX
    LEA SP, TOS            ; set SP to top of stack
    CLI                    ; clears IF flag during setup
    XOR AX, AX             ; AX = 0 for ES
    MOV ES, AX             ; ES -> interrupt vector table

    ;program the 8255
    MOV DX, COM_REG_1      ; select command register of 1st 8255
    MOV AL, 089H           ; mode 0, all outputs
    OUT DX, AL
    MOV DX, COM_REG_2      ; select command register of 2nd 8255
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

    ;install interrupt vectors (80H, 81H, 82H)
    MOV AX, OFFSET ISR_ONOFF ; get offset address of ISR_ONOFF
    MOV [ES:200H], AX        ; store offset at vector 80H
    MOV AX, SEG ISR_ONOFF    ; get segment address of ISR_ONOFF
    MOV [ES:202H], AX        ; store segment at vector 80H
    MOV AX, OFFSET ISR_PAUSE ; offset of ISR_PAUSE
    MOV [ES:204H], AX        ; vector 81H offset
    MOV AX, SEG ISR_PAUSE    ; segment of ISR_PAUSE
    MOV [ES:206H], AX        ; vector 81H segment
    MOV AX, OFFSET ISR_PATTERN ; offset of ISR_PATTERN
    MOV [ES:208H], AX        ; vector 82H offset
    MOV AX, SEG ISR_PATTERN  ; segment of ISR_PATTERN
    MOV [ES:20AH], AX        ; vector 82H segment

    STI                    ; enable maskable interrupts

;foreground routine
MAIN:
    CMP TURN_ON_REQUEST, 0  ; pending flash request?
    JE MAIN_RUN_CHECK
    MOV TURN_ON_REQUEST, 0  ; clear request
    CALL TURNON             ; flash all LEDs once

MAIN_RUN_CHECK:
    CMP PROGRAM_STATE, 0    ; powered off?
    JNE RUNNING
    CALL TURNOFF            ; ensure outputs off while powered down
WAIT_FOR_ON:
    CALL DELAY_1MS          ; poll state until ON interrupt
    CMP PROGRAM_STATE, 0
    JE WAIT_FOR_ON
    MOV PATTERN_REQUEST, 1  ; restart pattern after power up
    JMP MAIN

RUNNING:
    CMP PAUSE_STATE, 0      ; paused flag?
    JNE PAUSE_LOOP
    MOV AL, PATTERN_INDEX   ; select pattern set
    CMP AL, 0
    JE ROTATE
    CMP AL, 1
    JE ROTATE_REVERSE
    MOV PATTERN_INDEX, 0    ; guard against invalid index
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
    MOV DX, PORTB_1         ; port B (group 1)
    MOV AL, 11111111B       ; drive all bits high
    OUT DX, AL
    MOV DX, PORTA_1         ; port A (group 1)
    MOV AL, 11111111B
    OUT DX, AL
    MOV DX, PORTA_2         ; port A (group 2)
    MOV AL, 11111111B
    OUT DX, AL
    CALL DELAY_1MS          ; keep LEDs on briefly
    RET
TURNON ENDP

; TURN ALL OFF
TURNOFF PROC NEAR
    MOV DX, PORTA_1         ; port A (group 1)
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTB_1         ; port B (group 1)
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA_2         ; port A (group 2)
    MOV AL, 00000000B
    OUT DX, AL
    CALL DELAY_1MS          ; allow hardware to settle
    RET
TURNOFF ENDP

; ROTATE PATTERN (forward)
ROTATE:
    MOV PATTERN_REQUEST, 0  ; clear break flag
ROT_STEP1:
    MOV DX, PORTB_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA_1
    MOV AL, 00000011B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00000010B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
ROT_STEP2:
    MOV DX, PORTA_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTB_1
    MOV AL, 00000011B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00000100B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
ROT_STEP3:
    MOV DX, PORTB_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA_1
    MOV AL, 00001100B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00001000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
ROT_STEP4:
    MOV DX, PORTA_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTB_1
    MOV AL, 00001100B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00010000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
ROT_STEP5:
    MOV DX, PORTB_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA_1
    MOV AL, 00110000B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00100000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
ROT_STEP6:
    MOV DX, PORTA_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTB_1
    MOV AL, 00110000B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 01000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
ROT_STEP7:
    MOV DX, PORTB_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA_1
    MOV AL, 11000000B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 10000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
ROT_STEP8:
    MOV DX, PORTA_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTB_1
    MOV AL, 11000000B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00000001B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
    CMP PATTERN_INDEX, 0
    JE ROTATE
    JMP ROTATE_REVERSE

; ROTATE PATTERN (reverse)
ROTATE_REVERSE:
    MOV PATTERN_REQUEST, 0
REV_STEP8:
    MOV DX, PORTA_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTB_1
    MOV AL, 11000000B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00000001B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP7:
    MOV DX, PORTB_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA_1
    MOV AL, 11000000B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 10000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP6:
    MOV DX, PORTA_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTB_1
    MOV AL, 00110000B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 01000000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP5:
    MOV DX, PORTB_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA_1
    MOV AL, 00110000B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00100000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP4:
    MOV DX, PORTA_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTB_1
    MOV AL, 00001100B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00010000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP3:
    MOV DX, PORTB_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA_1
    MOV AL, 00001100B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00001000B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP2:
    MOV DX, PORTA_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTB_1
    MOV AL, 00000011B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00000100B
    OUT DX, AL
    CALL PATTERN_WAIT
    CALL CHECK_PATTERN_ABORT
REV_STEP1:
    MOV DX, PORTB_1
    MOV AL, 00000000B
    OUT DX, AL
    MOV DX, PORTA_1
    MOV AL, 00000011B
    OUT DX, AL
    MOV DX, PORTA_2
    MOV AL, 00000010B
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
    CMP PROGRAM_STATE, 0
    JE PATTERN_WAIT_EXIT
    CMP PATTERN_REQUEST, 0
    JNE PATTERN_WAIT_EXIT
    CMP PAUSE_STATE, 0
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
    CALL DELAY_1MS
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
    MOV AL, PROGRAM_STATE
    XOR AL, 1
    MOV PROGRAM_STATE, AL
    CMP AL, 0
    JNE ISR_ON_ENABLE
    MOV PAUSE_STATE, 0
    MOV PATTERN_REQUEST, 1
    JMP ISR_ON_FINISH
ISR_ON_ENABLE:
    MOV PAUSE_STATE, 0
    MOV TURN_ON_REQUEST, 1
    MOV PATTERN_REQUEST, 1
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

; Delay routines
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
