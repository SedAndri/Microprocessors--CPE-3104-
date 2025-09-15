
org 100h

.data

line1 db "Enter temperature in Celcius: $"
line2 db 0ah, 0dh, "In Degrees Farenheit is: $"
num db 10 dup (' ')
storedtc db ?
hundreds db ?
tens db ?
ones db ?

.code

mov ah, 09h
lea dx, line1
int 21h

mov ah, 01h
int 21h

sub al, 30h
mov ah, 0
mov bl, 10
mul bl
mov bl, al

mov ah, 01h
int 21h

sub al, 30h
mov ah, 0
add al, bl
mov storedtc, al

apply_formula:
    mov dl, 9
    mul dl
    mov bl, 5
    div bl
    mov ah, 0
    add al, 32
    
    mov bl, 100
    div bl 
    
storetf:    
    mov hundreds, al
    
    mov bl, ah
    mov ax, 0
    mov al, bl
    mov bl, 10
    div bl
    
    mov tens, al
    
    mov ones, ah
    
display_storedtf:
    mov ah, 09h
    lea dx, line2
    int 21h

    mov dx, 0    
    mov dl, hundreds
    add dl, 30h
    mov ah, 02h
    int 21h  
    
    mov dx, 0
    mov dl, tens
    add dl, 30h
    mov ah, 02h
    int 21h 
    
    mov dx, 0
    mov dl, ones
    add dl, 30h
    mov ah, 02h
    int 21h

ret