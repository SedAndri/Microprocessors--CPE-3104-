;.model small
;.stack 100h 

.data
prompt db "Input a value: $"
odd_msg db "The value is an odd number!$"
even_msg db "The value is an even number!$"
;buffer db 6, ?, 6 dup(?)

.code
main proc
    mov ax, @data
    mov ds, ax
    
    ; Print prompt
    mov ah, 9
    mov dx, offset prompt
    int 21h
    
    ; Read input
    mov ah, 0Ah
    mov dx, offset buffer
    int 21h
    
    ; Convert string to number
    mov si, offset buffer + 2
    mov cl, buffer + 1
    mov ch, 0
    mov ax, 0
convert_loop:
    mov bx, 10
    mul bx          ; ax = ax * 10
    mov dl, [si]
    sub dl, '0'
    mov dh, 0
    add ax, dx
    inc si
    loop convert_loop
    
    ; Check if odd or even
    test ax, 1
    jz is_even
    
    ; Odd
    mov dx, offset odd_msg
    jmp print_msg
    
is_even:
    mov dx, offset even_msg
    
print_msg:
    mov ah, 9
    int 21h
    
    ; Exit
    mov ah, 4Ch
    int 21h
main endp
end main