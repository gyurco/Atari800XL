static const int main_ram_size=65536;
#include "main.h" //!!!
#include "atari_drive_emulator.h"
#include "log.h"
#include "utils.h"
#include "sd_direct/spi.h"
#include "rom_location.h"

unsigned char freezer_rom_present;
unsigned char sd_present;
unsigned char sel_profile;
unsigned int romstart;

void loadosrom()
{
	if (!sd_present) return;
	if (file_size(files[5]) == 0x4000)
	{
		loadromfile(files[5],0x4000, os_addr());
	}
	else if (file_size(files[5]) ==0x2800)
	{
		loadromfile(files[5],0x2800, os_addr()+0x1800);
		memset8(os_addr(),0xff,0x1000);
	}
	else if (file_size(files[5]) ==0x2000)
	{
		loadromfile(files[5],0x2000, basic_addr());
	}
}

#ifdef USB
struct usb_host usb_porta;
#endif
#ifdef USB2
struct usb_host usb_portb;
#endif

void test_ram()
{
	int i;
	unsigned int volatile * addr = DIR_INIT_MEM;
	int k;
	for (k=0;k<DIR_INIT_MEMSIZE/4;++k)
	{
		addr[k] = k&0xffff;
	}
	int ok = 1;
	for (k=0;k<DIR_INIT_MEMSIZE/4;++k)
	{
		unsigned int val = addr[k];
		if (val != (k&0xffff))
		{
			ok = 0;
		}
	}

	int j =0;
	if (ok)
	{
		while(1)
		{
			++j;
			if (j&1)
				*atari_colbk = 0xc8;
			else
				*atari_colbk = 0x00;
		}
	}
	else
	{
		while(1)
		{
			++j;
			if (j&1)
				*atari_colbk = 0x38;
			else
				*atari_colbk = 0x00;
		}
	}
}

int init_sd()
{
	if (SimpleFile_OK == dir_init((void *)DIR_INIT_MEM, DIR_INIT_MEMSIZE))
	{
		//for(;;);
		#ifdef USB
			usb_log_init(files[7]);
		#endif

		//test_ram();

		return 1;
	}
	return 0;
}

/*static const unsigned char BitReverseTable256[] = 
{
	  0x00, 0x80, 0x40, 0xC0, 0x20, 0xA0, 0x60, 0xE0, 0x10, 0x90, 0x50, 0xD0, 0x30, 0xB0, 0x70, 0xF0, 
	    0x08, 0x88, 0x48, 0xC8, 0x28, 0xA8, 0x68, 0xE8, 0x18, 0x98, 0x58, 0xD8, 0x38, 0xB8, 0x78, 0xF8, 
	      0x04, 0x84, 0x44, 0xC4, 0x24, 0xA4, 0x64, 0xE4, 0x14, 0x94, 0x54, 0xD4, 0x34, 0xB4, 0x74, 0xF4, 
	        0x0C, 0x8C, 0x4C, 0xCC, 0x2C, 0xAC, 0x6C, 0xEC, 0x1C, 0x9C, 0x5C, 0xDC, 0x3C, 0xBC, 0x7C, 0xFC, 
		  0x02, 0x82, 0x42, 0xC2, 0x22, 0xA2, 0x62, 0xE2, 0x12, 0x92, 0x52, 0xD2, 0x32, 0xB2, 0x72, 0xF2, 
		    0x0A, 0x8A, 0x4A, 0xCA, 0x2A, 0xAA, 0x6A, 0xEA, 0x1A, 0x9A, 0x5A, 0xDA, 0x3A, 0xBA, 0x7A, 0xFA,
		      0x06, 0x86, 0x46, 0xC6, 0x26, 0xA6, 0x66, 0xE6, 0x16, 0x96, 0x56, 0xD6, 0x36, 0xB6, 0x76, 0xF6, 
		        0x0E, 0x8E, 0x4E, 0xCE, 0x2E, 0xAE, 0x6E, 0xEE, 0x1E, 0x9E, 0x5E, 0xDE, 0x3E, 0xBE, 0x7E, 0xFE,
			  0x01, 0x81, 0x41, 0xC1, 0x21, 0xA1, 0x61, 0xE1, 0x11, 0x91, 0x51, 0xD1, 0x31, 0xB1, 0x71, 0xF1,
			    0x09, 0x89, 0x49, 0xC9, 0x29, 0xA9, 0x69, 0xE9, 0x19, 0x99, 0x59, 0xD9, 0x39, 0xB9, 0x79, 0xF9, 
			      0x05, 0x85, 0x45, 0xC5, 0x25, 0xA5, 0x65, 0xE5, 0x15, 0x95, 0x55, 0xD5, 0x35, 0xB5, 0x75, 0xF5,
			        0x0D, 0x8D, 0x4D, 0xCD, 0x2D, 0xAD, 0x6D, 0xED, 0x1D, 0x9D, 0x5D, 0xDD, 0x3D, 0xBD, 0x7D, 0xFD,
				  0x03, 0x83, 0x43, 0xC3, 0x23, 0xA3, 0x63, 0xE3, 0x13, 0x93, 0x53, 0xD3, 0x33, 0xB3, 0x73, 0xF3, 
				    0x0B, 0x8B, 0x4B, 0xCB, 0x2B, 0xAB, 0x6B, 0xEB, 0x1B, 0x9B, 0x5B, 0xDB, 0x3B, 0xBB, 0x7B, 0xFB,
				      0x07, 0x87, 0x47, 0xC7, 0x27, 0xA7, 0x67, 0xE7, 0x17, 0x97, 0x57, 0xD7, 0x37, 0xB7, 0x77, 0xF7, 
				        0x0F, 0x8F, 0x4F, 0xCF, 0x2F, 0xAF, 0x6F, 0xEF, 0x1F, 0x9F, 0x5F, 0xDF, 0x3F, 0xBF, 0x7F, 0xFF
};*/

int flash_rpd(struct SimpleFile* file)
{
	int len;
	int readlen;
	int loc;
	int p;

	len = file_size(file);
	loc = 0;

	clearscreen();
	debug_pos = 0;
	debug_adjust = 0;
	printf("Flashing core");

	debug_pos = 80;

	printf("DO NOT POWER OFF");

	debug_pos = 160;

	while (len>0)
	{
		int chunk = len;
		int i = 0;
		if (chunk>262144)
		{
			chunk = 262144;
		}
		len = len-chunk;

		enum SimpleFileStatus ok;
		file_seek(file,loc);
		ok = file_read(file, SCRATCH_MEM, chunk, &readlen);
		if (ok != SimpleFile_OK) {
			LOG("cannot read rpd data\n");
			return 0;
		}

		// Byte swap it!
		for (i=0;i!=chunk;++i)
		{
			unsigned char in = ((unsigned char *)SCRATCH_MEM)[i];
			unsigned char res = 0;
			if (in&1)
				res=res|128;
			if (in&2)
				res=res|64;
			if (in&4)
				res=res|32;
			if (in&8)
				res=res|16;
			if (in&16)
				res=res|8;
			if (in&32)
				res=res|4;
			if (in&64)
				res=res|2;
			if (in&128)
				res=res|1;

			((unsigned char *)SCRATCH_MEM)[i] = res;
		}

		// Flash it!
		//printf("Erase    %x %x",loc,chunk);
		printf(".E.");
		eraseFlash(loc,chunk); // Clear at last 256kB
		//printf("Write    ");
		printf(".W.");
		writeFlash(loc,chunk,SCRATCH_MEM);
		//printf("Verify    ");
		printf(".V.");
		readFlash(loc, chunk, CARTRIDGE_MEM);

		for (i=0;i!=chunk;++i)
		{
			unsigned char in = ((unsigned char *)SCRATCH_MEM)[i];
			unsigned char inb = ((unsigned char *)CARTRIDGE_MEM)[i];
			if (in!=inb)
			{
				printf("FAIL:%02x %02x %d ", in, inb, i);
				break;
			}
		}

		loc = loc+chunk;
	}
	printf("Done    ");
	wait_us(1000000);

/*	printf("   VERIFY  ");
	len = file_size(file);
	loc = 0;
	while (len>0)
	{
		int chunk = len;
		int i = 0;
		if (chunk>262144)
		{
			chunk = 262144;
		}
		len = len-chunk;

		enum SimpleFileStatus ok;
		file_seek(file,loc);
		ok = file_read(file, SCRATCH_MEM, chunk, &readlen);
		if (ok != SimpleFile_OK) {
			LOG("cannot read rpd data\n");
			return 0;
		}

		// Byte swap it!
		for (i=0;i!=chunk;++i)
		{
			unsigned char in = ((unsigned char *)SCRATCH_MEM)[i];
			unsigned char res = 0;
			if (in&1)
				res=res|128;
			if (in&2)
				res=res|64;
			if (in&4)
				res=res|32;
			if (in&8)
				res=res|16;
			if (in&16)
				res=res|8;
			if (in&32)
				res=res|4;
			if (in&64)
				res=res|2;
			if (in&128)
				res=res|1;

			((unsigned char *)SCRATCH_MEM)[i] = res;
		}

		// Flash it!
		printf("Verify    %x %x",loc,chunk);
		readFlash(loc, chunk, CARTRIDGE_MEM);

		for (i=0;i!=chunk;++i)
		{
			unsigned char in = ((unsigned char *)SCRATCH_MEM)[i];
			unsigned char inb = ((unsigned char *)CARTRIDGE_MEM)[i];
			if (in!=inb)
			{
				printf("FAIL:%02x %02x %d ", in, inb, i);
				break;
			}
		}

		loc = loc+chunk;
	}

	debug_pos=400;
	printf("HERE");

	//file_seek(file,0);
	//file_read(file, SCRATCH_MEM, 256, &readlen);
	readFlash(0, 256, SCRATCH_MEM);
	for (p=0;p!=256;++p)
	{
		unsigned char in = ((unsigned char *)SCRATCH_MEM)[p];
		printf("%02x",in);
	}
	for (;;);*/
}

void load_roms(int profile)
{
	struct SimpleDirEntry * entries = dir_entries(ROM_DIR);

	// TODO profile shifts settings, basic rom, os rom address

	//memory map of flash
	//0x200000: settings (32KB!)
	//0x208000: basic rom (32KB)
	//0x210000: os rom (64KB - 4x16KB)
	//0x220000: freezer rom (64KB)
	//0x230000: ?? (64KB)

	if (profile == 4)
	{
		if (sd_present && SimpleFile_OK == file_open_name_in_dir(entries, "ataribas.rom", files[5]))
		{
			loadosrom();
		}
		if (sd_present && SimpleFile_OK == file_open_name_in_dir(entries, "atarixl.rom", files[5]))
		{
			loadosrom();
		}
		if (sd_present && SimpleFile_OK == file_open_name_in_dir(entries, "freezer.rom", files[6]))
		{
			enum SimpleFileStatus ok;
			int len;
			ok = file_read(files[6], FREEZER_ROM_MEM, 0x10000, &len);
			if (ok == SimpleFile_OK && len == 0x10000) {
				LOG("freezer rom loaded\n");
				freezer_rom_present = 1;
			} else {
				LOG("loading freezer rom failed\n");
				freezer_rom_present = 0;
			}
		}
	}
	else
	{
		readFlash(romstart + 0x08000 + (profile<<13),0x2000,basic_addr());
		readFlash(romstart + 0x10000 + (profile<<14),0x4000,os_addr());
		readFlash(romstart + 0x20000,0x10000,FREEZER_ROM_MEM);
		freezer_rom_present = 1;
	}

	set_freezer_enable(freezer_rom_present);
}

void mainmenu()
{
	*atari_colbk = 0xb8;
#ifdef USB
	usb_init(&usb_porta,0);
#endif
#ifdef USB2
	usb_init(&usb_portb,1);
#endif
	*atari_colbk = 0x38;
	freezer_rom_present = 0;

	sd_present = !get_sd_detect();
	if (sd_present)
	{
		if (init_sd())
		{
			*atari_colbk = 0x18;
		}
		else
		{
			*atari_colbk = 0x0f;
			sd_present = 0;
			//for(;;);
			//printf("DIR init failed\n");
		}
	}

	// Find rom settings location
	init_romstart();

	// default to flash
	load_roms(0);
	load_settings(0);

	// override if present on sd (do we really want this?)
	load_roms(4);
	load_settings(4);

	sel_profile = 1;

	init_drive_emulator();
	reboot(1);
	run_drive_emulator();
}

static char const * ramXL[] = 
{
	"64K",
	"128K",
	"320K(Compy)",
	"320K(Rambo)",
	"576K(Compy)",
	"576K(Rambo)",
	"1MB",
	"4MB"
};

static char const * ram800[] = 
{
	"8K",
	"16K",
	"32K",
	"48K",
	"52K"
	//TODO
};

static char const * key_types[] = 
{
	"ISO",
	"ANSI"
};

static char const * system[] = 
{
	"XL/XE",
	"400/800"
};

int devices_menu()
{
	struct joystick_status joy;
	joy.x_ = joy.y_ = joy.fire_ = joy.escape_ = 0;

	int row = 0;

	int done = 0;
	for (;!done;)
	{
		u08 res;
		int i;
		u08 data[8];

		// Render
		clearscreen();
		debug_pos = 0;
		debug_adjust = 0;
		printf("Devices");

		debug_pos = 80;
		for (i=1;i!=5;++i)
		{
			int temp = debug_pos;
			debug_adjust = row==i-1 ? 128 : 0;
			char buffer[20];
			describe_disk(i-1,&buffer[0]);
			printf("Drive %d:%s %s", i, file_name(files[i-1]), &buffer[0]);
			debug_pos = temp+40;
		}

		debug_pos = 240;
		debug_adjust = row==4 ? 128 : 0;
		printf("Cart: %s", get_cart_select() ? file_name(files[4]) : "NONE");

#ifdef USBSETTINGS
		debug_pos = 320;
		debug_adjust = row==5 ? 128 : 0;
		printf("Rotate USB joysticks");

		debug_pos = 400;
		debug_adjust = row==6 ? 128 : 0;
		printf("Exit");

		debug_adjust = 0;

		usb_devices(480);
#else
		debug_pos = 320;
		debug_adjust = row==5 ? 128 : 0;
		printf("Exit");
#endif

		// Slow it down a bit
		wait_us(100000);

		// move
		joystick_wait(&joy,WAIT_QUIET);
		joystick_wait(&joy,WAIT_EITHER);
		switch (joy.keyPressed_)
		{
		case '1':
		case '2':
		case '3':
		case '4':
			row = joy.keyPressed_-'1';
			joy.x_ = 1;
			break;
		case 'C':
			row = 4;
			joy.x_ = 1;
			break;
		}
		if (joy.escape_) break;

		row+=joy.y_;
		if (row<0) row = 0;
#ifdef USBSETTINGS
		if (row>6) row = 6;
#else
		if (row>5) row = 5;
#endif
		actions();

		int drive_offset = 0;

		switch (row)
		{
		case 0:
		case 1:
		case 2:
		case 3:
			{
				if (joy.x_>0)
				{
					// Choose new disk
					filter = filter_disks;
					file_selector(files[row-drive_offset]);
					set_drive_status(row-drive_offset,files[row-drive_offset]);
				}
				else if(joy.x_<0)
				{
					// Remove disk
					file_init(files[row-drive_offset]);
					set_drive_status(row-drive_offset,0);
				}
				else if (joy.fire_)
				{
					{
						// Swap files
						struct SimpleFile * temp = files[row-drive_offset];
						files[row-drive_offset] = files[0];
						files[0] = temp;
					}

					{
						// Swap disks
						struct SimpleFile * temp = get_drive_status(row-drive_offset);
						set_drive_status(row-drive_offset, get_drive_status(0));
						set_drive_status(0,temp);
					}
				}
			}
			break;
		case 4:
			{
				if (sd_present)
				{
					if (joy.x_>0) {
						fil_type = fil_type_car;
						filter = filter_specified;
						file_selector(files[4]);
						unsigned char mode = load_car(files[4]);
						set_cart_select(mode);
						if (mode) {
							return 1;
						}
					}
					else if (joy.x_<0) {
						file_init(files[4]);
						set_cart_select(0);
					}
				}
			}
			break;
#ifdef USBSETTINGS
		case 5:
			if (joy.fire_)
			{
				rotate_usb_sticks();
			}
			break;
		case 6:
			if (joy.fire_)
			{
				done = 1;
			}
			break;
#else
		case 5:
			if (joy.fire_)
			{
				done = 1;
			}
			break;
#endif
		}
	}

	return 0;
}

char const * const * ram;
int max_ram_select;
void set_system()
{
	if (get_atari800mode() == 1)
	{
		ram = ram800;
		max_ram_select = MAX_RAM_SELECT_800;
	}
	else
	{
		ram = ramXL;
		max_ram_select = MAX_RAM_SELECT_XL;
	}
}

int settings_menu()
{
	struct joystick_status joy;
	joy.x_ = joy.y_ = joy.fire_ = joy.escape_ = 0;

	int row = 0;

	int video_mode = get_video();
	int tv = get_tv();
	int scanlines = get_scanlines();
	int csync = get_csync();

	int flashid1;
	int flashid2;
	int sectorSize;
	readFlashId(&flashid1,&flashid2);
	sectorSize = flashSectorSize();

	set_system();

	int done = 0;
	for (;!done;)
	{
		u08 res;
		int i;
		u08 data[8];

		// Render
		clearscreen();
		debug_pos = 0;
		debug_adjust = 0;
		printf("Settings");

		debug_pos = 80;
		debug_adjust = row==0 ? 128 : 0;
		printf("Profile:%d", sel_profile);

		debug_pos = 160;
		debug_adjust = row==1 ? 128 : 0;
		printf("CPU:%dx", get_turbo_6502());
		debug_pos = 200;
		debug_adjust = row==2 ? 128 : 0;
		printf("Drive Turbo:%s", get_turbo_drive_str());
		debug_pos = 240;
		debug_adjust = row==3 ? 128 : 0;
		printf("System:%s %s", ram[get_ram_select()], system[get_atari800mode()]);
		debug_pos = 280;
		debug_adjust = row==4 ? 128 : 0;
		printf("ROM:%s", file_name(files[5]));
		debug_pos = 320;
		debug_adjust = row==5 ? 128 : 0;
		printf("Keyboard:%s", key_types[get_key_type()]);

		debug_pos = 400;
		debug_adjust = row==6 ? 128 : 0;
		printf("Mode:%s", get_video_mode(video_mode));
		debug_pos = 440;
		debug_adjust = row==7 ? 128 : 0;
		printf("TV standard:%s", get_tv_standard(tv));
		debug_pos = 480;
		debug_adjust = row==8 ? 128 : 0;
		printf("Scanlines:%d", scanlines);
		debug_pos = 520;
		debug_adjust = row==9 ? 128 : 0;
		printf("Composite sync:%d", csync);
		debug_pos = 560;
		debug_adjust = row==10 ? 128 : 0;
		printf("Apply video");

		debug_pos = 640;
		debug_adjust = row==11 ? 128 : 0;
		printf("Save Flash");
		debug_pos = 680;
		debug_adjust = row==12 ? 128 : 0;
		if (sd_present)
			printf("Save SD");

#ifdef RPD_SUPPORT
		debug_pos = 720;
		debug_adjust = row==13 ? 128 : 0;
		printf("Program RBD");

		debug_pos = 800;
		debug_adjust = row==14 ? 128 : 0;
		printf("Exit");
#else
		debug_pos = 720;
		debug_adjust = row==13 ? 128 : 0;
		printf("Exit");
#endif

		debug_pos = 840;
		debug_adjust = 0;
		printf("Board:%d %s %s%s%s",*zpu_board,"Date:YYYYMMDD Core:XX",isHDMIConnected() ? "HDMI " : "",isVGAConnected() ? "VGA ":"",sd_present ? "SD ":"");
		debug_pos = 880;
		printf("SPI:%08x/%08x/%d",flashid1,flashid2,sectorSize);

		// Slow it down a bit
		wait_us(100000);

		// move
		joystick_wait(&joy,WAIT_QUIET);
		joystick_wait(&joy,WAIT_EITHER);
		if (joy.escape_) break;
		if (joy.keyPressed_ > 0) 
		{
			int apply = 1;
			switch(joy.keyPressed_)
			{
			case 'P': // PAL
				tv = TV_PAL;
				break;
			case 'N': // NTSC
				tv = TV_NTSC;
				break;

			case 'R': // RGB
				video_mode = VIDEO_RGB;
				break;
			case 'A': // scAndouble (S taken for svideo, C taken for composite)
				video_mode = VIDEO_SCANDOUBLE;
				break;
			case 'D': // DVI
				video_mode = VIDEO_DVI;
				break;
			case 'H': // HDMI
				video_mode = VIDEO_HDMI;
				break;
			case 'V': // VGA
				video_mode = VIDEO_VGA;
				break;
			case 'S': // Svideo
				video_mode = VIDEO_SVIDEO;
				break;
			case 'C': // Composite
				video_mode = VIDEO_COMPOSITE;
				break;
			case 'Z': // Composite sync toggle
				csync  = !csync;
				break;
			case 'X': // Scanlines toggle
				scanlines  = !scanlines;
				break;
			case '1':
			case '2':
			case '3':
			case '4':
				apply = 0;
				row = 0;
				sel_profile = joy.keyPressed_ - '0';
				joy.fire_ = 1;
				break;
			default:
				apply = 0;
			}

			if (apply==1)
			{
				row = 10; // set, do not save
				joy.fire_ = 1;
			}
		}

		row+=joy.y_;
		if (row<0) row = 0;
#ifdef RPD_SUPPORT
		if (row>14) row = 14;
#else
		if (row>13) row = 13;
#endif
		actions();

		switch (row)
		{
		case 0:
			{
				sel_profile += joy.x_;
				if (sel_profile > 4)
					sel_profile = 4;
				if (sel_profile < 1)
					sel_profile = 1;

				if (joy.fire_)
				{
					load_roms(sel_profile-1);
					load_settings(sel_profile-1);

					video_mode = get_video();
					tv = get_tv();
					scanlines = get_scanlines();
					csync = get_csync();

					set_system();
				}
			}
			break;
		case 1:
			{
				int turbo = get_turbo_6502();
				if (joy.x_==1) turbo<<=1;
				if (joy.x_==-1) turbo>>=1;
				if (turbo>32) turbo = 32;
				if (turbo<1) turbo = 1;
				set_turbo_6502(turbo);
			}
			break;
		case 2:
			{
				int turbo = get_turbo_drive();
				turbo+=joy.x_;
				if (turbo<0) turbo = 0;
				if (turbo>7) turbo = 7;
				set_turbo_drive(turbo);
			}
			break;
		case 3:
			{
				int ram_select = get_ram_select();
				ram_select+=joy.x_;

				if (joy.fire_)
				{
					set_atari800mode(!get_atari800mode());
					set_system();
				}

				if (ram_select<0) ram_select = 0;
				if (ram_select>max_ram_select) ram_select = max_ram_select;
				set_ram_select(ram_select);
			}
			break;
		case 4:
			{
				if (joy.x_ || joy.fire_)
				{
					fil_type = fil_type_rom;
					filter = filter_specified;
					file_selector(files[5]);
					loadosrom();
				}
			}
			break;
/*		case 9:
		case 10:
			{
				if (joy.fire_)
				{
					fil_type = fil_type_mem;
					filter = filter_specified;
					file_selector(files[6]);
					if (row == 9)
					{
						freeze_load(files[6]);
					}
					else if (row == 10)
					{
						freeze_save(files[6]);
					}
				}
			}
			break;*/
		case 5:
			if (joy.x_ || joy.fire_)
			{
				set_key_type(!get_key_type());
			}
			break;
		case 6:
			{
				if (joy.x_==1) video_mode = video_mode+1;
				if (joy.x_==-1) video_mode = video_mode-1;
				if (video_mode > 6)
					video_mode = 6;
				if (video_mode < 0)
					video_mode = 0;
			}
			break;
		case 7:
			{
				if (joy.x_ || joy.fire_)
				{
					tv = !tv;
				}
			}
			break;
		case 8:
			{
				if (joy.x_ || joy.fire_)
				{
					scanlines = !scanlines;
				}
			}
			break;
		case 9:
			{
				if (joy.x_ || joy.fire_)
				{
					csync = !csync;
				}
			}
			break;
		case 10:
			if (joy.fire_)
			{
				set_video(video_mode);
				set_tv(tv);
				set_scanlines(scanlines);
				set_csync(csync);
				set_pll(get_tv()==TV_PAL, get_video()>=VIDEO_HDMI && get_video()<VIDEO_COMPOSITE);
			}
			break;
		case 11:
			if (joy.fire_)
			{
				set_video(video_mode);
				set_tv(tv);
				set_scanlines(scanlines);
				set_csync(csync);
				set_pll(get_tv()==TV_PAL, get_video()>=VIDEO_HDMI && get_video()<VIDEO_COMPOSITE);

				save_settings(sel_profile-1);
			}
			break;
		case 12:
			if (joy.fire_)
			{
				set_video(video_mode);
				set_tv(tv);
				set_scanlines(scanlines);
				set_csync(csync);
				set_pll(get_tv()==TV_PAL, get_video()>=VIDEO_HDMI && get_video()<VIDEO_COMPOSITE);

				save_settings(4);
			}
			break;
#ifdef RPD_SUPPORT
		case 13:
			if (sd_present)
			{
				if (joy.x_>0) {
					fil_type = fil_type_rpd;
					filter = filter_specified;
					file_selector(files[4]);
					flash_rpd(files[4]);
				}
			}
			break;
		case 14:
			if (joy.fire_)
			{
				done = 1;
			}
			break;
#else
		case 13:
			if (joy.fire_)
			{
				done = 1;
			}
			break;
#endif
		}
	}
	return 0;
}

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
	int sd_really_present;

	update_keys();

	sd_really_present = !get_sd_detect();
	if (sd_present==0 && sd_really_present==1)
	{
		if (init_sd())
		{
			init_drive_emulator();
		}
		else
		{
			sd_really_present = 0;
		}
	}
	if (sd_present==1 && sd_really_present==0)
	{
		int i;
		init_drive_emulator();
		for (i=0; i!=NUM_FILES; ++i)
		{
			file_init(files[i]);
		}
	}
	sd_present = sd_really_present;


	// Show some activity!
	//*atari_colbk = *atari_random;
	
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
	}
	else if (get_hotkey_settings())
	{
		set_pause_6502(1);
		set_freezer_enable(0);
		freeze();
		debug_pos = 0;	
		int do_reboot = settings_menu();
		debug_pos = -1;
		restore();
		if (do_reboot)
			reboot(1);
		else {
			set_freezer_enable(freezer_rom_present);
			set_pause_6502(0);
		}
	}
	else if (get_hotkey_fileselect())
	{
/*#ifdef USB
		set_pause_6502(1);
		set_freezer_enable(0);
		freeze();

		debug_pos = 0;	
		printf("Hello USB");
		debug_pos = 80;
		usb_init();
		while (1)
		{
			usb_poll();
			if (debug_pos>1000)
			{
				debug_pos = 80;
			}
		}

		debug_pos = -1;
		restore();
		set_freezer_enable(freezer_rom_present);
		set_pause_6502(0);
#else*/
		set_pause_6502(1);
		set_freezer_enable(0);
		freeze();
		debug_pos = 0;	
		int do_reboot = devices_menu();
		debug_pos = -1;
		restore();
		if (do_reboot)
			reboot(1);
		else {
			set_freezer_enable(freezer_rom_present);
			set_pause_6502(0);
		}
	}
}




