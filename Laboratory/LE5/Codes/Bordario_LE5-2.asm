;====================================================================
; Bordario, Sid Andre P.
;====================================================================

DATA SEGMENT 
 PORTA EQU 0F0H  
 PORTB EQU 0F2H 
 PORTC EQU 0F4H 
 

 SEVEN_SEG DB 00111111B  ; 0
           DB 00000110B  ; 1  
           DB 01011011B  ; 2
           DB 01001111B  ; 3
           DB 01100110B  ; 4
           DB 01101101B  ; 5
           DB 01111101B  ; 6
           DB 00000111B  ; 7
           DB 01111111B  ; 8
           DB 01101111B  ; 9
           

 LED_PATTERN DB 10000000B  ; LED 7
             DB 01000000B  ; LED 6
             DB 00100000B  ; LED 5
             DB 00010000B  ; LED 4
             DB 00001000B  ; LED 3
             DB 00000100B  ; LED 2
             DB 00000010B  ; LED 1
             DB 00000001B  ; LED 0
 DATA ENDS 
 
 CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA
 MOV AX, DATA 
 MOV DS, AX 
 
 ORG 0000H 
 
 START: 
 MOV DX, PORTA
 MOV AL, 00000000B 
 OUT DX, AL
 
 MOV DX, PORTB 
 MOV AL, 00000000B 
 OUT DX, AL

MAIN_LOOP:
 MOV DX, PORTC
 IN AL, DX 
 
 CMP AL, 01H  
 JE RUNNING_LED
 
 CMP AL, 02H   
 JE COUNT_DISPLAY
 
 JMP MAIN_LOOP 

RUNNING_LED:
 MOV SI, 0    
 MOV CX, 8     
 
LED_LOOP:
 MOV AL, LED_PATTERN[SI]  
 MOV DX, PORTA
 OUT DX, AL   
 
 ; Delay
 PUSH CX
 MOV CX, 5000
DELAY1:
 NOP
 LOOP DELAY1
 POP CX
 
 INC SI        
 LOOP LED_LOOP 
 
 JMP MAIN_LOOP 

COUNT_DISPLAY:
 MOV SI, 0     
 MOV CX, 10    
 
COUNT_LOOP:
 MOV AL, SEVEN_SEG[SI]  
 MOV DX, PORTB
 OUT DX, AL    
 
 ; Delay
 PUSH CX
 MOV CX, 8000
DELAY2:
 NOP  
 LOOP DELAY2
 POP CX
 
 INC SI        
 LOOP COUNT_LOOP 
 
 JMP MAIN_LOOP 
 
 CODE ENDS 
 END START