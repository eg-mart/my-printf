#include <stdio.h>

void print_num_hex(char *buf, unsigned long num);
void print_num_dec(char *buf, unsigned long num, int is_signed);
void print_num_bin(char *buf, unsigned long num);
void print_string(char *buf, char *str);
void print_char(char *buf, char str);

int main() {
    char buf[500] = "";

    unsigned long n = 0;
    scanf("%lu", &n);

    print_num_dec(buf, n, 0);
    print_num_hex(buf + 30, n);
    print_num_bin(buf + 60, n);
    print_string(buf + 300, "Hello world, I am Egor!");
    print_char(buf + 400, '?');
    
    puts(buf);
    puts(buf + 30);
    puts(buf + 60);
    puts(buf + 300);
    puts(buf + 400);
    
    return 0;
}
