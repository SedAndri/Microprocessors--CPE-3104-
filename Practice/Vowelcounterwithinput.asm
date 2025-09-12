 .model small
.stack 100h
.data
    msg_input db 'Input a string: $'
    msg_result db 0Dh, 0Ah, 'The string contains $'
    msg_vowels db ' vowels!$'
    buffer db 100 dup('$')  ; Buffer to store input string
    vowel_count db 0        ; Counter for vowels

.code
main proc
    mov ax, @data
    mov ds, ax
    
    ; Display input prompt
    mov ah, 09h
    lea dx, msg_input
    int 21h
    
    ; Read string from user
    mov ah, 0Ah
    lea dx, buffer
    mov buffer, 99         ; Maximum characters to read
    int 21h
    
    ; Initialize counter and pointer
    mov vowel_count, 0
    lea si, buffer + 2     ; Skip first two bytes (length info)
    
count_vowels:
    mov al, [si]           ; Get current character
    cmp al, 0Dh            ; Check for carriage return (end of string)
    je display_result
    
    ; Convert to uppercase for easier comparison
    cmp al, 'a'
    jb check_upper
    cmp al, 'z'
    ja check_upper
    sub al, 32             ; Convert lowercase to uppercase
    
check_upper:
    ; Check if character is a vowel (A, E, I, O, U)
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
    
    ; Not a vowel, move to next character
    inc si
    jmp count_vowels
    
found_vowel:
    inc vowel_count        ; Increment vowel counter
    inc si                 ; Move to next character
    jmp count_vowels
    
display_result:
    ; Display result message
    mov ah, 09h
    lea dx, msg_result
    int 21h
    
    ; Display vowel count
    mov dl, vowel_count
    add dl, '0'            ; Convert number to ASCII
    mov ah, 02h
    int 21h
    
    ; Display "vowels!" message
    mov ah, 09h
    lea dx, msg_vowels
    int 21h
    
    ; Exit program
    mov ah, 4Ch
    int 21h
    
main endp
end main