# Strings.

.section .init_asm, "ax"

.global str_hello_world
str_hello_world: .asciz "Hello World. Stack works\!\n"
.global str_paging_init
str_paging_init: .asciz "Paging initialized\!\n"
