SRC=pms2.asm
BIN=$(subst .asm,.com,$(SRC))

.PHONY: everything

# use "sudo" run this
# er... umount busy emerged...
everything: $(BIN)
	# pm.img(1.44) must be formated first!
	sudo mount -o loop pm.img /tmp/floppy/; \
	sudo cp $(BIN) /tmp/floppy/ -v; \
	sudo umount /tmp/floppy/

$(BIN): $(SRC)
	nasm $< -o $@

clean:
	rm -rf $(BIN)
