/* This linker script specifies the layout of the final ELF file. It contains a simulation of a
   relocation by a bootloader as for the sake of simplicity, this example doesn't use a dedicated
   boot loader. */

/* Symbol comes from main.S */
ENTRY(start)
OUTPUT_FORMAT("elf32-i386")
OUTPUT_ARCH("i386:i386")

/* Program headers. Also called segments. */
PHDRS
{
    /* PT_LOAD FLAGS(x): The flags of an ELF program header/segment. Always 32 bit long, also for
                             64-bit ELFs. Also called "Segment Permissions" in ELF specification or
                             "p_flags". Helps loaders to set the right page table bits. */

    init_asm     PT_LOAD FLAGS(5); /* 0b101 - read + execute */
}

/* Those symbols will land in the global symbol table in the ELF and will also
   be available in the assembly source, for example. */

/* Link address of code. For example, relevant for absolute addressing. */
BOOT_LINK_ADDR = 8M;
/* Hint for the boot loader where to load us. "PhysAddr" in readelf. */
BOOT_LOAD_ADDR = 4M;

SECTIONS {

    /*
     * Load address != Link address is the simple variant of simulating a relocation
     * by a bootloader. For more info about the syntax, see
     * https://sourceware.org/binutils/docs/ld/Output-Section-Attributes.html
     */
    .init_asm BOOT_LINK_ADDR : AT(BOOT_LOAD_ADDR) ALIGN(4K)
    {
        *(.init_asm)
    } : init_asm

    /DISCARD/ :
    {
        *(.note.*)
        *(.eh_frame*)
        *(.got*)
    }

}
