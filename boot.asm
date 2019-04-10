use16
[org 0x7c00]

section .text
    ; initialize cs
    jmp start
start:
    ; initialize ds
    xor ax, ax

    mov ds, ax
    mov ss, ax
    mov es, ax

    mov sp, 0x7f00
    
    ; loading kernel
    xor ax, ax
    mov es, ax
    mov bx, KERNEL ; where we want to store out second stage bootloader
    mov ah, 0x2 ; read function
    ; there is already in dl number of disk
    mov al, 0x8 ; how much sectors we will read
    mov ch, 0x0 ; track(cylinder) number
    mov cl, 0x2 ; from which sector we will read
    mov dh, 0x0 ; head
    int 0x13

    ; open A20 gate
    in al, 0x92
    or al, 2
    out 0x92, al

    cli
    lgdt [GDT32.Pointer]

    ; entering protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp GDT32.Code:init_pm

GDT32:
    .Null: equ $ - GDT32
    dd 0
    dd 0

.Code: equ $ - GDT32
    dw 0xffff ; limit
    dw 0	; base
    db 0	; base
    db 0x9a ; access rights
    db 11001111b ; 4 left - flags, 4 right = limit
    db 0		; base

.Data: equ $ - GDT32
    dw 0xffff
    dw 0
    db 0
    db 0x92
    db 11001111b
    db 0

.Pointer:
    dw $ - GDT32 -1
    dd GDT32

use32

GDT64_DESCRIPTOR equ 1 << 44
GDT64_PRESENT    equ 1 << 47
GDT64_READWRITE  equ 1 << 41
GDT64_EXECUTABLE equ 1 << 43
GDT64_64BIT      equ 1 << 53

GDT64:
	dq 0
	dq GDT64_DESCRIPTOR | GDT64_PRESENT | GDT64_READWRITE | GDT64_EXECUTABLE | GDT64_64BIT
	dq GDT64_DESCRIPTOR | GDT64_PRESENT | GDT64_READWRITE

.Pointer:                    ; The GDT-pointer.
dw $ - GDT64 - 1             ; Limit.
dq GDT64

PML4 equ 0x1000
PDPT equ 0x2000

KERNEL equ 0x9000

PAGE_PRESENT    equ 1 << 0
PAGE_WRITABLE   equ 1 << 1
PAGE_HUGE       equ 1 << 7

init_pm:
    ; init segments
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov eax, PDPT | PAGE_WRITABLE | PAGE_PRESENT
    mov dword [PML4],  eax
    mov dword [PML4 + 4], 0

    ; pointer in p3 table for p2 table
    ; here we are mapping 0x0 first gib
    mov eax, 0x0 | PAGE_HUGE | PAGE_WRITABLE | PAGE_PRESENT
    mov dword [PDPT], eax
    mov dword [PDPT + 4], 0

    mov eax, PML4
	mov cr3, eax

    ; Set CR4.PAE to 1 to enable 64-bit paging
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; Enable 64-bit mode
	; A logical processor uses IA-32e paging if CR0.PG = 1, CR4.PAE = 1, and IA32_EFER.LME = 1. (intel manual: Vol.3A 4.5 IA-32E PAGING)
	mov ecx, 0xc0000080 ; It's the argument for rdmsr following / MSR number of EFER is this constant
	rdmsr               ; Read EFER into eax
	or eax, 1 << 8      ; Set EFER.LME (enable long mode) to 1
	wrmsr

	; set CR0.PE and CR0.PG to 1 to enable paging
	mov eax, cr0
	or eax, 1 << 31
    mov cr0, eax

    lgdt [GDT64.Pointer]
    jmp 0x08:init_lm;
    
    jmp $

use64
init_lm:
    ; init segments
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Map kernel at 0xc0000000 (3 index in PDPT)
    mov rax, 0x0 | PAGE_HUGE | PAGE_WRITABLE | PAGE_PRESENT
    mov qword [PDPT + 8*3], rax

    ; Enabling FPU and SSE
    mov rax, cr0
    and rax, 0xFFFFFFFB       ;Clear the EM flag
    or rax, 0x2               ;Set the MP flag
    mov cr0, rax

    mov rax,cr4

    or rax,0x200
    mov cr4,rax
    mov rax, 0x37F
    FNINIT

    mov rax, 0xc0009000

    jmp rax ; far jump, cause jmp 0xc0009000 will cause relative jump
    jmp $


times 510-($-$$) db 0
dw 0xAA55

