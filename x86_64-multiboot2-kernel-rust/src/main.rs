// Disable rust standard library: will not work for several reasons:
//   1) the minimal Rust runtime is not there (similar to crt0 for C programs)
//   2) we write Kernel code, but standard lib makes syscalls and is meant for userland programs
#![no_std]
#![no_main]
#![deny(missing_debug_implementations)]

use crate::debugcon::Printer;
use core::fmt::Write;
use core::panic::PanicInfo;

mod asm;

const EXPECTED_LOAD_ADDR: u64 = 0x800000;

#[no_mangle]
extern "C" fn kernel_entry(load_addr: u64) -> ! {
    writeln!(Printer, "Hello World from Rust Kernel").unwrap();
    writeln!(
        Printer,
        "Expected Load Addr = {:#x} ({}M); Actual Load Addr = {:#x} ({}M)",
        EXPECTED_LOAD_ADDR,
        EXPECTED_LOAD_ADDR / 1024 / 1024,
        load_addr,
        load_addr / 1024 / 1024
    )
    .unwrap();
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
        unsafe { x86::io::outb(QEMU_DEBUGCON_PORT, c) }
    }
}
