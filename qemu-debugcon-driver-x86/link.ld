/* This linker script is used instead of the default one so that I have full control over the final
   binary. With some more linker arguments, we probably could also use the default linker script.
 */

/* Symbol comes from main.S */
ENTRY(start)
OUTPUT_FORMAT("elf32-i386")
OUTPUT_ARCH("i386:i386")

/* Program headers. Also called segments. */
PHDRS
{
    init_asm     PT_LOAD;
}

SECTIONS {

    .init_asm 8M :
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
