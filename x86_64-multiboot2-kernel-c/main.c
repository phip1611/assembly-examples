typedef char u8;

// GCC will make this a "COMMON" symbol.
char global_buffer_uninitialized[512];
// GCC will place this in the .data section.
char global_buffer_initialized_rw[4] = { 1, 2, 3, 4};
// GCC will place this in the .rodata section.
const char global_buffer_initialized_ro[4] = { 1, 2, 3, 4};
// GCC will place this in the .bss section.
int flag = 0;

void debugcon_print_byte(u8 c);
void debugcon_print_str(char const * const str);

void kernel_entry() {

    // will land in .rodata section
    char * msg = "Hello World from kernel code written in C!\n";

    // will land on stack
    volatile int a = 0xdeadbeef;
    volatile int b = 0x1337;
    volatile int c = a + b;

    debugcon_print_str(msg);

    while (1) {}
    __builtin_unreachable();
}

void debugcon_print_byte(u8 c) {
    asm volatile (
            "outb %0, %1"
            : /* no outputs */
            :
            "a"(c),
            "Nd"(0xe9)
            :
            );
}

void debugcon_print_str(char const * const str) {
    char const * a = str;
    while (*a) {
        char c = *a++;
        debugcon_print_byte(c);
    }
}


