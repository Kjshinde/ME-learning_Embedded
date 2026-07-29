# Raspberry Pi Zero 2W - Boot Quick Setup

Bare minimum to get your own C code running on the RPi Zero 2W in QEMU.
No bootloader knowledge required - just enough to set up the stack,
enter `main()`, and start writing drivers.

> For a full understanding of the RPi boot process and writing your own
> bootloader from scratch, see [custom bootloader plan](../../custom-bootloader/README.md)

---

## References

Documents used in this guide - pin these versions so a future reader uses the same source.

| Document | Version | Relevant Sections | Link |
| :--- | :--- | :--- | :--- |
| BCM2835 ARM Peripherals Manual | 2012-02-06 | §1 (Address Map), §13 (UART/PL011) | [PDF](https://datasheets.raspberrypi.com/bcm2835/bcm2835-peripherals.pdf) |
| ARM Cortex-A53 TRM | r0p4 | §4 (Registers), §6 (Reset) | [PDF](https://developer.arm.com/documentation/ddi0500/latest) |
| AArch64 ISA Reference | 2023 | `mrs`, `msr`, `ldr`, `bl`, `wfe` | [Web](https://developer.arm.com/documentation/ddi0602/latest) |
| GNU LD Manual | - | MEMORY command, SECTIONS, linker symbols | [Web](https://sourceware.org/binutils/docs/ld/Scripts.html) |

> The BCM2837B0 (used on RPi Zero 2W) shares the same peripheral map as the BCM2835.
> The BCM2835 peripherals manual is the correct reference for register-level work.
> The peripheral base address on BCM2837 is `0x3F000000`, not `0x20000000` as listed
> in the BCM2835 manual. Register offsets are the same - only the base differs.

---

## What you need to know before writing any code

### Memory map (only what matters right now)

> **Reference:** BCM2835 ARM Peripherals Manual §1.2 - Address Map

| Region | Address Range | What it's for |
| :--- | :--- | :--- |
| RAM | `0x00000000` – `0x3EFFFFFF` | 1GB RAM - code, stack, variables |
| Entry point | `0x80000` | Where QEMU loads and starts your binary |
| Peripherals | `0x3F000000` – `0x3FFFFFFF` | MMIO - UART, SPI, I²C registers |

### Entry point

> **Reference:** AArch64 Exception Model - EL2 reset vector, RPi firmware conventions

The RPi firmware loads your binary at `0x80000` and releases all 4 CPU cores to run
from that address simultaneously. QEMU's `raspi3b` machine replicates this behaviour.
We place `_start` at `0x80000` via the linker script.

### Stack

> **Reference:** AArch64 ISA - SP register, AAPCS64 stack alignment requirement

The CPU has no stack until you set one up. `_start` must set SP before any function
call or local variable. We grow the stack **downward from `0x80000`** - safe because
nothing is mapped below the entry point in RAM:

```
SP = 0x80000   (grows down into free RAM, 16-byte aligned per AAPCS64)
```

### Core parking

> **Reference:** ARM Cortex-A53 TRM §4.3 - MPIDR_EL1 register, Aff0 field

The BCM2837 is quad-core - all 4 cores start simultaneously. Only core 0 should run
until you explicitly need the others. We read `mpidr_el1`, check the Aff0 field (bits
[7:0]) and park any core that is not core 0 using `wfe` (Wait For Event).

---

## Project structure

The startup files are shared by every BCM2837 driver and remain separate from the UART implementation.

```text
platforms/bcm2837/startup/
├── boot.S
└── linker.ld

drivers/uart/bcm2837/
├── src/
│   └── main.c
├── Makefile
└── README.md
```

Run `make -C drivers/uart/bcm2837` from the repository root.

---

## Step 1 - Entry point, core parking, and stack setup

> **Reference:**
> - `mrs` - AArch64 ISA: Move to System Register
> - `mpidr_el1` - Cortex-A53 TRM §4.3: Multiprocessor Affinity Register
> - `cbnz` - AArch64 ISA: Compare and Branch if Non-Zero
> - `ldr` - AArch64 ISA: Load Register (literal)
> - `bl` - AArch64 ISA: Branch with Link (call)
> - `wfe` - AArch64 ISA: Wait For Event (low-power core park)

**`platforms/bcm2837/startup/boot.S`**

```asm
.section ".text.boot"
.global _start

_start:
    /* Park cores 1-3                                                        */
    /* mpidr_el1 bits [7:0] = Aff0 = core number                            */
    /* Ref: Cortex-A53 TRM §4.3 - MPIDR_EL1                                */
    mrs     x0, mpidr_el1
    and     x0, x0, #0xFF
    cbnz    x0, .park           /* non-zero core → park                     */

    /* Set stack pointer - grows down from entry point                       */
    /* Ref: BCM2835 Peripherals §1.2 - RAM starts at 0x00000000             */
    ldr     x0, =0x80000
    mov     sp, x0

    /* Clear BSS                                                             */
    /* _bss_start and _bss_end are defined in linker.ld                     */
    /* Ref: GNU LD Manual - Linker Scripts, Builtin Functions               */
    ldr     x0, =_bss_start
    ldr     x1, =_bss_end
    mov     x2, #0
.bss_loop:
    cmp     x0, x1
    beq     .bss_done
    str     x2, [x0], #8       /* store 0, post-increment by 8 bytes        */
    b       .bss_loop
.bss_done:

    /* Jump to main                                                          */
    /* bl: Branch with Link - stores return address in x30 (LR)             */
    bl      main

    /* Spin forever if main returns */
.hang:
    b       .hang

    /* Park non-zero cores using WFE (Wait For Event - low power idle)      */
    /* Ref: AArch64 ISA - WFE instruction                                   */
.park:
    wfe
    b       .park
```

---

## Step 2 - Linker script

> **Reference:** GNU LD Manual - [MEMORY command](https://sourceware.org/binutils/docs/ld/MEMORY.html),
> [SECTIONS command](https://sourceware.org/binutils/docs/ld/SECTIONS.html)
> Cross-check entry point against RPi AArch64 firmware conventions (`0x80000`).

**`platforms/bcm2837/startup/linker.ld`**

```ld
ENTRY(_start)

SECTIONS
{
    . = 0x80000;                /* RPi AArch64 entry point                  */
                                /* Ref: RPi firmware conventions            */

    .text : {
        *(.text.boot)           /* boot.S must come first                   */
        *(.text)
        *(.text.*)
    }

    .rodata : {
        *(.rodata)
        *(.rodata.*)
    }

    .data : {
        *(.data)
        *(.data.*)
    }

    .bss : {
        /* _bss_start and _bss_end used in boot.S to zero this region       */
        /* Ref: GNU LD Manual - Linker Scripts, Builtin Functions           */
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _bss_end = .;
    }
}
```

> `.text.boot` is listed first to guarantee `_start` lands exactly at `0x80000`.
> If it ends up anywhere else the binary will not run.
>
> Unlike the ESP32 linker script, there is no `.literal` section needed here -
> that is a Xtensa-specific requirement and does not apply to AArch64.

---

## Step 3 - Minimal main

**`src/main.c`**

```c
void main(void)
{
    /* UART driver code goes here */
    while (1);
}
```

---

## Step 4 - Makefile

The [BCM2837 UART Makefile](../../../drivers/uart/bcm2837/Makefile) compiles the shared BCM2837 startup code, the UART example, and the raw kernel image.

Run it from the repository root:

```bash
make -C drivers/uart/bcm2837
```

---

## Step 5 - Build and run

```bash
make -C drivers/uart/bcm2837
make -C drivers/uart/bcm2837 run
make -C drivers/uart/bcm2837 debug
```

Exit QEMU with **Ctrl-A then X**.

> If Ctrl-A X is unresponsive, kill from a second terminal:
> ```bash
> pkill qemu-system-aarch64
> ```

---

## Step 6 - Verify in GDB

In a second terminal while `make debug` is running:

```bash
aarch64-elf-gdb uart.elf
(gdb) target remote localhost:1234
(gdb) info registers        # confirm SP = 0x80000
(gdb) x/4i 0x80000          # confirm _start is at entry point
(gdb) break main
(gdb) continue              # should hit breakpoint in main
```

| What to check | Expected |
| :--- | :--- |
| `SP` register | `0x80000` |
| `PC` at entry | `0x80000` |
| Hits `main` breakpoint | ✅ boot setup is correct |

---

## Key differences from ESP32 boot setup

| | ESP32 (Xtensa LX6) | RPi Zero 2W (Cortex-A53) |
| :--- | :--- | :--- |
| Entry point | `0x40070000` (Internal SRAM 0) | `0x80000` |
| Stack pointer | `0x3FFFFFFC` (top of DRAM) | `0x80000` (grows down) |
| Core parking | Not needed (single core boot) | Required - 4 cores start together |
| Literal pool fix | Yes - `.literal` before `.text` | Not needed - AArch64 has no `l32r` |
| QEMU expects | ELF directly | Raw binary (`kernel8.img`) |
| Extra build step | None | `objcopy -O binary` |
| GDB port | `1235` | `1234` |
| GDB binary | `xtensa-esp32-elf-gdb` | `aarch64-elf-gdb` |

---

## What's next

Boot is set up. Head to the UART driver:
- [`../../../drivers/uart/bcm2837/README.md`](../../../drivers/uart/bcm2837/README.md)

UART peripheral base address you'll need:
- PL011 UART0: `0x3F201000` - registers defined in BCM2835 Peripherals Manual §13

> **Before writing UART code, read:**
> - BCM2835 Peripherals Manual §13.1 - PL011 UART feature list
> - BCM2835 Peripherals Manual §13.4 - Register descriptions (every register offset from `0x3F201000`)
> - ARM PrimeCell UART PL011 TRM - for baud rate divisor calculation
