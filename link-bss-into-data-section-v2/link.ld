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

    .rodata ALIGN(4K) : ALIGN(4K)
    {
        *(.rodata .rodata.*)
    } : ro

    /*
     * Section .bss is usually of type SHT_NOBITS. However, here I want to guarantee that
     * the file size equals the memory size for each LOAD segment. So we make sure that
     * .bss is not the last section in the "rw" segment.
     *
     * More info: https://phip1611.de/blog/how-does-the-file-size-is-smaller-than-mem-size-optimization-work-in-gnu-ld/
     */
    .bss ALIGN(4K) : ALIGN(4K)
    {
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

    /*
     * Section for .data and .bss. i.e., all data that needs read and write permissions.
     */
    .data ALIGN(4K) : ALIGN(4K)
    {
        *(.data .data.*)
    } : rw

    /DISCARD/ :
    {
        *(.note.*)
        *(.comment .comment.*)
        *(.eh_frame*)
        *(.got .got.*)
    }
}
