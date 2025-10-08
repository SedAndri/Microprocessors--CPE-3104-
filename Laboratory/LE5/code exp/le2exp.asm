;====================================================================
; Bordario, Sid Andre P.
;====================================================================

;========================================================================
; DATA SEGMENT: Defines I/O port addresses and lookup tables used by the code.
; - PORTA, PORTB, PORTC are equates for hardware I/O addresses used by IN/OUT.
; - SEVEN_SEG holds bit patterns for displaying digits 0-9 on a 7-segment.
; - LED_PATTERN holds bit patterns to light one LED at a time (running LED).
;========================================================================

DATA SEGMENT                   ; Begin data segment to store constants/tables
 PORTA EQU 0F0H                ; Define PORTA I/O address (hex F0) for LEDs (output)
 PORTB EQU 0F2H                ; Define PORTB I/O address (hex F2) for 7-seg display (output)
 PORTC EQU 0F4H                ; Define PORTC I/O address (hex F4) for mode selection (input)
 
 ; SEVEN_SEG table: bit patterns for digits 0-9
 ; Like an array, each DB entry corresponds to a digit (0 at offset 0, 1 at offset 1, etc.)
 ; Convention typically maps bits to segments a,b,c,d,e,f,g,dp (hardware-specific).
 ; Example 00111111b lights segments a,b,c,d,e,f for digit '0'.
 SEVEN_SEG DB 00111111B  ; 0  -> segments a,b,c,d,e,f on; g off7    
           DB 00000110B  ; 1  -> segments b,c on
           DB 01011011B  ; 2  -> segments a,b,d,e,g on
           DB 01001111B  ; 3  -> segments a,b,c,d,g on
           DB 01100110B  ; 4  -> segments b,c,f,g on
           DB 01101101B  ; 5  -> segments a,c,d,f,g on
           DB 01111101B  ; 6  -> segments a,c,d,e,f,g on
           DB 00000111B  ; 7  -> segments a,b,c on
           DB 01111111B  ; 8  -> all segments a,b,c,d,e,f,g on
           DB 01101111B  ; 9  -> segments a,b,c,d,f,g on
           
 ; LED_PATTERN table: one bit set per entry to light a single LED (running effect)
 ; Highest bit is LED 7, lowest bit is LED 0 (hardware assumes 8 LEDs on PORTA).
 LED_PATTERN DB 10000000B  ; LED 7 on
             DB 01000000B  ; LED 6 on
             DB 00100000B  ; LED 5 on
             DB 00010000B  ; LED 4 on
             DB 00001000B  ; LED 3 on
             DB 00000100B  ; LED 2 on
             DB 00000010B  ; LED 1 on
             DB 00000001B  ; LED 0 on
DATA ENDS                    ; End data segment

;========================================================================
; CODE SEGMENT SETUP: Configure segment registers and program entry point.
; - ASSUME tells the assembler which segments registers refer to.
; - DS is loaded with the address of DATA segment for table access.
; - ORG sets the origin; START is the program entry label.
;========================================================================
CODE SEGMENT                  ; Begin code segment
ASSUME CS:CODE, DS:DATA       ; Inform assembler: CS uses CODE, DS uses DATA
MOV AX, DATA                  ; Load the segment address of DATA into AX
MOV DS, AX                    ; Initialize DS (data segment register) with DATA

ORG 0000H                     ; Set code origin (offset 0000h)

START:                        ; Entry point label

;========================================================================
; INITIALIZATION: Clear PORTA and PORTB outputs to a known state (all off).
;========================================================================

MOV DX, PORTA                 ; DX <- address of PORTA (LEDs)
MOV AL, 00000000B             ; AL <- 0 (turn all LEDs off)
OUT DX, AL                    ; Write 0 to PORTA

MOV DX, PORTB                 ; DX <- address of PORTB (7-seg)
MOV AL, 00000000B             ; AL <- 0 (turn all segments off)
OUT DX, AL                    ; Write 0 to PORTB

;========================================================================
; MAIN LOOP: Poll mode selector on PORTC and dispatch to routines.
; - If PORTC == 01h: run LED chase pattern.
; - If PORTC == 02h: display 0..9 on 7-seg.
; - Else: keep polling.
;========================================================================

MAIN_LOOP:                    ; Main polling loop
MOV DX, PORTC                 ; DX <- address of PORTC (mode input)
IN AL, DX                     ; AL <- current input value from PORTC
; IN = read input from I/O    ; Note: hardware must drive PORTC with mode codes.

CMP AL, 01H                   ; Compare AL with 01h (running LED mode?)
JE RUNNING_LED                ; If equal, jump to RUNNING_LED routine

CMP AL, 02H                   ; Compare AL with 02h (count display mode?)
JE COUNT_DISPLAY              ; If equal, jump to COUNT_DISPLAY routine

JMP MAIN_LOOP                 ; Otherwise, keep polling until a valid mode is selected

;========================================================================
; RUNNING_LED: Animate LEDs on PORTA using LED_PATTERN table.
; - SI indexes the LED_PATTERN entries (0..7).
; - CX counts 8 iterations; LOOP uses CX to control the loop.
; - A software delay uses CX as a timing counter (saved/restored with PUSH/POP).
;========================================================================

;CX is used twice in this segment, 1st for the outerloop ("stopping" SI), and
;2nd for the delay loop. So we need to save and restore CX after the delay.
RUNNING_LED:
MOV SI, 0                     ; SI <- 0 (start at first LED pattern)
MOV CX, 8                     ; CX <- 8 (number of patterns/LEDs to output)

LED_LOOP:
MOV AL, LED_PATTERN[SI]       ; AL <- pattern at offset SI (light one LED)
MOV DX, PORTA                 ; DX <- PORTA address
OUT DX, AL                    ; Output pattern to LEDs on PORTA

; Delay block (coarse timing using busy loop)
PUSH CX                       ; Save outer loop counter CX on stack
MOV CX, 5000                  ; CX <- 5000 (delay count; tune for your clock)
DELAY1:                       ; uses new cx value since LOOP functionally decrements cx
NOP                           ; Do nothing (consume cycles)
LOOP DELAY1                   ; CX <- CX-1; repeat until CX == 0
POP CX                        ; Restore outer loop counter CX after delay

INC SI                        ; SI <- SI+1 (next LED pattern index)
LOOP LED_LOOP                 ; CX <- CX-1; loop LED_LOOP until 8 iterations done

JMP MAIN_LOOP                 ; Return to main polling loop

;========================================================================
; COUNT_DISPLAY: Show digits 0..9 on 7-seg via PORTB using SEVEN_SEG table.
; - SI indexes digit patterns (0..9).
; - CX counts 10 iterations; each iteration outputs one digit then delays.
;========================================================================

COUNT_DISPLAY:
MOV SI, 0                     ; SI <- 0 (start with digit '0')
MOV CX, 10                    ; CX <- 10 (number of digits to display: 0..9)

COUNT_LOOP:
MOV AL, SEVEN_SEG[SI]         ; AL <- 7-seg pattern for the current digit
MOV DX, PORTB                 ; DX <- PORTB address
OUT DX, AL                    ; Output pattern to 7-seg display on PORTB

PUSH CX                       ; Save outer loop counter CX
MOV CX, 8000                  ; CX <- 8000 (longer delay than RUNNING_LED)
DELAY2:
NOP                           ; No operation (consume cycles)
LOOP DELAY2                   ; CX <- CX-1; repeat until CX == 0
POP CX                        ; Restore outer loop counter CX

INC SI                        ; SI <- SI+1 (next digit index)
LOOP COUNT_LOOP               ; CX <- CX-1; loop until 10 digits have been shown

JMP MAIN_LOOP                 ; Return to main polling loop

;========================================================================
; PROGRAM END: Mark end of code segment and define the entry point.
;========================================================================

CODE ENDS                     ; End code segment
END START                     ; Assembler directive: program entry is label START