org 100h                  ; Set program start address for .COM file

.data
prompt db "Input a value: $"           ; Prompt message for user input
even_msg db 0Dh, 0Ah, "The value is an even number!$" ; Message for even number
odd_msg db 0Dh, 0Ah, "The value is an odd number!$"   ; Message for odd number

.code
    mov ax, @data         ; Load address of data segment into AX
    mov ds, ax            ; Set DS register to point to data segment
    
    lea dx, prompt        ; Load address of prompt message into DX
    mov ah, 9             ; DOS function: display string
    int 21h               ; Call DOS interrupt to display prompt
    
    mov ah, 1             ; DOS function: read character from keyboard
    int 21h               ; Call DOS interrupt to get input (result in AL)
    
    sub al, 30h           ; Convert ASCII digit to numeric value (subtract '0')
    
    mov ah, 0             ; Clear AH for division
    mov bl, 2             ; Set divisor to 2
    div bl                ; Divide AL by BL (AL/2), remainder in AH
    
    cmp ah, 0             ; Check if remainder is zero (even number)
    je even_label         ; If zero, jump to even_label
    
    lea dx, odd_msg       ; Load address of odd message into DX
    mov ah, 9             ; DOS function: display string
    int 21h               ; Call DOS interrupt to display odd message
    jmp end_label         ; Jump to end_label
    
even_label:
    lea dx, even_msg      ; Load address of even message into DX
    mov ah, 9             ; DOS function: display string
    int 21h               ; Call DOS interrupt to display even message
    


end_label:
    ret               ; Return to DOS