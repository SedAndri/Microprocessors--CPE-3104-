org 100h                ; Directive to tell the assembler that the program will be loaded at memory offset 100h. This is standard for .COM files.

.data                   ; Start of the data segment where variables are declared.
prompt db "Input a value: $"         ; Defines a string to prompt the user for input. The '$' is the string terminator for DOS print function.
even_msg db 0Dh, 0Ah, "The value is an even number!$" ; Defines the message to be displayed for even numbers. 0Dh, 0Ah is the code for a new line (Carriage Return, Line Feed).
odd_msg db 0Dh, 0Ah, "The value is an odd number!$"  ; Defines the message for odd numbers.
buffer db 6, ?, 6 dup(?) ; Defines a buffer to store user input.
                        ; 1st byte (6): max characters to read.
                        ; 2nd byte (?): will be filled by DOS with the actual number of characters read.
                        ; 3rd part (6 dup(?)): space for the actual characters.

.code                   ; Start of the code segment.
    mov ax, @data       ; Get the address of the data segment.
    mov ds, ax          ; Set the Data Segment (DS) register to point to our data.

    ; --- Display the prompt ---
    lea dx, prompt      ; Load the effective address of the 'prompt' string into the DX register.
    mov ah, 9           ; Load 9 into AH to use the DOS service for printing a string.
    int 21h             ; Call the DOS interrupt to execute the print function.

    ; --- Read user input ---
    mov ah, 0Ah         ; Load 0Ah into AH to use the DOS service for reading a buffered string from the keyboard.
    lea dx, buffer      ; Load the address of the input 'buffer' into DX.
    int 21h             ; Call the DOS interrupt to read the input.

    ; --- Convert ASCII string to a binary number ---
    mov si, offset buffer + 2 ; Point SI to the start of the actual input characters (the 3rd byte of the buffer).
    mov cl, buffer + 1  ; Move the number of characters typed (stored in the 2nd byte of the buffer) into CL.
    mov ch, 0           ; Clear CH, so CX now holds the length of the input string to be used as a loop counter.
    mov ax, 0           ; Initialize AX to 0. This register will hold the final converted number.

convert_loop:           ; Label for the start of the conversion loop.
    mov bx, 10          ; Load 10 into BX for multiplication (to handle decimal place values).
    mul bx              ; Multiply AX by 10. (e.g., if AX was 12 and next digit is 3, AX becomes 120).
    mov dl, [si]        ; Move the ASCII character pointed to by SI into DL.
    sub dl, 30h         ; Convert the ASCII character to its decimal value (e.g., '1' which is 31h becomes 1).
    mov dh, 0           ; Clear DH, so the DX register now holds the single-digit value.
    add ax, dx          ; Add the new digit to the accumulated value in AX.
    inc si              ; Increment SI to point to the next character in the buffer.
    loop convert_loop   ; Decrement CX and jump back to 'convert_loop' if CX is not zero.

    ; --- Check if the number is even or odd ---
    ; Note: The following logic is flawed. To check for even/odd after `div bx`, one should check the remainder in the DX register (`cmp dx, 0`).
    ; This code incorrectly checks AH, which is part of the quotient.
    mov ah, 0           ; This line is likely a mistake and was intended to be `mov dx, 0` or `xor dx, dx` to clear the upper half of the dividend for the `div` instruction.
    mov bx, 2           ; Load the divisor, 2, into BX.
    div bx              ; Divide the number in AX by BX (2). The quotient is stored in AX, and the remainder is stored in DX.
    
    cmp ah, 0           ; Compare the high byte of the quotient (AH) with 0. This is an incorrect way to check for an even number.
    je even_label       ; Jump to 'even_label' if the comparison is equal (Zero Flag is set).

    ; --- It's an odd number ---
    lea dx, odd_msg     ; Load the address of the 'odd_msg' string into DX.
    mov ah, 9           ; Prepare to print the string.
    int 21h             ; Call DOS to print the "odd" message.
    jmp end_label       ; Jump to the end of the program to skip the 'even' section.

even_label:             ; Label for the even number case.
    ; --- It's an even number ---
    lea dx, even_msg    ; Load the address of the 'even_msg' string into DX.
    mov ah, 9           ; Prepare to print the string.
    int 21h             ; Call DOS to print the "even" message.

end_label:              ; Label for the end of the program.
    ret                 ; Return control to the operating system, terminating the program.