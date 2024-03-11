#include <string.h>

int my_putc(char c);

int main() {
    const char str[] = "Hello Egor!\n";

    for (size_t i = 0; i < strlen(str); i++)
        my_putc(str[i]);
    
    return 0;
}
