; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

ORG 100h               ; Set the origin of the code at memory location 100h (COM file format starts execution here)
   
   CALL MAIN_PANEL     ; Call the MAIN_PANEL procedure to start the main menu
RET                    ; Return to terminate the program after MAIN_PANEL completes

MAIN_PANEL:
    CALL CLEAR_SCREEN  ; Clear the screen and initialize the display
    CALL DISP_MESS     ; Display the menu options and messages
    CALL GET_USER_CHOICE ; Wait for and process user input (keyboard/mouse)
    RET                ; Return to the caller (in this case, back to where MAIN_PANEL was called)

CLEAR_SCREEN:
    CALL INIT_MOUSE    ; Initialize the mouse
    MOV AL, 00h        ; AL = 0, to scroll the entire screen (clear the screen)
    MOV AH, 06h        ; AH = 6, scroll up window function
    MOV BH, 1001_1111b ; BH = background color attribute (light gray on black)
    XOR CX, CX         ; CX = 0, top-left corner of the screen (coordinates)
    MOV DH, 24         ; DH = 24, bottom row coordinate (25th row)
    MOV DL, 79         ; DL = 79, last column coordinate (80th column)
    INT 10h            ; BIOS interrupt to clear the screen
    RET                ; Return from CLEAR_SCREEN procedure

CLEAR_KB_BUFFER:
    MOV AH, 0Ch        ; AH = 0Ch, clear the keyboard buffer function
    INT 21h            ; DOS interrupt to perform the function
    RET                ; Return from CLEAR_KB_BUFFER procedure

    
DISP_MESS:               
    MOV AL, 0               ; Clear AL (not used here but can be for initialization)
    MOV BH, 0               ; Set display page to 0
    MOV BL, 09Eh            ; Set text color to light yellow on black (attribute)

    ; Display "MENU" at row 2, column 39
    MOV DH, 02              ; Set row to 2
    MOV DL, 39              ; Set column to 39 (centered horizontally)
    MOV CX, 4               ; Length of the string to display ("MENU" has 4 characters)
    MOV BP, OFFSET MENU_TEXT ; Load address of the "MENU" text
    CALL PRINT_STR           ; Call the procedure to print the string

    ; Display "1 - HORIZONTAL STRIPES" at row 5, column 0
    MOV DH, 05              ; Set row to 5
    XOR DL, DL              ; Set column to 0
    MOV CX, 22              ; Length of the string ("1 - HORIZONTAL STRIPES" has 22 characters)
    MOV BP, OFFSET FIRST_CHOICE ; Load address of the first menu option text
    CALL PRINT_STR           ; Print the string

    ; Display "2 - VERTICAL STRIPES" at row 6, column 0
    MOV DH, 06              ; Set row to 6
    XOR DL, DL              ; Set column to 0
    MOV CX, 20              ; Length of the string ("2 - VERTICAL STRIPES" has 20 characters)
    MOV BP, OFFSET SECOND_CHOICE ; Load address of the second menu option text
    CALL PRINT_STR           ; Print the string

    ; Display "F2 - CHECKERED PATTERN" at row 7, column 0
    MOV DH, 07              ; Set row to 7
    XOR DL, DL              ; Set column to 0
    MOV CX, 22              ; Length of the string ("F2 - CHECKERED PATTERN" has 22 characters)
    MOV BP, OFFSET THIRD_CHOICE ; Load address of the third menu option text
    CALL PRINT_STR           ; Print the string

    ; Display "Q - QUIT" at row 9, column 0
    MOV DH, 09              ; Set row to 9
    XOR DL, DL              ; Set column to 0
    MOV CX, 8               ; Length of the string ("Q - QUIT" has 8 characters)
    MOV BP, OFFSET QUIT_TEXT ; Load address of the quit option text
    CALL PRINT_STR           ; Print the string

    ; Display "ENTER CHOICE: " at row 11, column 18
    MOV DH, 11              ; Set row to 11
    MOV DL, 18              ; Set column to 18
    MOV CX, 13              ; Length of the string ("ENTER CHOICE: " has 13 characters)
    MOV BP, OFFSET CHOICE_TEXT ; Load address of the prompt text
    CALL PRINT_STR           ; Print the string
    RET                      ; Return from DISP_MESS procedure

GET_USER_CHOICE:
    MOV AX, 3               ; Set AX = 3 to get mouse position and button status
    INT 33h                 ; Call mouse interrupt
    CMP BX, 1               ; Check if the left mouse button is clicked (BX = 1)
    JE CHECK_MOUSE          ; Jump to mouse handling if clicked

    MOV AH, 1h              ; Check if a key has been pressed (AH = 1h)
    INT 16h                 ; Call BIOS keyboard interrupt
    JNZ CHECK_KEYBOARD      ; Jump to keyboard handling if a key is pressed

    JMP GET_USER_CHOICE     ; Loop until either a key is pressed or mouse clicked


CHECK_KEYBOARD:
    CMP AL, 31h           ; Compare AL (key pressed) with '1' (ASCII 31h)
    JE SETUP_HORI         ; Jump to SETUP_HORI if '1' is pressed (for horizontal stripes)
    CMP AL, 32h           ; Compare AL with '2' (ASCII 32h)
    JE SETUP_VERT         ; Jump to SETUP_VERT if '2' is pressed (for vertical stripes)
    CMP AH, 3Ch           ; Compare AH with F2 key (scan code 3Ch for checkered pattern)
    JE SETUP_CHECK        ; Jump to SETUP_CHECK if F2 is pressed
    CMP AL, 71h           ; Compare AL with 'q' (ASCII 71h for quitting)
    JE QUIT               ; Jump to QUIT if 'q' is pressed
    CALL CLEAR_KB_BUFFER   ; Clear the keyboard buffer after processing input
    JMP MAIN_PANEL        ; Return to the main panel after handling the key
    RET                   ; Return from CHECK_KEYBOARD

CHECK_MOUSE:
    CMP CX, 0B6h          ; Compare the mouse's X-coordinate (CX) with 0B6h
    JL CHECK_FIRST        ; If less than 0B6h, check if the first option was clicked

CHECK_FIRST: 
    CMP DX, 27h           ; Compare the mouse's Y-coordinate (DX) with 27h (top boundary for the first option)
    JG CHECK_FIRST_LOWER   ; Jump if Y-coordinate is greater (inside the first option)
    
CHECK_FIRST_LOWER:
    CMP DX, 02Fh          ; Compare Y-coordinate with 2Fh (bottom boundary for the first option)
    JL SETUP_HORI         ; Jump to SETUP_HORI if within bounds (first option selected)
    JMP CHECK_SECOND      ; Otherwise, check the second option

CHECK_SECOND:
    CMP DX, 30h           ; Compare Y-coordinate with 30h (top boundary for second option)
    JG CHECK_SECOND_LOWER ; Jump if Y-coordinate is greater (inside the second option)

CHECK_SECOND_LOWER:
    CMP DX, 36h           ; Compare Y-coordinate with 36h (bottom boundary for the second option)
    JL SETUP_VERT         ; Jump to SETUP_VERT if within bounds (second option selected)
    JMP CHECK_THIRD       ; Otherwise, check the third option

CHECK_THIRD: 
    CMP DX, 38h           ; Compare Y-coordinate with 38h (top boundary for the third option)
    JG CHECK_THIRD_LOWER  ; Jump if Y-coordinate is greater (inside the third option)

CHECK_THIRD_LOWER:
    CMP DX, 3Fh           ; Compare Y-coordinate with 3Fh (bottom boundary for the third option)
    JL SETUP_CHECK        ; Jump to SETUP_CHECK if within bounds (third option selected)
    JMP CHECK_QUIT        ; Otherwise, check the quit option

CHECK_QUIT:
    CMP DX, 48h           ; Compare Y-coordinate with 48h (top boundary for the quit option)
    JL GET_USER_CHOICE    ; If less, loop back to wait for more input
    CMP CX, 4Dh           ; Compare X-coordinate with 4Dh (left boundary for quit option)
    JG GET_USER_CHOICE    ; If greater, loop back to wait for more input
    CMP DX, 4Fh           ; Compare Y-coordinate with 4Fh (bottom boundary for quit option)
    JL QUIT               ; If within quit bounds, jump to QUIT
    JMP GET_USER_CHOICE    ; Otherwise, loop back to wait for more input

PROMPT_CONTINUE:  
    MOV DH, 22            ; Set row to 22 (location for the "Press any key" message)
    MOV DL, 30            ; Set column to 30
    MOV AH, 2             ; Set AH = 2 (BIOS cursor positioning function)
    INT 10h               ; Call BIOS interrupt to position cursor
    
    MOV DX, OFFSET KEY_PROMPT ; Load address of the "Press any key" message
    MOV AH, 9             ; Set AH = 9 (BIOS print string function)
    INT 21h               ; Call DOS interrupt to print the string
    
    MOV AH, 0             ; Set AH = 0 to wait for a key press
    INT 16h               ; Call BIOS interrupt to wait for key press
    RET                   ; Return from PROMPT_CONTINUE

SETUP_HORI:
    CALL CLEAR_SCREEN  
    CALL CLEAR_KB_BUFFER
    
    MOV AH, 06h
    XOR AL, AL 
    
    MOV BH, 0000_0000b
    XOR CX, CX
    MOV DH, 6
    MOV DL, 79
    INT 10h
    
    MOV BH, 1101_0000b
    MOV CH, 6
    MOV DH, 12
    MOV DL, 79
    INT 10h
    
    MOV BH, 1110_0000b
    MOV CH, 12
    MOV DH, 18
    MOV DL, 79
    INT 10h 
    
    MOV BH, 1001_0000b
    MOV CH, 18
    MOV DH, 24
    MOV DL, 79
    INT 10h
    
    MOV AL, 0
    MOV BH, 0
    MOV BL, 1001_0000b
    
    CALL PROMPT_CONTINUE
    CALL MAIN_PANEL
    RET

SETUP_VERT:
    CALL CLEAR_SCREEN
    CALL CLEAR_KB_BUFFER
    
    MOV AH, 06h
    XOR AL, AL 
    
    MOV BH, 0000_0000b
    XOR CX, CX
    MOV DH, 24
    MOV DL, 20
    INT 10h
    
    MOV BH, 1101_0000b
    MOV CL, 20
    MOV DL, 40
    INT 10h
    
    MOV BH, 1110_0000b
    MOV CL, 40
    MOV DL, 60
    INT 10h 
    
    MOV BH, 1001_0000b
    MOV CL, 60
    MOV DL, 79
    INT 10h
    
    MOV AL, 0
    MOV BH, 0
    MOV BL, 1001_0000b
    
    CALL PROMPT_CONTINUE
    CALL MAIN_PANEL
    RET

SETUP_CHECK:
    CALL CLEAR_SCREEN
    CALL CLEAR_KB_BUFFER 
    
    MOV AH, 06h
    XOR AL, AL
    
    ; FIRST ROW
    MOV BH, 0000_0000b
    XOR CX, CX
    MOV DH, 5
    MOV DL, 20
    INT 10h
    
    MOV BH, 1101_0000b
    MOV CL, 20
    MOV DL, 40
    INT 10h
    
    MOV BH, 1110_0000b
    MOV CL, 40
    MOV DL, 60
    INT 10h 
    
    MOV BH, 1001_0000b
    MOV CL, 60
    MOV DL, 79
    INT 10h
    
    ; SECOND ROW
    MOV BH, 1001_0000b
    MOV CH, 6
    XOR CL, CL
    MOV DH, 11
    MOV DL, 20
    INT 10h
    
    MOV BH, 0000_0000b
    MOV CL, 20
    MOV DL, 40
    INT 10h
    
    MOV BH, 1101_0000b
    MOV CL, 40
    MOV DL, 60
    INT 10h 
    
    MOV BH, 1110_0000b
    MOV CL, 60
    MOV DL, 79
    INT 10h  
    
    ; THIRD ROW
    MOV BH, 1110_0000b
    MOV CH, 12
    XOR CL, CL
    MOV DH, 17
    MOV DL, 20
    INT 10h
    
    MOV BH, 1001_0000b
    MOV CL, 20
    MOV DL, 40
    INT 10h
    
    MOV BH, 0000_0000b
    MOV CL, 40
    MOV DL, 60
    INT 10h 
    
    MOV BH, 1101_0000b
    MOV CL, 60
    MOV DL, 79
    INT 10h  
    
    ; FOURTH ROW
    MOV BH, 1101_0000b
    MOV CH, 18
    XOR CL, CL
    MOV DH, 24
    MOV DL, 20
    INT 10h
    
    MOV BH, 1110_0000b
    MOV CL, 20
    MOV DL, 40
    INT 10h
    
    MOV BH, 1001_0000b
    MOV CL, 40
    MOV DL, 60
    INT 10h 
    
    MOV BH, 0000_0000b
    MOV CL, 60
    MOV DL, 79
    INT 10h 
    
    CALL PROMPT_CONTINUE
    CALL MAIN_PANEL
    RET         
    
PRINT_STR:
    PUSH CS               ; Save the current code segment to the stack
    POP ES                ; Load the code segment into ES for string operations
    MOV AH, 13h           ; Set AH = 13h (function to print a string at the current cursor position)
    INT 10H               ; Call BIOS interrupt 10h to execute the print string function
    JMP msg1end           ; Jump to the end of the procedure
msg1end:
    RET                   ; Return from PRINT_STR

INIT_MOUSE:
    MOV AX, 1             ; Set AX = 1 to initialize the mouse (enable mouse support)
    INT 33h               ; Call mouse interrupt 33h to initialize the mouse
    RET                   ; Return from INIT_MOUSE

QUIT:
    RET                   ; Simply return from QUIT (exit point for the program)

    

MENU_TEXT DB 'MENU', '$'
FIRST_CHOICE DB '1 - HORIZONTAL STRIPES', '$'
SECOND_CHOICE DB '2 - VERTICAL STRIPES', '$'
THIRD_CHOICE DB 'F2 - CHECKERED PATTERN', '$'
QUIT_TEXT DB 'Q - QUIT', '$' 
CHOICE_TEXT DB 'ENTER CHOICE: ', '$'
KEY_PROMPT DB 'Press any key to continue', '$'

RET
