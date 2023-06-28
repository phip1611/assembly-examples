default: kernel

.PHONY: clean default kernel run

kernel:
	cargo build --release

	# verify that this is a valid Multiboot2 kernel
	grub-file --is-x86-multiboot2 target/x86_64-unknown-none/release/kernel

run:
	./mk_grub_img.sh
	./run_qemu.sh

clean:
	rm boot.img
	rm -rf grub
	cargo clean
