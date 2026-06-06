# ME-learning_Embedded

Learning embedded systems from first principles — no HALs, no pre-built drivers.
Direct register access only.

## Hardware
| Board | SoC | Emulated via |
|---|---|---|
| Raspberry Pi Zero 2W | BCM2837B0 (Cortex-A53) | QEMU `raspi3b` |
| SparkFun ESP32 Thing | ESP32 (Xtensa LX6) | Espressif QEMU fork |

## Roadmap
- [ ] Phase 0 — QEMU environment setup (macOS Apple Silicon)
- [ ] Phase 1 — UART: RPi Zero 2W ↔ ESP32
- [ ] Phase 2 — SPI
- [ ] Phase 2 — I²C
- [ ] Phase 3 — Bare metal & toolchain from scratch