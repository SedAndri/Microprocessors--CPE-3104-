
; Set memory model to small (code and data in separate segments)
.model small
; Allocate 256 bytes for stack
.stack 100h


.data
    ; Prompt to display to user
    prompt db 'Input a string: $'
    ; Newline characters for output
    newline db 13, 10, '$'
    
    ; Buffer for DOS function 0Ah input:
    buffer db 100          ; Max input size (user can type up to 100 chars)
        db ?            ; Actual size entered (filled by DOS after input)
        db 100 dup(?)   ; Actual characters entered

    input_length dw 0      ; Stores length of input string (used for rotation/display)


.code
main proc
    ; Set up data segment registers
    mov ax, @data          ; Load address of data segment
    mov ds, ax             ; Set DS to data segment
    mov es, ax             ; Set ES to data segment (not strictly needed here)

    ; Show prompt to user
    mov ah, 09h            ; DOS print string function
    lea dx, prompt         ; DX points to prompt string
    int 21h                ; Call DOS interrupt

    ; Read string from user
    mov ah, 0Ah            ; DOS buffered input function
    lea dx, buffer         ; DX points to buffer
    int 21h                ; Call DOS interrupt

    ; Get length of input
    mov al, [buffer+1]     ; AL = actual number of chars read
    mov ah, 0              ; Clear AH for 16-bit value
    mov input_length, ax   ; Store length in input_length

    ; Remove ENTER (0Dh) if present at end
    mov si, offset buffer+2 ; SI points to first char of input
    add si, ax              ; Move SI to last char entered
    dec si                  ; Adjust SI to last char
    cmp byte ptr [si], 0Dh  ; Is last char ENTER?

    jne skip_trim           ; If not ENTER, skip trimming
    dec input_length        ; If ENTER, reduce length by 1
skip_trim:


    ; Print newline after input
    call new_line

    ; Show original string
    call display_string     ; Print input string
    call new_line           ; Print newline

    ; Rotate and display (length-1) times
    mov cx, input_length    ; CX = number of chars
    dec cx                  ; We rotate (length-1) times

rotate_loop:
    call rotate_left        ; Rotate string left by 1
    call display_string     ; Show rotated string
    call new_line           ; Print newline
    loop rotate_loop        ; Repeat until CX = 0

    ; Exit program
    mov ah, 4Ch             ; DOS terminate program
    int 21h
main endp


; Rotates the string left by 1 character
rotate_left proc
    pusha                     ; Save all registers
    mov si, offset buffer+2   ; SI points to first char
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


; Displays the string character by character
display_string proc
    pusha                     ; Save all registers
    mov cx, input_length      ; CX = length
    mov si, offset buffer+2   ; SI points to first char
print_loop:
    mov dl, [si]              ; DL = current char
    mov ah, 02h               ; DOS print char function
    int 21h                   ; Print char
    inc si                    ; Next char
    loop print_loop           ; Repeat for all chars
    popa                      ; Restore registers
    ret
display_string endp


; Prints a newline using DOS function
new_line proc
    pusha                     ; Save all registers
    mov ah, 09h               ; DOS print string function
    lea dx, newline           ; DX points to newline string
    int 21h                   ; Print newline
    popa                      ; Restore registers
    ret
new_line endp


; End of program
end main
