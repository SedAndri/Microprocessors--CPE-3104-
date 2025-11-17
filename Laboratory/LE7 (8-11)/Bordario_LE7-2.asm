; Bordario, Sid Andre P.
; Program overview (beginner-friendly):
; - Uses two interrupt service routines (ISR1, ISR2).
; - Reads a 4-bit code from the lower nibble of PORTC (PC0–PC3).
; - Displays the corresponding symbol on 7-seg connected to PORTA (in ISR1).
; - Mirrors the same symbol on 7-seg connected to PORTB (in ISR2), using CL set by ISR1.
; - Configures an 8255-like PPI and an 8259-like PIC.
; - Installs interrupt vectors for IR0 (0x80) and IR1 (0x81).
; - Main loop periodically pulses PC7 (upper nibble of PORTC) to generate/handshake interrupts.

; ------------------------------
; ISR1: Reads input on PORTC (lower nibble), displays on PORTA, saves code in CL
; ------------------------------
PROCED1 SEGMENT
ISR1 PROC FAR                 ; FAR ISR: returns with IRET (needs segment:offset)
ASSUME CS:PROCED1, DS:DATA
ORG 01000H                    ; Place ISR1 at offset 0x1000 in its segment
    PUSHF                     ; Save FLAGS (interrupt state, etc.)
    PUSH AX                   ; Save AX (used below)
    PUSH DX                   ; Save DX (used for port addressing)
    ; NOTE: This ISR uses CL but does not save/restore CX.
    ; For safety, consider: PUSH CX ... POP CX (if other code depends on CX).

    MOV DX, PORTC             ; Select I/O port address for Port C (PPI)
        IN AL,DX                 ; Read 8-bit value from Port C
    AND AL,0FH                ; Mask to keep only lower 4 bits (PC0–PC3)
    ; Compare the 4-bit code against known patterns and jump to handlers
    CMP AL,00H
    JE _ONE
    CMP AL,01H
    JE _TWO
    CMP AL,02H
    JE _THREE
    CMP AL,04H
    JE _FOUR
    CMP AL,05H
    JE _FIVE
    CMP AL,06H
    JE _SIX
    CMP AL,08H
    JE _SEVEN
    CMP AL,09H
    JE _EIGHT
    CMP AL,0AH
    JE _NINE
    CMP AL,0CH
    JE _DASH
    CMP AL,0DH
    JE _ZERO
    CMP AL,0EH
    JE _DASH                  ; Some codes intentionally map to dash

    _ZERO:                    ; Show 0 on PORTA
        MOV CL, AL           ; Save original 4-bit code for ISR2
        MOV DX, PORTA        ; Select Port A (7-seg A)
        MOV AL, NUMB0        ; 7-seg pattern for '0'
        OUT DX, AL           ; Output to display
        JMP END_CHECK
    _ONE:                     ; Show 1 on PORTA
        MOV CL, AL
        MOV DX, PORTA
        MOV AL, NUMB1
        OUT DX, AL
        JMP END_CHECK
    _TWO:                     ; Show 2 on PORTA
        MOV CL, AL
        MOV DX, PORTA
        MOV AL, NUMB2
        OUT DX, AL
        JMP END_CHECK
    _THREE:                   ; Show 3 on PORTA
        MOV CL, AL
        MOV DX, PORTA
        MOV AL, NUMB3
        OUT DX, AL
        JMP END_CHECK
    _FOUR:                    ; Show 4 on PORTA
        MOV CL, AL
        MOV DX, PORTA
        MOV AL, NUMB4
        OUT DX, AL
        JMP END_CHECK
    _FIVE:                    ; Show 5 on PORTA
        MOV CL, AL
        MOV DX, PORTA
        MOV AL, NUMB5
        OUT DX, AL
        JMP END_CHECK
    _SIX:                     ; Show 6 on PORTA
        MOV CL, AL
        MOV DX, PORTA
        MOV AL, NUMB6
        OUT DX, AL
        JMP END_CHECK
    _SEVEN:                   ; Show 7 on PORTA
        MOV CL, AL
        MOV DX, PORTA
        MOV AL, NUMB7
        OUT DX, AL
        JMP END_CHECK
    _EIGHT:                   ; Show 8 on PORTA
        MOV CL, AL
        MOV DX, PORTA
        MOV AL, NUMB8
        OUT DX, AL
        JMP END_CHECK
    _NINE:                    ; Show 9 on PORTA
        MOV CL, AL
        MOV DX, PORTA
        MOV AL, NUMB9
        OUT DX, AL
        JMP END_CHECK
    _DASH:                    ; Show '-' on PORTA
        MOV CL, AL
        MOV DX, PORTA
        MOV AL, NUMBN
        OUT DX, AL
        JMP END_CHECK
        
    END_CHECK:
    ; Optional but typical for 8259-based ISRs: send EOI to PIC before IRET
    ; MOV AL, 20H           ; Non-specific EOI
    ; MOV DX, PIC1          ; PIC command port
    ; OUT DX, AL
    POP DX                   ; Restore DX
    POP AX                   ; Restore AX
    POPF                     ; Restore FLAGS
    IRET                     ; Return from interrupt (far return)
    ISR1 ENDP
PROCED1 ENDS

; ------------------------------
; ISR2: Mirrors last symbol onto PORTB based on CL set by ISR1
; ------------------------------
PROCED2 SEGMENT
ISR2 PROC FAR
ASSUME CS:PROCED2, DS:DATA
ORG 02000H                    ; Place ISR2 at offset 0x2000
    PUSHF
    PUSH AX
    PUSH DX
    ; WARNING: Uses CL but does not preserve CX.
    ; Consider PUSH CX / POP CX if needed.

    ; Compare saved code in CL and output the matching 7-seg pattern on PORTB
    CMP CL,00H
    JE _ONE
    CMP CL,01H
    JE _TWO
    CMP CL,02H
    JE _THREE
    CMP CL,04H
    JE _FOUR
    CMP CL,05H
    JE _FIVE
    CMP CL,06H
    JE _SIX
    CMP CL,08H
    JE _SEVEN
    CMP CL,09H
    JE _EIGHT
    CMP CL,0AH
    JE _NINE
    CMP CL,0CH
    JE _DASH
    CMP CL,0DH
    JE _ZERO
    CMP CL,0EH
    JE _DASH

    _ZERO:                    ; Show 0 on PORTB
        MOV DX, PORTB
        MOV AL, NUMB0
        OUT DX, AL
        JMP END_CHECK
    _ONE:                     ; Show 1 on PORTB
        MOV DX, PORTB
        MOV AL, NUMB1
        OUT DX, AL
        JMP END_CHECK
    _TWO:                     ; Show 2 on PORTB
        MOV DX, PORTB
        MOV AL, NUMB2
        OUT DX, AL
        JMP END_CHECK
    _THREE:                   ; Show 3 on PORTB
        MOV DX, PORTB
        MOV AL, NUMB3
        OUT DX, AL
        JMP END_CHECK
    _FOUR:                    ; Show 4 on PORTB
        MOV DX, PORTB
        MOV AL, NUMB4
        OUT DX, AL
        JMP END_CHECK
    _FIVE:                    ; Show 5 on PORTB
        MOV DX, PORTB
        MOV AL, NUMB5
        OUT DX, AL
        JMP END_CHECK
    _SIX:                     ; Show 6 on PORTB
        MOV DX, PORTB
        MOV AL, NUMB6
        OUT DX, AL
        JMP END_CHECK
    _SEVEN:                   ; Show 7 on PORTB
        MOV DX, PORTB
        MOV AL, NUMB7
        OUT DX, AL
        JMP END_CHECK
    _EIGHT:                   ; Show 8 on PORTB
        MOV DX, PORTB
        MOV AL, NUMB8
        OUT DX, AL
        JMP END_CHECK
    _NINE:                    ; Show 9 on PORTB
        MOV DX, PORTB
        MOV AL, NUMB9
        OUT DX, AL
        JMP END_CHECK
    _DASH:                    ; Show '-' on PORTB
        MOV DX, PORTB
        MOV AL, NUMBN
        OUT DX, AL
        JMP END_CHECK
        
        END_CHECK:
    ; Optional EOI for PIC:
    ; MOV AL, 20H
    ; MOV DX, PIC1
    ; OUT DX, AL
    POP DX
    POP AX
    POPF
    IRET
    ISR2 ENDP
PROCED2 ENDS

; ------------------------------
; DATA: I/O port addresses, PIC constants, and 7-seg bitmaps
; ------------------------------
DATA SEGMENT
    ORG 03000H                ; Place data at offset 0x3000
    PORTA EQU 0F0H            ; PPI Port A address
    PORTB EQU 0F2H            ; PPI Port B address
    PORTC EQU 0F4H            ; PPI Port C address (lower nibble as input, upper as output)
    COM_REG EQU 0F6H          ; PPI control register (8255)
    PIC1 EQU 0F8H             ; PIC command port (A1 = 0)
    PIC2 EQU 0FAH             ; PIC data port (A1 = 1)
    ICW1 EQU 13H              ; PIC ICW1: edge-triggered, requires ICW4 (board-specific)
    ICW2 EQU 80H              ; PIC base vector = 0x80 (IR0->0x80, IR1->0x81, ...)
    ICW4 EQU 03H              ; PIC ICW4: 8086/88 mode, normal EOI
    OCW1 EQU 0FCH             ; PIC interrupt mask: 11111100b (IR0 and IR1 unmasked)

    NUMB0 EQU 00111111B       ; 7-seg pattern for '0'
    NUMB1 EQU 00000110B       ; '1'
    NUMB2 EQU 01011011B       ; '2'
    NUMB3 EQU 01001111B       ; '3'
    NUMB4 EQU 01100110B       ; '4'
    NUMB5 EQU 01101101B       ; '5'
    NUMB6 EQU 01111101B       ; '6'
    NUMB7 EQU 00000111B       ; '7'
    NUMB8 EQU 01111111B       ; '8'
    NUMB9 EQU 01101111B       ; '9'
    NUMBN EQU 01000000B       ; '-' (dash)
    ; Note: These bitmaps assume a specific 7-seg wiring (likely common-cathode).
    ; If your display is common-anode or wired differently, invert/adjust bits.

DATA ENDS

; ------------------------------
; STACK: reserve space and define top-of-stack label
; ------------------------------
STK SEGMENT STACK
    BOS DW 64d DUP(?)         ; Reserve 64 words for stack
    TOS LABEL WORD            ; Label marking top of stack
STK ENDS

; ------------------------------
; CODE: Initialization, vector install, and main loop
; ------------------------------
CODE SEGMENT PUBLIC 'CODE'
ASSUME CS:CODE, DS:DATA, SS:STK
ORG 03000H

    START:
        ; Set up data segment
        MOV AX, DATA
        MOV DS, AX
        ; Set up stack segment and pointer
        MOV AX, STK
        MOV SS, AX
        LEA SP, TOS
        CLI                      ; Disable interrupts during hardware setup

        ; Configure 8255 PPI: 0x81 = 1000_0001b
        ; - Mode set
        ; - Group A mode 0
        ; - Port A = output
        ; - Port C upper (PC7-4) = output
        ; - Group B mode 0
        ; - Port B = output
        ; - Port C lower (PC3-0) = input
        MOV DX, COM_REG
        MOV AL, 81H
        OUT DX, AL

        ; Initialize 8259 PIC:
        ; ICW1 -> command, ICW2/ICW4 -> data, then OCW1 mask
        MOV DX, PIC1
        MOV AL, ICW1
        OUT DX, AL
        MOV DX, PIC2
        MOV AL, ICW2
        OUT DX, AL
        MOV AL, ICW4
        OUT DX, AL
        MOV AL, OCW1
        OUT DX, AL
        STI                      ; Enable maskable interrupts

        ; Install interrupt vectors for 0x80 (IR0) and 0x81 (IR1)
        ; NOTE: The IVT lives in segment 0000h. Make sure ES=0000 before writing.
        ; If ES is not known to be 0000, do this first:
        ; XOR AX, AX
        ; MOV ES, AX
        MOV AX, OFFSET ISR1      ; ISR1 offset
        MOV [ES:200H], AX        ; 0x80 * 4 = 0x200
        MOV AX, SEG ISR1         ; ISR1 segment
        MOV [ES:202H], AX
        MOV AX, OFFSET ISR2      ; ISR2 offset
        MOV [ES:204H], AX        ; 0x81 * 4 = 0x204
        MOV AX, SEG ISR2         ; ISR2 segment
        MOV [ES:206H], AX

        ; Initialize both 7-seg displays to '0'
           MOV DX, PORTA 
           MOV AL, NUMB0
           OUT DX, AL             ; Show '0' on PORTA
         
           MOV DX, PORTB 
           MOV AL, NUMB0
           OUT DX, AL             ; Show '0' on PORTB
    
    HERE:
        ; Main loop: generate a pulse on PC7 (upper nibble output) with delays
        CALL DELAY_5MS
        CALL DELAY_5MS           ; ~10ms total
        MOV DX, PORTC
        MOV AL, 80H              ; Set PC7 = 1 (1000_0000b), others 0
        OUT DX, AL
        CALL DELAY_5MS
        CALL DELAY_5MS
        MOV AL, 00H              ; Set PC7 = 0
        OUT DX, AL
        JMP HERE                 ; Repeat forever

    ; Simple busy-wait delay (duration depends on CPU clock)
    DELAY_5MS:
        MOV BX, 0DF2H            ; Loop count chosen for (~)5ms on target system
    L1:
        DEC BX
        NOP
        JNZ L1
        RET	
    
CODE ENDS
END START