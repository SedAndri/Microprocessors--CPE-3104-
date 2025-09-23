DATA SEGMENT

	       PORTA EQU 0F0H         ; Address of PORTA
	       PORTB EQU 0F2H         ; Address of PORTB
	       PORTC EQU 0F4H         ; Address of PORTC
	       COM_REG EQU 0F6H       ; Address of Command Register
	       NUMB0 EQU 00111111B    ; Binary code for displaying 0
	       NUMB1 EQU 00000110B    ; Binary code for displaying 1
	       NUMB2 EQU 01011011B    ; Binary code for displaying 2
	       NUMB3 EQU 01001111B    ; Binary code for displaying 3
	       NUMB4 EQU 01100110B    ; Binary code for displaying 4
	       NUMB5 EQU 01101101B    ; Binary code for displaying 5
	       NUMB6 EQU 01111101B    ; Binary code for displaying 6
	       NUMB7 EQU 00000111B    ; Binary code for displaying 7
	       NUMB8 EQU 01111111B    ; Binary code for displaying 8
	       NUMB9 EQU 01101111B    ; Binary code for displaying 9
	       
DATA ENDS

CODE SEGMENT

	       MOV AX, DATA         ; Load address of DATA segment into AX
	       MOV DS, AX           ; Set Data Segment register (DS) to AX
	       ORG 0000H            ; Start the code at memory address 0000H
	       
START:
	       MOV DX, COM_REG      ; Set Command Register address in DX
	       MOV AL, 89H          ; Load control value into AL (initialization)
	       OUT DX, AL           ; Send control value to Command Register
	       
RESET:
	       MOV DX, PORTA        ; Set address for PORTA
	       MOV AL, NUMB0        ; Load value for displaying 0 into AL
	       OUT DX, AL           ; Output value to PORTA
	       
	       MOV DX, PORTB        ; Set address for PORTB
	       MOV AL, NUMB0        ; Load value for displaying 0 into AL
	       OUT DX, AL           ; Output value to PORTB
	       
	       MOV CX, 0000H        ; Initialize CX register for counting

HERE:
	       MOV DX, PORTC        ; Set address for PORTC
	       IN AL, DX            ; Read input from PORTC into AL
	       CMP AL, 01H          ; Compare AL with 1 (button press signal)
	       JE LSDIG_A               ; Jump to LSDIG_A if equal
	       JMP HERE             ; Otherwise, loop back to HERE

LSDIG_A:
	       CALL DELAY           ; Call delay procedure
	       CALL DELAY           ; Add a second delay for proper timing
	       CMP CX, 0909H        ; Check if the count has reached 99
	       JE RESET             ; Reset to 00 if CX = 99

	       CMP CL, 09H          ; Check if lower byte of CX (CL) has reached 9
	       JE MSDIG_B               ; Jump to MSDIG_B if CL = 9

	       INC CL               ; Increment CL (units counter)

	       ; Update PORTA with the corresponding number based on CL
	       LSDIG_A1:
	       CMP CL, 01H          ; Check if CL = 1
	       JNE LSDIG_A2             ; Jump to LSDIG_A2 if not
	       MOV DX, PORTA        ; Set PORTA address
	       MOV AL, NUMB1        ; Load value for 1 into AL
	       OUT DX, AL           ; Output value to PORTA
	       JMP HERE

	       LSDIG_A2:
	       CMP CL, 02H          ; Check if CL = 2
	       JNE LSDIG_A3             ; Jump to LSDIG_A3 if not
	       MOV DX, PORTA
	       MOV AL, NUMB2
	       OUT DX, AL
	       JMP HERE
		 
	       LSDIG_A3:
	       CMP CL, 03H
	       JNE LSDIG_A4
	       MOV DX, PORTA
	       MOV AL, NUMB3
	       OUT DX, AL
	       JMP HERE

	       LSDIG_A4:
	       CMP CL, 04H
	       JNE LSDIG_A5
	       MOV DX, PORTA
	       MOV AL, NUMB4
	       OUT DX, AL
	       JMP HERE

	       LSDIG_A5:
	       CMP CL, 05H
	       JNE LSDIG_A6
	       MOV DX, PORTA
	       MOV AL, NUMB5
	       OUT DX, AL
	       JMP HERE

	       LSDIG_A6:
	       CMP CL, 06H
	       JNE LSDIG_A7
	       MOV DX, PORTA
	       MOV AL, NUMB6
	       OUT DX, AL
	       JMP HERE

	       LSDIG_A7:
	       CMP CL, 07H
	       JNE LSDIG_A8
	       MOV DX, PORTA
	       MOV AL, NUMB7
	       OUT DX, AL
	       JMP HERE

	       LSDIG_A8:
	       CMP CL, 08H
	       JNE LSDIG_A9
	       MOV DX, PORTA
	       MOV AL, NUMB8
	       OUT DX, AL
	       JMP HERE

	       LSDIG_A9:
	       CMP CL, 09H          ; Check if CL = 9
	       MOV DX, PORTA
	       MOV AL, NUMB9
	       OUT DX, AL
	       JMP HERE

MSDIG_B:
	       MOV CL, 00H          ; Reset CL (units counter) to 0
	       MOV DX, PORTA
	       MOV AL, NUMB0        ; Display 0 on PORTA
	       OUT DX, AL
	       
	       INC CH               ; Increment CH (tens counter)

	       ; Update PORTB with the corresponding number based on CH
	       HLSDIG_A1:
	       CMP CH, 01H
	       JNE HLSDIG_A2
	       MOV DX, PORTB
	       MOV AL, NUMB1
	       OUT DX, AL
	       JMP HERE

	       HLSDIG_A2:
	       CMP CH, 02H
	       JNE HLSDIG_A3
	       MOV DX, PORTB
	       MOV AL, NUMB2
	       OUT DX, AL
	       JMP HERE

	       HLSDIG_A3:
	       CMP CH, 03H
	       JNE HLSDIG_A4
	       MOV DX, PORTB
	       MOV AL, NUMB3
	       OUT DX, AL
	       JMP HERE

	       HLSDIG_A4:
	       CMP CH, 04H
	       JNE HLSDIG_A5
	       MOV DX, PORTB
	       MOV AL, NUMB4
	       OUT DX, AL
	       JMP HERE

	       HLSDIG_A5:
	       CMP CH, 05H
	       JNE HLSDIG_A6
	       MOV DX, PORTB
	       MOV AL, NUMB5
	       OUT DX, AL
	       JMP HERE

	       HLSDIG_A6:
	       CMP CH, 06H
	       JNE HLSDIG_A7
	       MOV DX, PORTB
	       MOV AL, NUMB6
	       OUT DX, AL
	       JMP HERE

	       HLSDIG_A7:
	       CMP CH, 07H
	       JNE HLSDIG_A8
	       MOV DX, PORTB
	       MOV AL, NUMB7
	       OUT DX, AL
	       JMP HERE

	       HLSDIG_A8:
	       CMP CH, 08H
	       JNE HLSDIG_A9
	       MOV DX, PORTB
	       MOV AL, NUMB8
	       OUT DX, AL
	       JMP HERE

	       HLSDIG_A9:
	       CMP CH, 09H          ; Check if CH = 9
	       MOV DX, PORTB
	       MOV AL, NUMB9
	       OUT DX, AL
	       JMP HERE

DELAY PROC                    ; Delay subroutine to slow down the counting
		  MOV BX, 1BE4H   ; BX controls the delay duration
	       L1:
		  DEC BX          ; Decrement BX until it reaches 0
		  NOP             ; No operation (waste one clock cycle)
		  JNZ L1          ; Jump to L1 if BX is not zero
		  RET             ; Return from subroutine
DELAY ENDP

CODE ENDS  
END