section .text

global _start
extern printf

_start:
    mov rdi, Msg
    mov rsi, Name
    xor eax, eax
    call printf
    
    mov rax, 0x3C
    xor rdi, rdi
    syscall

section .data

Msg:    db "Hello World! My name is %s", 0x0A, 0x0
Name:   db "Egor", 0x0
