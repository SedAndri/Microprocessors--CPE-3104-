
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h



    MOV BX, 0B800h
    MOV DS, BX
    
    
    
    ; Initialize for CGA mem address
    MOV DH, 0011_0111d
    MOV DL, 'B'
    MOV BX, 0000h;
                     
                     
    ; To control thet loop [AX = 21]
    MOV AX, 21 
    
    
 
    ; [TEMP] To get to the bottom of the screen
    ADD BX, 0D6Ch
    
    

        ; LOOP to scroll up the letter to the top
        
        DISPLAY_LETTER:
        
            

            MOV DH, 0011_0111d
            ; MOV DL,var1
            MOV DL, 'B'
            MOV [BX], DX
            ; move to the top
            ADD BX, 0A0h
                 
                 
                 
            MOV DH, 0011_0111d
            ; MOV DL, var2
            MOV DL, 'B'
            MOV [BX], DX
            ; move to the top   
            ADD BX, 0A0h
            
                       
               
            MOV DH, 0011_0111d
            ; MOV DL, var3
            MOV DL, 'N'
            MOV [BX], DX
            ; move to the top
            
            
            MOV DL, ' '
            ; ADD SPACE CHARACTER
            SUB BX, 1E0h
            MOV [BX], DX
        
            
            
            
            
            DEC AX      ; DECREMENT control loop
            JZ SPLIT    ; IF AX = 0, PROCEED TO func SPLIT
            

        LOOP DISPLAY_LETTER 
            
            
            
            ; =============================
            ;       FUNCTION SPLIT
            ; =============================
        
            SPLIT:
        
                MOV AX, 26h             ; SET LOOP CONTROL, AX = 26h
        
                LOOP_SPLIT:    
        
                    MOV DH, 0011_0111d  ; SET COLOR
                    MOV DL, 'N'         ; SET VAR
                    SUB BX, 002h        ; DECREMENT to move to left
                    MOV [BX], DX        ; DISPLAY
            

        
                    DEC AX              ; DECREMENT LOOP CONTROL AX =- 1
                    JZ SPLIT_OTHER_SIDE ; IF LOOP CONTROL = 0, PROCEED OTHER SIDE
        
        
                LOOP LOOP_SPLIT         ; GO BACK TO PRINT LEFT SIDE
                      
             
                      
            ; =======================================
            ;       FUNCTION SPLIT (other side)
            ; =======================================         
                      
                      
             SPLIT_OTHER_SIDE:
                    
                    
                ADD BX, 4Ch     ; ADD TO BX to reach right side
                MOV AX, 29h     ; SET LOOP CONTROL, AX = 29h
                               
                               
                               
                    LOOP_SPLIT_OTHER_SIDE:    
        
                        MOV DH, 0011_0111d
            

             
                        MOV DL, 'N'
                        ADD BX, 002h
            
                        MOV [BX], DX

        
                        DEC AX
                        JZ RETURN_OS
        
        
                LOOP LOOP_SPLIT_OTHER_SIDE
             
             
             
             
                  
        RETURN_OS:
        
        
        SUB BX, 52h
        MOV DL, 'B'
        MOV [BX], DX
    
   

ret

 
 
 
var1 DB 'B', 0
var2 DB 'B', 0
var3 DB 'N', 0
 


       ;SPLIT:
        
       ;     MOV AX, 10
       ; 
       ;     MOV DH, 0011_0111d
       ;     ; MOV DL, var3
       ;     MOV DL, 'N'
       ;     ADD BX, 002h
       ;     
       ;     MOV [BX], DX
            
            
            
            
        
        
       ;     DEC AX
       ;     JZ RETURN_OS
        
        
       ; LOOP SPLIT