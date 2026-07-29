.section .text
.global _start
.type _start, @function

.literal_position

_start:
    /* Set stack pointer to top of Internal SRAM 1 (data bus), 16-byte aligned */
    /* DRAM: 0x3FFB0000 + 0x50000 - 16 = 0x3FFFFFFC                           */
    /* Ref: ESP32 TRM §3.3 Table 1 - Internal SRAM 1 (data bus)               */
    movi    a0, 0x3FFFFFFC
    mov     sp, a0

    /* Clear BSS section                                                        */
    /* BSS symbols _bss_start and _bss_end are defined in linker.ld            */
    /* Ref: GNU LD Manual - Linker Scripts, Section Data                       */
    movi    a0, _bss_start
    movi    a1, _bss_end
    movi    a2, 0
.bss_loop:
    beq     a0, a1, .bss_done
    s32i    a2, a0, 0
    addi    a0, a0, 4
    j       .bss_loop
.bss_done:

    /* Jump to main                                                             */
    /* call0: bare call, no windowed register context needed yet               */
    /* Ref: Xtensa ISA §4.4.1                                                  */
    call0   main

    /* Spin forever if main returns */
.hang:
    j       .hang
