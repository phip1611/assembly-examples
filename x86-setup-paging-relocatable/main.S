# This assembly file uses AT&T syntax with GNU Assembler Syntax (GAS) directives.
# It contains the source code for a minimal kernel that can be booted via Multiboot1.
#
# When we boot, we are in 32-bit mode without paging enabled. This is guaranteed
# by the Multiboot1 boot flow. My kernel then sets up 32-bit paging (regular, without PAE)
# with a 4 MiB huge page mapping.

# "ax": section flags. Relevant for the section flags in the object file.
# Without those flags, the linker doesn't put this section into a LOAD segment as we expect.
.section .init_asm, "ax"

# Include helper macros.
.include "macros.S"

# By default are all unknown symbols external symbols. However, this is neat
# as it helps to keep track which function are used from other object files.m
.extern debugcon_print_string_until_null

# REGISTER USAGE IN THIS FILE
# %eax - Initially, this contains the Multiboot1 magic. After the check, I use it
#        as general purpose register.
# %ebx - Contains the Pointer to the Multiboot Information Structure
# %edx - Contains the load address offset to the link address. When we add this offset
#        to known link addresses of symbols, we get the runtime physical address.
#        This way, symbols can be found when the whole kernel binary was relocated.
# %esp - Stack Pointer
# %ebp - general purpose
# %ecx - general purpose

# Multiboot v1 Header. Required so that we can be booted by QEMU via the "-kernel" parameter.
__boot_header_mbi1:
    .long   0x1badb002
    .long   0x0
    .long  -0x1badb002

# We are booted by Multiboot1. We end up in 32-bit protected mode (without paging by the way).
# Thus, we produce 32-bit code. 64-bit code has other opcodes!
.code32
.global start
start:
    # The code uses several macros from "macros.S". Please check them out first!

    M_ASSERT_MB1_HANDOFF

    /*  Find offset of the relocation and store it in %edx. */

    M_CALC_RELOCATION_OFFSET_32BIT_WRAPPER     %ebx

    /* Setup stack a stack which allows us to use the M_DEBUGCON_PRINT macro. */
    M_RESOLVE_RUNTIME_ADDR mem_boot_stack_end # stack grows downwards.
    mov     %eax,           %esp

    M_DEBUGCON_PRINT str_hello_world

    /*
     * Now, we switch from 32-bit protected mode without paging to
     * 32-bit protected mode with paging. We enable huge page support but
     * do not use PAE.
     *
     * I create a single 4 MiB huge page mapping in the lvl2 page table.
     */

    /* BEGIN: IDENTITY MAP FOR BOOT_LINK_ADDR (WITH RESPECT TO RELOCATION) */
        M_RESOLVE_RUNTIME_ADDR LINK_ADDR
        mov %eax,   %ebp # save value in %ebp
        # entry flags: present, writeable, implicitly executable, huge page
        # writeable is required as the stack lies in this region.
        M_PAGE_TABLE_WRITE_ENTRY 2, %ebp, mem_page_table_lvl2, LINK_ADDR, 0x83
        M_INIT_PAGING mem_page_table_lvl2
    /* END:   IDENTITY MAP FOR BOOT_LINK_ADDR (WITH RESPECT TO RELOCATION) */

    # If there is no page fault (which will cause a triple fault very likely) at this point
    # here, then the page table setup was successful!

    # Pushes to the stack which is a write to the memory. Hence, the page table
    # mapping must be writeable.
    M_DEBUGCON_PRINT str_paging_init

    cli
    hlt


# Backing storage for a minimal stack. The memory will be static inside the final ELF.
.align 4
mem_boot_stack_begin:
# 1 KiB stack is more than enough for the boot code
.fill 1024, 1, 0
mem_boot_stack_end:

# Backing storage used as level 2 page table (page directory) for 32-bit paging
.align 4096
mem_page_table_lvl2:
.fill 4096, 1, 0
