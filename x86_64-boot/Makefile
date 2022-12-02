default: kernel

.PHONY: clean default kernel run

CFLAGS=-ffreestanding -nostdlib

kernel:
	gcc $(CFLAGS) -m64 -c -o main.o main.c
	gcc -m64 -c -o boot.o boot.S
	gcc -m64 -c -o static_mem.o static_mem.S
	ld -o kernel -Tlink.ld main.o boot.o static_mem.o
	objcopy -O elf32-i386 kernel kernel.elf32

	# verify that this is a valid Multiboot1 kernel
	grub-file --is-x86-multiboot kernel.elf32

run:
	./run_qemu.sh

clean:
	rm kernel
	rm kernel.elf32
	rm main.o
	rm boot.o
	rm static_mem.o
