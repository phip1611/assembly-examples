default: main

.PHONY: clean default main

CFLAGS=-ffreestanding -nostdlib

main:
	gcc $(CFLAGS) -S -o main.S ../link-bss-into-data-section/main.c
	as -o main.o main.S
	# -M: print verbose information where the linker puts things to
	ld -M -o main -Tlink.ld main.o

clean:
	rm main
	rm main.S
	rm main.o
