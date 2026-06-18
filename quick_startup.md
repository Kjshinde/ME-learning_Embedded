# comm-drivers — Quick Start

Get both machines running so you can focus on writing code.
For full setup details see each platform's boot README.

---

## Build

```bash
# ESP32
cd uart/esp32 && make

# RPi
cd uart/rpi && make
```

---

## Run

```bash
# ESP32
cd uart/esp32 && make run

# RPi
cd uart/rpi && make run
```

Exit either machine with **Ctrl-A then X**.
If unresponsive, kill from a second terminal:

```bash
pkill qemu-system-xtensa       # ESP32
pkill qemu-system-aarch64      # RPi
```

---

## Debug (both at the same time)

**Terminal 1 — ESP32**
```bash
cd uart/esp32 && make debug    # GDB server on port 1235
```

**Terminal 2 — RPi**
```bash
cd uart/rpi && make debug      # GDB server on port 1234
```

**Terminal 3 — ESP32 GDB**
```bash
xtensa-esp32-elf-gdb uart/esp32/uart.elf
(gdb) target remote localhost:1235
(gdb) break main
(gdb) continue
```

**Terminal 4 — RPi GDB**
```bash
aarch64-elf-gdb uart/rpi/uart.elf
(gdb) target remote localhost:1234
(gdb) break main
(gdb) continue
```

> Always pass the `.elf` to GDB, not `kernel8.img` — GDB needs the ELF for symbols.

---

## Quick reference

| | ESP32 | RPi Zero 2W |
| :--- | :--- | :--- |
| QEMU binary | `qemu-system-xtensa` | `qemu-system-aarch64` |
| Machine flag | `-machine esp32` | `-machine raspi3b` |
| GDB port | `1235` | `1234` |
| GDB binary | `xtensa-esp32-elf-gdb` | `aarch64-elf-gdb` |
| Entry point | `0x40070000` | `0x80000` |
| UART base | `0x3FF40000` | `0x3F201000` |
| Shared boot files | `shared/esp32/` | `shared/rpi/` |

---

## Structure

```
comm-drivers/
├── README.md                  ← you are here
├── shared/
│   ├── esp32/
│   │   ├── boot.S
│   │   └── linker.ld
│   └── rpi/
│       ├── boot.S
│       └── linker.ld
├── uart/
│   ├── esp32/
│   │   ├── src/main.c
│   │   └── Makefile
│   └── rpi/
│       ├── src/main.c
│       └── Makefile
├── spi/                       ← planned
└── i2c/                       ← planned
```

---

## Boot setup details

- [ESP32 boot quick setup](../../bootloader/quick_setup/esp32/README.MD)
- [RPi boot quick setup](../../bootloader/quick_setup/raspberrypi/README.MD)