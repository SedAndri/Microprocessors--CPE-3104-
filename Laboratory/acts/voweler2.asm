;Bordario, Sid Andre p.

org 100h  

.code
main proc
    mov ax, @data
    mov ds, ax

    
    mov si, offset string
    mov vowel_count, 0

count_vowels:
    mov al, [si]
    cmp al, 0
    je show_result

    
    cmp al, 'a'
    jb check_upper
    cmp al, 'z'
    ja check_upper
    sub al, 32

check_upper:
    cmp al, 'A'
    je found_vowel
    cmp al, 'E'
    je found_vowel
    cmp al, 'I'
    je found_vowel
    cmp al, 'O'
    je found_vowel
    cmp al, 'U'
    je found_vowel
    jmp next_char

found_vowel:
    inc vowel_count

next_char:
    inc si
    jmp count_vowels

show_result:
    
    mov dx, 0B800h
    mov es, dx
    mov di, 0                  
    mov si, offset string

write_string:
    mov al, [si]
    cmp al, 0
    je write_msg
    mov ah, 07h                
    mov es:[di], ax
    add di, 2         
    inc si
    jmp write_string

write_msg:
    mov si, offset msg_result
    add di, 290               ;hardcoded spacing

write_msg_loop:
    mov al, [si]
    cmp al, 0
    je write_count
    mov ah, 07h
    mov es:[di], ax
    add di, 2
    inc si
    jmp write_msg_loop

write_count:
    mov al, vowel_count
    add al, '0'
    mov ah, 07h
    mov es:[di], ax
    add di, 2

    
    jmp $
            
            
.data 
;==========================================
    string db 'power of the people', 0 
;==========================================
    msg_result db 'vowels: ', 0     
    vowel_count db 0


main endp
end main
