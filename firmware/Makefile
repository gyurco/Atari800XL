BASE	= zpu-elf
CC      = $(BASE)-gcc
LD      = $(BASE)-gcc
AS      = $(BASE)-as
CP      = $(BASE)-objcopy
DUMP    = $(BASE)-objdump

# we use mincrt0.s from here
STARTUP_DIR = .

# we fetch ROM prologue / epilogue from here
RTL_DIR = $(ZPUFLEXDIR)/RTL/


BUILD_DIR=zpu_obj

#MINSTARTUP_SRC = mincrt0.s
MINSTARTUP_SRC = mycrt0.s
MINSTARTUP_OBJ = $(patsubst $(STARTUP_DIR)/%.s,$(BUILD_DIR)/%.o,$(MINSTARTUP_SRC))

MAIN_PRJ = JustStartAtari
MAIN_SRC = main.c regs.c freeze.c atari_drive_emulator.c pokey/uart.c hexdump.c printf/printf.c fat/pff_file.c fat/pff.c common/utils.c sd_direct/diskio_mmc.c sd_direct/spi.c sd_direct/mmc.c
#gcc -g -O0 -DLITTLE_ENDIAN test_drive.c atari_drive_emulator.c native/uart.c hexdump.c printf/printf.c fat/pff_file.c fat/pff.c common/utils.c native/diskio_image.c -I. -Iprintf -Ifat -Icommon
#MAIN_SRC = stuff.c
MAIN_OBJ = $(COMMON_OBJ) $(patsubst %.c,$(BUILD_DIR)/%.o,$(MAIN_SRC))

LINKMAP  = ./standalone_simple.ld


# Commandline options for each tool.

#ZPUOPTS= -mno-poppcrel -mno-pushspadd -mno-callpcrel -mno-shortop -mno-neg # No-neg requires bugfixed toolchain
#Include everything -> need to include emulation rom...
ZPUOPTS =
CFLAGS  = -I. -Isd_direct -Iprintf -Ifat -Icommon -c -g -Os $(ZPUOPTS) -DDISABLE_UART_RX

LFLAGS  = -nostartfiles -Wl,--relax -g -Os
#LFLAGS  = -nostartfiles -Os


# Our target.
all: $(BUILD_DIR) $(MAIN_PRJ).bin $(MAIN_PRJ).rpt

clean:
	rm -f $(BUILD_DIR)/*.o *.hex *.elf *.map *.lst *.srec $(MAIN_PRJ).rom *~ */*.o *.bin


# Convert ELF binary to bin file.
%.bin: %.elf
	$(CP) -O binary $< $@

%.rpt: %.elf
	echo >$@ -n "End of code:\t"
	$(DUMP) -x $< | grep >>$@ _romend
	echo >>$@ -n "Start of BSS:\t"
	$(DUMP) -x $< | grep  >>$@ __bss_start__
	echo >>$@ -n "End of BSS:\t"
	$(DUMP) -x $< | grep >>$@ __bss_end__
	cat $@

# Link - this produces an ELF binary.

$(MAIN_PRJ).elf: $(MINSTARTUP_OBJ) $(MAIN_OBJ)
	$(LD) $(LFLAGS) -T $(LINKMAP) -o $@ $+ $(LIBS)

$(BUILD_DIR)/%.o: %.c Makefile
	mkdir -p `dirname $@`
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: %.s
	$(AS) -o $@ $<

$(BUILD_DIR)/%.o: $(STARTUP_DIR)/%.s
	$(AS) -o $@ $<

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

