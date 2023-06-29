# Helper macros.

# Verifies that there was a valid handoff from a Multiboot2 bootloader by checking the
# magic value in %eax.
#
# Input Registers:
#  - %eax - the Multiboot2 magic number
# Parameters:
#  - None
# Outputs:
#  - None
# Clobbers: rflags
.macro M_ASSERT_MB_HANDOFF
    cmp     $MULTIBOOT2_MAGIC,  %eax
    # relative jump to following code (local label "0"), if the magic matches
    je      0f
    # otherwise, flow continues here:
    # signal error and hlt
    mov     $0xbadb001, %ecx
    mov     $0xbadb001, %edx
    cli
    hlt
    ud2
    0:
    # flow continues..
.endm

# Determine the relocation offset during runtime.
#
# Calculates the offset between link addresses and load addresses during
# runtime and puts it into the provided register. This offset can be added to
# known link addresses of certain symbols to find them during runtime after a
# relocation.
#
# Useful in 32-bit code. In 64-bit x86, an approach using the lea instruction
# should be used instead.
#
# Input Registers:
#  - None
# Parameters:
#  - reg_tmp_addr: Register (distinct from the clobbered ones down below) with
#    the begin address of a 4-byte long memory area that can be used as
#    temporal storage. Must be valid and in physical ram. The original content
#    will be restored after this code is done. Valid options depend on the
#    platform. One valid option is to pass the pointer to the Multiboot
#    Information Structure (MBI).
#  - out_reg: Register where the output is stored.
# Outputs:
#  - The register behind the parameter 'out_reg' will contain the result.
# Clobbers: %eax, %edx, %esp, out_reg
.macro M_CALC_LOAD_ADDR_OFFSET_32BIT reg_tmp_addr out_reg
        # prepare minimal stack for the next call
        mov     (\reg_tmp_addr),   %eax    # save original memory content
        mov     \reg_tmp_addr,     %esp

        # The local label magic with "1b", "1f" etc. is documented here:
        # https://sourceware.org/binutils/docs/as/Symbol-Names.html

        # Relative call to local label "1". This puses %eip of the next
        # instruction onto the stack.
        call    1f
    1:  # After the call, the stack contains the old eip (which points to
        # runtime address of local symbol "1"). We then pop the eip from the
        # stack into register %edx.
        pop     %edx

        # We substract the link address of label "1" from the instruction
        # pointer in %edx. %eax now contains the offset between link address
        # and load address (=runtime address).
        sub     $1b,            \out_reg

        # restore memory that was used as stack
        mov     %eax,           (\reg_tmp_addr)
.endm

# Calculates the real load address from the link address of a known symbol and stores
# it in the provided register. It relies on that the relocation offset was already set
# in %edx.
#
# The function operates on 32 bit registers as we can only be loaded (and thus relocated) in a
# 32-bit address space.
#
# Input Register:
#  - %edx - must contain the load offset
# Parameters:
#  - link_addr: Link address by its symbol name.
#  - out_reg: Register where the output is stored.
# Outputs:
#  - The register behind the parameter 'out_reg' will contain the result.
# Clobbers: out_reg
.macro M_RESOLVE_RUNTIME_ADDR link_addr out_reg
    mov     $\link_addr,    \out_reg
    add     %edx,           \out_reg
.endm

# Computes the page table offset of an entry by calculating the index into the page table of the
# given level for the given virtual address. The index is multiplied with the size of each entry.
#
# Input Register:
# - None
# Parameters:
#  - level: 1, 2, 3, or 4 (specifies which part of the virtual address is used for indexing).
#  - reg_vaddr_higher: Register containing bits 63..32 of the 64-bit virtual address.
#  - reg_vaddr_lower: Register containing bits 31..0 of the 64-bit virtual address.
#  - reg_out: Register where the output is stored.
#  - reg_tmp: (Optional) Working register that is only required for level 3.
# Outputs:
#   - The register behind the parameter 'reg_out' will contain the result.
# Clobbers: reg_vaddr_higher, reg_vaddr_lower, reg_out, (optional) reg_tmp
.macro M_CALC_PAGE_TABLE_ENTRY_OFFSET level, reg_vaddr_higher, reg_vaddr_lower, reg_out, reg_tmp=0

    # The following code implements that for each level, the 9 relevant bits that
    # are used to index the page table of the given level are stored in the lowest
    #  9 bits of \reg_out.

    .if \level <= 2
        mov \reg_vaddr_lower,   \reg_out
        shr $(PAGE_TABLE_INDEX_BITS * (\level - 1) + PAGE_OFFSET_BITS), \reg_out
    .endif
    .if \level == 3
        # For the third level on x86_64 paging, the index is given by the 2 highest bits
        # of reg_vaddr_lower and the 7 lowest bits of reg_vaddr_higher.

        mov \reg_vaddr_lower,   \reg_out
        shr $30,                \reg_out # select two highest bits
        and $0x3,               \reg_out # zero all others

        # Now, we make sure to append the lowest 7 bits of \reg_vaddr_higher

        mov \reg_vaddr_higher,  \reg_tmp
        shl  $2,                \reg_tmp # shift 2 to the left
        or  \reg_tmp,           \reg_out # combine => index is in lowest 9 bits of \reg_out
    .endif
    .if \level == 4
        mov     \reg_vaddr_higher,  \reg_out
        # skip the 7 bits that were used in level 3
        shr     $7,                 \reg_out
    .endif

    # Now we make sure we only use relevant bits and we calculate the offset into
    # the page table.

    and     $PAGE_TABLE_INDEX_BITMASK,  \reg_out
    imul    $PAGE_TABLE_ENTRY_SIZE,     \reg_out # from index to byte offset
.endm

.set ADD_OFFSET, 1
.set DONT_ADD_OFFSET, 0

# Maps a virtual address 64-bit address for the given page-table level with the provided backing
# storage for the page tables. The backing storage must be between 0 and 2^32 bytes.
#
# Input Register:
# - %edx: Must contain the relocation offset.
# Parameters:
#  - vaddr: Virtual Address to create the mapping for.
#  - level: 1, 2, 3, or 4 (specifies which part of the virtual address is used for indexing).
#  - phys_from: Physical address of the page table where the entry must be written.
#  - phys_to: Physical address where the entry points to. Next page table or (super) page.
#  - entry_flags: Additional entry flags (only bits 11..0 are allowed.)
#  - add_offset: ADD_OFFSET or DONT_ADD_OFFSET. Whether the relocation adjustment must for the
#                lowest 32-bits of the vaddr. Only makes sense if vaddr points to symbol that was
#                relocated in physical memory and the (identity) mapping should reflect that.
# Outputs:
#   - The register behind the parameter 'reg_out' will contain the result.
# Clobbers: phys_from, phys_to, entry_flags, add_offset
.macro M_PAGE_TABLE_WRITE_ENTRY vaddr, level, phys_from, phys_to, entry_flags, add_offset = DONT_ADD_OFFSET
    mov $(\vaddr >> 32 & 0xffffffff),   %eax # upper half of vaddr (63..32)
    mov $(\vaddr & 0xfffff000),         %ecx # lower half of vaddr (31..00)

    # Should the relocation offset be applied?
    #
    # This will only be relevant for the identity mapping of the boot code
    # that was likely relocated.
    .if \add_offset == ADD_OFFSET
    add     %edx,   %ecx
    .endif

    M_CALC_PAGE_TABLE_ENTRY_OFFSET \level, %eax, %ecx, %esi, %edi

    # %eax and %ecx can now be reused; %esi is relevant as it contains the offset
    # %eax: will represent bits 63..32 of page table entry but as our physical
    #       backing memory is below 4G, this is zero.
    # %ecx: will represent bits 31..00 of page table entry

    M_RESOLVE_RUNTIME_ADDR  \phys_to,   %ecx
    or      $(\entry_flags & 0xfff),    %ecx # add flags to entry


    # Write the entry to the table

    M_RESOLVE_RUNTIME_ADDR  \phys_from,    %edi
    # add index to table => %edi is now pointer to first half of the table entry
    add     %esi,   %edi
    mov     %ecx,   (%edi) # write lower half of entry

    # write second part of entry - Not necessary as we are below 4G and this will be zero.
    # add     $4,     %edi   # increase pointer 4 byte (32bit)
    # movl     $0,     (%edi) # write upper half of entry
.endm

# Initializes paging the provided page directory and put the CPU into IA-32e compatibility mode
# (see Intel SDM Vol 1, Chapter 3, Section 3.1.1, "Intel 64 Architecture"). When this code is
# done, it only takes a long jump into 64-bit long mode to execute 64-bit opcodes.
#
# Input registers:
#  - %edx - must contain the load offset
# Parameters:
#  - page_directory: Symbol name of the backing memory for the page directory
# Outputs:
#   - None.
# Clobbers: %eax, %ebp, %cr0, %cr3, %cr4
.macro M_INIT_PAGING page_directory

    # Set top level page table.
    M_RESOLVE_RUNTIME_ADDR \page_directory,   %eax
    mov     %eax,           %cr3

    # Save relocation offset.
    mov     %edx,   %ebp

    mov     $MSR_IA32_EFER_REG,    %ecx
    # reads the lower 32-bits of MSR behind %ecx into %eax. The higher
    # 32-bits are read into %edx.
    rdmsr

    # Restore relocation offset.
    mov     %ebp,   %edx

    # enable 64-bit long mode
    or      $MSR_IA32_EFER_BITS,    %eax
    wrmsr

    # To enable 64-bit paging, the CR4.PAE bit must be set. Unlike for 32-bit paging,
    # the CR4.PSE bit is not required for huge pages.
    mov     %cr4,           %eax
    or      $CR4_PAE,       %eax
    mov     %eax,           %cr4

    # To enable paging, both the CR0.PE and CR0.PG flags must be set.
    mov     %cr0,           %eax
    or      $CR0_BITS,      %eax
    mov     %eax,           %cr0

    # Now, we are in 64-bit compatibility mode* with 4-level paging.
    # We need a far jump/long jump into 64-bit mode next.
.endm

# Prints out a single character via QEMUs debugcon device.
#
# Input registers:
#  - None
# Parameters:
#  - byte (ASCII character) to write
# Outputs:
#   - None.
# Clobbers: %eax, %edx
.macro M_DEBUGCON_PRINT_BYTE byte
    # 0xe9 => I/O port of debugcon device
    # movw: 16 bit
    movw    $0xe9,  %dx
    movb    $\byte, %al
    out     %al,    %dx
.endm
