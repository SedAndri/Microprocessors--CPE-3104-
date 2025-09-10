.model small
.stack 100h
.data
    mystring db 'Hello World!', 0   ; Hard-coded string, 0-terminated
    msg_result db 'Vowels: ', 0     ; Message to display before count
    vowel_count db 0                ; Counter for vowels

.code
main proc
    mov ax, @data
    mov ds, ax

    ; Count vowels in mystring
    mov si, offset mystring
    mov vowel_count, 0

count_vowels:
    mov al, [si]
    cmp al, 0
    je show_result

    ; Convert to uppercase if lowercase
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
    ; Write msg_result to video buffer
    mov dx, 0B800h
    mov es, dx
    mov di, 0                  ; Top-left corner
    mov si, offset msg_result

write_msg:
    mov al, [si]
    cmp al, 0
    je write_count
    mov ah, 07h                ; Attribute: light gray on black
    mov es:[di], ax
    add di, 2
    inc si
    jmp write_msg

write_count:
    mov al, vowel_count
    add al, '0'
    mov ah, 07h
    mov es:[di], ax
    add di, 2

    ; Optionally halt (infinite loop)
    jmp $

main endp
end main