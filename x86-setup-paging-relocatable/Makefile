default: kernel

.PHONY: clean default kernel run

kernel:
	gcc -m32 -ggdb -c -o main.o 		main.S
	gcc -m32 -ggdb -c -o debugcon.o 	debugcon.S
	gcc -m32 -ggdb -c -o strings.o 	strings.S
	ld -o kernel -Tlink.ld main.o debugcon.o strings.o

run:
	./run_qemu.sh

clean:
	rm kernel
	rm main.o
	rm debugcon.o
	rm strings.o
