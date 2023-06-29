// Disable rust standard library: will not work for several reasons:
//   1) the minimal Rust runtime is not there (similar to crt0 for C programs)
//   2) we write Kernel code, but standard lib makes syscalls and is meant for userland programs
#![no_std]
#![no_main]
#![feature(const_mut_refs)]
#![feature(panic_info_message)]
#![deny(missing_debug_implementations)]

use crate::debugcon::Printer;
use core::fmt::Write;
use core::mem::size_of;
use core::panic::PanicInfo;
use multiboot2::{BootInformation, BootInformationHeader};

mod asm;
mod global_alloc;

const EXPECTED_LOAD_ADDR: u64 = 0x800000;

#[no_mangle]
extern "C" fn kernel_entry(load_addr: u64, multiboot2_info: u64) -> ! {
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
    writeln!(
        Printer,
        "Multiboot2 boot info @ {:#x}",
        multiboot2_info as u32
    )
    .unwrap();

    #[derive(Copy, Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
    #[repr(C)]
    pub struct MbiHeader {
        // size is multiple of 8
        total_size: u32,
        _reserved: u32,
        // Followed by the boot information tags.
    }
    // Multiboot info within first 2 MiB (identity mapped as huge page)
    // I assume that GRUB is friendly here. This is no production-ready solution.
    assert!(multiboot2_info <= 0x1ff000);
    let mbi_ptr = multiboot2_info as *const u64 as *const MbiHeader;
    let bytes = unsafe {core::slice::from_raw_parts(mbi_ptr.cast::<u8>(), 32)};
    panic!("{bytes:#x?}"); /*
                        //let mbi = unsafe { BootInformation::load(mbi) }.unwrap();

                        let mbi_raw = unsafe { mbi_ptr.cast::<u8>().add(size_of::<BootInformationHeader>()) };
                        // let mbi_raw_slice = unsafe { core::slice::from_raw_parts(mbi_raw, (mbi.total_size - 4) as usize) };

                        writeln!(Printer, "{:#?}", mbi_raw_slice).unwrap();


                        writeln!(
                            Printer,
                            "Multiboot2 boot info: {:?}",
                            mbi
                        )
                            .unwrap();*/

    loop {}
}

#[panic_handler]
fn panic_handler(info: &PanicInfo) -> ! {
    let _ = write!(
        Printer,
        "PANIC: [{}:{}]: {:?}",
        info.location().map(|l| l.file()).unwrap_or("<unknown>"),
        info.location().map(|l| l.line()).unwrap_or(0),
        info.message().unwrap(),
    );
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
