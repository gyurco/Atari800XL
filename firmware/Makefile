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

AEON_LITE_PRJ = AEON_LITE
AEON_LITE_SRC = main_aeon_lite.c regs.c freeze.c joystick.c fileutils.c fileselector.c atari_drive_emulator.c pokey/uart.c hexdump.c printf/printf.c fat/pff_file.c fat/pff.c common/utils.c sd_direct/diskio_mmc.c sd_direct/spi.c sd_direct/mmc2.c de1/dirs.c
AEON_LITE_OBJ = $(patsubst %.c,$(BUILD_DIR)/%.o,$(AEON_LITE_SRC))

DE1_PRJ = DE1
DE1_SRC = main.c regs.c freeze.c joystick.c fileutils.c fileselector.c atari_drive_emulator.c pokey/uart.c hexdump.c printf/printf.c fat/pff_file.c fat/pff.c common/utils.c sd_direct/diskio_mmc.c sd_direct/spi.c sd_direct/mmc2.c de1/dirs.c
DE1_OBJ = $(patsubst %.c,$(BUILD_DIR)/%.o,$(DE1_SRC))

CHAMELEON_PRJ = CHAMELEON
CHAMELEON_SRC = main.c regs.c freeze.c joystick.c fileutils.c fileselector.c atari_drive_emulator.c pokey/uart.c hexdump.c printf/printf.c fat/pff_file.c fat/pff.c common/utils.c sd_direct/diskio_mmc.c sd_direct/spi.c sd_direct/mmc2.c chameleon/dirs.c
CHAMELEON_OBJ = $(patsubst %.c,$(BUILD_DIR)/%.o,$(CHAMELEON_SRC))

MCC_PRJ = MCC216
MCC_SRC = main.c regs.c freeze.c joystick.c fileutils.c fileselector.c atari_drive_emulator.c pokey/uart.c hexdump.c printf/printf.c fat/pff_file.c fat/pff.c common/utils.c sd_direct/diskio_mmc.c sd_direct/spi.c sd_direct/mmc2.c mcc/dirs.c
MCC_OBJ = $(patsubst %.c,$(BUILD_DIR)/%.o,$(MCC_SRC))

MIST_PRJ = MIST
MIST_SRC = main.c regs.c freeze.c joystick.c fileutils.c fileselector.c atari_drive_emulator.c pokey/uart.c hexdump.c printf/printf.c fat/pff_file.c fat/pff.c common/utils.c mist/diskio_sectorrequest.c mist/dirs.c
MIST_OBJ = $(patsubst %.c,$(BUILD_DIR)/%.o,$(MIST_SRC))

LINKMAP  = ./standalone_simple.ld


# Commandline options for each tool.

#ZPUOPTS= -mno-poppcrel -mno-pushspadd -mno-callpcrel -mno-shortop -mno-neg # No-neg requires bugfixed toolchain
#Include everything -> need to include emulation rom...
ZPUOPTS =
CFLAGS  = -I. -Isd_direct -Iprintf -Ifat -Icommon -c -g -Os $(ZPUOPTS) -DDISABLE_UART_RX

LFLAGS  = -nostartfiles -Wl,--relax -g -Os
#LFLAGS  = -nostartfiles -Os


# Our target.
all: mcc mist de1 aeon_lite chameleon 

install:
	cd ../common/romgen && ./createall && cd ../../firmware

aeon_lite: $(BUILD_DIR) $(AEON_LITE_PRJ).bin $(AEON_LITE_PRJ).rpt

de1: $(BUILD_DIR) $(DE1_PRJ).bin $(DE1_PRJ).rpt

chameleon: $(BUILD_DIR) $(CHAMELEON_PRJ).bin $(CHAMELEON_PRJ).rpt

mcc: $(BUILD_DIR) $(MCC_PRJ).bin $(MCC_PRJ).rpt

mist: $(BUILD_DIR) $(MIST_PRJ).bin $(MIST_PRJ).rpt

clean:
	rm -rf $(BUILD_DIR)/* *.hex *.elf *.map *.lst *.srec *.bin *.rpt


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

$(AEON_LITE_PRJ).elf: $(MINSTARTUP_OBJ) $(AEON_LITE_OBJ)
	$(LD) $(LFLAGS) -T $(LINKMAP) -o $@ $+ $(LIBS)

$(DE1_PRJ).elf: $(MINSTARTUP_OBJ) $(DE1_OBJ)
	$(LD) $(LFLAGS) -T $(LINKMAP) -o $@ $+ $(LIBS)

$(CHAMELEON_PRJ).elf: $(MINSTARTUP_OBJ) $(CHAMELEON_OBJ)
	$(LD) $(LFLAGS) -T $(LINKMAP) -o $@ $+ $(LIBS)

$(MCC_PRJ).elf: $(MINSTARTUP_OBJ) $(MCC_OBJ)
	$(LD) $(LFLAGS) -T $(LINKMAP) -o $@ $+ $(LIBS)

$(MIST_PRJ).elf: $(MINSTARTUP_OBJ) $(MIST_OBJ)
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

