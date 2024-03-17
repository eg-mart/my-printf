#include <stdio.h>
#include <limits.h>

int my_printf(const char *fmt, ...);

int main() {
    char buf[500] = "";

    int res = my_printf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n",
                        -1, -1, "love", 3802, 100, 33, 126,
                        -1, "love", 3802, 100, 33, 126);
    
    return 0;
}
