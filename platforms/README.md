# Platform Support

Platform directories contain reusable low-level support that is not owned by one peripheral driver.

```text
platforms/
├── bcm2837/
│   └── startup/
└── esp32/
    └── startup/
```

Startup assembly, linker scripts, interrupt entry code, memory maps, and platform-wide clock initialization belong here.
Peripheral register access and driver behavior belong under `drivers/`.
