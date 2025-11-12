;====================================================================
; 8086 + 8255 + ADC0808
; VREF+ = 5V, VREF- = 0V, external CLOCK = 500 kHz
; PORTA[3:0] -> BCD to 7-seg (decimal digit via 74LS48)
; PORTA[7:4] -> BCD to 7-seg (whole digit via 74LS48)
; PORTB -> control lines (ADD_A,ADD_B,ADD_C,START,ALE,OE)
; PORTC <- ADC0808 OUT0..OUT7 (data)
;====================================================================

;========================================================================
; Section: Data segment and I/O address/bit definitions
; Purpose: Define 8255 port addresses, control bit masks, and storage for
;          the last valid ADC reading.
;========================================================================
DATA SEGMENT
    PORTA   EQU 0F0H
    PORTB   EQU 0F2H
    PORTC   EQU 0F4H
    COM_REG EQU 0F6H

    PB_ADDR_IN0 EQU 00H ; Bit pattern for selecting ADC address IN0 (ADD_C..ADD_A = 000)
    PB_ALE      EQU 10H ; Bit mask for ALE (Address Latch Enable) high on PB4
    PB_START    EQU 08H ; Bit mask for START high on PB3 to begin conversion
    ; Bit mask for OE high on PB5 to enable ADC data outputs
    PB_OE       EQU 20H     ; PB5 = OE (active HIGH)

    ; Reserve one byte to cache the last good ADC sample
    LAST_ADC    DB 0        ; last valid ADC sample
DATA ENDS
;=========================== End Section ==============================

;========================================================================
; Section: Code segment setup and hardware initialization
; Purpose: Set DS to the data segment, configure 8255 ports (PA/PB outputs,
;          PC input), and perform a quick display check on PORTA.
;========================================================================
CODE SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE, DS:DATA

START:
        ; Load DATA segment address into AX (prepare to set DS)
        mov ax, DATA
        ; Initialize DS with DATA segment so data labels are addressable
        mov ds, ax

        ; Point DX to 8255 control register for mode configuration
        mov dx, COM_REG
        ; Load AL with 089h = 1000_1001b:
        ;  D7=1 (mode set), Group A: PA output, Group B: PB output, PC input
        mov al, 089h
        ; Write control word to 8255 to set port directions/modes
        out dx, al

        ; Quick display check: output "21" on PORTA
        ;mov dx, PORTA
        ; Load AL with 021h to display "21" (tens=2 on PA[7:4], ones=1 on PA[3:0])
        ;mov al, 021h              ; PA[7:4]=2, PA[3:0]=1 (displays "21")
        
        ;out dx, al
        ; Wait ~100 ms so the check value is visible
        call DELAY_100MS
;=========================== End Section ==============================

;========================================================================
; Section: Main loop — Trigger ADC0808 conversion on IN0 and display scaled result
; Purpose: Sequence ALE/START signals, wait for EOC on PC7, enable OE to read
;          ADC data on PC[7:0], fix bit order, scale 0..255 to 0..50, split
;          into tens/ones BCD, and output to PORTA. Repeat forever.
;========================================================================
MAIN_LOOP:
        ; --------------------------
        ; 1) Select IN0 (address 000) and keep OE=0 (disabled)
        ; --------------------------
        ; Point DX to PORTB to drive ADC control/address lines
        mov dx, PORTB
        ; AL = address bits for IN0, OE low (ADC outputs tri-stated)
        mov al, PB_ADDR_IN0               ; OE=0 (disabled)
        ; Write address/control to PORTB with OE low
        out dx, al

        ; 2) ALE = 1 (latch address)
        ; Set ALE high while keeping address stable to latch channel on ADC
        mov al, PB_ADDR_IN0 or PB_ALE
        ; Assert ALE on PORTB
        out dx, al
        ; Short pause to meet ALE pulse width/timing
        call DELAY_SHORT

        ; 3) START = 1 while ALE = 1
        ; Raise START (with ALE still high) to begin conversion cycle
        mov al, PB_ADDR_IN0 or PB_ALE or PB_START
        ; Output to set both ALE and START high
        out dx, al
        ; Hold briefly to satisfy ADC setup/hold timing
        call DELAY_SHORT

        ; 4) Drop ALE (keep START high briefly)
        ; Deassert ALE while leaving START high per ADC timing diagram
        mov al, PB_ADDR_IN0 or PB_START
        ; Output to drop ALE, keep START asserted
        out dx, al
        ; Brief wait to ensure proper edge recognition
        call DELAY_SHORT

        ; 5) START = 0 ? start conversion
        ; Drop START to complete the start pulse; conversion proceeds internally
        mov al, PB_ADDR_IN0               ; still OE=0 (disabled)
        ; Output to finish the START pulse (falling edge triggers conversion)
        out dx, al

        ; ----------------------------------------
        ; Wait until EOC (PC7 = 1) ? conversion done
        ; (OE must remain 0 so PC7 reflects EOC, not D7)
        ; ----------------------------------------
WAIT_EOC:
        ; Point DX to PORTC to read EOC/data lines
        ;mov dx, PORTC
        ; Read current state of PC[7:0]
        ;in  al, dx
        ; Mask PC7 (bit 7) to test EOC line level
        ;test al, 80h                      ; PC7 bit check
        ; If EOC still low (0), keep waiting
        ;jz   WAIT_EOC

        ; ----------------------------------------
        ; 6) OE = 1 (active HIGH) to enable outputs
        ; ----------------------------------------
        ; Point DX back to PORTB to change OE
        mov dx, PORTB
        ; Set OE high while keeping address lines unchanged
        mov al, PB_ADDR_IN0 or PB_OE
        ; Enable ADC data outputs onto PORTC
        out dx, al
        ; Short delay to allow bus to settle before reading
        call DELAY_SHORT

        ; 7) Read converted data from ADC (PC), filter tri-state, then BIT-REVERSE
        ; Point DX to PORTC to read 8-bit ADC result
        mov dx, PORTC
        ; Read ADC output byte (may be invalid if bus floating)
        in  al, dx
        ; If bus reads as 0xFF (likely floating), treat as invalid sample
        cmp al, 0FFh    ;FOR CHECKING PURPOSES
        ; If valid (not 0xFF), skip substitution
        jne SAMPLE_OK
        ; Substitute last known good sample if current read looks invalid
        mov al, BYTE PTR [LAST_ADC]
SAMPLE_OK:
        ; reverse bit order (OUT8 is LSB) using 8086-safe rotates
        ; Clear AH to use as the destination for reversed bits
        xor ah, ah
        ; Initialize loop counter to 8 bits
        mov cl, 8
REV8:
        ; Shift AL right by 1 into CF, extracting next input bit (LSB first)
        rcr al, 1           ; shift input right into CF
        ; Shift result left through AH, inserting CF on the left (bit reversal)
        rcl ah, 1           ; shift CF into result left
        ; Decrement CL and loop until 8 bits processed
        loop REV8
        ; Move reversed bits from AH back to AL as the corrected sample
        mov al, ah
        ; Store the corrected sample for future use (and for tri-state fallback)
        mov BYTE PTR [LAST_ADC], al    ; store corrected sample

        ; 8) Disable outputs (OE = 0)
        ; Point DX to PORTB to deassert OE after read
        mov dx, PORTB
        ; Keep address lines, turn OE low to tri-state ADC outputs
        mov al, PB_ADDR_IN0
        ; Update PORTB to disable ADC bus drive
        out dx, al

        ; Scale 0..255 -> 0..50 (tenths), then pack tens:ones -> PA[7:4]:PA[3:0]
        ; Fetch latest ADC sample into AL
        mov al, BYTE PTR [LAST_ADC]
        ; Clear AH to prepare for 8-bit unsigned multiply into AX
        xor ah, ah
        ; Set BL to 50 (target range 0..50)
        mov bl, 50
        ; AX = AL * BL (8x8 -> 16-bit product)
        mul bl
        ; Add 128 for rounding when later taking high byte (divide by 256)
        add ax, 128
        ; AL = AH gives (AX >> 8) ≈ (sample*50 + 128)/256
        mov al, ah                 ; ~ (sample * 50 + 128) / 256
        ; Clamp to 50 in case of any rounding overflow
        cmp al, 50
        ; If AL <= 50, keep it
        jbe  SCALE_OK
        ; Else cap at 50
        mov al, 50
SCALE_OK:
        ; Prepare for BCD split: AH will receive remainder (ones)
        xor ah, ah
        ; Divisor 10 to split into tens and ones
        mov bl, 10
        ; Unsigned divide AX by BL: AL = quotient (tens), AH = remainder (ones)
        div bl                     ; AL=tens, AH=ones
        ; Shift tens into high nibble
        mov cl, 4
        shl al, cl                 ; tens -> high nibble
        ; Merge ones into low nibble
        or  al, ah                 ; ones -> low nibble
        ; Select PORTA for display output
        mov dx, PORTA
        ; Output packed BCD to drive two 7-seg digits via 74LS48
        out dx, al

        ; Repeat acquisition/display indefinitely
        jmp MAIN_LOOP
;=========================== End Section ==============================

;========================================================================
; Section: Delay subroutines
; Purpose: Provide short and approximate millisecond delays using tight
;          loop constructs. Timing depends on CPU clock.
;========================================================================
;-------------------------------------------------
; Delays
;-------------------------------------------------
DELAY_SHORT:
        ; CX = 150 iterations of LOOP (tight short delay ~few microseconds)
        mov cx, 150                      ; ~few us @ ~5MHz 8086
DS_L:   ; LOOP decrements CX and jumps if not zero
        loop DS_L
        ; Return to caller
        ret

DELAY_1MS:
        ; CX = 1000 iterations (~1 ms placeholder; exact time CPU-dependent)
        mov cx, 1000		;3000 / 10
D1:     ; LOOP until CX becomes zero
        loop D1
        ; Return to caller
        ret

DELAY_100MS:
        ; BX counts number of milliseconds to wait (placeholder value)
        mov bx, 1	;1000
D100:   ; Call 1 ms delay per iteration
        call DELAY_1MS
        ; Decrement BX and continue until zero
        dec bx
        jnz D100
        ; Return to caller
        ret
;=========================== End Section ==============================

CODE ENDS
END START