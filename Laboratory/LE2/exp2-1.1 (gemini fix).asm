
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt


ORG 100h  ; Directive for a .COM file. Program starts at memory offset 100h.

jmp START:

; --- DATA DEFINITIONS ---
DATA1 DB 25H 
DATA2 DW 1234H  
DATA3 DB 0H  
DATA4 DW 0H 
DATA5 DW 2345H, 6789H 

; --- CODE --- 
START: 
 
MOV AL, 25H         ; CORRECTED: Use '25H' to copy the hex value into 8-bit AL.
MOV AX, 2345H       ; CORRECTED: Use '2345H' to copy the hex value into 16-bit AX.
MOV BX, AX          ; Copy the content of AX into BX.
MOV CL, AL          ; Copy the content of AL into CL.

MOV AL, [DATA1]     ; CORRECTED: Use brackets [] to copy the byte CONTENT from memory location DATA1 into AL.
MOV AX, [DATA2]     ; CORRECTED: Use brackets [] to copy the word CONTENT from memory location DATA2 into AX.

MOV [DATA3], AL     ; CORRECTED (best practice): Copies AL content into memory location DATA3.
MOV [DATA4], AX     ; CORRECTED (best practice): Copies AX content into memory location DATA4.

MOV BX, OFFSET DATA5 ; The 16-bit offset address of DATA5 is copied into BX.
MOV AX, [BX]         ; Copies the first word at DATA5 (2345H) into AX.

MOV DI, 02H          ; Address element for offset.
MOV AX, [BX+DI]      ; Copies the word at (address in BX + 2), which is 6789H, into AX.

; The following lines from the original code are omitted for clarity as they are either
; redundant (MOV AX, [BX+0002H]) or potentially unsafe (MOV AX, [BX+DI+0002H]).

; --- PROGRAM TERMINATION ---
MOV AH, 4CH         ; CORRECTED: Standard DOS function to exit a program.
INT 21H             ; Call the DOS interrupt.

ret




