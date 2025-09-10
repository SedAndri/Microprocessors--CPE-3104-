
org 100h  ; Set origin for a .COM-style program

    ; Initialize DS to the segment that contains STR1/ORIG
    MOV AX, SEG STR1
    MOV DS, AX

    ; Copy original string characters (STR1 layout: byte0=max, byte1=len, bytes from +2)
    LEA SI, STR1+2
    LEA DI, ORIG
    MOV CL, [STR1+1]
    XOR CH, CH
    CLD
    REP MOVSB

    ; Prepare video segment for display
    MOV AX, 0B800h
    MOV ES, AX

    ; DI will be used as the video memory pointer (cells = 2 bytes)
    XOR DI, DI        ; start at top-left of screen
    MOV DX, DI        ; DX will hold the start-of-line video pointer (fixed column)

    ; --- Display label "Input string: " then the original string on the top line ---
    LEA SI, MSG_LABEL+1    ; skip length byte
    MOV CL, [MSG_LABEL]    ; label length
    XOR CH, CH
    MOV DI, DX             ; display starting at top-left
LabelDisplayLoop:
    MOV AL, [SI]
    MOV AH, 07h
    MOV ES:[DI], AX
    ADD DI, 2
    INC SI
    LOOP LabelDisplayLoop

    ; now display the original string immediately after the label
    LEA SI, ORIG
    MOV CL, [STR1+1]
    XOR CH, CH
DisplayOrigLoop:
    MOV AL, [SI]
    MOV AH, 07h
    MOV ES:[DI], AX
    ADD DI, 2
    INC SI
    LOOP DisplayOrigLoop
    ADD DX, 160       ; move DX to next line so rotations print below the original

; Rotate-and-display loop
NextRotation:
    ; length in CX
    MOV CL, [STR1+1]
    XOR CH, CH
    CMP CX, 1
    JBE DoneRotation   ; nothing to rotate if length <= 1

    ; Perform right rotation by one character
    LEA SI, STR1+2     ; SI -> first character
    PUSH DX            ; save start-of-line pointer while we manipulate string
    MOV BX, CX
    DEC BX             ; BX = length-1 = index of last char
    MOV DI, SI
    ADD DI, BX         ; DI -> last character
    MOV AL, [DI]       ; save last char
    MOV CX, BX         ; CX = number of shifts to perform
ShiftLoop:
    MOV DL, [DI-1]
    MOV [DI], DL
    DEC DI
    LOOP ShiftLoop
    MOV [SI], AL       ; put last char to first position

    ; Display rotated string at current video DI
    POP DX             ; restore start-of-line pointer
    MOV DI, DX         ; use DX as the display starting DI
    LEA SI, STR1+2
    MOV CL, [STR1+1]
    XOR CH, CH
DisplayLoop:
    MOV AL, [SI]
    MOV AH, 07h
    MOV ES:[DI], AX
    ADD DI, 2
    INC SI
    LOOP DisplayLoop
    ADD DX, 160        ; advance to next line start (80 cols * 2 bytes)

    ; Compare rotated string with the original saved in ORIG
    LEA SI, STR1+2
    LEA BX, ORIG
    MOV CL, [STR1+1]
    XOR CH, CH
CompareLoop:
    MOV AL, [SI]
    CMP AL, [BX]
    JNE NextRotation
    INC SI
    INC BX
    DEC CX
    JNZ CompareLoop

DoneRotation:
    RET

.DATA
    ; STR1 layout: first byte = max length (unused), second byte = current length
    STR1  DB 100,5,'HELLO', 95 dup(' ')
    ORIG  DB 100 dup(' ')
    MSG_LABEL DB 14,'Input string: '
    MSG2  DB 0Dh,0Ah,' $'
    MSG1  DB 0Dh,0Ah,'Output: $'
.CODE