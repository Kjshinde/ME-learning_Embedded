# Driver Organization

Drivers are grouped first by peripheral type and then by platform:

```text
drivers/
├── uart/
│   ├── bcm2837/
│   └── esp32/
├── gpio/
├── spi/
└── i2c/
```

Use lowercase platform identifiers that describe the SoC rather than a particular development board.
Each platform implementation should contain its source, public headers, focused tests, and a minimal example as those components are introduced.

Platform startup assembly and linker scripts belong under `platforms/<platform>/startup/` because they are shared by every driver for that platform.
Do not duplicate startup files inside individual driver directories.
