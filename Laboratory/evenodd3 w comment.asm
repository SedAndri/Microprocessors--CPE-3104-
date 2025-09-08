org 100h                  ; Set code origin for .COM program

.code
    mov ax, 0B800h        ; Set AX to video memory segment (text mode)
    mov es, ax            ; ES = video segment for direct screen writes

    mov di, 0             ; DI = offset in video memory (top-left corner)

    mov al, 7             ; AL = number to check (hard-coded as 7)
    mov ah, 0             ; Clear AH for division
    mov bl, 2             ; BL = divisor (2 for even/odd check)
    div bl                ; Divide AL by BL; result in AL, remainder in AH

    ; Prepare message: "The number is X$"
    mov si, offset num_msg ; SI = address of message template
    mov al, 6             ; AL = number to display (should be 7 for accuracy)
    add al, 30h           ; Convert number to ASCII ('0' = 30h)
    mov [si+14], al       ; Place ASCII digit at correct spot in message

    call print_msg        ; Print "The number is X" at current screen position

    add di, 160           ; Move DI to next line (80 columns * 2 bytes per char)

    cmp ah, 0             ; Check remainder from division (even/odd)
    je show_even          ; If remainder is zero, number is even

    ; If not even, show "Odd" message
    mov si, offset odd_msg ; SI = address of odd message
    call print_msg         ; Print odd message
    jmp end_label          ; Jump to end

show_even:
    mov si, offset even_msg ; SI = address of even message
    call print_msg          ; Print even message

end_label:
    ret                    ; Return (end program)

;------------------------------------------
; Subroutine: print_msg
; Prints string at ES:DI until '$' is found
print_msg:
    mov cx, 0              ; Clear CX (not used here)
.next_char:
    mov al, [si]           ; Load next character from string
    cmp al, '$'            ; Check for end of string
    je .done               ; If '$', finish printing
    mov es:[di], al        ; Write character to video memory
    mov al, 0x07           ; Attribute: light gray on black
    mov es:[di+1], al      ; Write attribute byte
    add di, 2              ; Move to next character cell
    inc si                 ; Advance to next char in string
    jmp .next_char         ; Repeat
.done:
    ret                    ; Return from subroutine

;------------------------------------------
; Data section: messages
num_msg db "The number is X$"                ; Message template
even_msg db "The value is an even number!$"  ; Even message
odd_msg  db "The value is an odd number!$"   ; Odd message