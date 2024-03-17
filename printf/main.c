#include <stdio.h>
#include <limits.h>

int my_printf(const char *fmt, ...);

int main() {
    char buf[500] = "";

    const char *fmt_str = "%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n";
    puts("----------------------------------------");
    int real_res = printf(fmt_str, -1, -1, "love", 3802, 100, 33, 126,
                          -1, "love", 3802, 100, 33, 126);
    puts("----------------------------------------");
    int my_res = my_printf(fmt_str, -1, -1, "love", 3802, 100, 33, 126,
                           -1, "love", 3802, 100, 33, 126);
    puts("----------------------------------------");
    my_printf("Printf bytes: %d\nMy bytes: %d\n", real_res, my_res);
    
    return 0;
}
