
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

MSG DB 0DH,0AH,"Enter a string: $"
BUFFER DB 5,?,5 DUP (' ')

        


ret




