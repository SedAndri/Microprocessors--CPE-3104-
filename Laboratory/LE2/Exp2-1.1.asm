
;Bordario, Sid Andre P.

ORG 100h  

jmp START:

; --- DATA DEFINITIONS ---
DATA1 DB 25H               ; DB = Define Byte
DATA2 DW 1234H             ; DW = Define Word
DATA3 DB 0H  
DATA4 DW 0H 
DATA5 DW 2345H, 6789H 

; --- CODE --- 
START: 
 
MOV AL, 25H             ; COPY 25H INTO 8 BIT AL REGISTER 
MOV AX, 2345H           ; COPY 2345H INTO 16 BIT AX REGISTER 
MOV BX, AX              ; COPY THE CONTENT OF AX INTO BX REGISTER(16 BIT)
MOV CL, AL              ; COPY THE CONTENT OF AL INTO CL REGISTER    

                        

MOV AL, [DATA1]         ; COPIES THE BYTE CONTENTS OF DATA SEGMENT MEMORY LOCATION
MOV AX, [DATA2]         ; COPIES THE WORD CONTENTS OF DATA SEGMENT MEMORY

MOV [DATA3], AL         ; COPIES THE AL CONTENT INTO THE BYTE CONTENTS OF DATA.
MOV [DATA4], AX         ; COPIES THE AX CONTENT INTO THE WORD CONTENTS OF DATA
                        
MOV BX, OFFSET DATA5    ; THE 16 BIT OFFSET ADDRESS OF DS MEMEORY LOCATION DATA5 IS 
MOV AX, [BX]            ; COPIES THE WORD CONTENT OF DATA SEGMENT MEMORY LOCATION .

MOV DI, 02H             ; ADDRESS ELEMENT 
MOV AX, [BX+DI]         ; COPIES THE WORD CONTENT OF DATA SEGMENT MEMORY LOCATION 

; The following lines from the original code are omitted for clarity as they are either
; redundant (MOV AX, [BX+0002H]) or potentially unsafe (MOV AX, [BX+DI+0002H]).

; --- PROGRAM TERMINATION ---
MOV AH, 4CH         ; CORRECTED: Standard DOS function to exit a program.
INT 21H             ; Call the DOS interrupt.

ret







