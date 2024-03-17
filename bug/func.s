section .rodata
buf     db "Hello World!"
buf_len equ $ - buf

section .text
extern func

func:
    pop r10
    mov r11, rsp

    ; if this code is here, this works
    ;mov rsp, r11
    ;push r10

    mov rax, 1
    mov rdi, 1
    mov rsi, buf
    mov rdx, buf_len
    syscall

    ; if the same code is here, it segfaults on push r10
    mov rsp, r11
    push r10
    
    ; this is because r11 is destroyed by syscall, apparently

    ret
