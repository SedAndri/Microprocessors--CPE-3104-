;====================================================================
;
; Author: Ivor Canque & May Ochia
; Created: Tue Oct 29 2024
; Processor: 8086
; Compiler: MASM32
; 
; Before starting simulation, ensure the internal memory size in 
; the 8086 model properties is set to 0x10000.
;====================================================================

PROCED1 SEGMENT
ISR4 PROC FAR
ASSUME CS:PROCED1, DS:DATA
ORG 01000H
   PUSHF
   PUSH AX
   PUSH DX
   
   MOV AL, _TEST_BTN
   INC AL
   MOV _TEST_BTN, AL
   
   POP DX
   POP AX
   POPF
   IRET
   ISR4 ENDP
PROCED1 ENDS

PROCED2 SEGMENT
ISR6 PROC FAR
ASSUME CS:PROCED2, DS:DATA
ORG 02000H
   PUSHF
   PUSH AX
   PUSH DX
   
   MOV EMG_BTN, 01H
   
   POP DX
   POP AX
   POPF
   IRET
   ISR6 ENDP
PROCED2 ENDS

DATA SEGMENT
    ORG 03000H
    PORTA EQU 0E8H     
    PORTB EQU 0EAH     
    PORTC EQU 0ECH     
    COM_REG EQU 0EEH     
    PORTA1 EQU 0F0H    
    PORTB1 EQU 0F2H      
    PORTC1 EQU 0F4H  
    COM_REG1 EQU 0F6H  
    LOAD_CTR0 EQU 0F8H  
    WRITE_W EQU 0FEH
    PIC1 EQU 0E0H
    PIC2 EQU 0E2H
    ICW1 EQU 13H
    ICW2 EQU 84H
    ICW4 EQU 3H
    OCW1_84H EQU 0EFH
    OCW1_86H EQU 0BFH
    _TEST_BTN DB 0
    EMG_BTN DB 0
    LIST1 DB "[1] Coke Large","$$" 
    LIST2 DB "[2] Coke Medium","$$"  
    LIST3 DB "[3] Sprite Large","$$"   
    LIST4 DB "[4] Sprite Medium     ","$$" 
    Dispense DB "Dispensing...","$$" 
    _TestValve DB "Testing valves...","$$"
    Emg DB "Emergency stop...","$$"
DATA ENDS

STK SEGMENT STACK
	BOS DW 64d DUP(?) ; stack depth (bottom of stack)
	TOS LABEL WORD ; top of stack
STK ENDS

CODE SEGMENT PUBLIC 'CODE'
ASSUME CS:CODE, DS:DATA, SS:STK
ORG 08000H

START:		
    MOV AX, DATA
    MOV DS, AX ; set the Data Segment address
    MOV AX, STK
    MOV SS, AX ; set the Stack Segment address
    LEA SP, TOS ; set address of SP as top of stack
    CLI ; clears IF flag
		
    ; Program the first 8255 chip for LCD and keypad
    MOV DX, COM_REG     
    MOV AL, 89H      
    OUT DX, AL      

    ; Program the second 8255 chip
    MOV DX, COM_REG1  
    MOV AL, 89H  
    OUT DX, AL    

    ; Program the 8253 timer (mode 4)
    MOV DX, WRITE_W    
    MOV AL, 38H        
    OUT DX, AL

    MOV DX, PIC1 ; set I/O address to access ICW1
    MOV AL, ICW1
    OUT DX, AL
    
    MOV AX, OFFSET ISR4 ; get offset address of ISR1 (IP)
    MOV [ES:210H], AX ; store offset address to memory at 200H
    MOV AX, SEG ISR4 ; get segment address of ISR1 (CS)
    MOV [ES:212H], AX ; store segment address to memory at 202H
    MOV AX, OFFSET ISR6 ; get offset address of ISR2 (IP)
    MOV [ES:218H], AX ; store offset address to memory at 204H
    MOV AX, SEG ISR6 ; get segment address of ISR2 (CS)
    MOV [ES:21AH], AX ; store segment address to memory at 206H    

; Display Menu
DISP_MENU:
    MOV AL, 0H
    MOV _TEST_BTN, AL
    MOV EMG_BTN, AL
    
    MOV DX, PIC2
    MOV AL, ICW2
    OUT DX, AL
    MOV AL, ICW4
    OUT DX, AL
    MOV AL, OCW1_84H
    OUT DX, AL
    STI
    
    ; Initialize the LCD display
    XOR AX,AX
    XOR BX,BX
    CALL INIT_LCD
    
    MOV DX, PORTB1     
    MOV AL, 00H      
    OUT DX, AL    

    COKEL:
       XOR AX, AX        
       MOV AL, 80H      
       CALL INST_CTRL     
       LEA SI, LIST1      
       PUSH AX       

    NEXT_COKEL:
        MOV AX, [SI]    
        CMP AL, "$"     
        JE COKEM   
        CALL DATA_CTRL  
        INC SI        
        POP AX          
        INC AL        
        PUSH AX      
        CALL INST_CTRL  
        JMP NEXT_COKEL  

    COKEM:
       XOR AX, AX        
       MOV AL, 0C0H      
       CALL INST_CTRL     
       LEA SI, LIST2       
       PUSH AX           

    NEXT_COKEM:
        MOV AX, [SI]    
        CMP AL, "$"  
        JE SPRITEL    
        CALL DATA_CTRL  
        INC SI        
        POP AX           
        INC AL        
        PUSH AX         
        CALL INST_CTRL   
        JMP NEXT_COKEM 

    SPRITEL:
       XOR AX, AX        
       MOV AL, 94H      
       CALL INST_CTRL     
       LEA SI, LIST3  
       PUSH AX             

    NEXT_SPRITEL:
        MOV AX, [SI]   
        CMP AL, "$"    
        JE NEXT_SPRITEM   
        CALL DATA_CTRL   
        INC SI      
        POP AX  
        INC AL      
        PUSH AX     
        CALL INST_CTRL    
        JMP NEXT_SPRITEL 

    NEXT_SPRITEM:
       XOR AX, AX         
       MOV AL, 0D4H       
       CALL INST_CTRL    
       LEA SI, LIST4    
       PUSH AX              

    NEXT_NEXT_SPRITEM:
        MOV AX, [SI]   
        CMP AL, "$"     
        JE END_DISP      
        CALL DATA_CTRL    
        INC SI         
        POP AX          
        INC AL          
        PUSH AX         
        CALL INST_CTRL   
        JMP NEXT_NEXT_SPRITEM

    END_DISP:
        POP AX           
        XOR AX, AX     
     	
   CHECK_DAVBL:
       MOV AL, _TEST_BTN
       CMP AL, 02H
       JE DISPLAY_LEDTEST
  
       MOV DX, PORTC      
       IN AL, DX        
       AND AL, 10H         
       CMP AL, 10H
       JNE CHECK_DAVBL   
       IN AL, DX       
       AND AL, 0FH        
       CMP AL, 00H         ; Check if key pressed is 1 (00H)
       JE D1             
       CMP AL, 01H         ; Check if key pressed is 2 (01H)
       JE D2               
       CMP AL, 02H         ; Check if key pressed is 3 (02H)
       JE D3           
       CMP AL, 04H         ; Check if key pressed is 4 (04H)
       JE D4         
       JMP CHECK_DAVBL     ; If no valid key, check again

   D1: ; Large Coke selection
       MOV DX, PIC2
       MOV AL, OCW1_86H
       OUT DX,AL
       STI
       MOV CX, 0007H     
       LOOPD1:
	   MOV AL, EMG_BTN
	   CMP AL, 01H
	   JE START_EMG
	   MOV DX, PORTB1  
	   MOV AL, 01H    
	   OUT DX, AL       
	   CALL PRINT_DISPENSE
	   MOV AL, 9EH     
	   CALL INST_CTRL
	   MOV AL, 30H     
	   ADD AL, CL 
	   CALL DATA_CTRL   
	   MOV AL, 9FH    
	   CALL INST_CTRL  
	   MOV AL, 's'   
	   CALL DATA_CTRL
	   CALL DELAY_1S    
	   DEC CL       
	   CMP CL, 00H    
	   JE END_D1  
	   JMP LOOPD1      

   END_D1:
       JMP DISP_MENU       ; Go back to display menu

   D2: ; Medium Coke selection
       MOV DX, PIC2
       MOV AL, OCW1_86H
       OUT DX,AL
       STI
       MOV CX, 0004H     
       LOOPD2:
	    MOV AL, EMG_BTN
	   CMP AL, 01H
	   JE START_EMG
	   MOV DX, PORTB1 
	   MOV AL, 02H    
	   OUT DX, AL   
	   CALL PRINT_DISPENSE 
	   MOV AL, 9EH      
	   CALL INST_CTRL    
	   MOV AL, 30H   
	   ADD AL, CL      
	   CALL DATA_CTRL   
	   MOV AL, 9FH 
	   CALL INST_CTRL   
	   MOV AL, 's'   
	   CALL DATA_CTRL    
	   CALL DELAY_1S    
	   DEC CL         
	   CMP CL, 00H    
	   JE END_D2    
	   JMP LOOPD2    

   END_D2:
       JMP DISP_MENU       

   D3: ; Large Sprite selection
       MOV DX, PIC2
       MOV AL, OCW1_86H
       OUT DX,AL
       STI
       MOV CX, 0007H      
       LOOPD3:
	   MOV AL, EMG_BTN
	   CMP AL, 01H
	   JE START_EMG
	   MOV DX, PORTB1  
	   MOV AL, 04H      
	   OUT DX, AL   
	   CALL PRINT_DISPENSE
	   MOV AL, 9EH   
	   CALL INST_CTRL  
	   MOV AL, 30H    
	   ADD AL, CL   
	   CALL DATA_CTRL    
	   MOV AL, 9FH      
	   CALL INST_CTRL 
	   MOV AL, 's'      
	   CALL DATA_CTRL   
	   CALL DELAY_1S   
	   DEC CL   
	   CMP CL, 00H    
	   JE END_D3       
	   JMP LOOPD3       

   END_D3:
       JMP DISP_MENU      

   D4: ; Medium Sprite selection
       MOV DX, PIC2
       MOV AL, OCW1_86H
       OUT DX,AL
       STI
       MOV CX, 0004H     
       LOOPD4:
	   MOV AL, EMG_BTN
	   CMP AL, 01H
	   JE START_EMG
	   MOV DX, PORTB1   
	   MOV AL, 08H    
	   OUT DX, AL     
	   CALL PRINT_DISPENSE 
	   MOV AL, 9EH   
	   CALL INST_CTRL  
	   MOV AL, 30H   
	   ADD AL, CL      
	   CALL DATA_CTRL   
	   MOV AL, 9FH   
	   CALL INST_CTRL 
	   MOV AL, 's'  
	   CALL DATA_CTRL   
	   CALL DELAY_1S  
	   DEC CL        
	   CMP CL, 00H    
	   JE END_D1        
	   JMP LOOPD4      

   END_D4:
       JMP DISP_MENU
       
   DISPLAY_LEDTEST:
      MOV DX, PIC2
      MOV AL, OCW1_86H
      OUT DX,AL
      STI
      
      MOV CX, 01H
 
      LOOP_LED1:
	 MOV DX, PORTB1
	 MOV AL, 01H
	 OUT DX,AL
	 CALL PRINT_TESTVAL
	 CALL DELAY_1S
	 MOV AL, EMG_BTN
	 CMP AL, 00H
	 JNE START_EMG
	 DEC CL
	 CMP CL,00H
	 JE L2
	 JMP LOOP_LED1
 
      L2:
	 MOV CX, 01H
      LOOP_LED2:
	 MOV DX, PORTB1
	 MOV AL, 02H
	 OUT DX,AL
	 CALL PRINT_TESTVAL
	 CALL DELAY_1S
	 MOV AL, EMG_BTN
	 CMP AL, 00H
	 JNE START_EMG
	 DEC CL
	 CMP CL,00H
	 JE L4
	 JMP LOOP_LED2
	 
      L4:
	 MOV CX, 01H
      LOOP_LED4:
	 MOV DX, PORTB1
	 MOV AL, 04H
	 OUT DX,AL
	 CALL PRINT_TESTVAL
	 CALL DELAY_1S
	 MOV AL, EMG_BTN
	 CMP AL, 00H
	 JNE START_EMG
	 DEC CL
	 CMP CL,00H
	 JE L8
	 JMP LOOP_LED4
	 
      L8:
	 MOV CX, 01H
      LOOP_LED8:
	 MOV DX, PORTB1
	 MOV AL, 08H
	 OUT DX,AL
	 CALL PRINT_TESTVAL
	 CALL DELAY_1S
	 MOV AL, EMG_BTN
	 CMP AL, 00H
	 JNE START_EMG
	 DEC CL
	 CMP CL,00H
	 JE END_LOOPLED
	 JMP LOOP_LED8

      END_LOOPLED:
	 JMP DISP_MENU
   
      START_EMG:
	 MOV AL, 00H
	 MOV EMG_BTN, AL
	 MOV CX, 02H
	 
	 LOOPEMG:
	    MOV DX, PORTB1
	    MOV AL, 00H
	    OUT DX,AL
	    CALL PRINT_EMG
	    CALL DELAY_1S
	    DEC CL
	    CMP CL,00H
	    JE END_LOOPEMG
	    JMP LOOPEMG

      END_LOOPEMG:
	 JMP DISP_MENU
	 
; Subroutine to display dispensing message
PRINT_DISPENSE:
   CALL INIT_LCD     
   XOR AX, AX         
   MOV AL, 0C3H      
   CALL INST_CTRL    
   LEA SI, Dispense   
   PUSH AX         
   NEXT_DISP:
       MOV AX, [SI]      
       CMP AL, "$"         
       JE END_DISPENSE   
       CALL DATA_CTRL   
       INC SI          
       POP AX           
       INC AL          
       PUSH AX           
       CALL INST_CTRL   
       JMP NEXT_DISP    

   END_DISPENSE:
       POP AX           
       XOR AX, AX    
       RET

PRINT_TESTVAL:
    MOV AL, 0H
    MOV _TEST_BTN, AL
    CALL INIT_LCD     
    XOR AX, AX         
    MOV AL, 0C1H      
    CALL INST_CTRL    
    LEA SI, _TestValve   
    PUSH AX         
   NEXT_TESTDISP:
       MOV AX, [SI]      
       CMP AL, "$"         
       JE END_TESTVAL
       CALL DATA_CTRL   
       INC SI          
       POP AX           
       INC AL          
       PUSH AX           
       CALL INST_CTRL   
       JMP NEXT_TESTDISP
   END_TESTVAL:
       POP AX           
       XOR AX, AX    
       RET
       
   PRINT_EMG:
       CALL INIT_LCD     
       XOR AX, AX         
       MOV AL, 0C3H      
       CALL INST_CTRL    
       LEA SI, Emg 
       PUSH AX         
      NEXT_EMGDISP:
	  MOV AX, [SI]      
	  CMP AL, "$"         
	  JE END_EMG
	  CALL DATA_CTRL   
	  INC SI          
	  POP AX           
	  INC AL          
	  PUSH AX           
	  CALL INST_CTRL   
	  JMP NEXT_EMGDISP

   END_EMG:
       POP AX           
       XOR AX, AX    
       RET

ENDLESS:
    NOP
    JMP ENDLESS     

; Delay for 1 millisecond
DELAY_1MS:
    MOV DX, LOAD_CTR0   
    MOV AL, 04H     
    OUT DX, AL       
    MOV AL, 00H       
    OUT DX, AL   

CHECK:
    MOV DX, PORTC1    
    IN AL, DX   
    CMP AL, 00H        
    JNE CHECK         
    RET               

; Delay for 1 second
DELAY_1S:
    MOV DX, LOAD_CTR0    
    MOV AL, 0A0H         
    OUT DX, AL        
    MOV AL, 0FH        
    OUT DX, AL           

CHECK1:
    MOV DX, PORTC1      
    IN AL, DX          
    CMP AL, 00H       
    JNE CHECK1         
    RET                  

; Send instruction to LCD control
INST_CTRL:
    PUSH AX           
    MOV DX, PORTA      
    OUT DX, AL        
    MOV DX, PORTB      
    MOV AL, 02H     
    OUT DX, AL        
    CALL DELAY_1MS    
    MOV DX, PORTB     
    MOV AL, 00H     
    OUT DX, AL           
    POP AX             
    RET

; Send data to LCD data register
DATA_CTRL:
    PUSH AX           
    MOV DX, PORTA        
    OUT DX, AL        
    MOV DX, PORTB        
    MOV AL, 03H        
    OUT DX, AL          
    CALL DELAY_1MS      
    MOV DX, PORTB     
    MOV AL, 01H         
    OUT DX, AL      
    POP AX           
    RET

; Initialize the LCD display settings
INIT_LCD:
    MOV AL, 38H        
    CALL INST_CTRL 
    MOV AL, 08H     
    CALL INST_CTRL     
    MOV AL, 01H      
    CALL INST_CTRL     
    MOV AL, 04H        
    CALL INST_CTRL    
    MOV AL, 0CH         
    CALL INST_CTRL  
    RET


CODE ENDS
END START