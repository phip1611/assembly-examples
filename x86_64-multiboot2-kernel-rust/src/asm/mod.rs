core::arch::global_asm!(include_str!("vars.S"), options(att_syntax));
core::arch::global_asm!(include_str!("macros.S"), options(att_syntax));
core::arch::global_asm!(include_str!("boot.S"), options(att_syntax));
core::arch::global_asm!(include_str!("static_mem.S"), options(att_syntax));
