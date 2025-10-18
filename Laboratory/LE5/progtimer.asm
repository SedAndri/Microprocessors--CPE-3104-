;====================================================================
; Program: progtimer.asm
; Purpose: Count 00..99 on two 7‑segment displays using 8255 + 8253
; Author : Bordario, Sid Andre P.
; Notes :
;   - 8253 Counter 0 is clocked at 100 Hz.
;   - Period (seconds) = N / 100. Smaller N = faster counting.
;   - OUT0 is wired to 8255 PC4 (input). GATE0 must be high to run.
;====================================================================

;================== DATA SEGMENT (I/O map, tables, variables) ==================
DATA SEGMENT 
 PORTA     EQU 0F0H    ; 8255 Port A address (drives ones digit segments)
 PORTB     EQU 0F2H    ; 8255 Port B address (drives tens digit segments)
 PORTC     EQU 0F4H    ; 8255 Port C address (PC0=GATE0 drive, PC4=OUT0 read)
 COM_REG   EQU 0F6H    ; 8255 control register address

 ; 8253 PIT I/O base
 COUNTER0  EQU 0F8H    ; 8253 Counter 0 data port
 COUNTER1  EQU 0FAH    ; 8253 Counter 1 data port (unused)
 COUNTER2  EQU 0FCH    ; 8253 Counter 2 data port (unused)
 PIT_CTRL  EQU 0FEH    ; 8253 control/status port

 PIT_RELOAD EQU 064H   ; Reload (N). With CLK0=100 Hz: Period = N/100 s.
                       ; Examples: 64h=100 -> 1.00 s, 32h=50 -> 0.50 s,
                       ;           0Ah=10  -> 0.10 s, 01h=1 -> 0.01 s

 ; 7‑segment encoding table (active‑high, bit-per-segment)
 ; Index 0..9 -> byte to output to the 7‑segment pins
 SEVEN_SEG DB 10111111b  ; 0
           DB 10000110b  ; 1
           DB 11011011b  ; 2
           DB 11001111b  ; 3
           DB 11100110b  ; 4 (note: keep as in your hardware truth table)
           DB 11101101b  ; 5
           DB 11111101b  ; 6
           DB 10000111b  ; 7
           DB 11111111b  ; 8
           DB 11101111b  ; 9

 ONES DB 0               ; Ones digit value (0..9)
 TENS DB 0               ; Tens digit value (0..9)
DATA ENDS 
 
;================== CODE SEGMENT (program logic) ==================
CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA        ; Tell assembler our segment registers
 MOV AX, DATA                   ; AX <- segment address of DATA
 MOV DS, AX                     ; DS <- DATA so we can access variables
 ORG 0000H                      ; Program load origin

;================== STARTUP: configure 8255 and 8253 ==================
START:
 ;--- Configure 8255: PA/PB as outputs, PC upper as input (OUT0), PC lower as output (GATE0) ---
 MOV DX, COM_REG                ; DX <- 8255 control register I/O address
 MOV AL, 10001000b              ; AL <- control word: PA=out, PB=out, PCupper=in, PClower=out
 OUT DX, AL                     ; Write control to 8255

 ;--- Drive GATE0 high on PC0 so 8253 Counter0 runs ---
 MOV DX, PORTC                  ; DX <- Port C address
 MOV AL, 00000001b              ; AL bit0=1 -> PC0 high (bits 3:1 are don't-care here)
 OUT DX, AL                     ; Output to Port C (sets GATE0=HIGH)

 ;--- Configure 8253 Counter 0: Mode 2 (rate generator), LSB then MSB, binary counting ---
 MOV DX, PIT_CTRL               ; DX <- 8253 control port
 MOV AL, 00110100b              ; AL = 34h: Ctr0 | LSB/MSB | Mode2 | Binary
 OUT DX, AL                     ; Program 8253 control

 ;--- Load reload value N into Counter 0 (period = N / 100 Hz) ---
 MOV DX, COUNTER0               ; DX <- Counter 0 data port
 MOV AL, PIT_RELOAD             ; AL <- LSB of N (here 64h=100)
 OUT DX, AL                     ; Write LSB
 MOV AL, 000h                   ; AL <- MSB of N (0 for values < 256)
 OUT DX, AL                     ; Write MSB

 ;--- Initialize display to 00 and show once ---
 MOV ONES, 0                    ; ONES <- 0
 MOV TENS, 0                    ; TENS <- 0
 CALL SHOW_TWO_DIGITS           ; Update both 7‑seg displays

 ;--- Synchronize to OUT0 edge so the loop starts aligned to timer period ---
 CALL WAIT_TICK_OUT0            ; Wait for the next OUT0 pulse

;================== MAIN LOOP: wait one tick, increment, display ==================
MAIN_LOOP:
 CALL WAIT_TICK_OUT0            ; Block until one timer period elapses
 INC ONES                       ; ONES = ONES + 1
 CMP ONES, 10                   ; Reached 10?
 JB  SHOW_AND_LOOP              ; If ONES < 10, just show
 MOV ONES, 0                    ; Else roll over ONES to 0
 INC TENS                       ; Increment TENS
 CMP TENS, 10                   ; Reached 10?
 JB  SHOW_AND_LOOP              ; If TENS < 10, just show
 MOV TENS, 0                    ; Else roll over to 00 when 99 -> 00

SHOW_AND_LOOP:
 CALL SHOW_TWO_DIGITS           ; Output the two digits to 7‑segments
 JMP MAIN_LOOP                  ; Repeat forever

;================== WAIT_TICK_OUT0: poll PC4 for PIT OUT0 pulse ==================
; Uses 8253 Mode 2 behavior: OUT0 is normally high and goes low briefly each period.
; We wait for a low level, then for it to return high = one full tick.
WAIT_TICK_OUT0:
  PUSH AX                       ; Save AX (we modify AL)
  PUSH DX                       ; Save DX (we use DX for I/O port)
  MOV DX, PORTC                 ; DX <- Port C address to read PC4

WT_LOW:                         ; Wait while OUT0 is still high
  IN  AL, DX                    ; AL <- Port C input states
  TEST AL, 00010000b            ; Is PC4 (bit4) high?
  JNZ WT_LOW                    ; If high, keep waiting

WT_HIGH:                        ; OUT0 went low; now wait for it to return high
  IN  AL, DX                    ; Read Port C again
  TEST AL, 00010000b            ; Check PC4 high?
  JZ  WT_HIGH                   ; If still low, keep waiting

  POP DX                        ; Restore DX
  POP AX                        ; Restore AX
  RET                           ; Return to caller (one tick elapsed)

;================== READ_C0 (optional): latch & read 16‑bit Counter 0 ==================
; Not used by the main loop (we use OUT0 polling), but kept for reference.
; Returns AX = MSB:LSB of current Counter 0 value.
READ_C0:
 PUSH DX                        ; Save DX
 PUSH BX                        ; Save BX (used to assemble 16‑bit value)
 MOV DX, PIT_CTRL               ; DX <- 8253 control port
 MOV AL, 00h                    ; AL <- latch command for Counter 0
 OUT DX, AL                     ; Issue latch so reads are stable
 MOV DX, COUNTER0               ; DX <- Counter 0 data port
 IN  AL, DX                     ; Read LSB into AL
 MOV BL, AL                     ; Save LSB in BL
 IN  AL, DX                     ; Read MSB into AL
 MOV BH, AL                     ; Save MSB in BH
 MOV AX, BX                     ; AX <- combined MSB:LSB
 POP BX                         ; Restore BX
 POP DX                         ; Restore DX
 RET                            ; Return with AX = count

;================== SHOW_TWO_DIGITS: output ONES to PA, TENS to PB ==================
; Uses XLAT to translate a 0..9 value into the corresponding 7‑segment byte.
SHOW_TWO_DIGITS:
 PUSH AX                        ; Save AX (we modify AL)
 PUSH BX                        ; Save BX (base for XLAT)
 PUSH DX                        ; Save DX (I/O port address)

 ;--- Output ONES digit on Port A ---
 LEA BX, SEVEN_SEG              ; BX <- address of lookup table base
 MOV AL, ONES                   ; AL <- index (0..9) for ones digit
 XLAT                            ; AL <- [BX + AL] (fetch 7‑seg pattern)
 MOV DX, PORTA                  ; DX <- Port A address
 OUT DX, AL                     ; Send pattern to ones 7‑seg

 ;--- Output TENS digit on Port B ---
 LEA BX, SEVEN_SEG              ; BX <- table base again (XLAT uses BX)
 MOV AL, TENS                   ; AL <- index (0..9) for tens digit
 XLAT                            ; AL <- pattern for tens digit
 MOV DX, PORTB                  ; DX <- Port B address
 OUT DX, AL                     ; Send pattern to tens 7‑seg

 POP DX                         ; Restore DX
 POP BX                         ; Restore BX
 POP AX                         ; Restore AX
 RET                            ; Done updating both digits

CODE ENDS 
END START