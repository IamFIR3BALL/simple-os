use64

section .bss
stack_bottom:
align 16
resb 16384*4
stack_top:

section .bootloader
extern kmain
global _start

_start:
    mov rsp, stack_top
    mov qword [0x2000], 0
    call kmain
    jmp $
