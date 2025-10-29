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

    PB_ADDR_IN0 EQU 00H
    PB_ALE      EQU 10H
    PB_START    EQU 08H
    PB_OE       EQU 20H     ; PB5 = OE (active HIGH)

    LAST_ADC    DB 0        ; last valid ADC sample
DATA ENDS

CODE SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE, DS:DATA

START:
        ; init DS to DATA segment
        mov ax, DATA
        mov ds, ax

        ; 8255: PA=out, PB=out, PC=in
        mov dx, COM_REG
        mov al, 089h
        out dx, al

        ; Quick hardware check: put a valid BCD nibble (2 | 1)
        mov dx, PORTA
        mov al, 021h              ; PA[7:4]=2, PA[3:0]=1 (displays "21")
        out dx, al
        call DELAY_100MS

MAIN_LOOP:
        ; --------------------------
        ; 1) Select IN0 (address 000) and keep OE=0 (disabled)
        ; --------------------------
        mov dx, PORTB
        mov al, PB_ADDR_IN0               ; OE=0 (disabled)
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
        mov al, PB_ADDR_IN0               ; still OE=0 (disabled)
        out dx, al

        ; ----------------------------------------
        ; Wait until EOC (PC7 = 1) → conversion done
        ; (OE must remain 0 so PC7 reflects EOC, not D7)
        ; ----------------------------------------
WAIT_EOC:
        mov dx, PORTC
        in  al, dx
        test al, 80h                      ; PC7 bit check
        jz   WAIT_EOC

        ; ----------------------------------------
        ; 6) OE = 1 (active HIGH) to enable outputs
        ; ----------------------------------------
        mov dx, PORTB
        mov al, PB_ADDR_IN0 or PB_OE
        out dx, al
        call DELAY_SHORT

        ; 7) Read converted data from ADC (PC), filter tri-state, then BIT-REVERSE
        mov dx, PORTC
        in  al, dx
        cmp al, 0FFh
        jne SAMPLE_OK
        mov al, BYTE PTR [LAST_ADC]
SAMPLE_OK:
        ; reverse bit order (OUT8 is LSB) using 8086-safe rotates
        xor ah, ah
        mov cl, 8
REV8:
        rcr al, 1           ; shift input right into CF
        rcl ah, 1           ; shift CF into result left
        loop REV8
        mov al, ah
        mov BYTE PTR [LAST_ADC], al    ; store corrected sample

        ; 8) Disable outputs (OE = 0)
        mov dx, PORTB
        mov al, PB_ADDR_IN0
        out dx, al

        ; Scale 0..255 -> 0..50 (tenths), then pack tens:ones -> PA[7:4]:PA[3:0]
        mov al, BYTE PTR [LAST_ADC]
        xor ah, ah
        mov bl, 50
        mul bl
        add ax, 128
        mov al, ah                 ; ~ (sample * 50 + 128) / 256
        cmp al, 50
        jbe  SCALE_OK
        mov al, 50
SCALE_OK:
        xor ah, ah
        mov bl, 10
        div bl                     ; AL=tens, AH=ones
        mov cl, 4
        shl al, cl                 ; tens -> high nibble
        or  al, ah                 ; ones -> low nibble
        mov dx, PORTA
        out dx, al

        jmp MAIN_LOOP

;-------------------------------------------------
; Delays
;-------------------------------------------------
DELAY_SHORT:
        mov cx, 150                      ; ~few us @ ~5MHz 8086
DS_L:   loop DS_L
        ret

DELAY_1MS:
        mov cx, 1000		;3000 / 10
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
