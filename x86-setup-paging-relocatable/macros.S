# Helper macros.

.include "../common/macros.S"

# Computes the page table offset where a page table entry needs to be written to. This
# depends on the level of the page table and the given virtual address.s
#
# Inputs:
#  - level: 1 or 2 (specifies which part of the virtual address is used).
#  - vaddr_reg: Register that contains the virtual address used for this calculation.
#  - out_reg: Register where the output is stored.
# Outputs:
#   - The register behind the parameter 'out_reg' will contain the result.
# Clobbers: out_reg
.macro M_CALC_PAGE_TABLE_ENTRY_INDEX level, vaddr_reg, out_reg
    mov     \vaddr_reg,     \out_reg
    # We bit-shift the virtual address to the right.
    # * 9 as each level is indexed by 9 bits (with x86_64 4 level paging)
    # + 12 used as index into the page
    shr     $((\level - 1) * 10 + 12),   \out_reg
    # Now we select the 10 bits which are the index into the page table of the selected level.
    and     $0x3ff,         \out_reg
    imul    $4,             \out_reg # index * 4 as each entry is 4 byte long with 32-bit paging
.endm

# Creates a mapping for a virtual address in the page table for the given level.
#
# Parameters:
#  - level: 1 or 2
#  - vaddr_reg: Register that contains the virtual address used for the mapping.
#  - phys_src_table: Symbol name of backing storage for source table (the one that needs an entry).
#  - phys_dest: Symbol name of physical memory to point to. Next table or (super) page.
#  - entry_flags: page table entry flags (huge page, permission bits, ...) (bits 11..0)
# Clobbers: %eax, %ebp, %ecx
.macro M_CREATE_VADDR_PAGE_TABLE_MAPPING level, vaddr_reg, phys_src_table, phys_dest, entry_flags
    # calculate index into the phys_src_table
    M_CALC_PAGE_TABLE_ENTRY_INDEX    \level,  \vaddr_reg,    %ebp

    /* Create 32-bit page table entry in %eax. */
    M_CREATE_PAGE_TABLE_ENTRY  %eax,    \entry_flags
    # save entry in %ecx
    mov     %eax,   %ecx

    /* Write 32-bit page table entry. */
    M_RESOLVE_RUNTIME_ADDR  \phys_src_table
    # write %ecx to table behind %eax at offset %ebp
    M_WRITE_PAGE_TABLE_ENTRY %ecx, %eax, %ebp
.endm

# Wrapper around debugcon_print_string_until_null_32bit that prints a null-terminated string
# that ensures that no registers are clobbered.
#
# Input registers:
#  - None
# Parameters:
#  - string: Symbol name of null-terminated string.
# Outputs:
#   - None.
# Clobbers: %eax, %ecx
.macro M_DEBUGCON_PRINT string
    push %eax
    push %ecx
    push %edx
    M_RESOLVE_RUNTIME_ADDR  \string
    call debugcon_print_string_until_null
    pop %edx
    pop %ecx
    pop %eax
.endm

# CR0 bit Protection Enable
.set CR0_PE, (1 << 0)
# CR0 bit Write Protect
.set CR0_WP, (1 << 16)
# CR0 bit Paging
.set CR0_PG, (1 << 31)

.set CR0_BITS, (CR0_PE | CR0_WP | CR0_PG)

# CR4 bit Page Size Extension (PSE)
.set CR4_PAE, (1 << 4)

# Initializes paging with huge page support for the provided page directory.
#
# Input registers:
#  - %edx - Must contain the load offset.
# Parameters:
#  - page_directory: Symbol name of the backing memory for the page directory
# Outputs:
#   - None.
# Clobbers: %eax, %cr0, %cr3, %cr4
.macro M_INIT_PAGING page_directory
    M_RESOLVE_RUNTIME_ADDR \page_directory
    mov     %eax,           %cr3

    # Enable huge page support for 32-bit paging.
    # This is only required for 32-bit paging. 32-bit paging with PAE and 64-bit paging have
    # huge table support out of the box.
    mov     %cr4,           %eax
    or      $CR4_PAE,       %eax    # set bit 4 (Page Size Extension (PSE))
    mov     %eax,           %cr4

    # Set write protect (WP), paging (PG) and protection (PE) bits in cr0.
    # To enable paging, both the PE and PG flags must be set. WP is useful so
    # that the kernel can not write into read-only pages. We want the kernel to
    # fail in that case.
    mov     %cr0,           %eax
    or      $CR0_BITS,      %eax
    mov     %eax,           %cr0
.endm
