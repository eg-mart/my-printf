section .bss
buf: resb 1

section .text
extern my_putc

my_putc:
   mov buf[0], rdi
   mov rax, 0x01
   mov rdi, 1
   mov rsi, buf
   mov rdx, 1
   syscall

   ret
