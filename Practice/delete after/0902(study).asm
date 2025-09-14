ORG 100H
    START:  
    MOV AX, 0B800H          ; always start by setting video mode like this
    MOV DS, AX              ;cant directly move 0b800h to DS so we use AX as intermediary              
    MOV DI, 74              ;sets DI to column 38 (2 bytes per char, so 38*2=76)
    MOV SI, 74              ;same as DI
    MOV BL, 25              ;BL set to 25 (number of rows to display) also because CX will be used in DELAY module

    DISPLAY_LOOP:           ;main loop
    CALL DISPLAY_NAME
    CALL DELAY
    CALL CLEAR_NAME
                    
    SUB SI, 6               ;move SI back to the start position of the name (3 letters, 2 bytes each)
                            ;any number higher or lower will drift it (for another exercise)
    ADD SI, 160             ;move SI down one row (80 columns, 2 bytes each)
    MOV DI, SI              ;set DI position to SI position (where next name will be displayed)
    DEC BL                  ;decrement BL by 1 (BL counts how many rows have been displayed)
    CMP BL, 0               ;compare BL with 0, sets Zf flag if BL=0
    JNE DISPLAY_LOOP        ;looks at ZF flag, jumps to DISPLAY_LOOP if Zf=0 (BL!=0)
                            ;meaning not yet reach bottom row
         
RET

DISPLAY_NAME:               ;displays letter by letter    
MOV AH, 1EH                 ;puts attribute(color) in AH while AL contains ASCII code for the letter
MOV AL, 53H                 ;ASCII code for 'S'
MOV [DI], AX                ;prints AX (AX=color ; AL=letter) to DS:[DI]
                            ;DS is video buffer, DI is position (offset(current place in display)
                
ADD DI, 2                   ;move DI to next column/position (2 bytes per char)
MOV AL, 49H                 ;ASCII code for 'I'
MOV [DI], AX                ;prints AX (AX=color ; AL=letter) to DS:[DI]
                
ADD DI, 2                   ;move DI to next column/position (2 bytes per char)
MOV AL, 44H                 ;ASCII code for 'D'
MOV [DI], AX                ;prints AX (AX=color ; AL=letter) to DS:[DI]
                
;ADD DI, 2
;MOV AL, 49H
;MOV [DI], AX 
                
;ADD DI, 2
;MOV AL, 4CH
;MOV [DI], AX 
    
RET

DELAY:                  ;creates a delay so the name can be read before it is deleted
                        ;CX is a counter register
MOV CX, 1FH             ;sets CX to 31(in decimal)

    HERE:               ;
    LOOP HERE           ;LOOP decrements CX by 1(loop function), and jumps to HERE if CX != 0
RET

CLEAR_NAME:             ;deletes the name letter by letter
MOV CX, 3               ;sets CX to 3 (number of letters to delete)
    
    DELETE:             ;SI uses DS by default unless overridden
                        ;SI is where last letter was written (from DISPLAY_NAME)
    MOV AX, 0           ;AX=0 means blank char with black attribute
    MOV [SI], AX        ;writes blank char to DS:[SI] (SI is where last letter was written)
    ADD SI, 2           ;move SI to next column/position (2 bytes per char)
    LOOP DELETE         ;LOOP decrements CX by 1(loop function), and jumps to DELETE if CX != 0
RET
