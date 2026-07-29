# ESP-32 Thing QEMU Setup GUIDE
- This readme will guide you through how to setup qemu for esp32 thing:

**Host:** macOS Apple Silicon  
**Emulator:** Espressif QEMU fork (`qemu-system-xtensa -machine esp32`)  
**Source:** https://github.com/espressif/qemu

> Upstream QEMU does not have an `esp32` machine. Espressif maintains
> their own fork which we build from source.

## Prerequisites

- [ ] Homebrew installed - https://brew.sh

## Step 1 - Install build dependencies

[Reference for install and building qemu for mac](https://wiki.qemu.org/Hosts/Mac)

```bash
brew install glib pkg-config pixman gettext ninja meson python3 libgcrypt
brew link gettext --force
```

> `gettext` is keg-only on macOS - Homebrew won't link it automatically,
> the force link makes it findable during the QEMU build.



## Step 2 - Clone Espressif QEMU

Clone outside your repo - this is a build tool, not source code.

```bash
git clone https://github.com/espressif/qemu.git ~/tools/espressif-qemu
cd ~/tools/espressif-qemu
git checkout esp-develop
```


## Step 3 - Configure and build

Build only the Xtensa target to keep the build fast.

```bash
mkdir build && cd build

../configure \
  --target-list=xtensa-softmmu \
  --disable-sdl \
  --disable-gtk \
  --disable-spice \
  --disable-docs \
  --disable-werror

make -j$(sysctl -n hw.ncpu)
```

> **Note:** Always wipe the `build/` directory before re-running configure
> with changed flags. Stale build files from a previous configure run will
> ignore new flags and repeat old errors.
> ```bash
> rm -rf build && mkdir build && cd build
> ```

## For macs
## Step 3.1 - Add to PATH

> NOTE :
>The binary is called qemu-system-xtensa-unsigned. On macOS, QEMU builds an unsigned binary first and expects you to sign it before use. That's a macOS code signing requirement, not a build failure.

```bash
cd ~/tools/espressif-qemu/build

cp qemu-system-xtensa-unsigned qemu-system-xtensa

codesign --sign - --force --entitlements \
  ../pc-bios/keymaps/../../scripts/entitlements.plist \
  qemu-system-xtensa 2>/dev/null || codesign --sign - --force qemu-system-xtensa
```

```bash
echo 'export PATH="$HOME/tools/espressif-qemu/build:$PATH"' >> ~/.zshrc
source ~/.zshrc
```


## Step 4 - Verify

```bash
qemu-system-xtensa --version

qemu-system-xtensa -machine esp32 -nographic -kernel /dev/null
# Exit with Ctrl-A then X
```

> Expected output :- 
> ```bash
>Not initializing SPI Flash
>Warning: both -bios and -kernel arguments specified. Only loading the the -kernel file.
>qemu-system-xtensa: Error: could not load ELF file '/dev/null'
>```

| Line | What it means |
| :--- | :--- |
| Not initializing SPI Flash | ESP32 machine started, no flash image provided |
| expectedWarning: both -bios and -kernel... | Machine has a default ROM, we're overriding with -kernel |
| could not load ELF file '/dev/null' | /dev/null is not a real ELF binary - expected, we passed it intentionally |

>[!warning] Warning
> If you install qemu using brew after going through this guid and installing custome qemu for esp32, then make sure you have added the correct path to the ~/.zshrc file from step 3.1 and rerun `source ~/.zshrc` command.
> Because, homebrew will rewrite the PATH set in step 3.1 so we need to reinitilize the ~/.zshrc file

## Optional - Record the local QEMU revision

```bash
cd ~/tools/espressif-qemu
git log -1 --oneline
```

Record this output in `.local/tool-versions.md`.
The `.local/` directory is excluded from Git.

## Optional - Attaching GDB

Add `-gdb tcp::1235 -S` to your QEMU command:

```bash
~/tools/espressif-qemu/build/qemu-system-xtensa \
  -machine esp32 \
  -nographic \
  -serial mon:stdio \
  -gdb tcp::1235 -S \
  -kernel your_binary.elf
```

| Flag | What it does |
| :--- | :--- |
| `-gdb tcp::1235` | Opens GDB server on port `1235` (use `1235` to avoid conflict with RPi on `1234`) |
| `-S` | Freezes CPU at startup - waits for GDB before running |

> **Note:** Unlike the RPi setup, you cannot test GDB connectivity without a real binary.
> The ESP32 machine exits immediately if no valid ELF is provided - QEMU is gone
> before GDB can connect. This section becomes usable in Phase 1 once you have
> a compiled bare-metal binary.

### Installing xtensa GDB

`brew tap espressif/esp` may ask for GitHub credentials - don't use it.
The compiler toolchain (`xtensa-esp32-elf-gcc` etc.) does **not** include GDB - it is a separate download.

Download GDB directly from Espressif's releases:

```
https://github.com/espressif/binutils-gdb/releases
```

Look for a file with **`xtensa`** in the name for **`aarch64-apple-darwin`**:

```
xtensa-esp-elf-gdb-*-aarch64-apple-darwin*.tar.gz
```

> ⚠️ Do NOT download the `riscv32` version - that is for ESP32-C series chips, not the
> ESP32 Thing (Xtensa LX6).

Extract it:

```bash
cd ~/tools
tar -xf xtensa-esp-elf-gdb-*.tar.gz
```

Add to PATH in `~/.zshrc`:

```bash
export PATH="$HOME/tools/xtensa-esp-elf-gdb/bin:$PATH"
```

```bash
source ~/.zshrc
```

Verify:

```bash
xtensa-esp32-elf-gdb --version
```

Connect in a second terminal:

```bash
xtensa-esp32-elf-gdb your_binary.elf

# Inside GDB:
(gdb) target remote localhost:1235
(gdb) info registers
```


Record the installed GDB version in `.local/tool-versions.md`.
