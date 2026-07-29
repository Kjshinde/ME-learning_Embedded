# Bare Metal Drivers

Bare-metal peripheral drivers built from first principles with direct register access.
The project avoids vendor HALs and prebuilt driver frameworks so each implementation exposes the underlying hardware behavior.

## Supported platforms

| Platform | Board | Architecture | Emulator |
| :--- | :--- | :--- | :--- |
| ESP32 | SparkFun ESP32 Thing | Xtensa LX6 | Espressif QEMU fork |
| BCM2837 | Raspberry Pi Zero 2 W | Arm Cortex-A53 | QEMU `raspi3b` |

## Repository structure

```text
.
├── drivers/                 # Drivers grouped by peripheral type
│   └── uart/
│       ├── bcm2837/
│       └── esp32/
├── platforms/               # Platform startup code and linker scripts
│   ├── bcm2837/
│   │   └── startup/
│   └── esp32/
│       └── startup/
└── docs/                    # Plans, references, setup, and learning guides
    ├── boot/                # Minimal boot setup guides for driver targets
    └── setup/               # Toolchain, emulator, and debugging setup
```

Driver type is the primary grouping so equivalent implementations can be compared across platforms.
Platform-specific startup code remains separate because it is shared by every driver built for that platform.

See [drivers/README.md](./drivers/README.md) for naming and layout conventions.

## Current status

| Area | ESP32 | BCM2837 |
| :--- | :---: | :---: |
| QEMU setup | Complete | Complete |
| Startup and linker scaffolding | Complete | Complete |
| UART driver | In progress | In progress |
| GPIO, SPI, I2C, timers, and interrupts | Planned | Planned |

## Getting started

1. Follow the [setup guide](./docs/setup/README.md) for your platform.
2. Use the [quick-start guide](./docs/quick-start.md) to build, run, or debug the current UART targets.
3. Read the [boot setup guides](./docs/boot/README.md) when you need the minimal startup flow for a driver target.
4. Consult the [technical references](./docs/references.md) before implementing registers.
5. Track the planned work in the [implementation plan](./docs/implementation-plan.md).

