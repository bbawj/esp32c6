OUTPUT_ARCH( "riscv" )
ENTRY( _start )

INCLUDE esp32c6-rom.ld

/* These lengths can be adjusted, if necessary: */
bootloader_usable_dram_end = 0x4087c610;
bootloader_iram_seg_len = 0x2500;
bootloader_dram_seg_len = 0x5000;
bootloader_stack_overhead = 0x2000; /* For safety margin between bootloader data section and startup stacks */
bootloader_dram_seg_end = bootloader_usable_dram_end - bootloader_stack_overhead;
bootloader_dram_seg_start =  bootloader_dram_seg_end - bootloader_dram_seg_len;
bootloader_iram_seg_start = bootloader_dram_seg_start - bootloader_iram_seg_len;

MEMORY
{
  flash (RWX): org = bootloader_iram_seg_start, len = bootloader_iram_seg_len
  dram_seg (RW) : org = bootloader_dram_seg_start, len = bootloader_dram_seg_len
}

SECTIONS
{
  magic = 0xaedb041d;
  /*
   * ensure that entry.S / _entry is at 0x80000000,
   * where qemu's -kernel jumps.
   */
  .text : {
    . = ALIGN (16);
    LONG(0)
    LONG(magic)
    *(.entry.text)
    *(.init)
    *(.text .text.*)
    /* . = ALIGN(0x1000); */
    . += 16;
    PROVIDE(etext = .);
  } > flash

  .rodata : {
    . = ALIGN(16);
    *(.srodata .srodata.*) /* do not need to distinguish this from .rodata */
    . = ALIGN(16);
    *(.rodata .rodata.*)
  } > dram_seg

  .data : {
    . = ALIGN(16);
    *(.sdata .sdata.*) /* do not need to distinguish this from .data */
    . = ALIGN(16);
    *(.data .data.*)
  } > dram_seg

  .bss : {
    . = ALIGN(16);
    *(.sbss .sbss.*) /* do not need to distinguish this from .bss */
    . = ALIGN(16);
    *(.bss .bss.*)
  } > dram_seg

  PROVIDE(end = .);
}

