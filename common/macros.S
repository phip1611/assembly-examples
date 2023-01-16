/*
 * This file contains some common macros written for the GNU Assembler (GAS)
 * with AT&T syntax.
 *
 * All macros follow these properties:
 * - the runtime relocation offset is stored in %edx
 * - %eax can always be clobbered
 * - %eax contains the primary output value, if there is one
 * - %ebx is untouched as it contains the pointer to the Multiboot boot info
 */


/*
 * Asserts that the handoff to the code executing this was done by a
 * Multiboot boot loader. To verify this, the code checks the magic
 * value in %eax. See Multiboot spec for details.
 */
.macro M_ASSERT_MB_HANDOFF magic
    cmp     $\magic,  %eax
    # relative jump to following code (local label "0"), if the magic matches
    je      0f  # forward jump to local label 0
    # otherwise, flow continues here:

    /* signal error and hlt */
    mov     $0xbadb001, %ecx
    mov     $0xbadb001, %edx

    cli
    hlt
    ud2
    0:
    # flow continues..
.endm

/*
 * Verifies that the handoff was done by a Multiboot 1 bootloader. Otherwise,
 * the CPU halts.
 */
.macro M_ASSERT_MB1_HANDOFF
    M_ASSERT_MB_HANDOFF 0x2badb002  # Multiboot 1 magic number in %eax
.endm

/*
 * Verifies that the handoff was done by a Multiboot 2 bootloader. Otherwise,
 * the CPU halts.
 */
.macro M_ASSERT_MB2_HANDOFF
    M_ASSERT_MB_HANDOFF 0x36d76289  # Multiboot 2 magic number in %eax
.endm

/*
 * Calculates the relocation offset of the assembly code during runtime for x86
 * in 32-bit mode. In 64-bit mode, you should use the `lea` instruction as it
 * doesn't need the stack. The relocation offset is stored in %edx.
 *
 * This macro only needs to be called once. The macro itself is position
 * independend.
 *
 * Clobbers: %edx
 */
.macro M_CALC_RELOCATION_OFFSET_32BIT
    /*
     * Relative call to local label "1". This pushes the instruction pointer
     * (IP) of the next instruction onto the stack.
     */
    call    1f  # 1f: forward search for label "1"

    /*
     * After the call, the stack now contains return address, i.e., the runtime
     * address of the next instruction. Then, the IP is popped from the into
     * the register.
     */

    1:
    pop     %edx

    /*
     * We subtract the link address of label "1" from the actual IP. Register
     * %edx now contains the offset between link address and load address
     * (=runtime address).
     */

    sub     $1b,    %edx    # 1b: backward search for label "1"
.endm

/*
 * Wrapper around `M_CALC_RELOCATION_OFFSET_32BIT` that sets up a temporary
 * stack from a provided memory address. The macro restores the memory of that
 * memory after the relocation offset was calculated.
 *
 * Parameters:
 * - reg_tmp_stack: Register that holds the begin address of an at least 4-byte
 *   long physical memory area that is writeable.
 * Clobbers: %eax, %edx, %esp, flags
 */
.macro M_CALC_RELOCATION_OFFSET_32BIT_WRAPPER reg_tmp_stack
        # prepare minimal stack for the next call
        mov     (\reg_tmp_stack),   %eax    # save original memory content
        mov     \reg_tmp_stack,     %esp

        M_CALC_RELOCATION_OFFSET_32BIT

        # restore memory that was used as stack
        mov     %eax,           (\reg_tmp_stack)
.endm

/*
 * Resolves the runtime address of an symbol, i.e., an link address, and stores
 * the value in %eax. For this, it adds the relocation offset onto that address.
 *
 * This is useful to find symbols if the code was relocated.
 *
 * Parameters:
 * - link_addr: Link address either as symbol name or as numeric value.
 * Clobbers: %eax, %edx, flags
 */
.macro M_RESOLVE_RUNTIME_ADDR link_addr
    mov     $\link_addr,    %eax
    add     %edx,           %eax    # add relocation offset
.endm

/*
 * Creates a page table entry in %eax that points to a 32-bit physical address
 * with the given page table entry flags. The macro ensures that the physical
 * address is page aligned.
 *
 * For 64-bit paging with 64 bits per entry, this only covers the lowest 32
 * bits. Hence, the NX bits can't be set with this macro.
 *
 * Parameters:
 * - reg_phys_addr:
 * - entry_flags:
 * Clobbers: %eax, flags
 */
.macro M_CREATE_PAGE_TABLE_ENTRY reg_phys_addr, entry_flags
    mov \reg_phys_addr, %eax
    /* Check if the address is page-aligned/the lowest 12 bits are zero. */
    test $0xfff,        %eax # sets the zero flag to true, if the result is zero
    jz 0f  # jump to label 0 if the test was not successfull

    /* Panic. Unrecoverable error, something went really wrong. */

    ud2 # ud2 throws an exception; easily catchable in QEMU
    mov $0xbadb002, %eax
    ud2

    0:
    or $(\entry_flags & 0xfff), %eax # add flags to entry
.endm

/*
 * Writes a 32-bit page table entry into the corresponding page table. If 64 bit
 * paging with 64 bits per entry is used, this macro writes the lower half of
 * the entry.
 *
 * Parameters:
 * - reg_entry: Register that contains the page table entry
 * - reg_phys_table: Register that contains the physical address of the table
 * - reg_offset: Register that contains the offset into the page table
 * Clobbers: reg_entry, reg_phys_table, reg_offset, flags
 */
.macro M_WRITE_PAGE_TABLE_ENTRY reg_entry, reg_phys_table, reg_offset
    add \reg_offset,    \reg_phys_table   # add offset => pointer to entry
    mov \reg_entry,     (\reg_phys_table) # write entry to pointer
.endm
