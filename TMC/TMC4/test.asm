;====================================================================
; 8086 Program
; Press button on PORT F4H bit0 -> latch DIP upper nibble 👎
; Continuously count 0..N..0..N forever
; PORT F0H -> LEDs (raw binary)
; PORT F2H -> 7-seg (common cathode, active HIGH)
; Note: use immediate port forms (IN/OUT imm8, AL) to avoid assembler error
;====================================================================

.MODEL SMALL
.STACK 100H

DATA SEGMENT
PORTA    EQU 0F0H    ; LEDs output (imm8 form will be used)
PORTB    EQU 0F2H    ; 7-seg output
PORTC    EQU 0F4H    ; Button (bit0) + DIP (bits 4–7)
; 7-seg patterns for 0–9 (common cathode, active HIGH)
SEG_TABLE DB 00111111B,  ; 0
          00000110B,      ; 1
          01011011B,      ; 2
          01001111B,      ; 3
          01100110B,      ; 4
          01101101B,      ; 5
          01111101B,      ; 6
          00000111B,      ; 7
          01111111B,      ; 8
          01101111B       ; 9
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA

START:
    MOV AX, DATA
    MOV DS, AX

; Wait for a button press (bit0 = 1) on PORTC
WAIT_BUTTON:
    IN  AL, PORTC         ; read PORTC immediate (avoids IN AL,DX)
    TEST AL, 01H
    JZ   WAIT_BUTTON

; Latch DIP upper nibble (bits 7..4) -> N (0..9 clamped)
    IN   AL, PORTC        ; read PORTC again
    MOV  CL, 4
    SHR  AL, CL           ; shift upper nibble into lower nibble (use CL)
    AND  AL, 0FH
    CMP  AL, 9
    JBE  DIP_OK
    MOV  AL, 9
DIP_OK:
    MOV  DL, AL           ; DL = N (0..9)

; Prepare table pointer and start counting
    MOV  SI, OFFSET SEG_TABLE
    XOR  BX, BX           ; BL = 0 current count

; Continuous counting 0..N..0..N...
COUNT_LOOP:
    ; Output raw count to LEDs on PORTA
    MOV  AL, BL
    OUT  PORTA, AL        ; OUT imm8, AL

    ; Output 7-seg pattern using valid addressing [SI + BX]
    MOV  AL, [SI + BX]    ; pattern for current count (BX used as index)
    OUT  PORTB, AL        ; OUT imm8, AL

    ; 1-second delay (DELAY_1S preserves BX and CX)
    CALL DELAY_1S

    ; Increment and wrap to 0 when exceed limit DL
    INC  BL
    CMP  BL, DL
    JBE  COUNT_LOOP       ; if BL <= DL, continue
    XOR  BL, BL           ; else reset BL=0 and continue
    JMP  COUNT_LOOP

;--------------------------------------------------------------
; DELAY_1S: call DELAY_1MS 1000 times -> ~1 second
; Preserves BX and CX to prevent clobbering index & loops
;--------------------------------------------------------------
DELAY_1S PROC
    PUSH BX
    PUSH CX
    MOV  CX, 1000
D1:
    CALL DELAY_1MS
    LOOP D1
    POP  CX
    POP  BX
    RET
DELAY_1S ENDP

;--------------------------------------------------------------
; DELAY_1MS: ~1 millisecond delay (given). Overwrites BX internally.
;--------------------------------------------------------------
DELAY_1MS PROC
    MOV  BX, 02CAH
L1:
    DEC  BX
    NOP
    JNZ  L1
    RET
DELAY_1MS ENDP

CODE ENDS
END START