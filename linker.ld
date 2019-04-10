ENTRY(_start)

SECTIONS
{
 . = 0xc0009000;
 .text BLOCK(4K) : ALIGN(4K)
 {
  *(.bootloader)
  *(.text)
 }
 .data BLOCK(4K) : ALIGN(4K)
 {
  *(.data)
 }
 .bss BLOCK(4K) : ALIGN(4K)
 {
  *(.bss)
  *(COMMON)
 }
}
