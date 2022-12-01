# Setup 32-bit Paging from a Relocated Kernel

This code example sets up paging from a kernel that is initially in 32-bit mode without paging.
Please note that 32-bit paging is different from 32-bit paging with PAE or 64-bit paging.
More info can be found here: <https://phip1611.de/blog/cli-utility-to-calculate-indices-for-page-tables/>

I use a single 4 MiB huge page mapping for this. The kernel itself simulates a relocation of a
bootloader and can cope with that. Please head to `main.S` for all the details.
