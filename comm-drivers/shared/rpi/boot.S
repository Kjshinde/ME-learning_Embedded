.section .text.boot
.global _start

_start:
    /* Park cores 1-3 — BCM2837 is quad-core, all start simultaneously */
    mrs     x0, mpidr_el1
    and     x0, x0, #0xFF
    cbnz    x0, .park

    /* Set stack pointer — grows down from entry point */
    ldr     x0, =0x80000
    mov     sp, x0

    /* Clear BSS */
    ldr     x0, =_bss_start
    ldr     x1, =_bss_end
    mov     x2, #0
.bss_loop:
    cmp     x0, x1
    beq     .bss_done
    str     x2, [x0], #8
    b       .bss_loop
.bss_done:

    bl      main

.hang:
    b       .hang

.park:
    wfe
    b       .park
