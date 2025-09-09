
; Set memory model to small (code and data in separate segments)
.model small
; Allocate 256 bytes for stack
.stack 100h


.data
    ; Hard-coded string to rotate
    buffer db 'HELLO$'      ; The string we want to rotate ($ is just marker, not part of string)
    
    input_length dw 5       ; Length of the hard-coded string "HELLO"
    current_row db 0        ; Current row position on screen
    current_col db 0        ; Current column position on screen


.code
main proc
    ; Set up data segment registers
    mov ax, @data          ; Load address of data segment
    mov ds, ax             ; Set DS to data segment
    
    ; Set up video segment (B800h for color text mode)
    mov ax, 0B800h         ; Video memory segment
    mov es, ax             ; ES points to video memory

    ; Clear screen first
    call clear_screen

    ; Show original string
    call display_string     ; Print input string
    call new_line           ; Print newline

    ; Rotate and display until back to original (length times)
    mov cx, input_length    ; CX = number of chars
    ; Note: We rotate exactly 'length' times to return to original

rotate_loop:
    call rotate_left        ; Rotate string left by 1
    call display_string     ; Show rotated string
    call new_line           ; Print newline
    loop rotate_loop        ; Repeat until CX = 0

    ; Exit program (still need DOS interrupt for program termination)
    mov ah, 4Ch             ; DOS terminate program
    int 21h
main endp


; Rotates the string left by 1 character
rotate_left proc
    pusha                     ; Save all registers
    mov si, offset buffer     ; SI points to first char of hard-coded string
    mov al, [si]              ; Save first char in AL
    mov cx, input_length      ; CX = length
    dec cx                    ; We need to shift (length-1) chars

shift_loop:
    mov bl, [si+1]            ; Get next char
    mov [si], bl              ; Move it left
    inc si                    ; Advance SI
    loop shift_loop           ; Repeat for all but last char

    mov [si], al              ; Put saved first char at end
    popa                      ; Restore registers
    ret
rotate_left endp


; Displays the string character by character using video buffer
display_string proc
    pusha                     ; Save all registers
    mov cx, input_length      ; CX = length
    mov si, offset buffer     ; SI points to first char of hard-coded string
    
    ; Calculate video memory position: (row * 80 + col) * 2
    mov al, current_row       ; AL = current row
    mov bl, 80                ; 80 characters per row
    mul bl                    ; AX = row * 80
    mov bl, current_col       ; BL = current column
    mov bh, 0                 ; Clear BH
    add ax, bx                ; AX = row * 80 + col
    shl ax, 1                 ; Multiply by 2 (each char takes 2 bytes: char + attribute)
    mov di, ax                ; DI = offset in video memory

print_loop:
    mov al, [si]              ; AL = current char
    mov ah, 07h               ; AH = attribute (white on black)
    mov es:[di], ax           ; Write char and attribute to video memory
    add di, 2                 ; Move to next character position (skip attribute byte)
    inc current_col           ; Increment column
    inc si                    ; Next char in string
    loop print_loop           ; Repeat for all chars
    
    popa                      ; Restore registers
    ret
display_string endp


; Moves to next line by updating current_row and resetting current_col
new_line proc
    pusha                     ; Save all registers
    inc current_row           ; Move to next row
    mov current_col, 0        ; Reset column to beginning
    popa                      ; Restore registers
    ret
new_line endp


; Clears the screen by filling video memory with spaces
clear_screen proc
    pusha                     ; Save all registers
    mov di, 0                 ; Start at beginning of video memory
    mov cx, 2000              ; 80 columns * 25 rows = 2000 characters
    mov ax, 0720h             ; Space character (20h) with white on black attribute (07h)
    
clear_loop:
    mov es:[di], ax           ; Write space and attribute
    add di, 2                 ; Move to next position
    loop clear_loop           ; Repeat for entire screen
    
    ; Reset cursor position
    mov current_row, 0
    mov current_col, 0
    
    popa                      ; Restore registers
    ret
clear_screen endp


; End of program
end main
