CROSS   = xtensa-esp32-elf
CC      = $(CROSS)-gcc
AS      = $(CROSS)-gcc
LD      = $(CROSS)-ld
OBJCOPY = $(CROSS)-objcopy

SHARED  = ../../shared/esp32
BOOT    = $(SHARED)/boot.S
LDSCRIPT = $(SHARED)/linker.ld

CFLAGS  = -nostdlib -nostartfiles -ffreestanding -O0 -g
LDFLAGS = -T $(LDSCRIPT)

OBJS    = boot.o main.o

TARGET  = uart.elf

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^
	
boot.o: $(BOOT)
	$(AS) $(CFLAGS) -c -o $@ $<

main.o: src/main.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET)

run:
	~/tools/espressif-qemu/build/qemu-system-xtensa \
		-machine esp32 \
		-nographic \
		-serial mon:stdio \
		-kernel $(TARGET)

debug:
	~/tools/espressif-qemu/build/qemu-system-xtensa \
		-machine esp32 \
		-nographic \
		-serial mon:stdio \
		-gdb tcp::1235 -S \
		-kernel $(TARGET)