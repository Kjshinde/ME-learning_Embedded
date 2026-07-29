ENTRY(_start)

MEMORY
{
    /* Internal SRAM 0 - instruction bus, writable, code goes here             */
    /* Ref: ESP32 TRM §3.3 Table 1 - Internal SRAM 0 (instruction bus)        */
    sram0 (rwx) : ORIGIN = 0x40070000, LENGTH = 0x10000   /* 64KB  */

    /* Internal SRAM 1 - instruction bus, writable, additional code space      */
    /* Ref: ESP32 TRM §3.3 Table 1 - Internal SRAM 1 (instruction bus)        */
    sram1 (rwx) : ORIGIN = 0x40080000, LENGTH = 0x40000   /* 256KB */

    /* Internal SRAM 1 - data bus, stack and variables                         */
    /* Ref: ESP32 TRM §3.3 Table 1 - Internal SRAM 1 (data bus)               */
    dram  (rw)  : ORIGIN = 0x3FFB0000, LENGTH = 0x50000   /* 320KB */
}

SECTIONS
{
    .text : {
        *(.literal)
        *(.literal.*)
        *(.text)
        *(.text.*)
    } > sram0

    .rodata : {
        *(.rodata)
        *(.rodata.*)
    } > dram

    .data : {
        *(.data)
        *(.data.*)
    } > dram

    .bss : {
        /* _bss_start and _bss_end are used in boot.S to zero this region      */
        /* Ref: GNU LD Manual - Linker Scripts, Builtin Functions              */
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _bss_end = .;
    } > dram
}
