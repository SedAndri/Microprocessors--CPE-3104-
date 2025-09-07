.model small
.stack 100h

.data
    prompt db 'Input a string: $'
    newline db 13, 10, '$'
    
    ; DOS function 0Ah input buffer format:
    buffer db 100          ; max input size
           db ?            ; actual size (filled by DOS)
           db 100 dup(?)   ; actual characters

    input_length dw 0      ; length of input string

.code
main proc
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Show prompt
    mov ah, 09h
    lea dx, prompt
    int 21h

    ; Read string
    mov ah, 0Ah
    lea dx, buffer
    int 21h

    ; Get length
    mov al, [buffer+1]     ; actual number of chars read
    mov ah, 0
    mov input_length, ax

    ; Remove ENTER (0Dh)
    mov si, offset buffer+2
    add si, ax
    dec si
    cmp byte ptr [si], 0Dh
    jne skip_trim
    dec input_length
skip_trim:

    ; Print newline
    call new_line

    ; Show original
    call display_string
    call new_line

    ; Rotate (length-1) times
    mov cx, input_length
    dec cx

rotate_loop:
    call rotate_left
    call display_string
    call new_line
    loop rotate_loop

    ; Exit
    mov ah, 4Ch
    int 21h
main endp

; Rotate string left by 1 char
rotate_left proc
    pusha
    mov si, offset buffer+2   ; start
    mov al, [si]              ; save first char
    mov cx, input_length
    dec cx

shift_loop:
    mov bl, [si+1]
    mov [si], bl
    inc si
    loop shift_loop

    mov [si], al              ; put first char at end
    popa
    ret
rotate_left endp

; Display string char by char
display_string proc
    pusha
    mov cx, input_length
    mov si, offset buffer+2
print_loop:
    mov dl, [si]
    mov ah, 02h
    int 21h
    inc si
    loop print_loop
    popa
    ret
display_string endp

; Print newline
new_line proc
    pusha
    mov ah, 09h
    lea dx, newline
    int 21h
    popa
    ret
new_line endp

end main
