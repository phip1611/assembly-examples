# This assembly file uses AT&T syntax with GNU Assembler Syntax (GAS) directives.
# It contains the source code for a minimal kernel that can be booted via Multiboot1.
# The kernel implements a minimal driver for the debugcon device provided by QEMU via
# I/O port 0xe9. To find more about the debugcon device, please read this blogpost:
# https://phip1611.de/blog/how-to-use-qemus-debugcon-feature-and-write-to-a-file/

# "ax": section flags. Relevant for the section flags in the object file.
# Without those flags, the linker doesn't put this section into a LOAD segment as we expect.
.section .init_asm, "ax"

/* Multiboot v1 Header. Required so that we can be booted by QEMU via the "-kernel" parameter. */
__boot_header_mbi1:
    .long   0x1badb002
    .long   0x0
    .long  -0x1badb002

# Place a null-terminated ASCII string statically/"as is" inside the binary.
hello_world_str: .asciz "Hello World from Assembly Code\n"

# We are booted by Multiboot1. We end up in 32-bit protected mode (without paging by the way).
# Thus, we produce 32-bit code. 64-bit code has other opcodes!
.code32

# Start symbol. Referenced in linker script. Entry in the ELF.
.global start
start:
    # Set up stack so that we can use "call" and "ret".
    mov     $boot_stack_end,    %esp
    # Prepare function argument: string pointer into register eax
    mov     $hello_world_str,   %eax
    call    debugcon_print_string_until_null

    # pause processor: clear interrupts and halt
    cli
    hlt
    ud2


# Prints a C-style string to the QEMU debugcon port.
#
# Parameters:
#   1: %eax - Pointer to the begin of the string.
# Clobbers: %eax, %ecx
debugcon_print_string_until_null:
    # load byte behind string pointer
    movb    (%eax),     %cl
    # null byte check
    cmp     $0,         %cl
    jz      out
    # prepare function arguments; %cl => %al
    xchg    %eax,       %ecx
    call    debugcon_print_byte
    # restore string pointer in %eax
    xchg    %eax,       %ecx
    # increase string pointer
    inc     %eax
    # do again for next byte of string
    jmp     debugcon_print_string_until_null
    out: ret


# Prints a character to the QEMU debugcon port.
#
# Parameters:
#   1: %al - Character to print.
# Clobbers: %edx/%dx
#
# Example:
# ```asm
# mov       $'o',   %al
# call      debugcon_print_byte
# ```
debugcon_print_byte:
    # 0xe9 => I/O port of debugcon device
    # movw: 16 bit
    movw    $0xe9,  %dx
    out     %al,    %dx
    ret

# Backing storage for a minimal stack. The memory will be static inside the final ELF.
.align 4
boot_stack_begin:
# 1 KiB stack is more than enough for the boot code
.fill 1024, 1, 0
boot_stack_end:
