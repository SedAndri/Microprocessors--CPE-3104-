.model small
.stack 100h

.data
    ; Hardcoded string instead of user input
    hardcoded_string db 'Hello$'      ; String to process (note: $ is terminator, not part of string)
    input_length dw 5                 ; Length of hardcoded string (5 for "Hello")
    
    ; Video buffer constants
    video_segment equ 0B800h          ; Color text mode video segment
    row db 0                          ; Current row position
    col db 0                          ; Current column position
    
.code
main proc
    ; Set up data segment registers
    mov ax, @data
    mov ds, ax
    mov es, ax
    
    ; Set up video segment
    mov ax, video_segment
    mov es, ax
    
    ; Clear screen
    call clear_screen
    
    ; Show original string in video buffer
    mov row, 0
    mov col, 0
    call display_string_video
    
    ; Rotate and display (length-1) times
    mov cx, input_length
    dec cx
    mov row, 1
    
rotate_loop:
    call rotate_left
    call display_string_video
    inc row
    loop rotate_loop
    
    ; Wait for key press before exiting
    mov ah, 0
    int 16h
    
    ; Exit program
    mov ax, 4C00h
    int 21h
main endp

; Rotates the string left by 1 character
rotate_left proc
    pusha
    mov si, offset hardcoded_string
    mov al, [si]              ; Save first char in AL
    mov cx, input_length
    dec cx
    
shift_loop:
    mov bl, [si+1]            ; Get next char
    mov [si], bl              ; Move it left
    inc si
    loop shift_loop
    mov [si], al              ; Put saved first char at end
    popa
    ret
rotate_left endp

; Displays the string in video buffer
display_string_video proc
    pusha
    mov cx, input_length
    mov si, offset hardcoded_string
    
    ; Calculate video memory position: (row * 80 + col) * 2
    mov al, row
    mov bl, 80
    mul bl
    add al, col
    adc ah, 0
    shl ax, 1                 ; Multiply by 2 (each char has attribute byte)
    mov di, ax                ; ES:DI points to video memory location
    
print_loop:
    mov al, [si]              ; Get character
    mov ah, 07h               ; Gray text on black background
    mov es:[di], ax           ; Write character and attribute to video memory
    add di, 2                 ; Move to next character position
    inc si
    loop print_loop
    popa
    ret
display_string_video endp

; Clears the screen by writing spaces to video memory
clear_screen proc
    pusha
    mov ax, video_segment
    mov es, ax
    mov di, 0
    mov cx, 2000              ; 80x25 = 2000 characters
    mov ax, 0720h             ; Space character (20h) with gray on black (07h)
    
clear_loop:
    mov es:[di], ax
    add di, 2
    loop clear_loop
    popa
    ret
clear_screen endp

end main