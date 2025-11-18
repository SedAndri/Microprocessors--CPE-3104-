;BORDARIO SID ANDRE P


PROCED1 SEGMENT 'CODE'
ON_OFF PROC FAR
ASSUME CS:PROCED1, DS:DATA
ORG 00000H
   PUSHF
   PUSH AX
   PUSH DX
   CMP ON_FLAG, 1
   JE RESET_ON
   MOV ON_FLAG, 1
   MOV MODE_FLAG, 1
   JMP EXIT_ON_OFF
   RESET_ON:
      MOV ON_FLAG, 0
      MOV PAUSE_FLAG, 0
   EXIT_ON_OFF:
   POP DX
   POP AX
   POPF
   IRET
ON_OFF ENDP
PROCED1 ENDS

PROCED2 SEGMENT 'CODE'
PAUSE_PLAY PROC FAR
ASSUME CS:PROCED2, DS:DATA
ORG 00050H
   PUSHF
   PUSH AX
   PUSH DX
   CMP ON_FLAG, 1
   JNE CHECK_PASS          ; still allow pass trigger even if OFF? skip if off
   CMP PAUSE_FLAG, 1
   JE RESET_PAUSE
   MOV PAUSE_FLAG, 1
   JMP CONTINUE_PP
RESET_PAUSE:
   MOV PAUSE_FLAG, 0
CONTINUE_PP:
CHECK_PASS:
   CMP PASS_DONE, 1
   JNE EXIT_PAUSE_PLAY
   ; One full pass completed: fire ON_OFF interrupt (INT 80h) and light PA5
   MOV PASS_DONE, 0             ; auto-reset for next cycle
   MOV AL, 00100000B            ; PA5 high, others low
   OUT PORTA, AL
   MOV AL, 0FFH                 ; drive all Port C pins HIGH
   OUT PORTC, AL
   INT 80H                      ; invoke ON_OFF (vector stored at ES:200H)
EXIT_PAUSE_PLAY:
   POP DX
   POP AX
   POPF
   IRET
PAUSE_PLAY ENDP
PROCED2 ENDS

PROCED3 SEGMENT 'CODE'
MODES PROC FAR
ASSUME CS:PROCED3, DS:DATA
ORG 00100H
   PUSHF
   PUSH AX
   PUSH DX
   CMP PAUSE_FLAG, 1
   JNE EXIT_MODE
   INC MODE_FLAG
   MOV PAUSE_FLAG, 0
   CMP MODE_FLAG, 4
   JNE EXIT_MODE
   MOV MODE_FLAG, 1
   EXIT_MODE:
   POP DX
   POP AX
   POPF
   IRET
MODES ENDP
PROCED3 ENDS

DATA SEGMENT
ORG 00250H
   PORTA EQU 0F0H	; 8255 PPI
   PORTB EQU 0F2H
   PORTC EQU 0F4H
   COM_REG1 EQU 0F6H
   PIC1 EQU 0E0H	; 8259 PIC
   PIC2 EQU 0E2H
   ICW1 EQU 013H
   ICW2 EQU 080H
   ICW4 EQU 003H
   OCW1 EQU 0F8H	;1111 1000 = F8
   ON_FLAG DB 0
   PAUSE_FLAG DB 0
   MODE_FLAG DB 1
   TEMP DB ?
   PASS_DONE DB 0            ; set to 1 at end of one full S-P-B pass in DEFAULT
DATA ENDS

STK SEGMENT STACK
   BOS DW 64d DUP (?)
   TOS LABEL WORD
STK ENDS

CODE    SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE, DS:DATA, SS:STK
	ORG 00300H
START:
   MOV AX, DATA
   MOV DS, AX		; set the Data Segment address
   MOV AX, STK
   MOV SS, AX		; set the Stack Segment address
   LEA SP, TOS		; set SP as Top of Stack
   CLI

   MOV DX, COM_REG1	; Configuring 8255 PPI
   MOV AL, 10000000B   ; 8255 mode set: PA=out, PB=out, PC upper=out, PC lower=out (Mode 0)
   OUT DX, AL

   MOV AL, ICW1		; Configuring 8259
   OUT PIC1, AL
   MOV AL, ICW2
   OUT PIC2, AL
   MOV AL, ICW4
   OUT PIC2, AL
   MOV AL, OCW1
   OUT PIC2, AL
   STI


   MOV AX, OFFSET ON_OFF
   MOV [ES:200H], AX
   MOV AX, SEG ON_OFF
   MOV [ES:202H], AX
   MOV AX, OFFSET PAUSE_PLAY
   MOV [ES:204H], AX
   MOV AX, SEG PAUSE_PLAY
   MOV [ES:206H], AX
   MOV AX, OFFSET MODES
   MOV [ES:208H], AX
   MOV AX, SEG MODES
   MOV [ES:20AH], AX

   ; foreground routine
   HERE:
      MOV AL, 00000000B
      OUT PORTA, AL
      MOV AL, 00000000B
      OUT PORTB, AL
      CMP ON_FLAG, 0
      JE HERE
      CMP PAUSE_FLAG, 1
      JE PAUSE
      CMP MODE_FLAG, 1
      JE DEFAULT
      CMP MODE_FLAG, 2
     JE STOP

   JMP HERE
   
   DEFAULT:
      ; S (slow: each stage + hold)
      MOV SI, OFFSET GLYPH_S      
      CALL PRINT_CHAR
      CALL PRINT_CHAR              ; hold
      MOV SI, OFFSET GLYPH_S_HOLD1 ; slight variation dwell
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_SS     
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_SS_HOLD1
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_SSS    
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_SSS_HOLD1
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_SSSS   
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_SSSS_HOLD
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_S_SPACER
      CALL PRINT_CHAR

      ; P
      MOV SI, OFFSET GLYPH_P
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_P_HOLD1
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_PP
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_PP_HOLD1
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_PPP
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_PPP_HOLD1
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_PPPP
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_PPPP_HOLD
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_P_SPACER
      CALL PRINT_CHAR

      ; B
      MOV SI, OFFSET GLYPH_B
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_B_HOLD1
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_BB
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_BB_HOLD1
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_BBB
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_BBB_HOLD1
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_BBBB
      CALL PRINT_CHAR
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_BBBB_HOLD
      CALL PRINT_CHAR
      MOV SI, OFFSET GLYPH_B_SPACER
      CALL PRINT_CHAR
      
      MOV PASS_DONE, 1
      INT 81H
      
   JMP HERE
   
   ; Mode 2
   STOP:
      MOV SI, GLYPH_X
      CALL PRINT_CHAR
   CON_SM:
   JMP HERE
   
   ; Mode 2
   ;CON_SM:
   JMP HERE
   ; Print character from the specified font
   PRINT_CHAR:
      MOV DI, SI              ; start of glyph (8 bytes)
      MOV BX, 0040H           ; refresh count (increase for brighter / more “solid”)
REFRESH_LOOP:
      MOV AH, 11111110B       ; row select (active low single 0 bit)
      MOV SI, DI
ROW_LOOP:
      MOV AL, AH
      OUT PORTB, AL           ; select row
      MOV AL, BYTE PTR CS:[SI]
      CALL REV5               ; fix mirror if needed
      OUT PORTA, AL           ; output columns for this row
      ; tiny hold (crude)
      MOV DX, 0008H
HOLD_LOOP:
      NOP
      DEC DX
      JNZ HOLD_LOOP
      INC SI
      CLC
      ROL AH, 1
      JC ROW_LOOP             ; continue rows until carry cleared
      DEC BX
      JNZ REFRESH_LOOP        ; repeat whole glyph quickly
      RET

   PAUSE:
      MOV SI, DI
      MOV AH, 11111110B
   F2:
      CMP PAUSE_FLAG, 0
      JE UNPAUSE
      MOV AL, AH
      OUT PORTB, AL
      MOV AL, BYTE PTR CS:[SI]    ; Get row bits
      CALL REV5                   ; FIX: mirror correction also during pause
      OUT PORTA, AL
      CMP ON_FLAG, 0
      JE HERE
      CALL DELAY_250MS
      MOV AL, 00H
      OUT PORTA, AL
      INC SI
      CLC
      ROL AH, 1
      JC F2
      JMP HERE
   UNPAUSE:
      MOV AL, MODE_FLAG
      CMP TEMP, AL
      JNE CHECK_MODE
      RET
      CHECK_MODE:
      CMP MODE_FLAG, 1
      JE DEFAULT
     ; CMP MODE_FLAG, 2
      ;JE STICKMAN
      ;CMP MODE_FLAG, 3
      ;JE LANTERN

   OFF:
      MOV AL, 00000000B
      OUT PORTA, AL
      MOV AL, 11111111B
      OUT PORTB, AL
      MOV ON_FLAG, 0
      MOV MODE_FLAG, 1
   JMP HERE

   DELAY_250MS:	MOV CX, 0AFFH
   TIMER1:
      NOP
      NOP
      NOP
      NOP
      LOOP TIMER1
   RET

   DELAY_500MS:	MOV CX, 03AAH	; not 500MS
   L2:
      NOP
      NOP
      LOOP L2
   RET

   DELAY_1MS: MOV BX, 00AAH
   L1:
      DEC BX
      NOP
      JNZ L1
      RET
   RET

; --- NEW: reverse 5 LSBs in AL (bit0..bit4) to fix left-right mirroring ---
REV5 PROC NEAR
   PUSH CX
   PUSH DX
  AND AL, 00011111B      ; keep 5 columns
   XOR DL, DL
   MOV CL, 5
@@rev:
   SHR AL, 1              ; take LSB into CF
   RCL DL, 1              ; shift into DL
   LOOP @@rev
   MOV AL, DL
   POP DX
   POP CX
   RET
REV5 ENDP

GLYPH_SPACE:
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B   ; added

GLYPH_S:
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000000B   ; added

GLYPH_SS:
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000011B
      DB 00000001B
      DB 00000001B
      DB 00000011B
      DB 00000000B   ; added

GLYPH_SSS:
      DB 00000111B
      DB 00000100B
      DB 00000100B
      DB 00000111B
      DB 00000001B
      DB 00000001B
      DB 00000111B
      DB 00000000B   ; added

GLYPH_SSSS:
      DB 00011110B
      DB 00010000B
      DB 00010000B
      DB 00011110B
      DB 00000010B
      DB 00000010B
      DB 00011110B
      DB 00000000B   ; added

GLYPH_S_SPACER:
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B   ; added

GLYPH_P:
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000000B   ; added

GLYPH_PP:
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000010B
      DB 00000000B   ; added

GLYPH_PPP:
      DB 00000111B
      DB 00000100B
      DB 00000100B
      DB 00000111B
      DB 00000100B
      DB 00000100B
      DB 00000100B
      DB 00000000B   ; added

GLYPH_PPPP:
      DB 00011110B
      DB 00010010B
      DB 00010010B
      DB 00011110B
      DB 00010000B
      DB 00010000B
      DB 00010000B
      DB 00000000B   ; added

GLYPH_P_SPACER:
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B   ; added

GLYPH_B:
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000000B   ; added

GLYPH_BB:
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000011B
      DB 00000000B   ; added

GLYPH_BBB:
      DB 00000111B
      DB 00000101B
      DB 00000101B
      DB 00000111B
      DB 00000101B
      DB 00000101B
      DB 00000111B
      DB 00000000B   ; added

GLYPH_BBBB:
      DB 00011110B
      DB 00010010B
      DB 00010010B
      DB 00011110B
      DB 00010010B
      DB 00010010B
      DB 00011110B
      DB 00000000B   ; added

GLYPH_B_SPACER:
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B   ; added

GLYPH_X:
      DB 00000001B
      DB 00000010B
      DB 00001001B
      DB 00000100B
      DB 00010001B
      DB 00010001B
      DB 00011111B
      DB 00000000B   ; added

GLYPH_S_HOLD1:
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000000B   ; added

GLYPH_SS_HOLD1:
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000011B
      DB 00000001B
      DB 00000001B
      DB 00000011B
      DB 00000000B   ; added

GLYPH_SSS_HOLD1:
      DB 00000111B
      DB 00000100B
      DB 00000100B
      DB 00000111B
      DB 00000001B
      DB 00000001B
      DB 00000111B
      DB 00000000B   ; added

GLYPH_SSSS_HOLD:
      DB 00011110B
      DB 00010000B
      DB 00010000B
      DB 00011110B
      DB 00000010B
      DB 00000010B
      DB 00011110B
      DB 00000000B   ; added

GLYPH_P_HOLD1:
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000000B   ; added

GLYPH_PP_HOLD1:
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000010B
      DB 00000000B   ; added

GLYPH_PPP_HOLD1:
      DB 00000111B
      DB 00000100B
      DB 00000100B
      DB 00000111B
      DB 00000100B
      DB 00000100B
      DB 00000100B
      DB 00000000B   ; added

GLYPH_PPPP_HOLD:
      DB 00011110B
      DB 00010010B
      DB 00010010B
      DB 00011110B
      DB 00010000B
      DB 00010000B
      DB 00010000B
      DB 00000000B   ; added

GLYPH_B_HOLD1:
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000000B   ; added

GLYPH_BB_HOLD1:
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000011B
      DB 00000010B
      DB 00000010B
      DB 00000011B
      DB 00000000B   ; added

GLYPH_BBB_HOLD1:
      DB 00000111B
      DB 00000101B
      DB 00000101B
      DB 00000111B
      DB 00000101B
      DB 00000101B
      DB 00000111B
      DB 00000000B   ; added

GLYPH_BBBB_HOLD:
      DB 00011110B
      DB 00010010B
      DB 00010010B
      DB 00011110B
      DB 00010010B
      DB 00010010B
      DB 00011110B
      DB 00000000B   ; added

CODE ENDS
END START