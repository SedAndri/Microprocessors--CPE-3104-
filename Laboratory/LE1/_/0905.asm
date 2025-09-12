
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h



    MOV BX, 0B800h
    MOV DS, BX
    
    
    
    ; Initiate for CGA mem address
    MOV DH, 0011_0111d
    MOV DL, 'B'
    MOV BX, 0000h;
    
    ; FOR CONTROL PUSH POP
    MOV AX, 21 
    
    
    
    
    ; TEMP TO GET TO THE BOTTOM
    ADD BX, 0B86h
    ADD BX, 50h
    ADD BX, 50h
    ADD BX, 50h
    ADD BX, 56h
    ADD BX, 50h
    ADD BX, 50h
    
    


    
        ; LOOP
        
        DISPLAY_LETTER:
        
            

            MOV DH, 0011_0111d
            ; MOV DL,var1
            MOV DL, 'B'
            MOV [BX], DX
    

            ADD BX, 0A0h
    
            MOV DH, 0011_0111d
            ; MOV DL, var2
            MOV DL, 'B'
            MOV [BX], DX
               
            ADD BX, 0A0h           
               
            MOV DH, 0011_0111d
            ; MOV DL, var3
            MOV DL, 'N'
            MOV [BX], DX
            
            
            MOV DL, ' '
            SUB BX, 1E0h
            MOV [BX], DX
        
    
            DEC AX
            JZ SPLIT 
            
           
           
           
           
    
        LOOP DISPLAY_LETTER 
        
        
            SPLIT:
        
                MOV AX, 26h
        
                LOOP_SPLIT:    
        
                    MOV DH, 0011_0111d
            

             
                    MOV DL, 'N'
                    SUB BX, 002h
            
                    MOV [BX], DX
            

            
        
        
                    DEC AX
                    JZ SPLIT_OTHER_SIDE
        
        
                LOOP LOOP_SPLIT
                      
                      
                      
                      
                      
             SPLIT_OTHER_SIDE:
                
                ADD BX, 4Ch
             
                MOV AX, 29h
                
                    LOOP_SPLIT_OTHER_SIDE:    
        
                    MOV DH, 0011_0111d
            

             
                    MOV DL, 'N'
                    ADD BX, 002h
            
                    MOV [BX], DX
            
            
       
        
        
                    DEC AX
                    JZ RETURN_OS
        
        
                LOOP LOOP_SPLIT_OTHER_SIDE
             
             
             
             
                  
        RETURN_OS:
    
   

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