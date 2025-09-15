;-------------------------------------------------------
; AUTHOR/S:     Cyril Andre Durango
; 
; COURSE:       CpE 3104
;               Microprocessors   
;                               
; TITLE:        PREMID-2
; DESCRIPTION:  An assembly language program that
;               displays a running "CYRIL" vertically  
;-------------------------------------------------------
ORG 100H
    START:  MOV AX, 0B800H  ;   B800H indicates the segment address referring to the video memory
            MOV DS, AX      ;   stores the the segment address into the DS register 
            MOV DI, 74      ;   initializes the DI register to 74
            MOV SI, 74      ;   initializes the SI register to 74
            MOV BL, 25      ;   stores the maximum
    
        
    DISPLAY_LOOP:   CALL DISPLAY_NAME       ;   calls the block of code under the DISPLAY_NAME label
                    CALL DELAY              ;   calls the block of code under the DELAY label
                    CALL CLEAR_NAME         ;   calls the block of code under the CLEAR_NAME label
                    
                    SUB SI, 10              ;   
                    ADD SI, 160
                    MOV DI, SI              ;   copies the value of the SI register into the DI register 
                    DEC BL                  ;   decrements the BL register
                    CMP BL, 0               ;   compares the value of BL to 0
                        JNE DISPLAY_LOOP    ;   when it is not equal to 0 yet, it calls the block of code under the DISPLAY_LOOP label 
         
RET 


; --------------------------------------------------
; THE BLOCK OF CODE BELOW DISPLAYS THE NAME "CYRIL"
; --------------------------------------------------
DISPLAY_NAME:   MOV AH, 0B1H    ;   initializes the color of both the background and the text. "B" indicates a cyan color, and "1" indicates a blue color
                MOV AL, 43H     ;   stores the ascii value of "C" in AL register
                MOV [DI], AX    ;   displays the letter and its initialized background and text color.
                
                ADD DI, 2       ;   adds the DI register by 2 since one character space in the window occupies two bytes
                MOV AL, 59H     ;   stores the ascii value of "Y" in AL register
                MOV [DI], AX 
                
                ADD DI, 2       
                MOV AL, 52H     ;   stores the ascii value of "R" in AL register
                MOV [DI], AX 
                
                ADD DI, 2       
                MOV AL, 49H     ;   stores the ascii value of "I" in AL register
                MOV [DI], AX 
                
                ADD DI, 2       
                MOV AL, 4CH     ;   stores the ascii value of "L" in AL register
                MOV [DI], AX 
    
RET


     
; ---------------------------------------------------------------------------
; THE BLOCK OF CODE BELOW GENERATES A DELAY THROUGH LOOPED CX DECREMENTATION
; ---------------------------------------------------------------------------    
DELAY:  MOV CX, 1FH     ;   initializes the counter to 1FH that will act as a delay count
    
    HERE:   LOOP HERE   ;   loops to "HERE", decrementing CX until it reaches 0
    
RET


       
; -----------------------------------------------------------------------
; THE BLOCK OF CODE BELOW CLEARS THE WRITTEN NAME
; -----------------------------------------------------------------------     
CLEAR_NAME: MOV CX, 5       ;   initializes the counter to the length of name
    
    DELETE: MOV AX, 0       ;   resets the AX register, indicating no stored text, background color, nor text color
            MOV [SI], AX    ;   clears the letter stored in the address value written in the SI register
            ADD SI, 2       ;   adds the SI register by 2 since one character space in the window occupies two bytes
            LOOP DELETE     ;   loops to "DELETE", decrementing CX until it reaches 0
RET



