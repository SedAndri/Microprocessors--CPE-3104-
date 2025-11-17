; -----------------------------------------------------------------------------
; Project: 8255 + 8253 + 8259 + LCD + Keypad countdown timer
; CPU: 8086/88 style assembly (MASM/TASM syntax)
; Hardware:
;   - 8255 PPI (x2) for LCD and keypad I/O
;   - 8253 PIT (timer) for periodic timing
;   - 8259 PIC (interrupt controller) remapped to vector 0x80
;   - Character LCD (RS/E on PORTB, data on PORTA)
;   - Matrix keypad on PORTC
; Behavior:
;   - Prompts for time in minutes via keypad
;   - Press '*' to start countdown (mm:ss)
;   - Uses an ISR that toggles a software flag (CLOCK_FLAG) each timer event
; Notes:
;   - This code assumes specific I/O addresses for devices.
;   - Vector table write uses ES: make sure ES=0000h when writing IVT.
;   - MOV CS, AX is not legal on 8086. You normally keep CS as set by the loader
;     or use a far jump to change it. This line is commented on to warn beginners.
;   - Some busy-wait/polling sections assume specific external wiring.
; -----------------------------------------------------------------------------

INTERRUPT SEGMENT

   ISR0 PROC FAR                 ; Interrupt Service Routine (far, for IVT entry)
      ASSUME CS:INTERRUPT, DS:DATA
      ORG 0500H                 ; Place ISR code at offset 0500h within this segment
      PUSH AX                   ; Save registers used in ISR
      PUSH BX
      PUSH CX
      PUSH DX
      
      ; Toggle CLOCK_FLAG between 0 and 1 each time the ISR fires.
      ; Note: MOV does not affect flags; JZ here relies on ZF from the previous CMP.
      CMP CLOCK_FLAG, 1
      JZ SET_CLOCK_0            ; If flag was 1, set it to 0
      
      CMP CLOCK_FLAG, 0
      JZ SET_CLOCK_1            ; If flag was 0, set it to 1
      
      JMP SKIP_CLOCK_SET        ; If somehow neither, skip

      SET_CLOCK_0:
      MOV CLOCK_FLAG, 0         ; Set flag to 0
      JZ SKIP_CLOCK_SET         ; ZF still set from CMP above, jump out

      SET_CLOCK_1:
      MOV CLOCK_FLAG, 1         ; Set flag to 1
      JZ SKIP_CLOCK_SET         ; ZF still set from CMP above, jump out
      
      SKIP_CLOCK_SET:
      
      POP DX                    ; Restore registers
      POP CX
      POP BX
      POP AX
      IRET                      ; Return from interrupt
   ISR0 ENDP
   
INTERRUPT ENDS


DATA 	SEGMENT

   ORG 01000H                   ; Place data starting at this offset (assembler layout decision)

   ; 8255 #1 I/O addresses (assumed hardware mapping)
   PORTA 	EQU 0C0H           ; 8255 #1 Port A (LCD data)
   PORTB	EQU 0C2H           ; 8255 #1 Port B (LCD control: RS/E)
   PORTC	EQU 0C4H           ; 8255 #1 Port C (Keypad lines)
   C_REG	EQU 0C6H           ; 8255 #1 Control register

   CWORD	EQU 089H           ; 8255 control word: 1000 1001b
                             ; D7=1 (mode set), GA Mode=00 (Mode 0), PA=0 (out),
                             ; PC upper=1 (in), GB Mode=0 (Mode 0), PB=0 (out),
                             ; PC lower=1 (in). Adjust to your wiring.
   
   ; 8255 #2 I/O addresses (assumed for timer-ready input or other signals)
   PORTA_2	EQU 0D0H
   PORTB_2	EQU 0D2H
   PORTC_2	EQU 0D4H
   C_REG_2	EQU 0D6H
   
   ; 8253 PIT
   CLOCK_CREG	EQU 0DEH        ; PIT control register
   CLOCK0	    EQU 0D8H        ; PIT counter 0 data port
   
   ; 8259 PIC (single PIC assumed; PIC1=command, PIC2=data)
   PIC1		EQU 0C8H           ; PIC command port
   PIC2		EQU 0CAH           ; PIC data port
   
   ICW1		EQU 013H           ; Edge triggered, ICW4 needed (0001 0011b) - verify for your PIC
   ICW2		EQU 080H           ; Remap base vector to 0x80
   ICW4		EQU 03H            ; 8086/88 mode, normal EOI (0000 0011b)
   
   OCW1		EQU 11111110B      ; Unmask only IR0 (bit 0 = 0 = enabled); others masked

   ; LCD command constants
   CLR_DSP	EQU 1H             ; Clear display
   CR_HOME	EQU 2H             ; Cursor home
   FUNC1	EQU 00000110B      ; Entry mode set: increment, no shift
   DISP_ON	EQU 00001100B      ; Display on, cursor off, blink off
   FUNC2	EQU 00111000B      ; Function set: 8-bit, 2-line, 5x8 dots
   
   ; Variables
   MINUTE 	DB 0               ; Current minutes (0..99)
   SECOND	DB 0               ; Current seconds (0..59)
   
   CLOCK_FLAG	DB 0              ; Toggled by ISR to pace countdown
   
   KEYPAD_ARR 	DB 1,4,7,'*',2,5,8,0,3,6,9,'#'  ; Keypad scan-to-value map
   
   S_PROMPT 	DB 'Input time!$'  ; LCD string (terminated by '$' for this routine)
   
   ; Timing preset:
   ; If 1 second equals PIT count 4000, then for 1/100 second use 40 (example math).
   CLOCK_CYCLE 	DW 40             ; Number loaded into PIT for one tick period
   
DATA	ENDS

STK SEGMENT STACK
   BOS		DW 64 DUP(?)       ; Simple stack buffer (64 words)
   TOS		LABEL WORD         ; Top-of-stack label
STK ENDS

CODE    SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE, DS:DATA, SS: STK
    
    ORG 02000H                 ; Place code at this offset

START:
        SEG_INIT:               ; Initialize segment registers
    ; CAUTION: MOV CS, AX is illegal on 8086. CS is set by loader.
    ; If you need to change CS, use a far jump. Keeping as-is to match original.
       MOV AX, CODE            ; Load code segment value (for reference)
       MOV CS, AX              ; Not valid on real 8086; included per original code
       MOV AX, DATA            ; Load data segment
       MOV DS, AX              ; DS = DATA
       MOV AX, STK             ; Load stack segment
       MOV SS, AX              ; SS = STK
       LEA SP, TOS             ; SP points to top of stack
     
       CLI                     ; Disable interrupts during init

    P8255_INIT:                ; Initialize both 8255 PPIs with same control word
       MOV DX, C_REG           ; DX = 8255 #1 control register
       MOV AL, CWORD           ; AL = control word
       OUT DX, AL              ; Program 8255 #1
       
       MOV DX, C_REG_2         ; DX = 8255 #2 control register
       OUT DX, AL              ; Program 8255 #2
    
    LCD_INIT:                  ; Initialize LCD (clear, home, entry mode, display on, function set)
        MOV AL, CLR_DSP
        CALL LCD_COMMAND
        
        MOV AL, CR_HOME
        CALL LCD_COMMAND
        
        MOV AL, FUNC1
        CALL LCD_COMMAND
        
        MOV AL, DISP_ON
        CALL LCD_COMMAND
        
        MOV AL, FUNC2
        CALL LCD_COMMAND
        
     ISR_INIT:                 ; Initialize PIC and install ISR vector
        MOV DX, PIC1           ; PIC command port
        MOV AL, ICW1           ; ICW1: start init sequence
        OUT DX, AL
        
        MOV DX, PIC2           ; PIC data port
        MOV AL, ICW2           ; ICW2: base vector = 0x80
        OUT DX, AL
        
        MOV AL, ICW4           ; ICW4: 8086/88 mode
        OUT DX, AL
        
        MOV AL, OCW1           ; OCW1: mask all but IR0
        OUT DX, AL
        
        ; Install ISR0 at vector 0x80 (offset 0x200 in IVT).
        ; Each vector is 4 bytes; 0x80 * 4 = 0x200.
        ; CAUTION: ES must be 0000h to access IVT at 0000:0000!
        MOV AX, OFFSET ISR0    ; AX = offset of ISR0 within INTERRUPT segment
        MOV [ES:200H], AX      ; Write offset to IVT entry (0x80*4)
        MOV AX, SEG ISR0       ; AX = segment of ISR0
        MOV [ES:202H], AX      ; Write segment to IVT entry
        
     MAIN:                     ; Main UI loop
        MOV AL, 2              ; Row (Y) = 2
        MOV AH, 5              ; Column (X) = 5
        CALL LCD_CURSOR        ; Position cursor at (5,2)
        
        MOV DX, OFFSET S_PROMPT ; DX = address of prompt string
        CALL LCD_STRING        ; Print "Input time!"
        
        GET_TIME:               ; Time input loop
           CALL DISPLAY_TIME   ; Show current mm:ss
        
           CALL KEYPAD_INPUT   ; Wait for key, return in AL
           
           CMP AL, '*'         ; Start countdown?
           JZ COUNT_DOWN_INIT
           
           CMP AL, '#'         ; Ignore and refresh prompt?
           JZ GET_TIME
           
           ; Accumulate minutes as a decimal number: MINUTE = MINUTE*10 + key
           PUSH AX             ; Save key (AL)
           
           XOR AH, AH          ; AH = 0 for multiply
           MOV AL, MINUTE      ; AL = current minutes
           MOV BX, 10          ; BX = 10
           MUL BX              ; AX = AL * 10
           
           POP BX              ; BX low byte = new digit (from keypad)
           
           ADD AX, BX          ; AX = old*10 + new_digit
           
           CMP AX, 100         ; Keep minutes within 0..99
           JNGE SKIP_TIME_RESET
           
           MOV MINUTE, 0       ; If >= 100, reset minutes
           XOR AX, AX
           
           SKIP_TIME_RESET:
           
           MOV MINUTE, AL      ; Store updated minutes (low byte)
           
           MOV CX, 50000       ; Small debounce/UX delay
           CALL DELAY
           
           JMP GET_TIME        ; Read next key
           
        COUNT_DOWN_INIT:
           STI                 ; Enable interrupts (ISR will toggle CLOCK_FLAG)
           
           MOV AL, CLR_DSP     ; Clear LCD before countdown
           CALL LCD_COMMAND
           
        COUNT_DOWN:            ; Countdown loop paced by CLOCK_FLAG and PIT
           CMP CLOCK_FLAG, 0   ; Wait for flag to be 0 (edge-based gating)
           JNZ COUNT_DOWN      ; Spin until the ISR toggles it to 0
           
           CMP SECOND, 0       ; If seconds == 0, need to borrow from minutes
           JNZ SKIP_DEC
           
           CALL DISPLAY_TIME   ; Update display before minute decrement
           
           DEC MINUTE	        ; Decrement minute
           MOV SECOND, 59      ; Reset seconds to 59
           
           SKIP_DEC:            
           
           CALL DISPLAY_TIME   ; Show mm:ss
           
           DEC SECOND          ; Decrement seconds
            
           CMP SECOND, 0       ; If seconds hit 0, check if minutes also 0
           JNZ SKIP_CHECK
           
           CMP MINUTE, 0
           JNZ SKIP_CHECK
           
           ; Countdown completed (00:00)
           CALL DISPLAY_TIME
           MOV CX, CLOCK_CYCLE ; One more tick delay for neat finish
           CALL CLOCK_DELAY
           
           JMP START           ; Restart program
           
           SKIP_CHECK:
           
           MOV CX, CLOCK_CYCLE ; Wait one timing unit using PIT
           CALL CLOCK_DELAY
           
           JMP COUNT_DOWN      ; Next tick
        
        JMP MAIN               ; Redundant safety jump (loop)
        
    
ENDLESS:
        JMP ENDLESS             ; Failsafe infinite loop if ever reached
    
; ============================== PROCEDURES ===============================

; CLOCK_DELAY
; - Input: CX = count to load into PIT counter 0 (low then high byte)
; - Behavior: Programs 8253 counter 0 (mode 0, BCD) and busy-waits until
;             a non-zero value is seen on PORTC_2 (external ready/pulse).
; - Notes: Control word 0011 0001b = counter 0, lobyte/hibyte, mode 0, BCD=1.
CLOCK_DELAY PROC
   PUSH AX
   PUSH CX
   PUSH DX
   
   MOV AL, 00110001B      ; PIT control: SC=00 (ctr0), RL=11 (lo/hi), M=000 (mode0), BCD=1
   MOV DX, CLOCK_CREG     ; DX = PIT control port
   OUT DX, AL             ; Write control word
   
   MOV DX, CLOCK0         ; DX = PIT counter 0 data port
   MOV AL, CL             ; Load low byte of count
   OUT DX, AL             ; Write low byte
   
   MOV AL, CH             ; Load high byte of count
   OUT DX, AL             ; Write high byte
   
   MOV DX, PORTC_2        ; Poll an external signal on 8255 #2 Port C
CLOCK_DELAY_POLL:
      IN AL, DX           ; Read port
      CMP AL, 0           ; Wait until it becomes non-zero
      JZ CLOCK_DELAY_POLL
   
   POP DX
   POP CX
   POP AX
   RET
CLOCK_DELAY ENDP


; DISPLAY_TIME
; - Uses MINUTE and SECOND
; - Prints mm:ss at (X=?, Y=?). Caller positions cursor beforehand.
DISPLAY_TIME PROC
   PUSH AX
   PUSH DX
   
   MOV AH, 8              ; X = 8 (column offset for nice centering)
   MOV AL, 1              ; Y = 1 (row 1)
   CALL LCD_CURSOR        ; Move cursor
   
   MOV AL, MINUTE         ; Convert minutes to two ASCII digits
   CALL SEPARATE_NUM      ; AL=MSD, AH=LSD
   ADD AL, 30H            ; To ASCII
   ADD AH, 30H
   CALL LCD_DATA          ; Print MSD of minutes
   MOV AL, AH
   CALL LCD_DATA          ; Print LSD of minutes
   
   MOV AL, ':'            ; Separator
   CALL LCD_DATA
   
   MOV AL, SECOND         ; Convert seconds to two ASCII digits
   CALL SEPARATE_NUM
   ADD AL, 30H
   ADD AH, 30H
   CALL LCD_DATA          ; Print MSD of seconds
   MOV AL, AH
   CALL LCD_DATA          ; Print LSD of seconds
   
   POP AX
   POP DX
   RET
DISPLAY_TIME ENDP

; SEPARATE_NUM
; - Input: AL = 0..99
; - Output: AL = MSD (tens), AH = LSD (ones)
SEPARATE_NUM PROC
   PUSH BX
   XOR AH, AH
   MOV BL, 10
   DIV BL                 ; AL/10 => AL=quotient (tens), AH=remainder (ones)
   POP BX
   RET
SEPARATE_NUM ENDP

; KEYPAD_INPUT
; - Output: AL = value from KEYPAD_ARR (digits 0..9, '*' or '#')
; - Behavior: Polls PORTC until a key code is present, maps via KEYPAD_ARR.
; - Note: This uses DL (low byte) to form address; ensure KEYPAD_ARR is within
;         the same 256-byte page as its base for this to be safe.
; - Note: No key release debounce; may need further conditioning.
KEYPAD_INPUT PROC
   PUSH DX
   
   MOV DX, PORTC
KEYPAD_INPUT_LOOP:
      IN AL, DX           ; Read keypad-encoded value
      CMP AL, 16          ; Wait until value >= 16 (as per this wiring)
      JGE KEYPAD_INPUT_SKIP
      JMP KEYPAD_INPUT_LOOP
   
KEYPAD_INPUT_SKIP:
   XOR AL, 00010000B      ; Toggle bit 4 (depends on hardware encoding)
   
   MOV DX, OFFSET KEYPAD_ARR ; DX = base of table
   ADD DL, AL             ; DL += keycode (AL). CAUTION: page-boundary sensitive.
   MOV SI, DX             ; SI = effective address
   MOV AL, [SI]           ; AL = mapped key
   
   POP DX
   RET
KEYPAD_INPUT ENDP

; LCD_STRING
; - Input: DX = address of '$'-terminated string
; - Prints each char until '$'
LCD_STRING PROC
   PUSH AX
   PUSH DX
   
   MOV SI, DX
STRING_LOOP:
      MOV AL, [SI]        ; Load next char
      CMP AL, '$'         ; End?
      JZ STRING_LOOP_SKIP
      CALL LCD_DATA       ; Print char
      INC SI
      JMP STRING_LOOP
   
STRING_LOOP_SKIP:
   POP DX
   POP AX
   RET
LCD_STRING ENDP

; LCD_CURSOR
; - Input: AH = X (column offset), AL = Y (row: 0..3)
; - Computes DDRAM address base per row and adds X, then sends as command.
LCD_CURSOR PROC
   PUSH DX
   PUSH AX
   
   CMP AL, 0
   JZ CURSOR_0
   CMP AL, 1
   JZ CURSOR_1
   CMP AL, 2
   JZ CURSOR_2
   CMP AL, 3
   JZ CURSOR_3
   
   JMP LCD_CURSOR_SKIP
CURSOR_0:
      MOV AL, 080H        ; Row 0 base
      JMP LCD_CURSOR_SKIP
CURSOR_1:
      MOV AL, 0C0H        ; Row 1 base
      JMP LCD_CURSOR_SKIP
CURSOR_2:
      MOV AL, 094H        ; Row 2 base (typical 20x4 mapping)
      JMP LCD_CURSOR_SKIP
CURSOR_3:
      MOV AL, 0D4H        ; Row 3 base
      
LCD_CURSOR_SKIP:
   ADD AL, AH             ; Add X offset
   CALL LCD_COMMAND       ; Send as command
   
   POP AX
   POP DX
   RET
LCD_CURSOR ENDP

; LCD_COMMAND
; - Input: AL = command byte
; - Writes AL to LCD via PORTA, toggles control lines on PORTB (RS=0, E pulse).
LCD_COMMAND PROC
   PUSH AX
   PUSH CX
   PUSH DX
   
   MOV DX, PORTA
   OUT DX, AL             ; Put command on data bus
   
   MOV DX, PORTB
   MOV AL, 00000001B      ; RS=0 (command), E=1 (enable pulse start)
   OUT DX, AL
   MOV AL, 00000000B      ; RS=0, E=0 (latch)
   OUT DX, AL
   
   MOV CX, 1000           ; Small settle delay
   CALL DELAY
   
   POP DX
   POP CX
   POP AX
   RET
LCD_COMMAND ENDP

; LCD_DATA
; - Input: AL = data byte (ASCII char)
; - Writes AL to LCD via PORTA, toggles control lines on PORTB (RS=1, E pulse).
LCD_DATA PROC
   PUSH AX
   PUSH CX
   PUSH DX
   
   MOV DX, PORTA
   OUT DX, AL             ; Put data on bus
   
   MOV DX, PORTB
   MOV AL, 00000011B      ; RS=1 (data), E=1
   OUT DX, AL
   MOV AL, 00000010B      ; RS=1, E=0
   OUT DX, AL
   
   MOV CX, 1000           ; Small settle delay
   CALL DELAY
   
   POP DX
   POP CX
   POP AX
   RET
LCD_DATA ENDP

; DELAY
; - Input: CX = loop count
; - Busy-wait loop using LOOP instruction. Preserves CX on return.
DELAY PROC
   PUSH CX
DELAY_LOOP:
      NOP
   LOOP DELAY_LOOP
   POP CX
   RET
DELAY ENDP

CODE    ENDS
        END START