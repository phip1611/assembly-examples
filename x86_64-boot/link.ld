/* This linker script specifies the layout of the final ELF file. It contains a simulation of a
   relocation by a bootloader as for the sake of simplicity, this example doesn't use a dedicated
   boot loader. */

/* Symbol comes from main.S */
ENTRY(start)
OUTPUT_FORMAT("elf64-x86-64")
OUTPUT_ARCH("i386:x86-64")

/* Program headers. Also called segments. */
PHDRS
{
    /* PT_LOAD FLAGS(x): The flags of an ELF program header/segment. Always 32 bit long, even for
                         64-bit ELFs. Also called "Segment Permissions" in ELF specification or
                         "p_flags". Helps loaders of ELF files to set the right page table bits. */

    init_asm     PT_LOAD FLAGS(7); /* 0b101 - read + execute */

    kernel_rx    PT_LOAD FLAGS(5); /* 0b101 - read + execute */
    kernel_ro    PT_LOAD FLAGS(4); /* 0b100 - read  */
    kernel_rw    PT_LOAD FLAGS(6); /* 0b110 - read + write */
}

/* Those symbols will land in the global symbol table in the ELF and will also
   be available in the assembly source, for example. */

/* Link address of code. For example, relevant for absolute addressing.
   Attention: This is duplicated in vars.S - keep in sync! */
BOOT_LINK_ADDR = 0x800000; /* 8M */

/* Hint for the boot loader where to load us. "PhysAddr" in readelf. */
BOOT_LOAD_ADDR = 0x800000; /* TODO use relocation again; != 8M to simulate a relocation. */

/* Base link address for kernel code in high address space.
   Attention: This is duplicated in vars.S - keep in sync! */
BASE_LINK_ADDR = 0xffffffff88000000;

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

    /* I ensure that the load address and the link address of the kernel section have the same
       offset from BASE_LINK_ADDR. This allows to use 2 MiB huge page mappings where physical and
       virtual address needs a 2 MiB alignment. */

    TEXT_LINK_ADDRESS = BASE_LINK_ADDR + ALIGN(SIZEOF(.init_asm), 2M);
    TEXT_LOAD_ADDRESS = BOOT_LOAD_ADDR + ALIGN(SIZEOF(.init_asm), 2M);

    /* "ALIGN 4K": Ensure that the offset within the ELF file is page-aligned. This affects the
        "offset" property that readelf shows. */

    .text TEXT_LINK_ADDRESS : AT(TEXT_LOAD_ADDRESS) ALIGN(4K)
    {
        _text_begin = .;

        *(.text .text.*)

        _text_end = .;
    } : kernel_rx

    /* Link address will be increased to next 2M alignment; load address will be increase equally */
    .rodata ALIGN(2M) : ALIGN(4K)
    {
        _rodata_begin = .;

        *(.rodata .rodata.*)

        _rodata_end = .;
    } : kernel_ro

    .data ALIGN(2M) : ALIGN(4K)
    {
        _data_begin = .;

        *(.data .data.*)

        _data_end = .;
    } : kernel_rw

    .bss : /* No more address properties required as they come from .data already */
    {
        _bss_begin = .;

        /* COMMON symbols are also part of .bss. */
        *(COMMON)
        *(.bss .bss.*)

        _bss_end = .;
    } : kernel_rw


    /* Several size properties. The amount of huge pages per section will simplify a correct
       page table mapping in a loop in the boot code. */

    _text_size = _text_end - _text_begin;
    _rodata_size = _rodata_end - _rodata_begin;
    _data_size = _data_end - _data_begin;
    _bss_size = _bss_end - _bss_begin;

    /* Round up division. */
    _text_2mib_pages = (_text_size + (2M - 1)) / 2M;
    _rodata_2mib_pages = (_rodata_size + (2M - 1)) / 2M;
    _data_2mib_pages = (_data_size + (2M - 1)) / 2M;
    _bss_2mib_pages = (_bss_size + (2M - 1)) / 2M;

    KERNEL_RX_LOAD_ADDR = LOADADDR(.text);
    KERNEL_RO_LOAD_ADDR = LOADADDR(.rodata);
    KERNEL_RW_LOAD_ADDR = LOADADDR(.data);

    /DISCARD/ :
    {
        *(.note.*)
        *(.comment .comment.*)
        *(.eh_frame*)
        *(.got .got.*)
    }

}
