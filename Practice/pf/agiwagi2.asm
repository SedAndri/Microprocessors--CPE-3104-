; -----------------------------------------------------------------------------
; Project: 3x5 LED Matrix controller using 8255 PPI and 8259 PIC
; CPU: 8086/88 real-mode (MASM/TASM style)
; Interrupts:
;   - INT 80h: ON/OFF toggle
;   - INT 81h: PAUSE/PLAY toggle (only when ON)
;   - INT 82h: MODE cycle (only when PAUSED)
; Modes:
;   1 = DEFAULT (font sequence), 2 = STICKMAN, 3 = LANTERN
; Hardware mapping (as coded):
;   8255 at ports: PORTA=0xF0 (row data), PORTB=0xF2 (column select), PORTC=0xF4
;   8255 control register at COM_REG1=0xF6
;   8259 command=PIC1=0xE0, data=PIC2=0xE2
; Notes:
;   - Make sure ES=0000h before writing the Interrupt Vector Table (IVT at 0000:0000).
;   - It’s safer to CLI while changing IVT entries, then STI after.
;   - The 8255 control word 10001001b configures Port A as INPUT; this code outputs
;     to PORTA. If your wiring needs PA as output and PB as output, use 10000000b
;     (Mode 0, PA=out, PB=out, PC upper/lower out) or adjust as per your design.
; -----------------------------------------------------------------------------

; --------------------------- ISR: ON/OFF toggle ------------------------------
PROCED1 SEGMENT 'CODE'
ON_OFF PROC FAR
ASSUME CS:PROCED1, DS:DATA
ORG 00000H                 ; Place this ISR at offset 0000h in its segment
   PUSHF                   ; Save flags (required for interrupt nesting correctness)
   PUSH AX                 ; Save registers used
   PUSH DX

   CMP ON_FLAG, 1          ; If ON_FLAG == 1, device is ON
   JE RESET_ON             ; Jump to turn OFF

   MOV ON_FLAG, 1          ; Otherwise turn ON
   MOV MODE_FLAG, 1        ; Default to Mode 1 on power-on
   JMP EXIT_ON_OFF         ; Done

RESET_ON:
   MOV ON_FLAG, 0          ; Turn OFF
   MOV PAUSE_FLAG, 0       ; Ensure not paused when off

EXIT_ON_OFF:
   POP DX                  ; Restore registers
   POP AX
   POPF
   IRET                    ; Return from interrupt
ON_OFF ENDP
PROCED1 ENDS

; ----------------------- ISR: PAUSE/PLAY toggle ------------------------------
PROCED2 SEGMENT 'CODE'
PAUSE_PLAY PROC FAR
ASSUME CS:PROCED2, DS:DATA
ORG 00050H                 ; Place this ISR at offset 0050h
   PUSHF
   PUSH AX
   PUSH DX

   CMP ON_FLAG, 1          ; Only works if device is ON
   JNE EXIT_PAUSE_PLAY     ; If OFF, ignore

   CMP PAUSE_FLAG, 1       ; If currently paused
   JE RESET_PAUSE          ; then unpause
   MOV PAUSE_FLAG, 1       ; else pause
   JMP EXIT_PAUSE_PLAY

RESET_PAUSE:
   MOV PAUSE_FLAG, 0       ; Clear pause

EXIT_PAUSE_PLAY:
   POP DX
   POP AX
   POPF
   IRET
PAUSE_PLAY ENDP
PROCED2 ENDS

; ----------------------- ISR: MODE cycle while paused ------------------------
PROCED3 SEGMENT 'CODE'
MODES PROC FAR
ASSUME CS:PROCED3, DS:DATA
ORG 00100H                 ; Place this ISR at offset 0100h
   PUSHF
   PUSH AX
   PUSH DX

   CMP PAUSE_FLAG, 1       ; Only change mode while paused
   JNE EXIT_MODE

   INC MODE_FLAG           ; Next mode
   MOV PAUSE_FLAG, 0       ; Auto-unpause after mode change
   CMP MODE_FLAG, 4        ; Wrap 4 -> 1
   JNE EXIT_MODE
   MOV MODE_FLAG, 1

EXIT_MODE:
   POP DX
   POP AX
   POPF
   IRET
MODES ENDP
PROCED3 ENDS

; ------------------------------ Data/IO map ----------------------------------
DATA SEGMENT
ORG 00250H
   PORTA     EQU 0F0H      ; 8255 Port A (row data for LED matrix)
   PORTB     EQU 0F2H      ; 8255 Port B (column select mask, active-low)
   PORTC     EQU 0F4H      ; 8255 Port C (unused here)
   COM_REG1  EQU 0F6H      ; 8255 Control register

   PIC1      EQU 0E0H      ; 8259 PIC command port
   PIC2      EQU 0E2H      ; 8259 PIC data port

   ICW1      EQU 013H      ; ICW1 (edge triggered, ICW4 needed)
   ICW2      EQU 080H      ; ICW2: base vector 0x80
   ICW4      EQU 003H      ; ICW4: 8086/88 mode, normal EOI
   OCW1      EQU 0F8H      ; Interrupt mask to write to PIC (11111000b)

   ON_FLAG     DB 0        ; 0=off, 1=on
   PAUSE_FLAG  DB 0        ; 0=run, 1=pause
   MODE_FLAG   DB 1        ; 1..3
   TEMP        DB ?        ; Temp storage used by PRINT_CHAR/UNPAUSE
DATA ENDS

; ------------------------------- Stack segment --------------------------------
STK SEGMENT STACK
   BOS DW 64d DUP (?)      ; Reserve 64 words for stack
   TOS LABEL WORD          ; Top-of-stack label
STK ENDS

; -------------------------------- Main program --------------------------------
CODE    SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE, DS:DATA, SS:STK
    ORG 00300H

START:
   ; Set up segments and stack
   MOV AX, DATA            ; AX = data segment selector
   MOV DS, AX              ; Load DS
   MOV AX, STK
   MOV SS, AX              ; Load SS
   LEA SP, TOS             ; SP = top of stack
   CLI                     ; Disable interrupts during device init

   ; ------------------ Configure 8255 PPI (I/O directions) -------------------
   MOV DX, COM_REG1        ; DX = 8255 control register port
   MOV AL, 10001001B       ; Control word (Mode 0):
                           ; D7=1 (set mode), GA mode=00, PA=1 (INPUT),
                           ; PC upper=0 (OUTPUT), GB mode=0, PB=0 (OUTPUT),
                           ; PC lower=1 (INPUT)
                           ; NOTE: This program writes to PORTA/PORTB.
                           ; If your hardware needs PA as OUTPUT, adjust this CW.
   OUT DX, AL              ; Write control word to 8255

   ; ------------------------ Configure 8259 PIC (IV base) ---------------------
   MOV AL, ICW1            ; ICW1: start initialization, ICW4 will follow
   OUT PIC1, AL            ; Send to PIC command port
   MOV AL, ICW2            ; ICW2: vector base = 0x80
   OUT PIC2, AL            ; Send to PIC data port
   MOV AL, ICW4            ; ICW4: 8086/88 mode
   OUT PIC2, AL
   MOV AL, OCW1            ; OCW1: interrupt mask (11111000b -> enable IR0..IR2 only)
   OUT PIC2, AL
   STI                     ; Re-enable interrupts
                           ; NOTE: Safer to install IVT entries (below) with CLI, then STI.

   ; --------- Install interrupt vectors in the IVT at 0000:0000 ---------------
   ; Each vector is 4 bytes (offset:word, segment:word).
   ; INT 80h (0x80*4 = 0x200) -> ON_OFF
   ; INT 81h (0x204) -> PAUSE_PLAY
   ; INT 82h (0x208) -> MODES
   ; Ensure ES=0000h before accessing IVT.
   PUSH AX
   XOR AX, AX              ; AX = 0
   MOV ES, AX              ; ES = 0000h (IVT segment)
   POP AX                  ; Restore AX

   MOV AX, OFFSET ON_OFF   ; Write INT 80h offset
   MOV [ES:200H], AX
   MOV AX, SEG ON_OFF      ; Write INT 80h segment
   MOV [ES:202H], AX

   MOV AX, OFFSET PAUSE_PLAY ; INT 81h offset
   MOV [ES:204H], AX
   MOV AX, SEG PAUSE_PLAY    ; INT 81h segment
   MOV [ES:206H], AX

   MOV AX, OFFSET MODES    ; INT 82h offset
   MOV [ES:208H], AX
   MOV AX, SEG MODES       ; INT 82h segment
   MOV [ES:20AH], AX

   ; ------------------------------- Foreground loop ---------------------------
HERE:
      MOV AL, 00000000B    ; Clear row data (all LEDs off)
      OUT PORTA, AL
      MOV AL, 00000000B    ; Clear column mask (or pre-select, depending on wiring)
      OUT PORTB, AL

      CMP ON_FLAG, 0       ; If OFF, idle here
      JE HERE

      CMP PAUSE_FLAG, 1    ; If paused, jump to PAUSE routine
      JE PAUSE

      CMP MODE_FLAG, 1     ; Mode dispatch
      JE DEFAULT
      CMP MODE_FLAG, 2
      JE STICKMAN
      CMP MODE_FLAG, 3
      JE LANTERN
   JMP HERE                ; Safety loop

   ; ------------------------------- Mode 1: DEFAULT ---------------------------
DEFAULT:
      ; Print a long sequence of 3x5 glyphs. Each glyph is printed twice,
      ; likely to fill two LED modules side-by-side.
      MOV SI, OFFSET FONT_1
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_1
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_2
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_2
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_3
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_3
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_4
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_4
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_5
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_5
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_6
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_6
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_7
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_7
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_8
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_8
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_9
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_9
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_10
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_10
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_11
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_11
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_12
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_12
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_13
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_13
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_14
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_14
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_15
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_15
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_16
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_16
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_17
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_17
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_18
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_18
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_19
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_19
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_20
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_20
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_21
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_21
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_22
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_22
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_23
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_23
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_24
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_24
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_25
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_25
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_26
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_26
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_27
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_27
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_28
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_28
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_29
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_29
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_30
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_30
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_31
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_31
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_32
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_32
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_33
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_33
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_34
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_34
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_35
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_35
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_36
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_36
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_37
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_37
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_38
      CALL PRINT_CHAR
      MOV SI, OFFSET FONT_38
      CALL PRINT_CHAR
   JMP HERE                 ; Loop back to foreground

   ; ------------------------------ Mode 2: STICKMAN ---------------------------
STICKMAN:
      MOV SI, OFFSET STICKMAN_1
      CALL PRINT_CHAR
      MOV SI, OFFSET STICKMAN_1
      CALL PRINT_CHAR
      MOV SI, OFFSET STICKMAN_2
      CALL PRINT_CHAR
      MOV SI, OFFSET STICKMAN_2
      CALL PRINT_CHAR
CON_SM:
   JMP HERE

   ; ------------------------------ Mode 3: LANTERN ----------------------------
LANTERN:
      MOV SI, OFFSET LANTERN_1
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_2
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_3
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_4
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_5
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_6
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_7
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_8
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_9
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_9
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_10
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_10
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_9
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_9
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_10
      CALL PRINT_CHAR
      MOV SI, OFFSET LANTERN_10
      CALL PRINT_CHAR
   JMP HERE

   ; -------------------- Print 1 glyph (7 rows x columns) ---------------------
   ; IN: SI = address of 7-byte glyph (each byte = row pattern)
PRINT_CHAR:
      MOV AH, 11111110B    ; Column-select mask (active-low): start with col0 low
      MOV DI, SI           ; Save start of glyph (for PAUSE handling)
      MOV AL, MODE_FLAG    ; Snapshot mode to detect mode changes during pause
      MOV TEMP, AL
F1:
      CMP PAUSE_FLAG, 1    ; If paused, draw into PAUSE loop
      JE PAUSE

      MOV AL, AH
      OUT PORTB, AL        ; Select current column (active-low lines)

      MOV AL, BYTE PTR CS:[SI] ; Read current row data from glyph
      OUT PORTA, AL        ; Output row bits to LEDs

      CMP ON_FLAG, 0       ; If turned OFF mid-draw, bail to idle
      JE HERE

      CALL DELAY_250MS     ; Hold LEDs visible (approx)
      MOV AL, 00H
      OUT PORTA, AL        ; Clear row (turn LEDs off between columns)

      INC SI               ; Next row byte
      CLC                  ; Clear CF before rotate (so CF=old MSB after ROL)
      ROL AH, 1            ; Rotate column mask left; CF gets old MSB
      CALL DELAY_500MS     ; Inter-column delay (approx)

      JC F1                ; Loop while CF=1; exits once the single '0' reaches MSB
   RET

   ; ----------------------------- Pause display loop --------------------------
PAUSE:
      MOV SI, DI           ; Restart drawing from beginning of glyph while paused
      MOV AH, 11111110B    ; Reset column mask each pause refresh
F2:
      CMP PAUSE_FLAG, 0    ; Still paused?
      JE UNPAUSE           ; If unpaused, decide where to go next

      MOV AL, AH
      OUT PORTB, AL        ; Column select

      MOV AL, BYTE PTR CS:[SI]
      OUT PORTA, AL        ; Row data

      CMP ON_FLAG, 0       ; If turned OFF while paused, go idle
      JE HERE

      CALL DELAY_250MS     ; Hold
      MOV AL, 00H
      OUT PORTA, AL        ; Clear row

      INC SI               ; Next row
      CLC
      ROL AH, 1            ; Next column
      JC F2                ; Keep scanning all columns during pause
      JMP HERE             ; After 8 columns, return to main loop
UNPAUSE:
      MOV AL, MODE_FLAG    ; Check if mode changed during pause
      CMP TEMP, AL
      JNE CHECK_MODE       ; If mode changed, branch to new mode
      RET                  ; Else continue where PRINT_CHAR left off
CHECK_MODE:
      CMP MODE_FLAG, 1
      JE DEFAULT
      CMP MODE_FLAG, 2
      JE STICKMAN
      CMP MODE_FLAG, 3
      JE LANTERN

   ; ------------------------------- Power OFF path ----------------------------
OFF:
      MOV AL, 00000000B
      OUT PORTA, AL        ; Turn off all rows
      MOV AL, 11111111B
      OUT PORTB, AL        ; De-select all columns (inactive)
      MOV ON_FLAG, 0
      MOV MODE_FLAG, 1     ; Reset to default mode on next power-on
   JMP HERE

   ; ------------------------------- Delay helpers -----------------------------
DELAY_250MS:               ; Very approximate; depends on CPU clock
   MOV CX, 250
TIMER1:
      NOP
      NOP
      NOP
      NOP
      LOOP TIMER1
   RET

DELAY_500MS:               ; Not truly 500ms; tune for your clock
   MOV CX, 00FFH
L2:
      NOP
      NOP
      LOOP L2
   RET

DELAY_1MS:                 ; Rough ~1ms delay (tune for clock)
   MOV BX, 02CAH
L1:
      DEC BX
      NOP
      JNZ L1
      RET
   RET                      ; Note: second RET is unreachable (left as-is)

; -------------------------- 3x5 LED matrix glyphs ----------------------------
; Each glyph has 7 bytes (rows). Bit=1 means LED on for that row/column.
FONT_1:
      DB 00001110B
      DB 00010001B
      DB 00010001B
      DB 00011111B
      DB 00010001B
      DB 00010001B
      DB 00010001B

FONT_2:
      DB 00000111B
      DB 00001000B
      DB 00001000B
      DB 00001111B
      DB 00001000B
      DB 00001000B
      DB 00001000B

FONT_3:
      DB 00000011B
      DB 00000100B
      DB 00000100B
      DB 00010111B
      DB 00000100B
      DB 00000100B
      DB 00000100B

FONT_4:
      DB 00000001B
      DB 00000010B
      DB 00010010B
      DB 00001011B
      DB 00010010B
      DB 00000010B
      DB 00010010B

FONT_5:
      DB 00000000B
      DB 00000001B
      DB 00011001B
      DB 00000101B
      DB 00011001B
      DB 00000001B
      DB 00011001B

FONT_6:
      DB 00000000B
      DB 00000000B
      DB 00011100B
      DB 00000010B
      DB 00011100B
      DB 00000000B
      DB 00011100B

FONT_7:
      DB 00000000B
      DB 00000000B
      DB 00011110B
      DB 00010001B
      DB 00011110B
      DB 00010000B
      DB 00001110B

FONT_8:
      DB 00000000B
      DB 00000000B
      DB 00001111B
      DB 00001000B
      DB 00001111B
      DB 00001000B
      DB 00000111B

FONT_9:
      DB 00000000B
      DB 00000000B
      DB 00010111B
      DB 00010100B
      DB 00010111B
      DB 00010100B
      DB 00000011B

FONT_10:
      DB 00000000B
      DB 00000000B
      DB 00001011B
      DB 00001010B
      DB 00001011B
      DB 00001010B
      DB 00010001B

FONT_11:
      DB 00000000B
      DB 00000000B
      DB 00001011B
      DB 00001010B
      DB 00001011B
      DB 00001010B
      DB 00010001B

FONT_12:
      DB 00000000B
      DB 00000000B
      DB 00000101B
      DB 00000101B
      DB 00000101B
      DB 00000101B
      DB 00011000B

FONT_13:
      DB 00000000B
      DB 00000000B
      DB 00000010B
      DB 00000010B
      DB 00000010B
      DB 00010010B
      DB 00001100B

FONT_14:
      DB 00000000B
      DB 00000000B
      DB 00010001B
      DB 00010001B
      DB 00010001B
      DB 00011001B
      DB 00010110B

FONT_15:
      DB 00000000B
      DB 00000000B
      DB 00001000B
      DB 00001000B
      DB 00001000B
      DB 00001100B
      DB 00001011B

FONT_16:
      DB 00000000B
      DB 00010000B
      DB 00000100B
      DB 00010100B
      DB 00010100B
      DB 00010110B
      DB 00010101B

FONT_17:
      DB 00000000B
      DB 00001000B
      DB 00000010B
      DB 00001010B
      DB 00001010B
      DB 00001011B
      DB 00001010B

FONT_18:
      DB 00010000B
      DB 00000100B
      DB 00000001B
      DB 00000101B
      DB 00000101B
      DB 00000101B
      DB 00010101B

FONT_19:
      DB 00011000B
      DB 00010010B
      DB 00010000B
      DB 00010010B
      DB 00010010B
      DB 00010010B
      DB 00011010B

FONT_20:
      DB 00001100B
      DB 00001001B
      DB 00001000B
      DB 00001001B
      DB 00001001B
      DB 00001001B
      DB 00011101B

FONT_21:
      DB 00000160B ; (original 00000110B) keep as-is if intended
      DB 00000100B
      DB 00000100B
      DB 00000100B
      DB 00000100B
      DB 00000100B
      DB 00001110B

FONT_22:
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000010B
      DB 00000010B
      DB 00010010B
      DB 00000111B

FONT_23:
      DB 00000001B
      DB 00000001B
      DB 00010001B
      DB 00000001B
      DB 00010001B
      DB 00001001B
      DB 00010011B

FONT_24:
      DB 00000000B
      DB 00000000B
      DB 00011000B
      DB 00000000B
      DB 00011000B
      DB 00000100B
      DB 00011001B

FONT_25:
      DB 00000000B
      DB 00000000B
      DB 00011100B
      DB 00000000B
      DB 00011100B
      DB 00000010B
      DB 00011100B

FONT_26:
      DB 00000000B
      DB 00000000B
      DB 00001110B
      DB 00010000B
      DB 00011110B
      DB 00010001B
      DB 00011110B

FONT_27:
      DB 00000000B
      DB 00000000B
      DB 00000111B
      DB 00001000B
      DB 00001111B
      DB 00001000B
      DB 00001111B

FONT_28:
      DB 00000000B
      DB 00000000B
      DB 00010011B
      DB 00010100B
      DB 00010111B
      DB 00010100B
      DB 00010111B

FONT_29:
      DB 00000000B
      DB 00000000B
      DB 00001001B
      DB 00011010B
      DB 00001011B
      DB 00001010B
      DB 00001011B

FONT_30:
      DB 00000000B
      DB 00000000B
      DB 00010100B
      DB 00001101B
      DB 00000101B
      DB 00000101B
      DB 00000101B

FONT_31:
      DB 00000000B
      DB 00000000B
      DB 00011010B
      DB 00000110B
      DB 00000010B
      DB 00000010B
      DB 00000010B

FONT_32:
      DB 00000000B
      DB 00000000B
      DB 00001101B
      DB 00010011B
      DB 00000001B
      DB 00000001B
      DB 00000001B

FONT_33:
      DB 00000000B
      DB 00000000B
      DB 00000110B
      DB 00001001B
      DB 00000000B
      DB 00000000B
      DB 00000000B

FONT_34:
      DB 00000000B
      DB 00000000B
      DB 00000011B
      DB 00000100B
      DB 00000000B
      DB 00000000B
      DB 00000000B

FONT_35:
      DB 00000000B
      DB 00010000B
      DB 00010001B
      DB 00010010B
      DB 00010000B
      DB 00010000B
      DB 00010000B

FONT_36:
      DB 00010000B
      DB 00001000B
      DB 00001000B
      DB 00011001B
      DB 00001000B
      DB 00001000B
      DB 00001000B

FONT_37:
      DB 00011000B
      DB 00000100B
      DB 00000100B
      DB 00011100B
      DB 00000100B
      DB 00000100B
      DB 00000100B

FONT_38:
      DB 00011100B
      DB 00000010B
      DB 00000010B
      DB 00011110B
      DB 00000010B
      DB 00000010B
      DB 00000010B

STICKMAN_1:
      DB 00000100B
      DB 00001010B
      DB 00000100B
      DB 00011111B
      DB 00000100B
      DB 00001010B
      DB 00001010B

STICKMAN_2:
      DB 00001010B
      DB 00010101B
      DB 00001110B
      DB 00000100B
      DB 00001010B
      DB 00010001B
      DB 00000000B

LANTERN_1:
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000100B

LANTERN_2:
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000100B
      DB 00000100B

LANTERN_3:
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000100B
      DB 00000100B
      DB 00000100B

LANTERN_4:
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00001110B
      DB 00000100B
      DB 00000100B

LANTERN_5:
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000100B
      DB 00011111B
      DB 00000100B
      DB 00000100B

LANTERN_6:
      DB 00000000B
      DB 00000000B
      DB 00000100B
      DB 00000100B
      DB 00011111B
      DB 00000100B
      DB 00000100B

LANTERN_7:
      DB 00000000B
      DB 00000100B
      DB 00001110B
      DB 00000100B
      DB 00011111B
      DB 00000100B
      DB 00000100B

LANTERN_8:
      DB 00000100B
      DB 00000100B
      DB 00001110B
      DB 00000100B
      DB 00011111B
      DB 00000100B
      DB 00000100B

LANTERN_9:
      DB 00000100B
      DB 00000000B
      DB 00001110B
      DB 00000000B
      DB 00011111B
      DB 00000100B
      DB 00000100B

LANTERN_10:
      DB 00000100B
      DB 00000100B
      DB 00001010B
      DB 00001010B
      DB 00010101B
      DB 00000100B
      DB 00000100B

CODE ENDS
END START
