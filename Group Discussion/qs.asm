;====================================================================
; 8086 + 8255 + ADC0808
; VREF+ = 5V, VREF- = 0V, external CLOCK = 500 kHz
; PORTA[3:0] -> BCD to 7-seg (decimal digit via 74LS48)
; PORTA[7:4] -> BCD to 7-seg (whole digit via 74LS48)
; PORTB -> control lines (ADD_A,ADD_B,ADD_C,START,ALE,OE)
; PORTC <- ADC0808 OUT0..OUT7 (data)
;====================================================================

DATA SEGMENT
    PORTA   EQU 0F0H
    PORTB   EQU 0F2H
    PORTC   EQU 0F4H
    COM_REG EQU 0F6H

    PB_ADDR_IN0 EQU 00H     ; ADD_C..A = 000
    PB_ALE      EQU 10H     ; PB4 = ALE
    PB_START    EQU 08H     ; PB3 = START
    PB_OE       EQU 20H     ; PB5 = OE (active LOW)
DATA ENDS

CODE SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE

START:
        ; 8255: PA=out, PB=out, PC=in
        mov dx, COM_REG
        mov al, 089h
        out dx, al

        ; Quick hardware check: show "3 1" for a moment
        mov dx, PORTA
        mov al, 0AAh              ; PA[7:4]=0, PA[3:0]=0
        out dx, al
        call DELAY_100MS

MAIN_LOOP:
        ; --------------------------
        ; 1) Select IN0 (address 000)
        ; --------------------------
        mov dx, PORTB
        mov al, PB_ADDR_IN0
        out dx, al

        ; 2) ALE = 1 (latch address)
        mov al, PB_ADDR_IN0 or PB_ALE
        out dx, al
        call DELAY_SHORT

        ; 3) START = 1 while ALE = 1
        mov al, PB_ADDR_IN0 or PB_ALE or PB_START
        out dx, al
        call DELAY_SHORT

        ; 4) Drop ALE (keep START high briefly)
        mov al, PB_ADDR_IN0 or PB_START
        out dx, al
        call DELAY_SHORT

        ; 5) START = 0 → start conversion
        mov al, PB_ADDR_IN0
        out dx, al

        ; ----------------------------------------
        ; Wait until EOC (PC7 = 1) → conversion done
        ; ----------------------------------------
WAIT_EOC:
        mov dx, PORTC
        in  al, dx
        test al, 80h              ; PC7 bit check
        jz   WAIT_EOC

        ; ----------------------------------------
        ; 6) OE = 0 (active LOW) to enable outputs
        ; ----------------------------------------
        mov dx, PORTB
        mov al, PB_ADDR_IN0       ; OE = 0
        out dx, al
        call DELAY_SHORT

        ; 7) Read converted data from ADC (PC)
        mov dx, PORTC
        in  al, dx

        ; 8) Disable outputs (OE = 1)
        mov dx, PORTB
        mov al, PB_ADDR_IN0 or PB_OE
        out dx, al

        ; ----------------------------------------
        ; Scale 8-bit result (0–255) to 0.0–5.0 display
        ; ----------------------------------------
        xor ah, ah
        mov bl, 50
        mul bl           ; AX = AL * 50
        add ax, 128
        mov al, ah
        cmp al, 50
        jbe T_OK
        mov al, 50
T_OK:
        xor ah, ah
        mov bl, 10
        div bl           ; AL = tens, AH = ones
        mov cl, 4
        shl al, cl
        or  al, ah
        mov dx, PORTA
        out dx, al

        jmp MAIN_LOOP

;-------------------------------------------------
; Delays
;-------------------------------------------------
DELAY_SHORT:
        mov cx, 1		;;150
DS_L:   loop DS_L
        ret

DELAY_1MS:
        mov cx, 1		;3000 / 10
D1:     loop D1
        ret

DELAY_100MS:
        mov bx, 1	;1000
D100:   call DELAY_1MS
        dec bx
        jnz D100
        ret

CODE ENDS
END START
