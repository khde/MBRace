SRC := mbrace.asm
DST := mbrace.img
AS := nasm
ASFLAGS := -f bin

$(DST): $(SRC)
	$(AS) $(ASFLAGS) $(SRC) -o $(DST)
	
run: $(DST)
	# qemu-system-i386 -drive file=$(DST),format=raw,index=0,media=disk
	qemu-system-i386 -fda $(DST)
	
