.section .init_asm.mem, "ax", @progbits

# Backing storage for the lvl 4 page table.
.align 4096
.global mem_pt_lvl4
mem_pt_lvl4:
.fill 4096, 1, 0

.align 4096
.global mem_pt_lvl3h
mem_pt_lvl3h:
.fill 4096, 1, 0

.align 4096
.global mem_pt_lvl3l
mem_pt_lvl3l:
.fill 4096, 1, 0

.align 4096
.global mem_pt_lvl2h
mem_pt_lvl2h:
.fill 4096, 1, 0

.align 4096
.global mem_pt_lvl2l
mem_pt_lvl2l:
.fill 4096, 1, 0

# Will be placed in high address space.
.bss
.align 0x1000
.fill 0x4000, 1, 0
.global hi_stack_end
hi_stack_end:
