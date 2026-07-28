# ME-learning_Embedded

Learning embedded systems from first principles — no HALs, no pre-built drivers.
Direct register access only.

## Hardware
| Board | SoC | Emulated via |
|---|---|---|
| Raspberry Pi Zero 2W | BCM2837B0 (Cortex-A53) | QEMU `raspi3b` |
| SparkFun ESP32 Thing | ESP32 (Xtensa LX6) | Espressif QEMU fork |

## Roadmap
- [x] Phase 0 — QEMU environment setup (macOS Apple Silicon)
- [ESP32 QEMU Setup](./setup/qemu/esp32/README.md)
- [RPi Zero 2W QEMU Setup](./setup/qemu/rpi/README.md)
- [ ] Phase 1 — UART: RPi Zero 2W ↔ ESP32
- [ ] Phase 2 — SPI
- [ ] Phase 2 — I²C
- [ ] Phase 3 — Bare metal & toolchain from scratch
- [ ] Phase 4 - Bootloader

_Planned_ — write a custom bootloader for both platforms from scratch.

_Requires_ understanding of the boot process, memory layout, and ELF loading._

> Important Docs links can be found in [docs/documentation](./docs/documentaion.md)

# Startup
- Refere to the [quick_starup_guide](./quick_startup.md) once the setup is done and would quickly want to get started and start writing code.