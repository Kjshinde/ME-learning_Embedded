# Raspberry Pi Zero 2W QEMU Setup Guide

- This readme will guide you through how to setup QEMU for the Raspberry Pi Zero 2W (BCM2837B0, Cortex-A53)

**Host:** macOS Apple Silicon  
**Emulator:** Upstream QEMU (`qemu-system-aarch64 -machine raspi3b`)  
**Source:** https://www.qemu.org

> Unlike the ESP32 setup, the RPi Zero 2W's SoC (BCM2837B0, Cortex-A53) is supported by
> **upstream QEMU** via the `raspi3b` machine - no custom fork or build from source required.

---

## Prerequisites

- [ ] Homebrew installed - https://brew.sh
- [ ] `aarch64-elf-gcc` cross-compiler (installed in Step 3)

---

## Step 1 - Install QEMU (upstream)

```bash
brew install qemu
```

Verify the AArch64 target is present:

```bash
qemu-system-aarch64 --version
```

> Expected output:
> ```
> QEMU emulator version 9.x.x
> Copyright (c) 2003-2024 Fabrice Bellard and the QEMU Project developers
> ```

| What it means |
| :--- |
| No build step needed - Homebrew ships upstream QEMU with `aarch64-softmmu` included |
| This is the key difference from the ESP32 setup, which required a custom Espressif fork |

---

## Step 2 - Install the AArch64 bare-metal toolchain

You need a cross-compiler that targets bare-metal AArch64 (no OS, no libc).

```bash
brew install aarch64-elf-gcc aarch64-elf-binutils
```

Verify:

```bash
aarch64-elf-gcc --version
aarch64-elf-objcopy --version
```

> This gives you:
> - `aarch64-elf-gcc` - compiler
> - `aarch64-elf-ld` - linker
> - `aarch64-elf-objcopy` - ELF → raw binary conversion
> - `aarch64-elf-objdump` - disassembly and inspection

---

Here's the updated Step 3 onwards - drop this straight into your README:

---

## Step 3 - Verify the machine boots

```bash
qemu-system-aarch64 \
  -machine raspi3b \
  -cpu cortex-a53 \
  -nographic \
  -serial mon:stdio \
  -kernel /dev/null
```

> Expected behaviour: terminal **hangs** - this is correct.
> Unlike the ESP32 setup which errors immediately on `/dev/null`, the `raspi3b` machine
> boots successfully and idles waiting for a real binary. A hang means the machine is alive.

To confirm QEMU is actually running, open a second terminal:

```bash
ps aux | grep qemu-system-aarch64
```

If you see the process listed, setup is correct. Exit with **Ctrl-A then X**.

> If Ctrl-A X is unresponsive, kill it from the second terminal:
> ```bash
> pkill qemu-system-aarch64
> ```

| Output | What it means |
| :--- | :--- |
| Terminal hangs + process visible in `ps` | ✅ Machine booted successfully |
| `machine 'raspi3b' not found` | QEMU build missing AArch64 target - reinstall via `brew reinstall qemu` |
| Exits immediately with no output | Unexpected - check `qemu-system-aarch64 --version` |

---

## Optional - Record the local QEMU version

```bash
qemu-system-aarch64 --version
brew info qemu | head -3
```

Record this output in `.local/tool-versions.md`.
The `.local/` directory is excluded from Git.

## Optional - Attaching GDB

Add `-s -S` to your QEMU command:

```bash
qemu-system-aarch64 \
  -machine raspi3b \
  -cpu cortex-a53 \
  -nographic \
  -serial mon:stdio \
  -s -S \
  -kernel /dev/null
```

| Flag | What it does |
| :--- | :--- |
| `-s` | Opens a GDB server on `localhost:1234` |
| `-S` | Freezes CPU at startup - waits for GDB before running |

- How to attache it to some other port
```bash
# RPi - explicit port (same as -s)
qemu-system-aarch64 \
  -machine raspi3b \
  -cpu cortex-a53 \
  -nographic \
  -serial mon:stdio \
  -gdb tcp::1234 -S \
  -kernel kernel8.img
```

Install GDB:

```bash
brew install aarch64-elf-gdb
```

Connect in a second terminal:

```bash
aarch64-elf-gdb

# Inside GDB:
(gdb) target remote localhost:1234
(gdb) info registers
```

> You can test this now with `/dev/null` - the `raspi3b` machine boots and idles,
> giving GDB a window to connect before any binary runs.
