CC=gcc
LD=ld
LDFILE=boot.ld
OBJCOPY=objcopy

all: boot.img

# Step 1: gcc call as do: boot.S -> boot.o
boot.o: boot.S
	$(CC) -c boot.S

# Step 2: ld call script boot.ld: boot.o -> boot.elf
boot.elf: boot.o
	$(LD) boot.o -o boot.elf -T$(LDFILE)

# Step 3: objcopy remove nouse section of boot.elf(.pdr, .comment, .note),
#         strip symbols, at last produce boot.bin
boot.bin: boot.elf
	@$(OBJCOPY) -R .pdr -R .comment -R .note -S -O binary boot.elf boot.bin

# Step 4: generate bootable floppy image
boot.img: boot.bin
	@dd if=boot.bin of=boot.img bs=512 count=1 # copy to 1st sector
	@dd if=/dev/zero of=boot.img skip=1 seek=1 bs=512 count=2879 # fill rest with 0s

clean:
	@rm -rf boot.o boot.elf boot.bin boot.img
