IntMaxPow10 equ 1000000000  ; maximum power of 10 that fits in an unsigned int
ArgumentRegisterNum equ 6   ; number of registers used for arguments passing
BufLen     equ 10           ; length of the internal output buffer
BufMargin  equ 1            ; how much bytes of the buffer will be left just in case

; how much bits one digit of hex and oct number takes up
BitsInHexDigit  equ 4
BitsInOctDigit  equ 3

section .rodata
HexDigits   db "0123456789abcdef"   ; digits and letters of a hex number in order

; A jumptable for processing format specifiers in my_printf function
; 'b': my_printf.case_bin (print a long int in binary)
; 'c': my_printf.case_char (print a character)
; 'd': my_printf.case_dec (print a signed int)
; 'o': my_printf.case_oct (print a long int in octal)
; 's': my_printf.case_str (print a string)
; 'u': my_printf.case_unsigned (print an unsigned int)
; 'x': my_printf.case_hex (print a long int in hex)
; other: my_printf.case_error (return -1)
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
buf         resb BufLen ; the internal output buffer

section .text
extern my_printf
extern print_num_dec
extern print_num_hex
extern print_num_bin
extern print_string
extern print_char
extern print_num_pow2

;------------------------------------------------------------------------------
; int my_printf(const char *fmt, ...)
; 
; A function for printing a formatted string to stdout. Every character from
; the format string except for '%' is printed as-is. '%%' is replaced with '%'.
;
; Otherwise if a '%' is encountered, function takes its next argument and
; prints it according to the format, specified by the character after '%':
; %b - unsigned binary 64-bit integer
; %c - character (in ASCII encoding)
; %d - signed decimal 32-bit integer
; %o - unsigned octal 64-bit integer
; %s - null-terminated string of characters (in ASCII encoding)
; %u - unsigned decimal 32-bit integer
; %x - unsigned hexadecimal 64-bit integer
;
; Any other combination causes function to return -1 immediately.
;
; If number of arguments and of format specifiers isn't equal, undefined
; behaviour will occur.
;
; Output is line buffered (buffer: buf, size: BufLen)
;------------------------------------------------------------------------------
; Entry: rdi - address of the format string
;        rsi-r9 - arguments for printing
;        Stack - the rest of the arguments for printing
; Assumes: -
; Destroyes: rdi, rsi, r11, rax, rcx, rdx
; Returns (rax): number of bytes printed. -1 in case of an error
;------------------------------------------------------------------------------
my_printf:
    ; save the return address
    pop r11

    ; push all argument registers on the stack, so all that arguments lie
    ; continuosly on the stack
    push r9
    push r8
    push rcx
    push rdx
    push rsi

    ; push return address and rbp on stack, creating a stack frame
    push r11
    push rbp
    mov rbp, rsp

    ; save callee-saved registers
    push rbx
    push r12
    push r13

    ; rdi = start of the buffer, rsi = start of format string
    mov rsi, rdi
    mov rdi, buf

    ; rbx = offset of the next argument from rbp on the stack (in qwords)
    ; 2 beacuse besides arguments there is return addr and rbp 
    ; on the stack before the start of stack frame
    mov rbx, 2

    ; r12 = end of buffer
    mov r12, buf
    add r12, BufLen
    sub r12, BufMargin

    ; r13 = number of bytes printed
    xor r13, r13

; take the next symbol from format str (rsi) and print or process it
.process_symbol:
    lodsb

    ; if symbol (al) = '\0', format string has ended: return
    cmp al, 0
    je .print_buf_and_exit

    ; if symbol = '%', look at the next one and decide what to do
    cmp al, '%'
    je .process_variable

    ; otherwise, print the symbol
    stosb
    inc r13

    ; if symbol was '\n', flush the buffer
    cmp al, 0xA
    je .print_buf

    ; if rdi (current address in buffer) exceeds r12 (end of buffer) - 
    ; flush the buffer
    cmp rdi, r12
    jae .print_buf
    
    jmp .process_symbol

; flush the buffer
.print_buf:
    push rsi
    call print_buf
    pop rsi
    jmp .process_symbol

; flush the buffer and return from the function with code 0
.print_buf_and_exit:
    call print_buf

.exit:
    ; return value = number of bytes printed
    mov rax, r13

    ; restore callee-saved registers
    pop r13
    pop r12
    pop rbx

    ; restore previous stack frame
    pop rbp
    pop r11

    ; clear whe stack of argument registers (all except from rdi)
    ; 8 = size of one register
    add rsp, (ArgumentRegisterNum - 1) * 8

    ; move the return address to where it belongs
    push r11

    ret

; if '%' was encountered, process the character next to it
.process_variable:
    xor rax, rax
    lodsb

    ; if '%%' is encountered, print '%'
    cmp al, '%'
    je .case_percent

    ; 'a' <= symbol (al) <= 'x', otherwise return an error
    cmp al, 'a'
    jb .case_error
    cmp al, 'x'
    ja .case_error

    ; al = index of the letter in the alphabet
    sub rax, 'a'

    ; all cases (except from .case_percent) have the same beginning -
    ; save rsi, put the next argument from the stack into rsi,
    ; put the end of the buffer into rdx
    push rsi
    mov rsi, [rbp + 8 * rbx]
    mov rdx, r12
    inc rbx

    ; switch (symbol (rax)), 8 = size of an address in the table
    jmp [MyPrintfJmpTable + 8 * rax]

; if '%%' is encountered, print '%'
.case_percent:
    mov byte [rdi], '%'
    inc rdi ; inc the buffer pointer
    inc r13 ; inc the number of bytes printed
    jmp .process_symbol

.case_bin:
    call print_num_bin
    jmp .common_end

.case_dec:
    mov rdx, 1 ; is_signed = 1 (argument of print_num_dec)
    mov rcx, r12 ; in print_num_dec, end of buffer is passed in rcx
    call print_num_dec
    jmp .common_end

.case_unsigned:
    xor rdx, rdx ; is_signed = 0 (argument of print_num_dec)
    mov rcx, r12 ; in print_num_dec, end of buffer is passed in rcx
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

; if unknown format specifier is found, return -1 immediately
.case_error:
    mov rax, -1
    jmp .exit

; most cases have the same ending - this is it. name might change
.common_end:
    pop rsi
    add r13, rax
    jmp .process_symbol
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; int print_buf(char *buf_end)
;
; Flushes the internal input buffer (buf).
;------------------------------------------------------------------------------
; Entry: rdi - pointer to the current position in the buffer
; Assumes: buf - internal input buffer
; Destroyes: rax, rcx, rdx, rdi, rsi, r11
; Returns (rax): number of bytes printed
; Notes: rdi is set to the beginning of the buffer (buf)
;------------------------------------------------------------------------------
print_buf:
    mov rax, 1
    mov rdx, rdi
    sub rdx, buf
    mov rdi, 1
    mov rsi, buf
    syscall
    mov rdi, buf
    ret
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; void print_num_dec(char *buf, int num, bool is_signed, const char *end_buf)
;
; Print a 32-bit integer as a decimal to a buffer in 1 of 2 formats - signed or
; unsigned. Flushes the buffer (with a call to print_buf) if it has overflowed.
;------------------------------------------------------------------------------
; Entry: rdi - address of the ouput buffer
;        rsi - 32-bit int to print (lower 32 bits are interpreted as int)
;        rdx - 1 to print signed number, 0 otherwise
;        rcx - end of the output buffer
; Assumes: -
; Destroys: rax, rdx, rdi, rsi, r10, r11
; Returns (rax): number of bytes printed
; Notes: rdi is moved to the end of printed number in the buffer.
;------------------------------------------------------------------------------
print_num_dec:
    ; save callee-saved registers
    push rbx

    ; rbx = number of bytes printed
    xor rbx, rbx

    ; r11 = current power of 10 (number / r11 % 10 is the current digit)
    mov r11, IntMaxPow10

    ; save 10 to the register because there is a lot of division by 10
    mov r10, 10

    ; if is_signed (rdx) = 0, start printing the number
    cmp rdx, 0
    je .find_first_digit

    ; otherwise check if first bit of the number is 0 (if it is positive)
    ; print it if true
    mov eax, esi
    shr eax, 31
    cmp eax, 0
    je .find_first_digit

    ; otherwise print '-'
    mov rax, '-'
    stosb
    inc rbx

    ; and adjust the number to equal its absolute value
    xor rax, rax
    dec eax
    sub eax, esi
    inc eax
    mov esi, eax

; while (number (rsi) / r11) == 0, divide r11 by ten (find the first most
; significant non-zero digit)
.find_first_digit:
    xor rdx, rdx
    mov eax, esi
    div r11
    
    cmp eax, 0
    jne .print_digit

    xor rdx, rdx
    mov rax, r11
    div r10
    mov r11, rax

    ; if r11 == 1, number consists of 1 digit, so print it
    cmp r11, 1
    jne .find_first_digit

; print all digits in the number, starting with the most significant
.print_digit:
    ; rdx = rsi / r11 % 10
    xor rdx, rdx
    mov eax, esi
    div r11
    xor rdx, rdx
    div r10

    ; rax = ascii code of the digit in rdx, print it
    mov rax, rdx
    add rax, '0'
    stosb
    inc rbx

    ; if buffer overflowed, flush it
    cmp rdi, rcx
    jae .print_buf

; the second part of .print_digit loop (after flushing loop continues from here)
.continue_print_digit:
    ; r11 /= 10
    xor rdx, rdx
    mov rax, r11
    div r10
    mov r11, rax

    ; if r11 == 0, number has been printed
    cmp r11, 0
    jne .print_digit

    ; rax = number of bytes printed, restore calle-saved rbx
    mov rax, rbx
    pop rbx

    ret

; flush the internal buffer by a call to print_buf and return to the printing loop
.print_buf:
    push rcx
    push rsi
    push r11
    call print_buf
    pop r11
    pop rsi
    pop rcx
    jmp .continue_print_digit
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; void print_num_hex(char *buf, long int num, const char *end_buf)
;
; Print a 64-bit integer to a buffer in hex format with lowercase letters.
; Flushed the buffer by a call to print_buffer if it has overflowed.
;------------------------------------------------------------------------------
; Entry: rdi - address of the ouput buffer
;        rsi - 64-bit int to print
;        rdx - end of the buffer
; Assumes: -
; Destroys: rax, rcx, rdi
; Returnes (rax): number of bytes printed
; Notes: rdi is moved to the end of printed number.
;------------------------------------------------------------------------------
print_num_hex:
    push rbx

    ; rbx = number of bytes printed
    xor rbx, rbx

    ; rcx = how much bits to shift right for printing the current digit
    ; (each hex digit is four bits)
    mov rcx, 60

; find the first most significant non-zero digit
; (while (rsi >> cl) && 0xF == 0, decrease rcx by 4 to look at the next hex digit)
.find_first_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0xF

    cmp rax, 0
    jne .print_digit

    sub cl, BitsInHexDigit
    cmp cl, 0
    jg .find_first_digit

; print all hex digits starting from the most significant
.print_digit:
    ; take the lower four bytes of (rax >> cl) - this is equal to the current
    ; digit's value
    mov rax, rsi
    shr rax, cl
    and rax, 0xF

    ; print HexDigits[current_digit_value (rax)]
    mov al, byte HexDigits[rax]
    stosb
    inc rbx

    ; if buffer overflowed - flush
    cmp rdi, rdx
    jae .print_buf

; second part of the .print_digit loop (control returns here after flushing)
.continue_print_digit:
    ; decrease cl by 4 to look at the next hex digit
    sub cl, BitsInHexDigit
    cmp cl, 0
    jge .print_digit

    ; return value = number of bytes printed, restore callee-saved rbx
    mov rax, rbx
    pop rbx

    ret

; flush the buffer by calling print_buf
.print_buf:
    push rcx
    push rsi
    push rdx
    push r11
    call print_buf
    pop r11
    pop rdx
    pop rsi
    pop rcx
    jmp .continue_print_digit
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; void print_num_oct(char *buf, long int num, const char *end_of_buffer)
;
; Print a 64-bit integer to a buffer in octal format. Flushes the buffer
; by calling print_buf if the buffer has overflowed.
;------------------------------------------------------------------------------
; Entry: rdi - address of the ouput buffer
;        rsi - 64-bit int to print
;        rdx - end of the output buffer
; Assumes: -
; Destroys: rax, rcx, rdi
; Returnes (rax): number of bytes printed
; Notes: rdi is moved to the end of printed number.
;------------------------------------------------------------------------------
print_num_oct:
    push rbx

    mov rcx, 63
    xor rbx, rbx

.find_first_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0x7

    cmp rax, 0
    jne .print_digit

    sub cl, BitsInOctDigit
    cmp cl, 0
    jg .find_first_digit

.print_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0x7

    add rax, 'a'
    stosb
    inc rbx

    cmp rdi, rdx
    jae .print_buf

.continue_print_digit:
    sub cl, BitsInOctDigit
    cmp cl, 0
    jge .print_digit

    mov rax, rbx
    pop rbx

    ret

.print_buf:
    push rcx
    push rdx
    push rsi
    push r11
    call print_buf
    pop r11
    pop rsi
    pop rdx
    pop rcx
    jmp .continue_print_digit
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; void print_num_bin(char *buf, long int num, const char *end_of_buffer)
;
; Print a 64-bit integer to a buffer in binary format.
; If buffer has overflowed, flushes it by calling print_buf.
;------------------------------------------------------------------------------
; Entry: rdi - address of the ouput buffer
;        rsi - 64-bit int to print
;        rdx - end of the output buffer
; Assumes: -
; Destroys: rax, rcx, rdi
; Returnes (rax): number of bytes printed
; Notes: rdi is moved to the end of printed number.
;------------------------------------------------------------------------------
print_num_bin:
    push rbx

    mov rcx, 63
    xor rbx, rbx

.find_first_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0x1

    cmp rax, 0
    jne .print_digit

    ; decrease cl by 1 (number of bits in a bin digit) to look at the next digit
    dec cl
    cmp cl, 0
    jg .find_first_digit

.print_digit:
    mov rax, rsi
    shr rax, cl
    and rax, 0x1

    add rax, 0x30
    stosb
    inc rbx
    
    cmp rdi, rdx
    jae .print_buf

.continue_print_digit:
    ; decrease cl by 1 (number of bits in a bin digit) to look at the next digit
    dec cl
    cmp cl, 0
    jge .print_digit

    mov rax, rbx
    pop rbx

    ret

.print_buf:
    push rcx
    push rdx
    push rsi
    push r11
    call print_buf
    pop r11
    pop rsi
    pop rdx
    pop rcx
    jmp .continue_print_digit
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; void print_num_pow2(char *buf, long int num, int power)
; 
; Print a 64-bit unsigned integer in base 2 ^ power (rdx).
; DO NOT USE THIS! WIP
;------------------------------------------------------------------------------
; Entry: rdi - address of the output buffer
;        rsi - the 64-bit uint to print
;        rdx - the power of 2 (1 - 3)
; Assumes: -
; Destroys: rax, rcx, rdx, rdi, r10, r11
; Returns: -
; Notes: sets rdi to the end of the printed number
;------------------------------------------------------------------------------
print_num_pow2:
    mov rcx, rdx
    xor rdx, rdx
    mov rax, 64
    div rcx
    mov r11, 64
    sub r11, rdx

    mov rdx, 1
    shl rdx, cl
    dec rdx

    mov r10, rcx
    mov rcx, r11

.find_first_digit:
    mov rax, rsi
    shr rax, cl
    and rax, rdx

    cmp rax, 0
    jne .print_digit

    sub rcx, r10
    cmp cl, 0
    jg .find_first_digit

.print_digit:
    mov rax, rsi
    shr rax, cl
    and rax, rdx

    add rax, 'a'
    stosb

    sub rcx, r10
    cmp cl, 0
    jge .print_digit

    ret
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; int print_string(char *buf, const char *string, const char *end_of_buf)
;
; Print a null-terminated string of chars (in ASCII encoding) to the buffer.
; In case of an overflow, flushed the buffer with a call to print_buffer.
;------------------------------------------------------------------------------
; Entry: rdi - address of the output buffer
;        rsi - address of the string to print
;        rdx - end of the output buffer
; Assumes: -
; Destroys: rax, r11
; Returns (rax): number of bytes printed
; Notes: sets rdi to the end of the printed string in the output buffer
;------------------------------------------------------------------------------
print_string:
    ; r11 = number of bytes printed
    xor r11, r11
.print_char:
    lodsb

    ; if current symbol (al) == 0, string has ended - return
    cmp al, 0
    je .exit
    stosb
    inc r11

    ; if the buffer has overflowed - flush it
    cmp rdi, rdx
    jae .print_buf

    jmp .print_char

.print_buf:
    push rdx
    push rsi
    call print_buf
    pop rsi
    pop rdx
    jmp .print_char

.exit:
    mov rax, r11
    ret
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; int print_char(char *buf, char character, const char *end_of_buf)
;
; Print a character in ASCII-encoding to the buffer. Flushed the buffer in
; case of an oveflow.
;------------------------------------------------------------------------------
; Entry: rdi - address of the output buffer
;        rsi - character to print (in ASCII)
;        rdx - end of the buffer
; Assumes: -
; Destroys: rax, rdi
; Returns (rax): number of bytes printed (1)
; Notes: sets rdi to point after the printed char
;------------------------------------------------------------------------------
print_char:
    mov rax, rsi
    mov byte [rdi], al
    inc rdi
    mov rax, 1
    ret
;------------------------------------------------------------------------------
