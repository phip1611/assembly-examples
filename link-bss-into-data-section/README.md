# Link .bss into .data section

This example shows some background on where the GCC places certain data structures in an object file
and how we can link `.bss` into `.data` to guarantee that for each LOAD segment the file size equals
the memory size. A full write-up can be found on [phip1611.de](https://phip1611.de/?s=.bss).

Important files are `link.ld` and `main.c`. Build everything with `$ make`. It will generate
`main.S`.
