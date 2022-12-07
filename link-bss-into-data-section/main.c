/*
 * This is the code for a minimal, freestanding C program that shows how the
 * GCC puts certain code constructs into specific sections.
 *
 * The output can be seen in "main.S" which is generated by invoking the
 * "make" command.
 *
 * The linker will use the linker file to rename some of those sections
 * and place it into LOAD segments.
 */

// GCC will make this a "COMMON" symbol.
char global_buffer_uninitialized[512];
// GCC will place this in the .data section.
char global_buffer_initialized_rw[4] = { 1, 2, 3, 4};
// GCC will place this in the .rodata section.
const char global_buffer_initialized_ro[4] = { 1, 2, 3, 4};
// GCC will place this in the .bss section.
int flag = 0;

// A simple function with no inputs and no return value. This program can be
// executed under Linux but will stick in an endless loop.
void start() {
    // All variables are marked as volatile so that the compiler
    // does not discard them.

    // This string will land in the .rodata section.
    volatile char * msg = "Hello World!\n";

    // Values will land on the stack.
    volatile int a = 0xdeadbeef;
    volatile int b = 0x1337;
    volatile int c = a + b;

    while (1) {}
    __builtin_unreachable();
}
