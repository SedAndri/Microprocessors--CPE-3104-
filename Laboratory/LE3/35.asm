

ORG 100h               
   
   CALL MAIN_PANEL     
RET                    

MAIN_PANEL:
    CALL CLEAR_SCREEN  
    CALL DISP_MESS    
    CALL GET_USER_CHOICE 
    RET                

CLEAR_SCREEN:
    CALL INIT_MOUSE
    MOV AL, 00h
    MOV AH, 06h
    MOV BH, 0000_0000b    
    XOR CX, CX
    MOV DH, 24
    MOV DL, 79
    INT 10h
    RET                

CLEAR_KB_BUFFER:
    MOV AH, 0Ch
    XOR AL, AL            
    INT 21h
    RET                

    
DISP_MESS:               
    MOV AL, 0
    MOV BH, 0
    MOV BL, 1Eh    ; light yellow on black (no blink)

    ; "MENU"
    MOV DH, 02
    MOV DL, 39
    MOV CX, 4
    MOV BP, OFFSET MENU_TEXT
    CALL PRINT_STR

    ; "A - HORIZONTAL STRIPES"
    MOV DH, 05
    XOR DL, DL
    MOV CX, 22
    MOV BP, OFFSET FIRST_CHOICE
    CALL PRINT_STR

    ; "B - VERTICAL STRIPES"
    MOV DH, 06
    XOR DL, DL
    MOV CX, 20
    MOV BP, OFFSET SECOND_CHOICE
    CALL PRINT_STR

    ; "C - CHECKERED PATTERN"
    MOV DH, 07
    XOR DL, DL
    MOV CX, 21
    MOV BP, OFFSET THIRD_CHOICE
    CALL PRINT_STR

    ; "ENTER CHOICE: "
    MOV DH, 11
    MOV DL, 18
    MOV CX, 13
    MOV BP, OFFSET CHOICE_TEXT
    CALL PRINT_STR
    RET                      

GET_USER_CHOICE:
    MOV AX, 3               
    INT 33h                
    CMP BX, 1              
    JE CHECK_MOUSE         

    MOV AH, 1h             
    INT 16h                 
    JNZ CHECK_KEYBOARD      

    JMP GET_USER_CHOICE    


CHECK_KEYBOARD:
    CMP AL, 'a'
    JE SETUP_HORI
    CMP AL, 'A'
    JE SETUP_HORI

    CMP AL, 'b'
    JE SETUP_VERT
    CMP AL, 'B'
    JE SETUP_VERT

    CMP AL, 'c'
    JE SETUP_CHECK
    CMP AL, 'C'
    JE SETUP_CHECK

    CMP AL, 'q'         
    JE QUIT
    CALL CLEAR_KB_BUFFER
    JMP MAIN_PANEL
    RET                   

CHECK_MOUSE:
    CMP CX, 0B6h          
    JL CHECK_FIRST        

CHECK_FIRST: 
    CMP DX, 27h          
    JG CHECK_FIRST_LOWER   
    
CHECK_FIRST_LOWER:
    CMP DX, 02Fh         
    JL SETUP_HORI         
    JMP CHECK_SECOND      

CHECK_SECOND:
    CMP DX, 30h           
    JG CHECK_SECOND_LOWER 

CHECK_SECOND_LOWER:
    CMP DX, 36h           
    JL SETUP_VERT         
    JMP CHECK_THIRD      

CHECK_THIRD: 
    CMP DX, 38h           
    JG CHECK_THIRD_LOWER  

CHECK_THIRD_LOWER:
    CMP DX, 3Fh           )
    JL SETUP_CHECK       
    JMP CHECK_QUIT       

CHECK_QUIT:
    CMP DX, 48h           
    JL GET_USER_CHOICE    
    CMP CX, 4Dh           
    JG GET_USER_CHOICE    
    CMP DX, 4Fh           ;
    JL QUIT               ; 
    JMP GET_USER_CHOICE    

PROMPT_CONTINUE:  
    MOV DH, 22            
    MOV DL, 30            
    MOV AH, 2            
    INT 10h              
    
    MOV DX, OFFSET KEY_PROMPT 
    MOV AH, 9             
    INT 21h              
    
    MOV AH, 0            
    INT 16h              
    RET                   

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
    PUSH CS               
    POP ES               
    MOV AH, 13h           
    INT 10H              
    JMP msg1end          
msg1end:
    RET                   

INIT_MOUSE:
    MOV AX, 1             
    INT 33h               
    RET                   

QUIT:
    RET                   

    

MENU_TEXT DB 'MENU', '$'
FIRST_CHOICE  DB 'A - HORIZONTAL PATTERN', '$'
SECOND_CHOICE DB 'B - VERTICAL PATTERN', '$'
THIRD_CHOICE  DB 'C - CHECKERED PATTERN', '$'
QUIT_TEXT DB 'Q - QUIT', '$'            
CHOICE_TEXT DB 'ENTER CHOICE: ', '$'
KEY_PROMPT  DB 'Press any key to continue', '$'

RET
