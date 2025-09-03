
; Bordario, Sid Andre P.

org 100h

SOURCE  DW 1111H, 2222H, 3333H     ; 3 words
DEST    DW 0H, 0H, 0H              ; 3 words

START:

    MOV BX, OFFSET SOURCE          ; Base register points to SOURCE
    MOV SI, OFFSET DEST            ; Index register points to DEST

    ; Use displacement of 0002H (2 bytes = 1 word)
    ; This will access the second element (2222H)

    MOV AX, [BX+SI+0002H]          ; Load word from SOURCE[1] into AX
    MOV [SI+BX+0002H], AX          ; Store AX into DEST[1]

    MOV AH, 4CH                    ; DOS terminate program
    INT 21H


ret




