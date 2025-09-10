ORG 100h

    CALL MAIN
    RET

MAIN:
    CALL CLEAR_SCREEN

    ; MENU title
    MOV AH, 02h        ; set cursor
    MOV BH, 0
    MOV DH, 2
    MOV DL, 37
    INT 10h
    MOV DX, OFFSET MENU_TITLE
    CALL DISP_MESS

    ; a - hstripe
    MOV AH, 02h
    MOV DH, 5
    MOV DL, 0
    INT 10h
    MOV DX, OFFSET OPT_A
    CALL DISP_MESS

    ; b - vstripe
    MOV AH, 02h
    MOV DH, 6
    MOV DL, 0
    INT 10h
    MOV DX, OFFSET OPT_B
    CALL DISP_MESS

    ; prompt
    MOV AH, 02h
    MOV DH, 8
    MOV DL, 0
    INT 10h
    MOV DX, OFFSET CHOICE_PROMPT
    CALL DISP_MESS

WAIT_CHOICE:
    MOV AH, 00h        ; wait key
    INT 16h
    CMP AL, 'a'
    JE DO_HSTRIPE
    CMP AL, 'A'
    JE DO_HSTRIPE
    CMP AL, 'b'
    JE DO_VSTRIPE
    CMP AL, 'B'
    JE DO_VSTRIPE
    JMP WAIT_CHOICE

DO_HSTRIPE:
    CALL DRAW_HSTRIPES
    JMP MAIN

DO_VSTRIPE:
    CALL DRAW_VSTRIPES
    JMP MAIN

; ---------- Subroutines ----------

CLEAR_SCREEN:
    MOV AH, 06h
    XOR AL, AL         
    MOV BH, 1Eh     ;bg color   + yellow text
    XOR CX, CX         
    MOV DH, 18h        
    MOV DL, 4Fh        
    INT 10h
   
    MOV AH, 02h
    MOV BH, 0
    XOR DH, DH
    XOR DL, DL
    INT 10h
    RET


DISP_MESS:
    MOV AH, 09h
    INT 21h
    RET


DRAW_HSTRIPES:
    CALL CLEAR_SCREEN
    MOV AH, 06h
    XOR AL, AL

    
    MOV BH, 10h        ; background blue
    XOR CX, CX         
    MOV DH, 5
    MOV DL, 79
    INT 10h

   
    MOV BH, 20h        ; background green
    MOV CH, 6
    MOV CL, 0
    MOV DH, 11
    MOV DL, 79
    INT 10h

    
    MOV BH, 40h        ; background red
    MOV CH, 12
    MOV CL, 0
    MOV DH, 17
    MOV DL, 79
    INT 10h

    
    MOV BH, 60h        ; background brown
    MOV CH, 18
    MOV CL, 0
    MOV DH, 24
    MOV DL, 79
    INT 10h

    ; "Press any key to continue."
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 22
    MOV DL, 25
    INT 10h
    MOV DX, OFFSET KEY_PROMPT
    CALL DISP_MESS

    MOV AH, 00h        ; wait key
    INT 16h
    RET


DRAW_VSTRIPES:
    CALL CLEAR_SCREEN
    MOV AH, 06h
    XOR AL, AL

    
    MOV BH, 10h
    XOR CX, CX         ; (0,0)
    MOV DH, 24
    MOV DL, 19
    INT 10h

    
    MOV BH, 20h
    MOV CH, 0
    MOV CL, 20
    MOV DH, 24
    MOV DL, 39
    INT 10h

   
    MOV BH, 40h
    MOV CH, 0
    MOV CL, 40
    MOV DH, 24
    MOV DL, 59
    INT 10h

    
    MOV BH, 60h
    MOV CH, 0
    MOV CL, 60
    MOV DH, 24
    MOV DL, 79
    INT 10h

    
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 22
    MOV DL, 25
    INT 10h
    MOV DX, OFFSET KEY_PROMPT
    CALL DISP_MESS

    MOV AH, 00h        
    INT 16h
    RET


MENU_TITLE     DB 'MENU', '$'
OPT_A          DB 'a - HORIZONTAL STRIPE', '$'
OPT_B          DB 'b - VERTICAL STRIPE', '$'
CHOICE_PROMPT  DB 'Enter choice (a/b): ', '$'
KEY_PROMPT     DB 'Press any key to continue', '$'