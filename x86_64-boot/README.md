# Setup 64-bit Paging from a Relocated Kernel

This example is similar to the other example in the repository, but here, the kernel performs a
transition from 32-bit mode without paging to 64-bit mode. There are no intermediate steps.
When the (possibly relocated) assembly boot code is done with the setup and setting up page tables,
it performs a long jump into 64-bit mode. From there, it jumps into code written in a higher level
language. In this example, this is C code.

For simplicity, I create a 2 MiB huge page mapping which covers the whole kernel. The kernel
itself simulates a relocation of a bootloader and can cope with that. Please head to `boot.S` for
all the details.
