# Boot Setup

These guides document the bare minimum startup path needed before driver code can run.
They cover entry points, stack setup, linker scripts, and the small amount of platform boot handling shared by the driver targets.

This project does not currently maintain a custom bootloader implementation.
Boot work stays focused on the minimal processing needed to enter `main()` and exercise bare-metal drivers.

## Platform Guides

- [ESP32 boot setup](./esp32/README.md)
- [BCM2837 boot setup](./bcm2837/README.md)

## References

| Document | URL |
| :--- | :--- |
| ESP32 Technical Reference Manual | https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf |
| ESP-IDF Startup Guide | https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/startup.html |
| BCM2835 ARM Peripherals | https://datasheets.raspberrypi.com/bcm2835/bcm2835-peripherals.pdf |
