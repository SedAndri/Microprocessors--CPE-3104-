;====================================================================
; Bordario, Sid Andre P.
;====================================================================

;========================================================================
; DATA SEGMENT: Defines I/O port addresses, lookup tables, and variables.
; - PORTA, PORTB, PORTC, COM_REG are equates for hardware I/O addresses.
; - SEVEN_SEG holds bit patterns for displaying digits 0-9 on a 7-segment.
; - ONES and TENS are variables for the current digit values to display.
;========================================================================

DATA SEGMENT 
 PORTA   EQU 0F0H            ; Output port for ones digit (7-segment)
 PORTB   EQU 0F2H            ; Output port for tens digit (7-segment)
 PORTC   EQU 0F4H            ; Input port for button (bit 0)
 COM_REG EQU 0F6H            ; Command register for hardware setup
 
 ; SEVEN_SEG table: bit patterns for digits 0-9 on 7-segment display
 SEVEN_SEG DB 00111111B  ; 0  -> segments a,b,c,d,e,f on
           DB 00000110B  ; 1  -> segments b,c on
           DB 01011011B  ; 2  -> segments a,b,d,e,g on
           DB 01001111B  ; 3  -> segments a,b,c,d,g on
           DB 01100110B  ; 4  -> segments b,c,f,g on
           DB 01101101B  ; 5  -> segments a,c,d,f,g on
           DB 01111101B  ; 6  -> segments a,c,d,e,f,g on
           DB 00000111B  ; 7  -> segments a,b,c on
           DB 01111111B  ; 8  -> all segments on
           DB 01101111B  ; 9  -> segments a,b,c,d,f,g on

 ONES DB 0                ; Variable for ones digit (0-9)
 TENS DB 0                ; Variable for tens digit (0-9)
DATA ENDS 

;========================================================================
; CODE SEGMENT SETUP: Configure segment registers and program entry point.
; - ASSUME tells the assembler which segments registers refer to.
; - DS is loaded with the address of DATA segment for table access.
; - ORG sets the origin; START is the program entry label.
;========================================================================

CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA
 MOV AX, DATA              ; Load DATA segment address to AX
 MOV DS, AX                ; Set DS to DATA segment
 ORG 0000H                 ; Code starts at offset 0

START:

;========================================================================
; INITIALIZATION: Configure the command register and initialize display to 00.
;========================================================================

 MOV DX, COM_REG           ; DX <- command register address
 MOV AL, 10001001B         ; Set up hardware (mode/configuration bits)
 ; in hardware, port C will be Active High so input must connect to ground
 OUT DX, AL                ; Write config to command register

 ; Start at 00
 MOV ONES, 0               ; Clear ones digit
 MOV TENS, 0               ; Clear tens digit
 CALL SHOW_TWO_DIGITS      ; Display 00 on 7-segment

;========================================================================
; MAIN_IDLE: Wait for a button press (PORTC bit 0 low) to start counting.
;========================================================================

MAIN_IDLE:
 MOV DX, PORTC             ; DX <- input port address (button)
 MOV ONES, 0               ; Reset ones digit
 MOV TENS, 0               ; Reset tens digit
 CALL SHOW_TWO_DIGITS      ; Display 00

MI_POLL:
 IN  AL, DX                ; Read PORTC (button state)
 TEST AL, 00000001B        ; Isolate bit 0 (button)
 JNZ  MI_POLL              ; If not pressed (bit 0 high), keep polling

;========================================================================
; RUN_LOOP: Increment and display two-digit counter (00 to 99).
; - Increments ONES, then TENS when ONES rolls over.
; - Loops back to 00 after 99.
; - Exits to MAIN_IDLE if button is pressed again.
;========================================================================

RUN_LOOP:
 CALL SHOW_TWO_DIGITS      ; Output current digits to display
 CALL DELAY                ; Wait (software delay)

; PORTC is still in DX from before (line 68)
 IN  AL, DX                ; Read PORTC (button state) || load PORTC state/input to AL
 TEST AL, 00000001B        ; Check if button is pressed (ZF == 1 when not pressed it 
                           ;jumps to MAIN_IDLE)
 
 JNZ  MAIN_IDLE            ; If pressed, return to idle

 INC ONES                  ; Increment ones digit
 CMP ONES, 10              ; If ones < 10, continue (stops at 9)
 JB  RUN_LOOP              ; jumps if ONES is below 10

 MOV ONES, 0               ; Reset ones, increment tens
 INC TENS
 CMP TENS, 10              ; If tens < 10, continue
 JB  RUN_LOOP
 MOV TENS, 0               ; Reset tens after 99
 JMP RUN_LOOP

;========================================================================
; SHOW_TWO_DIGITS: Output the current TENS and ONES values to 7-segment displays.
; - Uses XLAT to map digit value to segment pattern.
; - PORTA: ones digit, PORTB: tens digit.
;========================================================================

SHOW_TWO_DIGITS:
 PUSH AX                    ;preserves registers to avoid overwriting values
 PUSH BX
 PUSH DX

 ; Ones -> PORTA
 LEA BX, SEVEN_SEG         ; BX <- address of SEVEN_SEG table
 MOV AL, ONES              ; AL <- ones digit (0-9)
 XLAT                      ; AL <- segment pattern for ONES  (reads from table using AL as index)
 MOV DX, PORTA             ; DX <- PORTA address
 OUT DX, AL                ; Output pattern to ones display

 ; Tens -> PORTB
 LEA BX, SEVEN_SEG         ; BX <- address of SEVEN_SEG table
 MOV AL, TENS              ; AL <- tens digit (0-9)
 XLAT                      ; AL <- segment pattern for TENS
 MOV DX, PORTB             ; DX <- PORTB address
 OUT DX, AL                ; Output pattern to tens display

 POP DX                   ; Reverse because of LIFO stack
 POP BX
 POP AX
 RET

;========================================================================
; DELAY: Simple software delay using nested loops.
; - Adjust CX and SI for timing.
;========================================================================

DELAY:
 PUSH CX                   ; Preserve registers (CX is also used by LOOP)
 PUSH SI                   ; Preserve SI  (kinda not needed)
 MOV CX, 50                ; Outer loop count (lower = faster)
D1: MOV SI, 400            ; Inner loop count
D2: DEC SI
    JNZ D2                 ; Inner loop
    LOOP D1                ; Outer loop
 POP SI
 POP CX
 RET

;========================================================================
; PROGRAM END: Mark end of code segment and define the entry point.
;========================================================================

CODE ENDS 
END START