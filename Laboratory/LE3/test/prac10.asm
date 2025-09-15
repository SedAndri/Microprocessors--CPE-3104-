; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h


start:
	; Prompt for input
	mov     dx, OFFSET MSG
	mov     ah, 9
	int     21h

	; Read up to 4 characters, we will use the first 3 digits
	mov     dx, OFFSET DIGIT
	mov     ah, 0Ah
	int     21h

	; Convert first three ASCII digits at DIGIT+2 into numeric value in DX
	xor     dx, dx
	mov     si, OFFSET DIGIT+2

	; hundreds place: (ch0 - '0') * 100
	mov     al, [si]
	sub     al, 30h              ; '0'
	mov     bl, 64h              ; 100
	mul     bl                   ; AX = AL * 100
	mov     dx, ax
	inc     si

	; tens place: (ch1 - '0') * 10
	mov     al, [si]
	sub     al, 30h
	mov     bl, 0Ah              ; 10
	mul     bl
	add     dx, ax
	inc     si

	; ones place: (ch2 - '0')
	mov     al, [si]
	sub     al, 30h
	add     dx, ax

	; ---------------------------------------------------------
	; Compute denomination counts into DENO+2 as ASCII digits
	; Order: 100, 50, 20, 10, 5, 1
	; Remainder is carried in AL (AH zeroed before DIV)
	; ---------------------------------------------------------
	mov     si, OFFSET DENO+2

	; 100s
	mov     ax, dx
	mov     cl, 64h
	div     cl                   ; AL=quot, AH=rem
	add     al, 30h
	mov     [si], al
	inc     si
	mov     al, ah               ; move remainder for next step
	xor     ah, ah

	; 50s
	mov     cl, 32h
	div     cl
	add     al, 30h
	mov     [si], al
	inc     si
	mov     al, ah
	xor     ah, ah

	; 20s
	mov     cl, 14h
	div     cl
	add     al, 30h
	mov     [si], al
	inc     si
	mov     al, ah
	xor     ah, ah

	; 10s
	mov     cl, 0Ah
	div     cl
	add     al, 30h
	mov     [si], al
	inc     si
	mov     al, ah
	xor     ah, ah

	; 5s
	mov     cl, 5
	div     cl
	add     al, 30h
	mov     [si], al
	inc     si
	mov     al, ah
	xor     ah, ah

	; 1s
	add     al, 30h
	mov     [si], al

	; ---------------------------------------------------------
	; Display results (label + single digit count per line)
	; ---------------------------------------------------------
	mov     dx, OFFSET HUNDREDS
	mov     ah, 9
	int     21h

	mov     di, OFFSET DENO+2
	mov     dl, [di]
	mov     ah, 2
	int     21h
	inc     di

	mov     dx, OFFSET FIFTY
	mov     ah, 9
	int     21h

	mov     dl, [di]
	mov     ah, 2
	int     21h
	inc     di

	mov     dx, OFFSET TWENTY
	mov     ah, 9
	int     21h

	mov     dl, [di]
	mov     ah, 2
	int     21h
	inc     di

	mov     dx, OFFSET TENS
	mov     ah, 9
	int     21h

	mov     dl, [di]
	mov     ah, 2
	int     21h
	inc     di

	mov     dx, OFFSET FIVE
	mov     ah, 9
	int     21h

	mov     dl, [di]
	mov     ah, 2
	int     21h
	inc     di

	mov     dx, OFFSET ONE
	mov     ah, 9
	int     21h

	mov     dl, [di]
	mov     ah, 2
	int     21h

	; Exit to DOS
	mov     ax, 4C00h
	int     21h

MSG       DB "Enter three (3) digit: $"
HUNDREDS  DB 0Dh, 0Ah, "100   $"   
FIFTY     DB 0Dh, 0Ah, "50    $"
TWENTY    DB 0Dh, 0Ah, "20   $"
TENS      DB 0Dh, 0Ah, "10   $"
FIVE      DB 0Dh, 0Ah, "5    $"
ONE       DB 0Dh, 0Ah, "1    $"
DIGIT     DB 4,?,4 DUP (' ')
DENO      DB 10,?,10 DUP (' ')