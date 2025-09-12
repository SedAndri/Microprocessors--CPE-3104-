org 100h

mov ax, 0B800h          ;default when using video buffer for text mode  
mov es, ax              ;es is made to point directly into video memory so we can write to it

mov si, offset msg      ;offset takes the memory address of a variable or label
                        ;offset takes msg memory and puts it into si register 
                        ;si register is usually used to contain offset memory addresses
                        
mov cx, 0
calc_len:
    mov bx, si          ;loads starting address of msg into bx
    add bx, cx          ;moves bx to next character in msg (cx controlled)
    mov al, [bx]        ; loads contents of bx into al
    cmp al, 0           ;checks if al is null terminator
                        ;null = empty/no character
    je len_done         ;if null, jump to len_done
    inc cx              ;if not null, increment cx to check next character
    jmp calc_len        ;jump back to calc_len
                        ;je = jump if equal (zero flag set) || jmp = unconditional jump 
len_done:

                        ;bx cx no longer needed so reused
mov bx, 80              ;loads 80 into bx (80 is the width of the screen in text mode)
sub bx, cx              ;bx = 80 - length of msg (cx)
shr bx, 1               ;shift right = divide by 2
                        ;bx now contains the number of spaces to the left of the message to center it

                        ;total vertical lines = 25
mov dx, 12              ; middle row/line = 12 (0-24)    
mov ax, dx              ;copies dx into ax
mov dx, 80              ;dx = 80 (width of screen)  
mul dx                  ;ax = ax * dx (row * width of screen)
add ax, bx              ;for adding spaces to the left of message (for centering) 
shl ax, 1               ;shift left = multiply by 2 (because each character cell is 2 bytes)
mov di, ax              ;di now contains the offset in video memory where the message will start

mov si, offset msg      ;reload the starting address of msg into si (para sure)

;=====PRINTING THE STRING=====
                        ;printing the string
next_char:
    mov al, [si]        ; loads a character from msg into al
    cmp al, 0           ; checks if the character is a null terminator = no character/empty
    je done             ; if null, jump to done
                        ; remember es points to video memory
    mov es:[di], al     ; writes the character in al to video memory at offset di
    mov es:[di+1], 1Eh  ; writes the attribute byte (color) to video memory at offset di+1
                        ; 1Eh = yellow on blue background
    add di, 2           ; move to the next character cell in video memory (2 bytes per cell)
    inc si              ; move to the next character in msg
    jmp next_char       ; repeat for next character

done:
    ret              

msg db 'Sid Bordario', 0