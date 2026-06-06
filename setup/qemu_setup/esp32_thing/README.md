# ESP-32 Thing QEMU Setup GUIDE
- This readme will guide you through how to setup qemu for esp32 thing:

**Host:** macOS Apple Silicon  
**Emulator:** Espressif QEMU fork (`qemu-system-xtensa -machine esp32`)  
**Source:** https://github.com/espressif/qemu

> Upstream QEMU does not have an `esp32` machine. Espressif maintains
> their own fork which we build from source.

## Prerequisites

- [ ] Homebrew installed — https://brew.sh

## Step 1 — Install build dependencies

[Reference for install and building qemu for mac](https://wiki.qemu.org/Hosts/Mac)

```bash
brew install glib pkg-config pixman gettext ninja meson python3 libgcrypt
brew link gettext --force
```

> `gettext` is keg-only on macOS — Homebrew won't link it automatically,
> the force link makes it findable during the QEMU build.



## Step 2 — Clone Espressif QEMU

Clone outside your repo — this is a build tool, not source code.

```bash
git clone https://github.com/espressif/qemu.git ~/tools/espressif-qemu
cd ~/tools/espressif-qemu
git checkout esp-develop
```


## Step 3 — Configure and build

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
>My device config
![./my_qemu_esp32_setup]

## For macs
## Step 3.1 — Add to PATH

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


## Step 4 — Verify

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
| could not load ELF file '/dev/null' | /dev/null is not a real ELF binary — expected, we passed it intentionally |

## Optional 
```bash
cd ~/tools/espressif-qemu && git log -1 --oneline
```
The reason we want it is so your README records the exact snapshot of the Espressif QEMU code you built from. esp-develop is a moving branch — someone building it a month from now gets different code. The commit hash pins it:

### My commit hash for library

| Espressif QEMU | 40edccac41 (HEAD -> esp-develop, tag: esp-develop-9.2.2-20260417, origin/esp-develop, origin/HEAD) hw/riscv: fix interrupts being lost or delayed when MIE=0 on the ESP32-C3 |
| :-- | :-- |
