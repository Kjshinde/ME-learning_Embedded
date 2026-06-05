# ME-learning_Embedded — Roadmap & TODO

> **Goal:** Build embedded systems knowledge from first principles.
> No pre-built drivers. No HALs. No magic libraries. Just registers, datasheets, and code.

---

## Hardware on the Bench

| Board | SoC | Architecture | Voltage |
|---|---|---|---|
| Raspberry Pi Zero 2W | BCM2837B0 | ARM Cortex-A53 (64-bit, quad-core) | 3.3V GPIO |
| SparkFun ESP32 Thing | ESP32 (Xtensa LX6) | Dual-core 240 MHz | 3.3V GPIO |

> ✅ Both boards are 3.3V logic — **no level shifter needed** for direct UART wiring.

---

## Phase 1 — UART: RPi Zero 2W ↔ ESP32

### 1.1 — Theory Checkpoint
- [ ] Understand UART framing: start bit → data bits (8) → parity (none) → stop bit(s) (1)
- [ ] Understand baud rate and how the divisor is calculated from a source clock
  - Formula: `Baud Divisor = UART_CLK / (16 × Baud Rate)`
- [ ] Understand difference between **PL011 (full UART)** and **Mini UART** on BCM2837
  - PL011: fixed clock, reliable baud rate, proper FIFO — **prefer this**
  - Mini UART: baud rate slaved to VPU core clock — unreliable without explicit clock lock
- [ ] Understand the ESP32 GPIO matrix — UART TX/RX are not hardwired to pins,
  they are routed through a crossbar switch via `GPIO_FUNCn_OUT_SEL_CFG` registers

---

### 1.2 — Hardware Setup
- [ ] **Wiring:**
  ```
  RPi Zero 2W GPIO14 (TXD) ──────► ESP32 GPIO16 (RXD / UART2 RX)
  RPi Zero 2W GPIO15 (RXD) ◄────── ESP32 GPIO17 (TXD / UART2 TX)
  RPi Zero 2W GND           ──────── ESP32 GND
  ```
- [ ] Confirm with a multimeter that both VCC rails are at 3.3V before connecting
- [ ] **Do NOT connect** ESP32 GPIO1 (U0TXD) / GPIO3 (U0RXD) — UART0 is the
  flash/debug port; use UART2 (GPIO16/17) for external comms

---

### 1.3 — Raspberry Pi Zero 2W: UART Driver

#### 1.3a — OS / Boot Config
- [ ] Add `dtoverlay=disable-bt` to `/boot/config.txt` to release PL011 from Bluetooth
  and map it back to GPIO14/15
- [ ] Add `enable_uart=1` to `/boot/config.txt`
- [ ] Remove `console=serial0,115200` from `/boot/cmdline.txt` (free the UART from kernel console)
- [ ] Reboot and verify `/dev/ttyAMA0` is free (not in use by any process)

#### 1.3b — Memory Map (BCM2837B0)
```
Peripheral Base (ARM physical) : 0x3F000000
GPIO Base                       : 0x3F200000
UART0 / PL011 Base              : 0x3F201000
```
> Datasheet calls it `0x7E000000` — that is the VideoCore bus address.
> Add `0x3F000000` for ARM-side physical addresses.

#### 1.3c — Register Map (PL011 UART — offset from 0x3F201000)
```
DR       0x00   Data Register (read = RX, write = TX)
FR       0x18   Flag Register  [bit3=TXFE, bit4=RXFF, bit5=TXFF, bit6=RXFE, bit7=TXBUSY]
IBRD     0x24   Integer Baud Rate Divisor
FBRD     0x28   Fractional Baud Rate Divisor
LCRH     0x2C   Line Control   [bit4=FEN(FIFO), bit5:6=WLEN(word length)]
CR       0x30   Control        [bit0=UARTEN, bit8=TXE, bit9=RXE]
ICR      0x44   Interrupt Clear Register
```

#### 1.3d — GPIO Alternate Function (for UART0 on GPIO14/15)
```
GPIO14 → ALT0 = TXD0
GPIO15 → ALT0 = RXD0

GPFSEL1 register (0x3F200004):
  bits [14:12] control GPIO14  → set to 0b100 (ALT0)
  bits [17:15] control GPIO15  → set to 0b100 (ALT0)
```
- [ ] Write helper: `gpio_set_alt(pin, alt_func)` using GPFSEL registers

#### 1.3e — Baud Rate Calculation (115200, UART_CLK = 48 MHz)
```
DIVINT  = 48000000 / (16 × 115200) = 26
DIVFRAC = ((0.041666... × 64) + 0.5) = 3
→ Write 26 to IBRD, 3 to FBRD
```
- [ ] Write the baud rate calculation as a function parameterized by clock and baud

#### 1.3f — Driver Implementation Steps (userspace via `/dev/mem`)
- [ ] Open `/dev/mem`, `mmap()` the peripheral block starting at `0x3F000000`
- [ ] Implement `uart_init(baud_rate)`:
  - Disable UART (CR = 0)
  - Wait for any ongoing transmission to finish (check FR.TXBUSY)
  - Flush FIFOs (LCRH.FEN = 0)
  - Set IBRD and FBRD
  - Set LCRH: 8-bit word length (WLEN=0b11), enable FIFO (FEN=1)
  - Set CR: enable TX (TXE=1), RX (RXE=1), UART (UARTEN=1)
- [ ] Implement `uart_putc(char c)`:
  - Spin-wait while FR.TXFF (TX FIFO full) is set
  - Write `c` to DR
- [ ] Implement `uart_getc()`:
  - Spin-wait while FR.RXFE (RX FIFO empty) is set
  - Read and return DR
- [ ] Implement `uart_puts(char *s)` wrapping `uart_putc`
- [ ] **Loopback test first**: short GPIO14 → GPIO15 on the Pi and verify echo before
  connecting to the ESP32

---

### 1.4 — ESP32: UART Driver

#### 1.4a — Memory Map (ESP32)
```
UART0 Base : 0x3FF40000   ← USB/flash port, avoid for user comms
UART1 Base : 0x3FF50000   ← GPIO9/10 are flash pins, also avoid
UART2 Base : 0x3FF6E000   ← Use this (GPIO16 RX, GPIO17 TX)
```

#### 1.4b — Register Map (offset from UART base)
```
UART_FIFO_REG         0x00   Read/write data FIFO
UART_STATUS_REG       0x1C   [bits 7:0 = rxfifo_cnt, bits 23:16 = txfifo_cnt]
UART_CONF0_REG        0x20   Parity, stop bits, data bits, loopback
UART_CONF1_REG        0x24   FIFO thresholds
UART_CLKDIV_REG       0x14   Clock divider for baud rate
UART_INT_RAW_REG      0x04   Raw interrupt status
UART_INT_CLR_REG      0x10   Clear interrupts
```

#### 1.4c — GPIO Matrix for UART2
```
IO_MUX_GPIO16_REG  (0x3FF49040) → set MCU_SEL to 0 (GPIO matrix)
IO_MUX_GPIO17_REG  (0x3FF49044) → set MCU_SEL to 0 (GPIO matrix)

GPIO_FUNC198_OUT_SEL_CFG (UART2 TXD signal = 198) → set to GPIO17
GPIO_FUNC16_IN_SEL_CFG   (GPIO16 → UART2 RXD input signal = 23)
```
- [ ] Write `gpio_matrix_out(gpio_num, signal_idx)` helper
- [ ] Write `gpio_matrix_in(gpio_num, signal_idx)` helper

#### 1.4d — Baud Rate Calculation (ESP32, APB clock = 80 MHz)
```
UART_CLKDIV = APB_CLK / Baud = 80,000,000 / 115200 ≈ 694
```
- [ ] Parameterize with a `#define APB_CLK_HZ 80000000`

#### 1.4e — Driver Implementation Steps
- [ ] Implement `uart2_init(baud_rate)`:
  - Reset UART2 via DPORT_PERIP_RST_EN_REG (bit 2 = UART2)
  - Re-enable clock via DPORT_PERIP_CLK_EN_REG
  - Configure GPIO matrix for TX/RX routing
  - Set UART_CLKDIV_REG
  - Set UART_CONF0: 8N1 (8 data, no parity, 1 stop)
- [ ] Implement `uart2_putc(char c)`:
  - Wait while UART_STATUS txfifo_cnt >= 127
  - Write to UART_FIFO_REG
- [ ] Implement `uart2_getc()`:
  - Wait while UART_STATUS rxfifo_cnt == 0
  - Return UART_FIFO_REG
- [ ] **Loopback test first**: connect GPIO16 → GPIO17 on ESP32 and verify

---

### 1.5 — Integration Test
- [ ] RPi sends `"PING\n"`, ESP32 receives and echoes back `"PONG\n"`
- [ ] Stress test: send 1000 bytes continuously, verify zero corruption
- [ ] Define a minimal framing protocol (e.g., `[SOF][LEN][PAYLOAD][CRC8]`) so the
  conversation layer is structured, not raw bytes
- [ ] Implement `crc8()` on both sides and verify end-to-end integrity

---

### 1.6 — Datasheets & Reference
- [ ] Download and bookmark:
  - [BCM2835 Peripherals Datasheet (covers BCM2837 UART)](https://datasheets.raspberrypi.com/bcm2835/bcm2835-peripherals.pdf)
  - [ESP32 Technical Reference Manual](https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf)
    - Chapter 13 (UART), Chapter 4 (GPIO Matrix), Appendix A (register map)
  - [ARM PL011 Datasheet](https://developer.arm.com/documentation/ddi0183/latest)

---

## Phase 2 — More Protocols (queued)

- [ ] **SPI** — RPi as master, ESP32 as slave; manual CS toggling, understand CPOL/CPHA
- [ ] **I²C** — multi-device bus, address arbitration, clock stretching
- [ ] **Custom protocol** — design a simple request/response RPC over UART from Phase 1

---

## Phase 3 — Bare Metal & Toolchain (future)

- [ ] **ESP32 bare metal**
  - Set up `xtensa-esp32-elf` cross-compiler manually (no IDF)
  - Write a minimal linker script, startup `.s` file, and `main.c`
  - Understand ESP32 boot process (ROM bootloader → 2nd stage → app)
  - Write directly to flash via `esptool.py` with a raw binary

- [ ] **RPi Zero 2W bare metal (AArch64)**
  - Set up `aarch64-none-elf` cross-compiler (GCC or LLVM)
  - Write `boot.S`: set up stack, zero BSS, branch to `main()`
  - Write linker script: place `.text` at `0x80000` (where GPU loads the kernel)
  - Build a `kernel8.img`, rename to `kernel8.img` on SD card
  - Bring up UART0 with no OS — your first bare-metal `printf`
  - Understand the GPU/ARM handoff and mailbox interface

- [ ] **Toolchain deep-dive**
  - `gcc` → `as` → `ld` pipeline by hand (no Makefile magic at first)
  - Understand ELF sections, `objdump`, `readelf`, `nm`
  - Write a `Makefile` from scratch after understanding the manual steps
  - Understand `objcopy -O binary` to strip ELF to raw binary

---

## Repo Structure (suggested)

```
ME-learning_Embedded/
├── README.md
├── TODO.md                        ← this file
├── docs/
│   └── datasheets/                ← store PDFs locally
├── phase1_uart/
│   ├── rpi/
│   │   ├── uart.h
│   │   ├── uart.c
│   │   ├── gpio.h
│   │   ├── gpio.c
│   │   └── main.c
│   └── esp32/
│       ├── uart2.h
│       ├── uart2.c
│       ├── gpio_matrix.h
│       ├── gpio_matrix.c
│       └── main.c
├── phase2_spi/
├── phase2_i2c/
└── phase3_bare_metal/
    ├── esp32/
    └── rpi_zero2w/
```

---

## Rules of the Repo

1. **No HAL. No SDK abstractions.** Register access only.
2. Every register write gets a comment citing the datasheet page/section.
3. Every phase gets its own `NOTES.md` with lessons learned and gotchas hit.
4. Loopback test before cross-board test. Always.
5. Commit working code before experimenting further.