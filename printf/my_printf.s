section .rodata
HexDigits   db "0123456789ABCDEF"

align 8
MyPrintfJmpTable:
    dq my_printf.case_error
    dq my_printf.case_bin
    dq my_printf.case_char
    dq my_printf.case_dec
    times 'o' - 'd' - 1 dq my_printf.case_error
    dq my_printf.case_oct
    times 's' - 'o' - 1 dq my_printf.case_error
    dq my_printf.case_str
    times 'u' - 's' - 1 dq my_printf.case_error
    dq my_printf.case_unsigned
    times 'x' - 'u' - 1 dq my_printf.case_error
    dq my_printf.case_hex

section .bss
buf         resb 2048

section .text
extern my_printf
extern print_num_dec
extern print_num_hex
extern print_num_bin
extern print_string
extern print_char

my_printf:
    pop r11

    push r9
    push r8
    push rcx
    push rdx
    push rsi

    push r11
    push rbp
    mov rbp, rsp
    push rbx

    mov rsi, rdi
    mov rdi, buf
    mov rbx, 2

.process_symbol:
    lodsb

    cmp al, 0
    je .print_buf

    cmp al, '%'
    je .process_variable

    stosb
    
    jmp .process_symbol

.print_buf:
    mov rax, 1
    mov rdx, rdi
    sub rdx, buf
    mov rdi, 1
    mov rsi, buf
    syscall

.exit:
    pop rbx
    pop rbp
    pop r11
    add rsp, 5 * 8
    push r11

    ret

.process_variable:
    xor rax, rax
    lodsb

    cmp al, '%'
    je .case_percent

    cmp al, 'a'
    jb .case_error
    cmp al, 'x'
    ja .case_error
    sub rax, 'a'

    push rsi
    mov rsi, [rbp + 8 * rbx]
    inc rbx

    jmp [MyPrintfJmpTable + 8 * rax]

.case_percent:
    mov byte [rdi], '%'
    inc rdi
    jmp .process_symbol

.case_bin:
    call print_num_bin
    jmp .common_end

.case_dec:
    mov rdx, 1
    call print_num_dec
    jmp .common_end

.case_unsigned:
    xor rdx, rdx
    call print_num_dec
    jmp .common_end

.case_hex:
    call print_num_hex
    jmp .common_end

.case_oct:
    call print_num_oct
    jmp .common_end

.case_str:
    call print_string
    jmp .common_end

.case_char:
    call print_char
    jmp .common_end

.case_error:
    mov rax, -1
    jmp .exit

.common_end: ; some cases have the same end, so here it is. name might to change
    pop rsi
    jmp .process_symbol

;--------------------------------------------------------------
print_num_dec:
    mov r11, 1000000000
    mov rcx, 10

    cmp rdx, 0
    je .find_first_digit

    mov eax, esi
    shr eax, 31
    cmp eax, 0
    je .find_first_digit

    mov rax, '-'
    stosb

    xor rax, rax
    dec eax
    sub eax, esi
    inc eax
    mov esi, eax

.find_first_digit:
    xor rdx, rdx
    mov eax, esi
    div r11
    
    cmp eax, 0
    jne .print_digit

    xor rdx, rdx
    mov rax, r11
    div rcx
    mov r11, rax

    cmp r11, 1
    jne .find_first_digit

.print_digit:
    xor rdx, rdx
    mov eax, esi
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
print_num_oct:
    mov rcx, 63

.find_first_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0x7

    cmp rax, 0
    jne .print_digit

    sub cl, 3
    cmp cl, 0
    jg .find_first_digit

.print_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0x7

    add rax, 0x30
    stosb

    sub cl, 3
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
    cmp al, 0
    je .exit
    stosb
    jmp .print_char

.exit:
    ret
;--------------------------------------------------------------

;--------------------------------------------------------------
print_char:
    mov rax, rsi
    mov byte [rdi], al
    inc rdi
    ret
;--------------------------------------------------------------
