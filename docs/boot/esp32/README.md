# ESP32 - Boot Quick Setup

Bare minimum to get your own C code running on the ESP32 in QEMU.
No bootloader knowledge required - just enough to set up the stack,
enter `main()`, and start writing drivers.

---

## References

Documents used in this guide - pin these versions so a future reader uses the same source.

| Document | Version | Relevant Sections | Link |
| :--- | :--- | :--- | :--- |
| ESP32 Technical Reference Manual | v5.4 | §2 (System Description), §3.3 (Memory Map), §13 (UART) | [PDF](https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf) |
| ESP32 Datasheet | v3.4 | §3 (Pin Description), §4 (Electrical Characteristics) | [PDF](https://www.espressif.com/sites/default/files/documentation/esp32_datasheet_en.pdf) |
| Xtensa ISA Reference Manual | 2022.8 | §4.4 (call0/ret0), §4.3 (movi), §4.8 (s32i) | [PDF](https://0x04.net/~mwk/doc/xtensa.pdf) |
| ESP-IDF Startup Guide | v5.3.1 | Boot stages, entry point, stack init | [Web](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/startup.html) |
| GNU LD Manual | - | MEMORY command, SECTIONS, linker symbols | [Web](https://sourceware.org/binutils/docs/ld/Scripts.html) |

---

## What you need to know before writing any code

### Memory map (only what matters right now)

> **Reference:** ESP32 TRM §3.3 - Table 1 "Address Mapping"

> ⚠️ **Terminology note:** The TRM uses the term **Internal SRAM**, not "IRAM".
> "IRAM" is shorthand used by ESP-IDF and is not official Espressif terminology.
> The addresses below come directly from TRM §3.3 Table 1.

| TRM Name | Address Range | Bus | What it's for |
| :--- | :--- | :--- | :--- |
| Internal ROM 0 | `0x40000000` – `0x4005FFFF` | Instruction | Boot ROM - Espressif code, **read-only, do not use** |
| Internal SRAM 0 | `0x40070000` – `0x4007FFFF` | Instruction | 64KB - writable, **your code goes here** |
| Internal SRAM 1 | `0x40080000` – `0x400BFFFF` | Instruction | 256KB - writable, additional code space |
| Internal SRAM 1 | `0x3FFB0000` – `0x3FFFFFFF` | Data | 320KB DRAM - **your stack and variables go here** |

> `0x40000000` is Internal ROM 0 - the Espressif boot ROM. It is read-only.
> QEMU does not enforce this protection, so writing to `0x40000000` appears to work
> in emulation but would fail silently on real hardware.
> Always place your code at `0x40070000` (base of Internal SRAM 0).

### Entry point

> **Reference:** ESP-IDF Startup Guide - "Application Startup Flow", first stage

When QEMU loads your ELF, execution starts at the address specified in the ELF header.
We tell the linker to place `_start` at `0x40070000` (base of Internal SRAM 0) -
that becomes the entry point.

### Stack

> **Reference:** ESP32 TRM §3.3 Table 1 - Internal SRAM 1 (data bus) address range

The CPU has no stack until you set one up yourself. The very first thing `_start` must do
is point the stack pointer (`SP`) to the top of DRAM (Internal SRAM 1, data bus):

```
SP = 0x3FFB0000 + 0x50000 - 16 = 0x3FFFFFFC  (top of DRAM, 16-byte aligned)
```

Without this, any function call or local variable will corrupt memory.

---

## Project structure

The startup files are shared by every ESP32 driver and remain separate from the UART implementation.

```text
platforms/esp32/startup/
├── boot.S
└── linker.ld

drivers/uart/esp32/
├── src/
│   └── main.c
├── Makefile
└── README.md
```

Run `make -C drivers/uart/esp32` from the repository root.

---

## Step 1 - Entry point and stack setup

> **Reference:** Xtensa ISA Reference Manual
> - `movi` - §4.3.7: Move Immediate. Loads a signed 12-bit constant into a register.
> - `s32i` - §4.8.3: Store 32-bit. Writes a word to memory at `base + offset`.
> - `beq` / `j` - §4.7.1: Branch if Equal, §4.7.9: Unconditional Jump.
> - `call0` - §4.4.1: Call a function without using the register window mechanism. `ret0` is its matching return.

**`platforms/esp32/startup/boot.S`**

```asm
.section .text
.global _start
.type _start, @function

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
```

> `call0` is the bare call instruction on Xtensa - no windowed register overhead.
> We use it here because we haven't set up a proper windowed register context yet.
> See Xtensa ISA Reference Manual §4.4.1 for the full call0/ret0 ABI.

---

## Step 2 - Linker script

> **Reference:** GNU LD Manual - [MEMORY command](https://sourceware.org/binutils/docs/ld/MEMORY.html),
> [SECTIONS command](https://sourceware.org/binutils/docs/ld/SECTIONS.html)
> Cross-check region origins and lengths against ESP32 TRM §3.3 Table 1.

**`platforms/esp32/startup/linker.ld`**

```ld
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
```

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

The [ESP32 UART Makefile](../../../drivers/uart/esp32/Makefile) compiles the shared ESP32 startup code and the UART example.

Run it from the repository root:

```bash
make -C drivers/uart/esp32
```

---

## Step 5 - Build and run

```bash
make -C drivers/uart/esp32
make -C drivers/uart/esp32 run
make -C drivers/uart/esp32 debug
```

Exit QEMU with **Ctrl-A then X**.

---

## Step 6 - Verify in GDB

In a second terminal while `make debug` is running:

```bash
xtensa-esp32-elf-gdb uart.elf
(gdb) target remote localhost:1235
(gdb) info registers        # confirm SP = 0x3FFFFFFC
(gdb) x/4i 0x40070000      # confirm _start is at Internal SRAM 0 base
(gdb) break main
(gdb) continue              # should hit breakpoint in main
```

| What to check | Expected |
| :--- | :--- |
| `SP` register | `0x3FFFFFFC` |
| `PC` at entry | `0x40070000` |
| Hits `main` breakpoint | ✅ boot setup is correct |

---

## What's next

Boot is set up. Head to the UART driver:
- [`../../../drivers/uart/esp32/README.md`](../../../drivers/uart/esp32/README.md)

UART peripheral base address you'll need:
- UART0: `0x3FF40000` - registers defined in ESP32 TRM §13.3 "Register Summary"

> **Before writing UART code, read:**
> - ESP32 TRM §13.1 - UART feature list and functional description
> - ESP32 TRM §13.2 - UART functional description (baud rate clock, FIFO)
> - ESP32 TRM §13.3 - Register summary (every register offset from `0x3FF40000`)
