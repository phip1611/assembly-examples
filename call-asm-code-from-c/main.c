#include <stdlib.h>
#include <stdio.h>

// Calculates the sum of the division and the remainder of a and b,
// i.e. (a / b) + (a % b)
extern int calc(int, int);

int main(int argc, char ** argv) {
    if (argc != 3) {
        printf("Bitte zwei Zahlen übergeben!\n");
        exit(1);
    }
	
    int input_a = atoi(argv[1]);
    int input_b = atoi(argv[2]);

    int x = calc(input_a, input_b);
    printf("calc(%d, %d) = %d\n", input_a, input_b, x);

    return 0;
}
