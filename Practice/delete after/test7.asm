

org 100h
        jmp start

; ---------- DATA ----------
prompt      db 'Input string [max. 20]: $'
; DOS 0Ah input buffer: [0]=max, [1]=len, [2..]=data, [2+len]=CR
inbuf       db 20
inlen       db 0
intext      db 20 dup(0)

; Clean output labels
hdr_results db 0Dh,0Ah,'Results:',0Dh,0Ah,'$'
label_chars db 'Characters: $'
label_a     db 'a: $'
label_e     db 'e: $'
label_i     db 'i: $'
label_o     db 'o: $'
label_u     db 'u: $'
label_vow   db 'Vowels: $'
label_con   db 'Consonants: $'
newline     db 0Dh,0Ah,'$'

vowels      db 'AEIOU'

cnt_len     dw 0
cnt_a       dw 0
cnt_e       dw 0
cnt_i       dw 0
cnt_o       dw 0
cnt_u       dw 0
cnt_v       dw 0
cnt_c       dw 0

; ---------- CODE ----------
start:
        push cs
        pop  ds

        mov  dx, offset prompt
        mov  ah, 9
        int  21h

        mov  dx, offset inbuf
        mov  ah, 0Ah
        int  21h

        ; clear counters (8 words) with REP STOSW
        xor  ax, ax
        lea  di, cnt_len
        mov  cx, 8
        rep  stosw

        ; total characters
        mov  al, inlen
        cbw
        mov  cnt_len, ax

        ; scan characters
        mov  si, offset intext
        mov  cl, inlen
        xor  ch, ch
        jcxz show_results

scan_loop:
        lodsb                        ; AL = char

        ; to uppercase if 'a'..'z'
        cmp  al, 'a'
        jb   chk_letter
        cmp  al, 'z'
        ja   chk_letter
        sub  al, 20h                 ; 'a'..'z' -> 'A'..'Z'

chk_letter:
        ; only letters A..Z count
        cmp  al, 'A'
        jb   next_char
        cmp  al, 'Z'
        ja   next_char

        ; check if vowel via small table (keeps SI intact)
        mov  bx, offset vowels       ; 'A','E','I','O','U'
        mov  di, offset cnt_a        ; counters in same order
        mov  dl, 5
vchk:
        cmp  al, [bx]
        je   is_vowel
        inc  bx
        add  di, 2                   ; next word counter
        dec  dl
        jnz  vchk
        ; not a vowel => consonant
        inc  word ptr cnt_c
        jmp  short next_char
is_vowel:
        inc  word ptr [di]
        inc  word ptr cnt_v

next_char:
        loop scan_loop

; ---------- OUTPUT ----------
show_results:
        ; print header
        mov  dx, offset hdr_results
        mov  ah, 9
        int  21h

        mov  ax, cnt_len
        mov  dx, offset label_chars
        call print_label_count

        mov  ax, cnt_a
        mov  dx, offset label_a
        call print_label_count

        mov  ax, cnt_e
        mov  dx, offset label_e
        call print_label_count

        mov  ax, cnt_i
        mov  dx, offset label_i
        call print_label_count

        mov  ax, cnt_o
        mov  dx, offset label_o
        call print_label_count

        mov  ax, cnt_u
        mov  dx, offset label_u
        call print_label_count

        mov  ax, cnt_v
        mov  dx, offset label_vow
        call print_label_count

        mov  ax, cnt_c
        mov  dx, offset label_con
        call print_label_count

        mov  ax, 4C00h
        int  21h

; ---------- routines ----------
; print_ud: print AX as unsigned decimal without leading zeros (0..65535)
print_ud:
        push bx
        push cx
        push dx
        mov  bx, 10
        xor  cx, cx
        cmp  ax, 0
        jne  pu_loop
        mov  dl, '0'
        mov  ah, 2
        int  21h
        jmp  short pu_done
pu_loop:
        xor  dx, dx
        div  bx              ; AX = AX/10, DX = remainder
        push dx              ; push remainder
        inc  cx
        test ax, ax
        jnz  pu_loop
pu_print:
        pop  dx
        add  dl, '0'
        mov  ah, 2
        int  21h
        loop pu_print
pu_done:
        pop  dx
        pop  cx
        pop  bx
        ret

; print_label_count: AX=count to print, DX=offset of label to print before
print_label_count:
        push ax
        mov  ah, 9
        int  21h             ; print label
        pop  ax
        call print_ud        ; print number
        mov  dx, offset newline
        mov  ah, 9
        int  21h             ; newline
        ret