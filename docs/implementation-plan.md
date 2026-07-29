# Implementation Plan

## Repository foundations

- [x] Create QEMU setup guides for ESP32 and BCM2837.
- [x] Add platform startup assembly and linker scripts.
- [x] Organize code by driver type and platform.
- [ ] Add automated formatting, static analysis, and build checks.

## Driver roadmap

- [ ] UART polling transmit and receive
- [ ] GPIO input, output, and alternate functions
- [ ] Timer and delay primitives
- [ ] Interrupt controller support
- [ ] UART interrupt-driven operation
- [ ] SPI controller support
- [ ] I2C controller support
- [ ] Watchdog support
- [ ] DMA support where the platform exposes it

## Completion criteria

A driver is complete when it has a documented public interface, a platform implementation, a minimal example, register references, error handling, and a verified QEMU or hardware test.
Every driver should remain independent of vendor HALs and avoid hidden global state unless the peripheral hardware requires it.
