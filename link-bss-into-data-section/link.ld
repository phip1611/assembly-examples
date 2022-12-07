ENTRY(start)

/* Program headers. Also called segments. */
PHDRS
{
    /*
     * PT_LOAD FLAGS(x):
     *   The flags of an ELF program header/segment. Always 32 bit long, even for
     *   64-bit ELFs. Also called "Segment Permissions" in ELF specification or
     *   "p_flags". Helps loaders of ELF files to set the right page table bits.
     */

    rx    PT_LOAD FLAGS(5); /* 0b101 - read + execute */
    ro    PT_LOAD FLAGS(4); /* 0b100 - read  */
    rw    PT_LOAD FLAGS(6); /* 0b110 - read + write */
}

SECTIONS {

    .text 4M : ALIGN(4K)
    {
        *(.text .text.*)
    } : rx

    /*
     * ALIGN(4K):
     *   The linker parses this file from top to bottom and automatically increases link
     *   and load addresses.
     */
    .rodata ALIGN(4K) : ALIGN(4K)
    {
        *(.rodata .rodata.*)
    } : ro

    /*
     * Section for .data and .bss. i.e., all data that needs read and write permissions.
     */
    .data ALIGN(4K) : ALIGN(4K)
    {
        *(.data .data.*)

        /*
         * We place the .bss section in .data as .bss is of type SHT_NOBITS by default but
         * we need its symbols to be in a section of type SHT_PROGBITS so that FILESIZE
         * equals MEMSIZE for each LOAD segment.
         */

        /*
         * The .bss output section of an ELF executable (or shared lib) actually consists
         * of symbols that are either in the COMMON section or the `.bss` section of
         * object files.
         *
         * This can also be verified by looking at the standard linker script for Linux
         * programs.
         */

        *(COMMON)
        *(.bss .bss.*)
    } : rw

    /DISCARD/ :
    {
        *(.note.*)
        *(.comment .comment.*)
        *(.eh_frame*)
        *(.got .got.*)
    }
}
