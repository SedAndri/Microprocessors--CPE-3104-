ORG 100H
    START:  
    MOV AX, 0B800H      ;set to video buffer mode (color text)
                        ;Use DS:[DI] if you don’t need DS for anything else.
                        ;Prefer ES:DI when using string ops or when you want
                        ;DS to keep pointing to your program’s data.
                        ;DS holds variables and data and also ES

    MOV DS, AX          ;move video buffer to DS register
    MOV DI, 0           ;set to 0 for first column of top row
    MOV SI, 0           ;same as DI

    DISPLAY_LOOP:       ;loop module name
                        ;use CALL function to call subroutine/module
    CALL DISPLAY_NAME   ;calls DISPLAY_NAME module until its end
    CALL DELAY          ;calls DELAY module until its end
    CALL CLEAR_NAME     ;calls CLEAR_NAME module until its end
    MOV DI, SI          ;DI is where it writes next, SI is where it last deleted
                        ;SI is changed in CLEAR_NAME module
    CMP DI, 156         ;156 = 24*80/2, stop when reach bottom row
                        ;CMP makes Zf flag = 1 if DI=156
    JNE DISPLAY_LOOP    ;jumps to DISPLAY_LOOP if Zf=0 (DI!=156)
                            ;meaning not yet reach bottom row
                        ;when DI increases by 2 each letter displayed
RET 

DISPLAY_NAME:           ;displays letter by letter
    MOV AH, 1EH         ;puts attribute(color) in AH while AL contains ASCII code for the letter
    MOV AL, 53H         ;ASCII code for 'S'
    MOV [DI], AX        ;prints AX (AX=color ; AL=letter) to DS:[DI]
                        ;DS is video buffer, DI is position (offset(current place in display)
    ADD DI, 2           ;move DI to next column (2 bytes per char)
    MOV AL, 49H         ;ASCII code for 'I'
    MOV [DI], AX        ;prints AX (AX=color ; AL=letter) to DS:[DI] 
                
    ADD DI, 2           ;move DI to next column (2 bytes per char) 
    MOV AL, 44H         ;ASCII code for 'D'
    MOV [DI], AX        ;prints AX (AX=color ; AL=letter) to DS:[DI]
                
;    ADD DI, 2       
;    MOV AL, 49H
;    MOV [DI], AX 
;                
;    ADD DI, 2       
;    MOV AL, 4CH
;    MOV [DI], AX 
RET

DELAY:                  ;creates a delay so the name can be read before it is deleted
                        ;CX is a counter register
    MOV CX, 1FH         ;sets CX to 31(in decimal) 
    
HERE:                   
    LOOP HERE           ;LOOP decrements CX by 1(loop function), and jumps to HERE if CX != 0
RET

CLEAR_NAME:             ;deletes the name letter by letter      
    MOV CX, 3           ;sets CX to 3 (number of letters to delete)    
    
DELETE:                 ;SI uses DS by default unless overridden
                        ;SI is where last letter was written (from DISPLAY_NAME)
    MOV AX, 0           ;AX=0 means blank char with black attribute
    MOV [SI], AX        ;writes blank char to DS:[SI] (SI is where last letter was written)
    ADD SI, 2           ;move SI to next column (2 bytes per char)
    LOOP DELETE        ;LOOP decrements CX by 1(loop function), and jumps to DELETE if CX != 0
RET