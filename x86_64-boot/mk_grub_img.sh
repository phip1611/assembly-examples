#!/usr/bin/env bash
# This script generates a bootimage for the legacy x86 boot flow. It uses GRUB 2 as boot loader
# to bootstrap Hedron.
#
# The ISO can be tested like this:
# `$ qemu-system-x86_64 -boot d -cdrom grub/legacy_x86_boot.img -m 1024 -cpu host -machine q35,accel=kvm:tcg -serial stdio`
set -e
function fn_main() {
    fn_prepare_iso_dir
    fn_make_image
}
function fn_prepare_iso_dir() {
    rm -rf "grub/iso"
    # GRUB expects the config by default at /boot/grub/grub.cfg
    mkdir -p "grub/iso/boot/grub"
    cp "grub.cfg" "grub/iso/boot/grub/grub.cfg"
    cp "kernel" "grub/iso/kernel"
}
function fn_make_image() {
    grub-mkrescue -o "boot.img" "grub/iso"
    echo "boot.img' is the bootable image (legacy x86 boot)"
}
# invoke main function
fn_main
