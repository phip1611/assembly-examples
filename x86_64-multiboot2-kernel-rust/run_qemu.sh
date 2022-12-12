#!/usr/bin/env bash

set -e

#########################################################################
# nice "hack" which make the script work, even if not executed from "./"
DIR=$(dirname "$(realpath "$0")")
cd "$DIR" || exit
#########################################################################

fn_main() {
    fn_start_qemu
}

# Function: Starts QEMU with proper parameters (e.g. local directories will be mapped as volumes into the VM).
fn_start_qemu() {
    QEMU_ARGS=(
        # Disable default devices
        # QEMU by default enables a ton of devices which slow down boot.
        "-nodefaults"

        # required for the monitor (behind CTRL+ALT+2) that can be used to view registers etc.
        # Could not find official documentation for it but the source code tells this:
        # char.c - QemuOpts *qemu_chr_parse_compat(...)
        "-monitor"
        "vc"

        "-boot"
        "d"

        "-cdrom"
        "boot.img"

        # Use a standard VGA for graphics
        "-vga"
        "std"

        # Use a modern machine, with acceleration if possible.
        "-machine"
        "q35" # also works, but slower
        # "q35,accel=kvm:tcg"

        # Allocate some memory
        "-m"
        "16M"

        # https://phip1611.de/blog/how-to-use-qemus-debugcon-feature-and-write-to-a-file/
        "-debugcon"
        "stdio"

        # Add this to debug page faults and other faults.
        # "-d"
        # "int,cpu_reset"

        # now reboot loop on broken code
        "-no-reboot"
    )

    echo "Executing: qemu-system-x86_64 " "${QEMU_ARGS[@]}"
    echo "-------"
    qemu-system-x86_64 "${QEMU_ARGS[@]}"
}

#########################################
# invoke function main
fn_main
