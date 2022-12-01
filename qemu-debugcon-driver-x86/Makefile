default: kernel

.PHONY: clean default kernel

kernel:
	gcc -m32 -c -o main.o main.S
	ld -o $@ -Tlink.ld main.o

run:
	./run_qemu.sh

clean:
	rm kernel
