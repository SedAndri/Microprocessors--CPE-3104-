;====================================================================
; Modules.asm - reusable building blocks for 8086 + 8255/8253 labs
; All routines are register-parameterized to avoid hard-coded ports.
; Keep DS pointing to the combined DATA segment so XLAT tables work.
;====================================================================

DATA    SEGMENT PUBLIC 'DATA'
; 7-seg LUTs (bit order: a b c d e f g; dp excluded)
; Common-cathode (1 = LED on)
SEVEN_SEG_CC  DB 00111111b, 00000110b, 01011011b, 01001111b, 01100110b
              DB 01101101b, 01111101b, 00000111b, 01111111b, 01101111b

; Common-anode (0 = LED on)
SEVEN_SEG_CA  DB 10111111b, 10000110b, 11011011b, 11001111b, 11100110b
              DB 11101101b, 11111101b, 10000111b, 11111111b, 11101111b
DATA    ENDS


CODE    SEGMENT PUBLIC 'CODE'
ASSUME  CS:CODE

;---------------------------------------------------------------
; Init8255
; In:  DX = control register port (e.g., 0F6h)
;      AL = control word (e.g., 10001000b)
; Out: none
;---------------------------------------------------------------
Init8255:
    OUT DX, AL
    RET

;---------------------------------------------------------------
; PIT_InitC0_Mode2
; Configure 8253 Counter0 in Mode 2 (rate generator), binary.
; In:  DX = PIT control port (e.g., 0FEh)
;      BX = Counter0 port (e.g., 0F8h)
;      AX = reload value (LSB in AL, MSB in AH)
; Out: none
; Clobbers: AL, DX
;---------------------------------------------------------------
PIT_InitC0_Mode2:
    PUSH AX
    MOV  AL, 00110100b        ; SC=00 (C0), RW=11 (LSB/MSB), Mode=010, BCD=0
    OUT  DX, AL
    MOV  DX, BX               ; DX = Counter0 port
    POP  AX                   ; AX = reload
    OUT  DX, AL               ; LSB
    MOV  AL, AH
    OUT  DX, AL               ; MSB
    RET

;---------------------------------------------------------------
; ShowDigit_LUT (XLAT)
; In:  AL = digit 0..9
;      BX = OFFSET of LUT (SEVEN_SEG_CC or SEVEN_SEG_CA)
;      DX = output port for 7-seg segments
; Out: AL = encoded pattern (written to port)
; Clobbers: AL
;---------------------------------------------------------------
ShowDigit_LUT:
    XLAT                      ; AL = [BX + AL]
    OUT DX, AL
    RET

;---------------------------------------------------------------
; ShowTwoDigits_LUT
; In:  AH = TENS (0..9), AL = ONES (0..9)
;      SI = OFFSET of LUT
;      DX = port for ONES (e.g., PORTA)
;      BX = port for TENS (e.g., PORTB)
; Out: none
; Clobbers: AX, DX, BX
;---------------------------------------------------------------
ShowTwoDigits_LUT:
    PUSH BP

    ; ONES -> DX
    PUSH AX
    PUSH BX
    MOV  BX, SI               ; BX = LUT base
    ; AL already has ONES
    XLAT
    OUT  DX, AL
    POP  BX
    POP  AX

    ; TENS -> BX (reuse DX)
    XCHG DX, BX               ; DX = TENS port, BX = ONES port (saved)
    MOV  AL, AH               ; AL = TENS
    MOV  BX, SI               ; BX = LUT base
    XLAT
    OUT  DX, AL
    XCHG DX, BX               ; restore DX

    POP  BP
    RET

;---------------------------------------------------------------
; ShowTwoDigits_BCD_PortA
; Pack TENS(upper nibble) and ONES(lower nibble) for two 74LS48s.
; In:  AH = TENS (0..9), AL = ONES (0..9)
;      DX = Port A (to both 74LS48 decoders)
; Out: none
; Clobbers: AL
;---------------------------------------------------------------
ShowTwoDigits_BCD_PortA:
    AND  AL, 0Fh
    AND  AH, 0Fh
    SHL  AH, 4
    OR   AL, AH               ; AL = TTTT OOOO
    OUT  DX, AL
    RET

;---------------------------------------------------------------
; SplitToTensOnes
; Split 0..255 into TENS (AL) and ONES (AH). CF=1 if input > 99.
; In:  AL = value
; Out: AL = TENS, AH = ONES, CF set if original > 99
; Clobbers: AL, AH
;---------------------------------------------------------------
SplitToTensOnes:
    PUSH BX
    MOV  BL, AL               ; preserve original
    XOR  AH, AH
    MOV  BH, 10
    DIV  BH                   ; AL=quotient (tens), AH=remainder (ones)
    CMP  BL, 99
    JBE  STO_NO_OVF
    STC
    JMP  STO_DONE
STO_NO_OVF:
    CLC
STO_DONE:
    POP  BX
    RET

;---------------------------------------------------------------
; Clamp0to9
; In:  AL = value
; Out: AL = min(value, 9)
;---------------------------------------------------------------
Clamp0to9:
    CMP AL, 9
    JBE C09_DONE
    MOV AL, 9
C09_DONE:
    RET

;---------------------------------------------------------------
; ReadOperandsActiveLow
; Read 8-bit port as two active-low 4-bit operands.
; In:  DX = input port (e.g., PORTB)
; Out: AL = OPERAND1 (lower nibble), AH = OPERAND2 (upper nibble)
; Clobbers: AL, AH
;---------------------------------------------------------------
ReadOperandsActiveLow:
    IN   AL, DX
    NOT  AL
    MOV  AH, AL
    AND  AL, 0Fh
    SHR  AH, 4
    AND  AH, 0Fh
    RET

;---------------------------------------------------------------
; ReadUpperNibbleActiveLow
; In:  DX = input port
; Out: AL = upper nibble (0..15), active-low normalized to active-high
;---------------------------------------------------------------
ReadUpperNibbleActiveLow:
    IN   AL, DX
    NOT  AL
    SHR  AL, 4
    AND  AL, 0Fh
    RET

;---------------------------------------------------------------
; ReadLowerNibbleActiveLow
; In:  DX = input port
; Out: AL = lower nibble (0..15), active-low normalized to active-high
;---------------------------------------------------------------
ReadLowerNibbleActiveLow:
    IN   AL, DX
    NOT  AL
    AND  AL, 0Fh
    RET

;---------------------------------------------------------------
; WaitForBitHigh / WaitForBitLow
; Busy-wait for an input bit to reach a level.
; In:  DX = input port, BL = bit mask (e.g., 00000001b for PC0)
; Out: none
;---------------------------------------------------------------
WaitForBitHigh:
WFH_LOOP:
    IN   AL, DX
    TEST AL, BL
    JZ   WFH_LOOP
    RET

WaitForBitLow:
WFL_LOOP:
    IN   AL, DX
    TEST AL, BL
    JNZ  WFL_LOOP
    RET

;---------------------------------------------------------------
; WaitBitLowHigh
; Wait for a full low->high transition on a bit (edge sync).
; In:  DX = input port, BL = bit mask
; Out: none
;---------------------------------------------------------------
WaitBitLowHigh:
    CALL WaitForBitLow
    CALL WaitForBitHigh
    RET

;---------------------------------------------------------------
; Delay_CX_SI
; Nested busy-wait. Larger CX/SI => longer delay.
; In:  CX = outer count, SI = inner count
; Out: none
; Clobbers: CX, SI
;---------------------------------------------------------------
Delay_CX_SI:
DLY1:  PUSH CX
       MOV  CX, SI
DLY2:  NOP
       LOOP DLY2
       POP  CX
       LOOP DLY1
       RET

;---------------------------------------------------------------
; DelayWhileBitHigh
; Delay while (port & mask) != 0, up to CX outer loops.
; Returns with ZF=1 if the bit went low early (like a level-run gate).
; In:  DX = input port, BL = bit mask, CX = loop count
; Out: ZF=1 if bit went low during delay; ZF=0 if delay elapsed with bit high
; Clobbers: CX, AL
;---------------------------------------------------------------
DelayWhileBitHigh:
DWBH_LOOP:
    IN   AL, DX
    TEST AL, BL
    JZ   DWBH_EXIT            ; bit low => ZF=1
    NOP
    LOOP DWBH_LOOP            ; on completion, last TEST had ZF=0
DWBH_EXIT:
    RET

CODE    ENDS
END