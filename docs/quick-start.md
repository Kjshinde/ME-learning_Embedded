# Quick Start

This guide builds and runs the current UART scaffolding from the repository root.
Complete the relevant [QEMU setup](./setup/README.md) before continuing.

## Build

```bash
make -C drivers/uart/esp32
make -C drivers/uart/bcm2837
```

## Run

```bash
make -C drivers/uart/esp32 run
make -C drivers/uart/bcm2837 run
```

Exit QEMU with `Ctrl-A`, then `X`.

## Debug both platforms

Start each QEMU target in a separate terminal:

```bash
make -C drivers/uart/esp32 debug
make -C drivers/uart/bcm2837 debug
```

Connect GDB from two additional terminals:

```bash
xtensa-esp32-elf-gdb drivers/uart/esp32/uart.elf
(gdb) target remote localhost:1235
```

```bash
aarch64-elf-gdb drivers/uart/bcm2837/uart.elf
(gdb) target remote localhost:1234
```

Always give GDB the ELF file rather than the raw `kernel8.img` image because the ELF contains debugging symbols.

## Target reference

| Property | ESP32 | BCM2837 |
| :--- | :--- | :--- |
| QEMU machine | `esp32` | `raspi3b` |
| GDB port | `1235` | `1234` |
| Entry point | `0x40070000` | `0x80000` |
| UART base | `0x3FF40000` | `0x3F201000` |
| Startup files | `platforms/esp32/startup/` | `platforms/bcm2837/startup/` |

## Detailed startup guides

- [ESP32 startup guide](../bootloader/quick-setup/esp32/README.MD)
- [BCM2837 startup guide](../bootloader/quick-setup/bcm2837/README.md)
