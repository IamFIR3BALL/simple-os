#!/bin/bash
nasm -f bin boot.asm -o boot.bin
nasm -f elf64 loader.asm -o loader.o
g++ -fno-exceptions -ffreestanding -c /home/kirill/long-os/kmain.c -o /home/kirill/long-os/kmain.o

ld -o kmain.bin -T linker.ld loader.o kmain.o --oformat binary

cat boot.bin kmain.bin > image.bin


#objcopy -R .note -R .comment -S -O binary kernel_main.elf kernel_main.bin

#dd if=/dev/zero of=image.bin bs=512 count=2880
#dd if=boot.bin of=image.bin conv=notrunc
#dd if=kernel_main.bin of=image.bin conv=notrunc bs=512 seek=1

rm ./boot.bin ./kmain.bin ./kmain.o ./loader.o
qemu-system-x86_64 -d guest_errors -m 1G image.bin
