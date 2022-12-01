# Minimal Driver for QEMU's debugcon-Device Written in x86 Assembly

This repository demonstrates a minimal example on how to write the probably simplest x86 driver
possible. It consists of an assembly file (`main.S`) using GNU Assembler (GAS) syntax and a
corresponding linker script (`link.ld`) necessary to build a bare-metal x86 binary. The resulting
`kernel` binary can be executed by a QEMU VM with the `-kernel` parameter. For minimality and
simplicity, the binary is a
[Multiboot1](https://www.gnu.org/software/grub/manual/multiboot/multiboot.html)-compliant kernel
so that it can easily be bootstraped by QEMU without having to provide an additional bootloader.

## Functionality Of The Driver
The driver targets the "debugcon"-device from QEMU. This device is probably the simplest possible
x86 device one can write a driver for. Some background information can be found in
[this blogpost](https://phip1611.de/blog/how-to-use-qemus-debugcon-feature-and-write-to-a-file/).
The device is accessible through the I/O port `0xe9` and passes bytes to the Virtual Machine Monitor
(i.e., the QEMU VMM). This way, the kernel can print ASCII or UTF-8 to the VMM, for example.

All relevant code is inside `main.S`.

## Terminology
In a real kernel, a driver is a modular component. In here, the driver is just the function that
passes data to the device.

## Build Prerequisites
- GNU Make
- GNU Assembler (part of the GNU Compiler Collection)

## Build and Run
When you execute `$ make && make run` you will see that the driver prints
`Hello World from Assembly Code` to stdout.

## FAQ
### Where can I find more resources?
- **GNU Assembler (ld):** <https://sourceware.org/binutils/docs/as/>
- **GNU Linker (as):** <https://sourceware.org/binutils/docs/ld/>
- **debugcon Device:** <https://phip1611.de/blog/how-to-use-qemus-debugcon-feature-and-write-to-a-file/>
- **Multiboot1:** <https://www.gnu.org/software/grub/manual/multiboot/multiboot.html>
### Why is x86 (32-bit) chosen explicitly?
Just for simplicity. I want to boot the binary as Multiboot1 payload. This is only supported for
32-bit ELF executables by QEMU.
### Can this run on real hardware?
Sure, but you need a bootloader and the code will have no observable effect. The debugcon-device
is only available on QEMU (or the Bochs x86 emulator). However, many real-world x86 chipsets have a
serial device (also called COM1 port). This device is basically an UART_16550-compatible device
accessible via eight I/O ports and can print ASCII data to the outside world. The serial device
needs some very small setup code. You can find it on
[wiki.os-dev.com](https://wiki.osdev.org/Serial_Ports). After the small setup routine, you can also
print data byte by byte to it which is accessible from the outer world. If you manage to do this,
you can get data from that device either by reading from the right pins on the board or by
accessing serial over LAN with Intel AMT.
