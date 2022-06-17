#include "main.h" //!!!
#include "atari_drive_emulator.h"
#include "log.h"
#include "utils.h"
#include "sd_direct/spi.h"
#include "printf.h"
#include "menu.h"

unsigned char freezer_rom_present;
unsigned char sd_present;
unsigned char sel_profile;
unsigned char sd_mounted;

void mainmenu()
{
	int i;
	*atari_colbk = 0xb8;
	*atari_colbk = 0x38;
	freezer_rom_present = 0;

	sd_mounted = 0;
	for (i=0; i!=NUM_FILES; ++i)
	{
		file_init(files[i]);
	}

	sel_profile = 1;

	init_drive_emulator();
	reboot(1);
	run_drive_emulator();
}
#ifdef DEBUG_SUPPORT
struct EditNumberState
{
	unsigned char col;
	unsigned char mask;
	unsigned char defaultShift;
};

struct DebugMenuData
{
	struct EditNumberState state[2];
};

void initDebugMenuData(struct DebugMenuData * menuData2)
{
	menuData2->state[0].col = 0;
	menuData2->state[0].mask = 0x3;
	menuData2->state[0].defaultShift = 12;
	menuData2->state[1].col = 0;
	menuData2->state[1].mask = 0x1;
	menuData2->state[1].defaultShift = 4;
}

void menuDisplayEditNumber(unsigned int num, struct EditNumberState * state)
{
	int shift = state->defaultShift;
	int i=0;
	int adj = debug_adjust;

	printf("0x");
	while(shift>=0)
	{
		int val = num;
		val = (val>> shift)&0xf;
		
		if (state->col == i)
			debug_adjust = adj^128;
		else
			debug_adjust = adj;
		printf("%1x",val);
		shift = shift-4;
		i=i+1;
	}

	debug_adjust = adj;
}

void menuPrintDebugAddress(void * menuData, void * itemData)
{
	printf("Addr:");
	struct DebugMenuData * menuData2 = (struct DebugMenuData *)(menuData);
	menuDisplayEditNumber(get_debug_addr(),&menuData2->state[0]);
}
void menuPrintDebugData(void * menuData, void * itemData)
{
	printf("Data:");
	struct DebugMenuData * menuData2 = (struct DebugMenuData *)(menuData);
	menuDisplayEditNumber(get_debug_data(),&menuData2->state[1]);
}
void menuPrintDebugMode(void * menuData, void * itemData)
{
	printf("Mode:");
	if (get_debug_read_mode())
		printf("Read ");
	if (get_debug_write_mode())
		printf("Write ");
	if (get_debug_data_match())
		printf("Match ");
}

bool hexDigitToNumber(unsigned char digit, int *val)
{
	if (digit>='0' && digit<='9')
	{
		*val = digit-'0';
		return true;
	}
	else if (digit>='A' && digit<='F')
	{
		*val = 10 + digit-'A';
		return true;
	}
	return false;
}

bool menuEditNumber(struct EditNumberState * state, struct joystick_status * joy, unsigned int * data)
{
	unsigned int val = 0;
	unsigned int mask = 0;
	int i;
	int shift = state->defaultShift;
	bool res = false;
	if (hexDigitToNumber(joy->keyPressed_,&val))
	{
		//key pressed, store the number in the current location
		for (i=0;i!=state->col;++i)
			shift = shift-4;

		mask = 0xf;
		val = val<<shift;
		mask = mask<<shift;

		*data = ((*data)&~mask) | val;

		state->col = state->col+1;
		res = true;
	}
	else if (joy->keyPressed_==-1)
	{
		// delete pressed, move back one place
		state->col = state->col-1;
	}

	state->col = state->col & state->mask; // sanitize col

	return res;
}

void menuDebugAddress(void * menuData, struct joystick_status * joy, int j)
{
	int i;
	struct DebugMenuData * menuData2 = (struct DebugMenuData *)(menuData);
	
	unsigned int addr = get_debug_addr();
	if (menuEditNumber(&menuData2->state[j],joy,&addr))
		set_debug_addr(addr);
}
void menuDebugData(void * menuData, struct joystick_status * joy, int j)
{
	int i;
	struct DebugMenuData * menuData2 = (struct DebugMenuData *)(menuData);

	unsigned int data = get_debug_data();

	if (menuEditNumber(&menuData2->state[j],joy,&data))
		set_debug_data(data);
}
void menuDebugHotkeys(void * menuData, unsigned char keyPressed)
{
	switch (keyPressed)
	{
	case 'R':
		set_debug_read_mode(!get_debug_read_mode());
		break;
	case 'W':
		set_debug_write_mode(!get_debug_write_mode());
		break;
	case 'M':
		set_debug_data_match(!get_debug_data_match());
		break;
	}
}

int debug_menu()
{
	struct MenuEntry entries[] = 
	{
		{&menuPrintDebugAddress,0,&menuDebugAddress,MENU_FLAG_KEYPRESS},
		{&menuPrintDebugData,1,&menuDebugData,MENU_FLAG_KEYPRESS},
		{&menuPrintDebugMode,0,0,MENU_FLAG_KEYPRESS},
		{0,0,0,0}, //blank line
		{0,"Exit",0,MENU_FLAG_EXIT},
		{0,0,0,MENU_FLAG_FINAL} //blank line
	};

	struct DebugMenuData menuData;
	initDebugMenuData(&menuData);
	return display_menu("Debug",&entries[0], &menuDebugHotkeys, &menuData);
}
#endif

void update_keys()
{
	#ifdef LINUX_BUILD
		check_keys();
	#endif
	#ifdef USB
		usb_poll(&usb_porta);
	#endif
	#ifdef USB2
		usb_poll(&usb_portb);
	#endif
}

void actions()
{
	update_keys();
	// Check for new mounts
	unsigned char sd_new_mounted = get_sd_mounted();
	char ext_idx = get_ext_idx();
	if ((sd_mounted & 0x01) != (sd_new_mounted & 0x01))
	{
		int size = *(int*)zpu_in2;
		if (size) {
			file_mount(files[0], 0, size, ext_idx);
			set_drive_status(0,files[0]);
		} else {
			// remove
			file_init(files[0]);
			set_drive_status(0, 0);
		}
	}
	if ((sd_mounted & 0x02) != (sd_new_mounted & 0x02))
	{
		int size = *(int*)zpu_in2;
		if (size) {
			file_mount(files[1], 1, size, ext_idx);
			set_drive_status(1,files[1]);
		} else {
			// remove
			file_init(files[1]);
			set_drive_status(1, 0);
		}
	}
	sd_mounted = sd_new_mounted;

	// Hot keys
	if (get_hotkey_softboot())
	{
		reboot(0);
	}
	else if (get_hotkey_coldboot())
	{
		reboot(1);

		do
		{
			update_keys();
		}
		while (get_hotkey_coldboot());
	} else if (get_hotkey_settings())
		// cold boot with disk unload
	{
		set_drive_status(0, 0);
		set_drive_status(1, 0);
		reboot(1);
		do
		{
			update_keys();
		}
		while (get_hotkey_settings());
	}
}
