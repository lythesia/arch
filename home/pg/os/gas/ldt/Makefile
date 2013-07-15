CC=gcc
LD=ld
OBJCOPY=objcopy

TRIM_FLAGS=-R .pdr -R .comment -R .note -S -O binary

LDFILE_BOOT=boot.ld
LDFILE_DOS=dos.ld
LDFLAGS_BOOT=-T$(LDFILE_BOOT)
LDFLAGS_DOS=-T$(LDFILE_DOS)

all: boot.img LOADER.BIN
	@echo '###############################################'
	@echo '# Compiling finished, use "sudo make copy to" #'
	@echo '# copy LOADER.BIN into boot.img               #'
	@echo '###############################################'

boot.bin: boot.S
	$(CC) -c boot.S
	$(LD) boot.o -o boot.elf $(LDFLAGS_BOOT)
	$(OBJCOPY) $(TRIM_FLAGS) boot.elf $@

LOADER.BIN: loader.S
	$(CC) -c loader.S
	$(LD) loader.o -o loader.elf $(LDFLAGS_DOS)
	$(OBJCOPY) $(TRIM_FLAGS) loader.elf $@

boot.img: boot.bin
	@dd if=boot.bin of=boot.img bs=512 count=1
	@dd if=/dev/zero of=boot.img skip=1 seek=1 bs=512 count=2879

copy: boot.img LOADER.BIN
	@mkdir -p /tmp/floppy;\
	mount -o loop boot.img /tmp/floppy/ -o fat=12;\
	cp LOADER.BIN /tmp/floppy/;\
	sleep 3;\
	umount /tmp/floppy;\
	rm -rf /tmp/floppy/;

clean:
	@rm -rf *.o *.elf *.bin *.BIN

distclean: clean
	@rm -rf boot.img
