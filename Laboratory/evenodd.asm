org 100h                  ; Set program start address for .COM file

.data
value_msg db 0Dh, 0Ah, "The value is: $"
even_msg db 0Dh, 0Ah, "The value is an even number!$"
odd_msg db 0Dh, 0Ah, "The value is an odd number!$"

.code
    mov ax, @data         ; Load address of data segment into AX
    mov ds, ax            ; Set DS register to point to data segment

    mov al, 7             ; Hard-coded value (change this to any value you want)
    mov bl, al            ; Save value for display

    lea dx, value_msg     ; Display "The value is: "
    mov ah, 9
    int 21h

    mov ah, 0             ; Convert value to ASCII
    mov al, bl            ; Restore value
    add al, 30h           ; Convert to ASCII
    mov dl, al
    mov ah, 2             ; DOS function: display character
    int 21h

    mov al, bl            ; Restore value for even/odd check
    mov ah, 0
    mov bl, 2
    div bl

    cmp ah, 0
    je even_label

    lea dx, odd_msg
    mov ah, 9
    int 21h
    jmp end_label

even_label:
    lea dx, even_msg
    mov ah, 9
    int 21h

end_label:
    ret