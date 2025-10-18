;====================================================================
; Author: GROUP 1-4
; Description: Code that counts the 7-Seg displays from 0-9 then repeat
; Created:   Monday Nov 9 2020
; Processor: 8086
; Compiler:  MASM32
;
; Before starting simulation set Internal Memory Size 
; in the 8086 model properties to 0x10000
;============

DATA SEGMENT     
    
PORTA		EQU	0F0H	; Port A Address
PORTB		EQU 0F2H	; Port B Address
PORTC		EQU	0F4H	; Port C Address
COM_REG	   	EQU	0F6H	; Command Register Address  
COM_REGA   	EQU 89H     	; Port A and B -> OUTPUT
				; Port C -> INPUT  
				; MODE 0        
                        
                        
COUNTERA	    EQU 0F8H		; Counter A Port address
COUNTERB	    EQU 0FAH		; Counter B Port address
COUTNERC	    EQU 0FCH		; Counter C Port address
COUNTER_REG 	EQU 0FEH	    	; 8253 Register Address
COUNTER_REGA	EQU	032H	    	; MSB -> LSB
				        ; 00  -> COUNTER 0
				        ; 01  -> Read/Write low byte of counter value only
				        ; 001 -> Mode 1
				        ; 0  -> HEX count
				        ; 00110010 -> Combined
					; 32H
    
    
DATA ENDS  


CODE SEGMENT    
  
   MOV AX, DATA
   MOV DS, AX
   ORG 0000H  
   
START:  
   MOV DX,COM_REG        ;Settings for uP 8086
   MOV AL,COM_REGA
   OUT DX,AL
   
   MOV DX,COUNTER_REG    ;Settings for 8253 
   MOV AL,COUNTER_REGA
   OUT DX,AL    	 
			 ;Solving for number of N for 1 second
                         ;Frequency  = 100hz
                         ;T = 1/100hz = .01
                         ;N = 1/.01  = 100 
			 ;N = 100(0064H) = 1 second		
   
   MOV DX,COUNTERA 		
   MOV AL,64H		 ;Move lower byte 64H to counter A
   OUT DX,AL   
   MOV AL,00h		 ;Move uppoer byte 00H to counter A
   OUT DX,AL
   
   COUNT:
   MOV DX,PORTA 	 
   MOV AL,10111111B      ;0 for 7seg  
   OUT DX,AL     
   
   CAll DELAY
   
   MOV DX,PORTA 	 ;configure port A 
   MOV AL,10000110B      ;1 for 7seg 
   OUT DX,AL                        
      CAll DELAY	 ;Call delay funtion
   
   MOV DX,PORTA 	 ;configure port A
   MOV AL,11011011B      ;2 for 7seg   
   OUT DX,AL    
      CAll DELAY	 ;Call delay funtion
   
   MOV DX,PORTA 	 ;configure port A
   MOV AL,11001111B      ;3 for 7seg 
   OUT DX,AL
     CAll DELAY		 ;Call delay funtion
     
   MOV DX,PORTA 	 ;configure port A
   MOV AL,11100110B      ;4 for 7seg 
   OUT DX,AL
     CAll DELAY		 ;Call delay funtion
     
   MOV DX,PORTA 	 ;configure port A
   MOV AL,11101101B      ;5 for 7seg 
   OUT DX,AL
     CAll DELAY
			 ;....
			 ;...
			 ;..
   MOV DX,PORTA                
   MOV AL,11111101B      ;6 for 7seg  
   OUT DX,AL
    CAll DELAY
    
   MOV DX,PORTA 
   MOV AL,10000111B      ;7 for 7seg 
   OUT DX,AL
     CAll DELAY
     
   MOV DX,PORTA 
   MOV AL,11111111B      ;8 for 7seg
   OUT DX,AL
     CAll DELAY
     
   MOV DX,PORTA 
   MOV AL,11101111B      ;9 for 7seg                            
   OUT DX,AL
   CAll DELAY
   
   
   LOOP COUNT		 ;Loop counter

   DELAY proc		 ;Delay funciton for 1 second
        MOV DX,PORTC	 ;configure portC
        IN  AL,DX        ;READ VALUE OF OUT in 8253
        
        CMP AL,08H       ;Compare OUT if its 0 or 1
        JE  timer        ;JUMP timer if OUT is high
        
        JMP here1
          timer: 
             MOV DX,PORTB	;configure portb
             MOV AL,01H         ;set portB0(TRIGGER) to HIGH to trigger the count	           
             OUT DX,AL   	;output at portB
        here1:   
        here:      
        MOV DX,PORTC	 ;configure portC
        IN  AL,DX        ;READ VALUE OF OUT in 8253
        
        CMP AL,00H	 ;compare the Input OUT(PC3) if:
			 ;LOW(0) then it is still counting
			 ;HIGH(1) then it is finished counting
        JE  here	 ;loop until it reaches 1 second
        MOV DX,PORTB	 ;configure port B
             MOV AL,00H       ;set portB0(TRIGGER) to LOW           
             OUT DX,AL        ;output goes to GATE SIGNAL of 8283
                    
                  
        ret		       ;return
        DELAY ENDP
 
CODE ENDS
END