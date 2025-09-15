; EMU8086 / DOS .COM style program
; EQUATION: X = A - B x C / D
; - Inputs: A, B, C, D as two decimal digits (00-99)
; - Displays inputted values
; - Shows equation with values
; - Evaluates X
; - Shows X in base 10 and base 5

org 100h

; ----------------------
; Data
; ----------------------

promptA     db 'Input A: $'
promptB     db 'Input B: $'
promptC     db 'Input C: $'
promptD     db 'Input D: $'
msgBad2Dig  db 13,10,'Please enter exactly 2 digits (00-99).',13,10,'$'
msgDZero    db 13,10,'D cannot be 00 (division by zero). Try again.',13,10,'$'
sepLine     db '==========$'
lblA        db 'A = $'
lblB        db 'B = $'
lblC        db 'C = $'
lblD        db 'D = $'
lblXeq      db 'X = $'
sp_minus    db ' - $'
sp_mul      db ' x $'
sp_div      db ' / $'
base10suf   db '10$'
base5suf    db '5$'

; input buffer for DOS function 0Ah (line input)
; structure: [max][len][data...]
inbuf       db 2      ; maximum 2 chars
			db 0      ; actual length (filled by DOS)
			db 2 dup(?)

A_val       dw 0
B_val       dw 0
C_val       dw 0
D_val       dw 0
TEMP_val    dw 0
X_val       dw 0

digitsBuf   db 6 dup(?)  ; for printing up to 5 digits plus safety

; ----------------------
; Code
; ----------------------

start:
	; DS = CS for COM program by default; safe to proceed

	; Read inputs A, B, C, D (2 digits each)
	lea dx, promptA
	mov ah, 09h
	int 21h
	call ReadTwoDigits      ; AX = value 0..99
	mov [A_val], ax
	call PrintCRLF

	lea dx, promptB
	mov ah, 09h
	int 21h
	call ReadTwoDigits
	mov [B_val], ax
	call PrintCRLF

	lea dx, promptC
	mov ah, 09h
	int 21h
	call ReadTwoDigits
	mov [C_val], ax
	call PrintCRLF

ReadD:
	lea dx, promptD
	mov ah, 09h
	int 21h
	call ReadTwoDigits
	mov [D_val], ax
	call PrintCRLF
	cmp ax, 0
	jne ShowInputs
	lea dx, msgDZero
	mov ah, 09h
	int 21h
	jmp ReadD

ShowInputs:
	; Print separator
	lea dx, sepLine
	mov ah, 09h
	int 21h
	call PrintCRLF

	; A = xx
	lea dx, lblA
	mov ah, 09h
	int 21h
	mov ax, [A_val]
	call PrintTwoDigits
	call PrintCRLF

	; B = xx
	lea dx, lblB
	mov ah, 09h
	int 21h
	mov ax, [B_val]
	call PrintTwoDigits
	call PrintCRLF

	; C = xx
	lea dx, lblC
	mov ah, 09h
	int 21h
	mov ax, [C_val]
	call PrintTwoDigits
	call PrintCRLF

	; D = xx
	lea dx, lblD
	mov ah, 09h
	int 21h
	mov ax, [D_val]
	call PrintTwoDigits
	call PrintCRLF

	; Print separator
	lea dx, sepLine
	mov ah, 09h
	int 21h
	call PrintCRLF

	; Show equation: X = A - B x C / D
	lea dx, lblXeq
	mov ah, 09h
	int 21h
	mov ax, [A_val]
	call PrintTwoDigits

	lea dx, sp_minus
	mov ah, 09h
	int 21h
	mov ax, [B_val]
	call PrintTwoDigits

	lea dx, sp_mul
	mov ah, 09h
	int 21h
	mov ax, [C_val]
	call PrintTwoDigits

	lea dx, sp_div
	mov ah, 09h
	int 21h
	mov ax, [D_val]
	call PrintTwoDigits
	call PrintCRLF

	; Print separator
	lea dx, sepLine
	mov ah, 09h
	int 21h
	call PrintCRLF

	; Compute X = A - (B*C)/D
	mov ax, [B_val]
	mov bx, [C_val]
	mul bx               ; DX:AX = AX * BX (unsigned)
	xor dx, dx           ; ensure DX:AX is 16-bit value for divide
	mov bx, [D_val]
	div bx               ; AX = (B*C)/D, DX = remainder
	mov [TEMP_val], ax

	mov ax, [A_val]
	cwd                  ; extend AX into DX for signed subtract safety (not strictly needed)
	sub ax, [TEMP_val]   ; AX = A - temp
	mov [X_val], ax

	; X in base 10
	lea dx, lblXeq
	mov ah, 09h
	int 21h
	mov ax, [X_val]
	call PrintSignedDec
	mov dl, '1'
	mov ah, 02h
	int 21h
	mov dl, '0'
	mov ah, 02h
	int 21h
	call PrintCRLF

	; X in base 5
	lea dx, lblXeq
	mov ah, 09h
	int 21h
	mov ax, [X_val]
	call PrintSignedBase5
	mov dl, '5'
	mov ah, 02h
	int 21h
	call PrintCRLF

	; Exit
	mov ah, 4Ch
	xor al, al
	int 21h

; ----------------------
; Procedures
; ----------------------

; ReadTwoDigits
; Uses DOS buffered input (AH=0Ah) to read exactly two decimal digits.
; Returns AX = value (0..99). Re-prompts on invalid input.
ReadTwoDigits proc near
Read2_retry:
	mov byte ptr [inbuf], 2  ; set max length
	lea dx, inbuf
	mov ah, 0Ah
	int 21h
	; check length
	mov al, [inbuf+1]
	cmp al, 2
	je Read2_checkdigits
	lea dx, msgBad2Dig
	mov ah, 09h
	int 21h
	jmp Read2_retry

Read2_checkdigits:
	mov si, offset inbuf+2
	mov al, [si]
	cmp al, '0'
	jb Read2_bad
	cmp al, '9'
	ja Read2_bad
	mov bl, al               ; tens ASCII
	inc si
	mov al, [si]
	cmp al, '0'
	jb Read2_bad
	cmp al, '9'
	ja Read2_bad
	mov bh, al               ; ones ASCII
	; convert to value: (tens-'0')*10 + (ones-'0')
	mov ax, 0
	mov al, bl
	sub al, '0'
	xor ah, ah               ; AX = tens
	mov bx, 10
	mul bx                   ; AX = tens*10
	mov dl, bh
	sub dl, '0'
	xor dh, dh               ; DX = ones
	add ax, dx               ; AX = tens*10 + ones
	ret

Read2_bad:
	lea dx, msgBad2Dig
	mov ah, 09h
	int 21h
	jmp Read2_retry
ReadTwoDigits endp

; PrintTwoDigits
; Input: AX = 0..99
PrintTwoDigits proc near
	push ax
	push bx
	push dx
	xor dx, dx
	mov bx, 10
	div bx            ; AX / 10 -> AX=quot, DX=rem
	; print tens
	add al, '0'
	mov dl, al
	mov ah, 02h
	int 21h
	; print ones
	mov ax, dx
	add al, '0'
	mov dl, al
	mov ah, 02h
	int 21h
	pop dx
	pop bx
	pop ax
	ret
PrintTwoDigits endp

; PrintCRLF: prints CR LF
PrintCRLF proc near
	mov dl, 13
	mov ah, 02h
	int 21h
	mov dl, 10
	mov ah, 02h
	int 21h
	ret
PrintCRLF endp

; PrintUnsignedDec: prints AX (unsigned) in decimal (no leading zeros)
PrintUnsignedDec proc near
	push ax
	push bx
	push cx
	push dx
	push si
	mov si, offset digitsBuf
	mov cx, 0
	mov bx, 10
	cmp ax, 0
	jne Pud_loop
	; print single zero
	mov dl, '0'
	mov ah, 02h
	int 21h
	jmp Pud_done_pop
Pud_loop:
	xor dx, dx
	div bx              ; DX:AX / BX -> AX=quot, DX=rem
	add dl, '0'
	mov [si], dl
	inc si
	inc cx
	cmp ax, 0
	jne Pud_loop
	; print in reverse
Pud_print:
	dec si
	mov dl, [si]
	mov ah, 02h
	int 21h
	loop Pud_print
Pud_done_pop:
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PrintUnsignedDec endp

; PrintSignedDec: prints AX as signed decimal
PrintSignedDec proc near
	push ax
	cmp ax, 0
	jge Psd_pos
	; negative
	mov dl, '-'
	mov ah, 02h
	int 21h
	neg ax
Psd_pos:
	call PrintUnsignedDec
	pop ax
	ret
PrintSignedDec endp

; PrintUnsignedBase5: prints AX (unsigned) in base 5
PrintUnsignedBase5 proc near
	push ax
	push bx
	push cx
	push dx
	push si
	mov si, offset digitsBuf
	mov cx, 0
	mov bx, 5
	cmp ax, 0
	jne Pub5_loop
	; print single zero
	mov dl, '0'
	mov ah, 02h
	int 21h
	jmp Pub5_done
Pub5_loop:
	xor dx, dx
	div bx              ; DX:AX / 5 -> AX=quot, DX=rem (0..4)
	add dl, '0'
	mov [si], dl
	inc si
	inc cx
	cmp ax, 0
	jne Pub5_loop
	; print in reverse
Pub5_print:
	dec si
	mov dl, [si]
	mov ah, 02h
	int 21h
	loop Pub5_print
Pub5_done:
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PrintUnsignedBase5 endp

; PrintSignedBase5: prints AX as signed base-5 number (prefix '-' if negative)
PrintSignedBase5 proc near
	push ax
	cmp ax, 0
	jge Psb5_pos
	mov dl, '-'
	mov ah, 02h
	int 21h
	neg ax
Psb5_pos:
	call PrintUnsignedBase5
	pop ax
	ret
PrintSignedBase5 endp

; End of file