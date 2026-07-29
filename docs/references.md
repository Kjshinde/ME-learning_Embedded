# Technical References

This page records the authoritative documents used to implement and review the drivers.
Link to official vendor documents instead of committing third-party PDF files unless their licenses explicitly permit redistribution.

## ESP32

| Document | Relevant material | Source |
| :--- | :--- | :--- |
| ESP32 Technical Reference Manual | Memory map, UART, GPIO, SPI, I2C, timers, and interrupts | [Espressif PDF](https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf) |
| ESP32 Series Datasheet | Pins, clocks, electrical limits, and package information | [Espressif PDF](https://www.espressif.com/sites/default/files/documentation/esp32_datasheet_en.pdf) |
| ESP-IDF startup guide | Boot stages and application startup context | [Espressif documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/startup.html) |

## BCM2837 and Raspberry Pi Zero 2 W

| Document | Relevant material | Source |
| :--- | :--- | :--- |
| BCM2835 ARM Peripherals Manual | Peripheral register offsets and programming model | [Raspberry Pi PDF](https://datasheets.raspberrypi.com/bcm2835/bcm2835-peripherals.pdf) |
| Arm Cortex-A53 Technical Reference Manual | Processor registers, reset, exceptions, and memory behavior | [Arm documentation](https://developer.arm.com/documentation/ddi0500/latest) |
| A64 Instruction Set Architecture | AArch64 instruction reference | [Arm documentation](https://developer.arm.com/documentation/ddi0602/latest) |

The BCM2835 peripheral document describes the register offsets used by BCM2837, but BCM2837 uses a peripheral base address of `0x3F000000`.
Record the document revision and exact section beside any implementation whose behavior depends on a specific revision.

## Toolchain

- [GNU linker scripts](https://sourceware.org/binutils/docs/ld/Scripts.html)
- [QEMU documentation](https://www.qemu.org/documentation/)
