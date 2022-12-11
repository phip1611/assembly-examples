# Setup 64-bit Paging from a Relocated Kernel

This example is similar to the other example in the repository, but here, the kernel performs a
transition from 32-bit mode without paging to 64-bit mode. There are no intermediate steps.
The kernel is a Multiboot2 kernel and will likely be relocated by a Multiboot2 bootloader. This
example uses GRUB. When the (possibly relocated) assembly boot code is done with the setup and
setting up page tables, it performs a long jump into 64-bit mode. From there, it jumps into code
written in a higher level language. In this example, this is C code.

For simplicity, I create 2 MiB huge page mappings for each load segment.

## Build & Run
- `$ make && make run`
