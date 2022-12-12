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
     * (ip) of the next instruction onto the stack.
     */
    call    1f  # 1f: forward search for label "1"

    /*
     * After the call, the stack now contains return address, i.e., the runtime
     * address of the next instruction. Then, the ip is popped from the into
     * the register.
     */

    1:
    pop     %edx

    /*
     * We subtract the link address of label "1" from the actual ip. This
     * register now contains the offset between link address and load address
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
