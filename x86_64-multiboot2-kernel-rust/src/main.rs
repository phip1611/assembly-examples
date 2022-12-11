// Disable rust standard library: will not work for several reasons:
//   1) the minimal Rust runtime is not there (similar to crt0 for C programs)
//   2) we write Kernel code, but standard lib makes syscalls and is meant for userland programs
#![no_std]
#![no_main]

#![deny(missing_debug_implementations)]

use core::panic::PanicInfo;
use crate::debugcon::Printer;
use core::fmt::Write;

mod asm;

#[no_mangle]
fn kernel_entry() -> ! {
    write!(Printer, "Hello World from Rust Kernel").unwrap();
    loop {}
}

#[panic_handler]
fn panic_handler(info: &PanicInfo) -> ! {
    write!(Printer, "PANIC: {:#?}", info).unwrap();
    loop {}
}

mod debugcon {
    use super::*;

    const QEMU_DEBUGCON_PORT: u16 = 0xe9;

    pub struct Printer;

    impl core::fmt::Write for Printer {
        fn write_str(&mut self, s: &str) -> core::fmt::Result {
            for byte in s.as_bytes() {
                print_char(*byte);
            }
            Ok(())
        }
    }

    fn print_char(c: u8) {
        unsafe {
            x86::io::outb(QEMU_DEBUGCON_PORT, c)
        }
    }
}
