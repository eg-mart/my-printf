section .text
extern my_printf
extern print_num_dec
extern print_num_hex
extern print_num_bin
extern print_string
extern print_char

;--------------------------------------------------------------
print_num_dec:
    mov r11, 10000000000000000000
    mov rcx, 10

    cmp rdx, 0
    je .find_first_digit

    mov rax, rsi
    shr rax, 63
    cmp rax, 0
    je .find_first_digit

    mov rax, '-'
    stosb

    xor rax, rax
    dec rax
    sub rax, rsi
    inc rax
    mov rsi, rax

.find_first_digit:
    xor rdx, rdx
    mov rax, rsi
    div r11
    
    cmp rax, 0
    jne .print_digit

    xor rdx, rdx
    mov rax, r11
    div rcx
    mov r11, rax

    cmp r11, 1
    jne .find_first_digit

.print_digit:
    xor rdx, rdx
    mov rax, rsi
    div r11
    xor rdx, rdx
    div rcx

    mov rax, rdx
    add rax, 0x30
    stosb

    xor rdx, rdx
    mov rax, r11
    div rcx
    mov r11, rax

    cmp r11, 0
    jne .print_digit

    ret
;--------------------------------------------------------------

;--------------------------------------------------------------
print_num_hex:
    mov rcx, 60

.find_first_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0xF

    cmp rax, 0
    jne .print_digit

    sub cl, 4
    cmp cl, 0
    jg .find_first_digit

.print_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0xF

    mov rax, HexDigits[rax]
    stosb

    sub cl, 4
    cmp cl, 0
    jge .print_digit

    ret
;--------------------------------------------------------------

;--------------------------------------------------------------
print_num_bin:
    mov rcx, 63

.find_first_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0x1

    cmp rax, 0
    jne .print_digit

    dec cl
    cmp cl, 0
    jg .find_first_digit

.print_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0x1

    add rax, 0x30
    stosb

    dec cl
    cmp cl, 0
    jge .print_digit

    ret
;--------------------------------------------------------------

;--------------------------------------------------------------
print_string:

.print_char:
    lodsb
    stosb
    cmp al, 0
    jne .print_char

    ret
;--------------------------------------------------------------

;--------------------------------------------------------------
print_char:
    mov [rdi], rsi
    ret
;--------------------------------------------------------------

section .rodata
HexDigits   db "0123456789ABCDEF"
