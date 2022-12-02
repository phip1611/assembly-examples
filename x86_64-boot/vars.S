# Multiboot v1 magic value
.set MULTIBOOT_MAGIC, 0x2badb002

/* In order to let "GNU as" perform inline calculations with addresses, the symbol
 * must be in name space during compile time. Hence, I have to duplicate a few values
 * here that are also defined in "link.ld". */

.set VAR_BOOT_LINK_ADDR, 0x800000
.set VAR_BASE_LINK_ADDR, 0xffffffff88000000

/* Paging Constants */

# Number how many bits are used to index into a page. This is 12, as 2^12 is 4096,
# i.e., one page.
.set PAGE_OFFSET_BITS, 12
# Number of bits that x86_64 paging uses for indexing page tables.
.set PAGE_TABLE_INDEX_BITS, 9
# Bitmask to select the lowest 9 bits. Must be applied to properly shifted values.
.set PAGE_TABLE_INDEX_BITMASK, 0x1ff
# Size of each page table entry
.set PAGE_TABLE_ENTRY_SIZE, 8

/* CR4 bits */

# CR4 bit Page Address Extension
.set CR4_PAE, (1 << 5)

/* CR0 bits */

# CR0 bit Protection Enable
.set CR0_PE, (1 << 0)
# CR0 bit Write Protect
.set CR0_WP, (1 << 16)
# CR0 bit Paging
.set CR0_PG, (1 << 31)
.set CR0_BITS, (CR0_PE | CR0_WP | CR0_PG)

/* X86 instructions */

# op-code of the "ljmp" instruction.
.set X86_LJMP, 0xea

/*
 * Constants for the IA32_IFER register. The documentation is a little hidden inside the Intel.
 * manuel. These constants can be found in the section "2.2.1 Extended Feature Enable Register"
 * of the "System Architeture Overview" chapter.
 */

# The register address of the MSR_IA32_EFER register.
.set MSR_IA32_EFER_REG, (0xc0000080)
# Bit that turns on 64-bit (IA32e - extended) mode.
.set MSR_IA32_EFER_LME, (1 << 8)
# All MSR_IA32_EFER bits that my kernel for a simple mode 64-bit transition.
.set MSR_IA32_EFER_BITS, (MSR_IA32_EFER_LME)
