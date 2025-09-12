     ; Bordario, Sid Andre P.
     
     ;study and improve
org 100h  

   
    MOV AX, SEG STR1
    MOV DS, AX

   
    LEA SI, STR1+2
    LEA DI, ORIG
    MOV CL, [STR1+1]
    XOR CH, CH
    CLD
    REP MOVSB

   
    MOV AX, 0B800h
    MOV ES, AX

    
    XOR DI, DI        
    MOV DX, DI        

   
    LEA SI, MSG_LABEL+1    
    MOV CL, [MSG_LABEL]   
    XOR CH, CH
    MOV DI, DX             
LabelDisplayLoop:
    MOV AL, [SI]
    MOV AH, 07h
    MOV ES:[DI], AX
    ADD DI, 2
    INC SI
    LOOP LabelDisplayLoop

    
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
    ADD DX, 160       


NextRotation:
   
    MOV CL, [STR1+1]
    XOR CH, CH
    CMP CX, 1
    JBE DoneRotation   

    
    LEA SI, STR1+2     
    PUSH DX            
    MOV BX, CX
    DEC BX             
    MOV DI, SI
    ADD DI, BX        
    MOV AL, [DI]       
    MOV CX, BX         
ShiftLoop:
    MOV DL, [DI-1]
    MOV [DI], DL
    DEC DI
    LOOP ShiftLoop
    MOV [SI], AL      

    
    POP DX             
    MOV DI, DX         
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
    ADD DX, 160        

    
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
    
    STR1  DB 200,9,'mamma mia', 194 dup(' ')
    ORIG  DB 200 dup(' ')
    MSG_LABEL DB 14,'Input string: '
    MSG2  DB 0Dh,0Ah,' $'
    MSG1  DB 0Dh,0Ah,'Output: $'
.CODE