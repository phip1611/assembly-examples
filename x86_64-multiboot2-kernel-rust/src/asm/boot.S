# This assembly file uses AT&T syntax with GNU Assembler Syntax (GAS) directives.
# It contains the source code for a minimal kernel that can be booted via Multiboot1.
#
# When we boot, we are in 32-bit mode without paging enabled. This is guaranteed
# by the Multiboot1 boot flow. My kernel then sets up 32-bit paging (regular, without PAE)
# with a 4 MiB huge page mapping.

# Entry into the kernel code written in C.
# By default are all unknown symbols external symbols. However, this is neat
# as it helps to keep track which function are used from other object files.
.extern kernel_entry

# REGISTER USAGE IN THIS FILE
# %eax - Initially, this contains the Multiboot1 magic. After the check, I use it
#        as general purpose register.
# %ebx - Contains the Pointer to the Multiboot Information Structure
# %edx - Contains the load address offset to the link address. When we add this offset
#        to known link addresses of symbols, we get the runtime physical address.
#        This way, symbols can be found when the whole kernel binary was relocated.
# others - general purpose
# rsp/rbp - stack once 64-bit paging is active.

.section .multiboot2_header, "ax", @progbits

/*
 * Multiboot v2 Header
 */
__boot_header_mbi2_s:   .align 8 /* align to 8 byte for mbi2 */
                        .long   0xe85250d6
                        .long   0x0
                        .long   (__boot_header_mbi2_e - __boot_header_mbi2_s)
                        .long  -(0xe85250d6 + (__boot_header_mbi2_e - __boot_header_mbi2_s))
                        /* relocatable tag */
                        .word   0xa /* type = relocatable */
                        .word   0x0 /* flags */
                        .long   0x18 /* size */
                        .long   0x200000 /* 2 MiB minimum load address. */
                        .long   0xc0000000 /* 3 GiB maximum load address. */
                        .long   0x200000 /* 2 MiB huge page alignment */
                        .long   2 /* prefer high - just for the purpose of the demo. */
                        /* end tag */
                        .word   0x0 /* type */
                        .word   0x0 /* flags */
                        .long   0x8 /* size */
__boot_header_mbi2_e:

# "ax": section flags. Relevant for the section flags in the object file.
# Without those flags, the linker doesn't put this section into a LOAD segment as we expect.
.section .init_asm, "ax", @progbits

# We are booted by Multiboot1. We end up in 32-bit protected mode (without paging by the way).
# Thus, we produce 32-bit code. 64-bit code has other opcodes!
.code32
.global start
start:
    # call macro from macros.S
    M_ASSERT_MB_HANDOFF

    # Find offset of the relocation and store it in %edx.
    M_CALC_LOAD_ADDR_OFFSET_32BIT     %ebx,   %edx

    # Update gdt pointer with relocation offset.
    M_RESOLVE_RUNTIME_ADDR gdt,     %eax
    M_RESOLVE_RUNTIME_ADDR gdt_ptr, %ecx
    mov     %eax,   (%ecx)

    # We need to load a gdt with a 64-bit code segment to jump into 64-bit mode.
    M_RESOLVE_RUNTIME_ADDR ldt_gdt_data, %eax
    lgdt    (%eax)

    # Update position of 64-bit trampoline with relocation offset.
    M_RESOLVE_RUNTIME_ADDR bit64_trampoline, %ecx
    M_RESOLVE_RUNTIME_ADDR .L_ljmp_dest, %eax
    mov %ecx, (%eax)


    /* BEGIN: Setup Identity Page Table Mapping for Boot Code
       Create an identity map for the memory where the boot code was relocated to
       so that the code can continue running after paging was enabled. */

    M_PAGE_TABLE_WRITE_ENTRY VAR_BOOT_LINK_ADDR, 4, mem_pt_lvl4,  mem_pt_lvl3l, 0x1, ADD_OFFSET
    M_PAGE_TABLE_WRITE_ENTRY VAR_BOOT_LINK_ADDR, 3, mem_pt_lvl3l, mem_pt_lvl2l, 0x1, ADD_OFFSET
    M_PAGE_TABLE_WRITE_ENTRY VAR_BOOT_LINK_ADDR, 2, mem_pt_lvl2l, VAR_BOOT_LINK_ADDR, 0x81, ADD_OFFSET

    /*   END: Setup Identity Page Table Mapping for Boot Code */

    /* BEGIN: Setup Page Table Mappings for all non-boot code LOAD segments. */
    # TODO this should be improved: no hardcoded addresses but automatically map
    # all relevant (huge) pages for .text, .rodata, and .data/.bss.

    M_PAGE_TABLE_WRITE_ENTRY 0xffffffff88200000, 4, mem_pt_lvl4,  mem_pt_lvl3h, 0x3
    M_PAGE_TABLE_WRITE_ENTRY 0xffffffff88200000, 3, mem_pt_lvl3h, mem_pt_lvl2h, 0x3

    # map each load segment with respective to its relocation

    # text
    M_PAGE_TABLE_WRITE_ENTRY 0xffffffff88200000, 2, mem_pt_lvl2h, KERNEL_RX_LOAD_ADDR, 0x81
    # rodata
    M_PAGE_TABLE_WRITE_ENTRY 0xffffffff88400000, 2, mem_pt_lvl2h, KERNEL_RO_LOAD_ADDR, 0x81
    # data
    M_PAGE_TABLE_WRITE_ENTRY 0xffffffff88600000, 2, mem_pt_lvl2h, KERNEL_RW_LOAD_ADDR, 0x83

    /*   END: Setup Page Table Mappings for all non-boot code LOAD segments. */

    M_INIT_PAGING mem_pt_lvl4

    # Now paging is set up but we are in IA-32e compatibility mode until we perform a
    # long jump into 64-bit code.

    # ljmp into 64-bit code that is patched during runtime to cope with relocations:
    # - The local label (".L_ljmp_dest") contains the absolute 32-bit address of actual
    # 64-bit code.
    # The outcome is equal to something like "ljmp $8:label" but it is constructed at runtime.
    .byte X86_LJMP
    .L_ljmp_dest: # ".L" local label
    .long 0
    .word 8

    ud2a

# A trampoline in 32-bit address space to jump to for activating 64-bit mode.
.code64
bit64_trampoline:

    mov $hi_stack_end, %rax
    sub $(64 - 8),    %rax # weird x86 stack alignment. 64-byte alignment 8 byte above %rsp
    mov %rax, %rsp
    mov %rax, %rbp

    # Prepare function arguments
    xor %rdi,   %rdi
    mov %edx,   %edi
    add $VAR_BOOT_LINK_ADDR, %edi

    # We jump at the link address of the high level kernel code. This works as
    # I set up the page table properly. I cannot use "jmp kernel_entry" as the jump
    # will be relative, hence, the relocation is added.
    mov $kernel_entry, %rax
    jmp *%rax

    ud2

.align 4

# Pointer for the ldgdt instruction which takes a 6-byte sequence
# describing the size (2 byte) and the location (4 byte) of the GDT.
ldt_gdt_data:
            .word gdt_end - gdt - 1
gdt_ptr:    .quad 0     # this location will be updated during runtime to reflect relocations


# Global Descriptor Table (GDT)
.align 8
gdt:
    .long 0
    .long 0

    .long 0
    .long 0xa09b00 // 64bit CS CPL0
gdt_end:
