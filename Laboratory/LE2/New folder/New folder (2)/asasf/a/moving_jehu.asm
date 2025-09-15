org 100h

    MOV AX, 0B800H
    MOV DS, AX
    
    MOV DI, (0*160)+(38*2)
    
    CALL DISPLAY_HE
    CALL DISPLAY_L
    CALL DISPLAY_LO 
    MOV SI, (0*160)+(38*2)
    CALL CLEAR
    
    MOV DI, (1*160)+(36*2) 
    CALL DISPLAY_HE           
    ADD DI, 4    
    CALL DISPLAY_L  
    ADD DI, 4   
    CALL DISPLAY_LO 
    
    MOV DI, (2*160)+(34*2) 
    MOV SI, (1*160)+(34*2) 
    CALL DISPLAY_HE       
    ADD DI, 8             
    ADD SI, 4     
    CALL CLEAR 
    CALL DISPLAY_L
    ADD DI, 8                    
    ADD SI, 2
    CALL DISPLAY_LO
    CALL CLEAR  
    
    MOV DI, (3*160)+(32*2) 
    MOV SI, (2*160)+(32*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 12            
    ADD SI, 4
    CALL DISPLAY_L    
    CALL CLEAR 
    ADD DI, 12            
    ADD SI, 2
    CALL DISPLAY_LO     
    CALL CLEAR 
    
    MOV DI, (4*160)+(30*2)
    MOV SI, (3*160)+(30*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 16            
    ADD SI, 4
    CALL DISPLAY_L   
    CALL CLEAR 
    ADD DI, 16           
    ADD SI, 4
    CALL DISPLAY_LO   
    CALL CLEAR 
    
    MOV DI, (5*160)+(28*2)  
    MOV SI, (4*160)+(28*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 20              
    ADD SI, 6
    CALL DISPLAY_L  
    CALL CLEAR 
    ADD DI, 20              
    ADD SI, 10
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (6*160)+(26*2) 
    MOV SI, (5*160)+(26*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 24                 
    ADD SI, 10
    CALL DISPLAY_L  
    CALL CLEAR 
    ADD DI, 24                
    ADD SI, 16
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (7*160)+(24*2)
    MOV SI, (6*160)+(24*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 28                    
    ADD SI, 14
    CALL DISPLAY_L  
    CALL CLEAR 
    ADD DI, 28                   
    ADD SI, 22
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (8*160)+(22*2)
    MOV SI, (7*160)+(22*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 32                        
    ADD SI, 18
    CALL DISPLAY_L  
    CALL CLEAR 
    ADD DI, 32                      
    ADD SI, 26
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (9*160)+(20*2)
    MOV SI, (8*160)+(20*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 36                            
    ADD SI, 22
    CALL DISPLAY_L  
    CALL CLEAR 
    ADD DI, 36                        
    ADD SI, 30
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (10*160)+(18*2) 
    MOV SI, (9*160)+(18*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 40                               
    ADD SI, 26
    CALL DISPLAY_L  
    CALL CLEAR 
    ADD DI, 40                             
    ADD SI, 34
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (11*160)+(16*2)
    MOV SI, (10*160)+(16*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 44                                 
    ADD SI, 30
    CALL DISPLAY_L  
    CALL CLEAR 
    ADD DI, 44                               
    ADD SI, 38
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (12*160)+(14*2) 
    MOV SI, (11*160)+(14*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 48                                    
    ADD SI, 34
    CALL DISPLAY_L  
    CALL CLEAR 
    ADD DI, 48                                   
    ADD SI, 42
    CALL DISPLAY_LO 
    CALL CLEAR    
    
    MOV DI, (13*160)+(12*2) 
    MOV SI, (12*160)+(12*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 52                                        
    ADD SI, 38
    CALL DISPLAY_L  
    CALL CLEAR 
    ADD DI, 52                                        
    ADD SI, 46
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (14*160)+(10*2)
    MOV SI, (13*160)+(10*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 56                                            
    ADD SI, 42
    CALL DISPLAY_L  
    CALL CLEAR 
    ADD DI, 56                                           
    ADD SI, 50
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (15*160)+(8*2)
    MOV SI, (14*160)+(8*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 60                                                 
    ADD SI, 46
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 60                                               
    ADD SI, 54
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (16*160)+(6*2) 
    MOV SI, (15*160)+(6*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 64                                                    
    ADD SI, 50
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 64                                                  
    ADD SI, 58
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (17*160)+(4*2)  
    MOV SI, (16*160)+(4*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 68                                                       
    ADD SI, 54
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 68                                                      
    ADD SI, 62
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (18*160)+(2*2)   
    MOV SI, (17*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (17*160)+(2*2)   
    MOV SI, (18*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (16*160)+(2*2)   
    MOV SI, (17*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR   
    
    MOV DI, (15*160)+(2*2)   
    MOV SI, (16*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (14*160)+(2*2)   
    MOV SI, (15*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (13*160)+(2*2)   
    MOV SI, (14*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (12*160)+(2*2)   
    MOV SI, (13*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (11*160)+(2*2)   
    MOV SI, (12*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (10*160)+(2*2)   
    MOV SI, (11*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (9*160)+(2*2)   
    MOV SI, (10*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (8*160)+(2*2)   
    MOV SI, (9*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (7*160)+(2*2)   
    MOV SI, (8*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (6*160)+(2*2)   
    MOV SI, (7*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (5*160)+(2*2)   
    MOV SI, (6*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR  
    
    MOV DI, (4*160)+(2*2)   
    MOV SI, (5*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (3*160)+(2*2)   
    MOV SI, (4*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (2*160)+(2*2)   
    MOV SI, (3*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    MOV DI, (1*160)+(2*2)   
    MOV SI, (2*160)+(2*2)   
    CALL CLEAR 
    CALL DISPLAY_HE       
    ADD DI, 72                                                          
    ADD SI, 58
    CALL DISPLAY_L  
    CALL CLEAR
    ADD DI, 72                                                         
    ADD SI, 66
    CALL DISPLAY_LO 
    CALL CLEAR 
    
    
    
    RET
    
    DISPLAY_HE:
        MOV AH, 0CEH
        MOV AL, 48H
        MOV DS:[DI], AX
        ADD DI, 2
        MOV AL, 45H      
        MOV DS:[DI], AX
        ADD DI, 2
    RET
    
    DISPLAY_L:
        MOV AH, 0CEH
        MOV AL, 4CH     
        MOV DS:[DI], AX
        ADD DI, 2   
    RET
    
    DISPLAY_LO:
        MOV AH, 0CEH 
        MOV AL, 4CH     
        MOV DS:[DI], AX
        ADD DI, 2
        MOV AL, 4FH      
        MOV DS:[DI], AX
        ADD DI, 2 
    RET
    
    DELAY:
        MOV CX, 3FH
        HERE:
            LOOP HERE
    RET  
    
    CLEAR:
        MOV CX, 5     
        DEL_CHAR:
        XOR AX, AX
        MOV [SI], AX
        ADD SI, 2
        LOOP DEL_CHAR
    RET
    
    CLEAR_ALL:
        MOV CX, 160
        LOOP DEL_CHAR
    RET
        
    
ret