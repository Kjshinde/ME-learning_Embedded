CROSS   = aarch64-elf
CC      = $(CROSS)-gcc
AS      = $(CROSS)-gcc
LD      = $(CROSS)-ld
OBJCOPY = $(CROSS)-objcopy

SHARED   = ../../shared/rpi
BOOT     = $(SHARED)/boot.S
LDSCRIPT = $(SHARED)/linker.ld

CFLAGS  = -nostdlib -nostartfiles -ffreestanding -O0 -g
LDFLAGS = -T $(LDSCRIPT)

OBJS    = boot.o main.o
TARGET  = uart.elf
IMG     = kernel8.img

all: $(IMG)

$(IMG): $(TARGET)
	$(OBJCOPY) -O binary $< $@

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

boot.o: $(BOOT)
	$(AS) $(CFLAGS) -c -o $@ $<

main.o: src/main.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET) $(IMG)

run:
	qemu-system-aarch64 \
		-machine raspi3b \
		-cpu cortex-a53 \
		-nographic \
		-serial mon:stdio \
		-kernel $(IMG)

debug:
	qemu-system-aarch64 \
		-machine raspi3b \
		-cpu cortex-a53 \
		-nographic \
		-serial mon:stdio \
		-gdb tcp::1234 -S \
		-kernel $(IMG)