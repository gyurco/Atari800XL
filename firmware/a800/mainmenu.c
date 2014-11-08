static const int main_ram_size=65536;
#include "main.h" //!!!
#include "atari_drive_emulator.h"
#include "log.h"

unsigned char freezer_rom_present;

void loadosrom()
{
	if (file_size(files[5]) == 0x4000)
	{
		loadromfile(files[5],0x4000, ROM_OFS + 0x4000);
	}
	else if (file_size(files[5]) ==0x2800)
	{
		loadromfile(files[5],0x2800, ROM_OFS + 0x5800);
	}
}


void mainmenu()
{
	freezer_rom_present = 0;
	if (SimpleFile_OK == dir_init((void *)DIR_INIT_MEM, DIR_INIT_MEMSIZE))
	{
		init_drive_emulator();
		
		struct SimpleDirEntry * entries = dir_entries(ROM_DIR);
		
		//loadrom_indir(entries,"atarixl.rom",0x4000, (void *)0x704000);

		/*loadrom_indir(entries,"xlhias.rom",0x4000, (void *)0x708000);
		loadrom_indir(entries,"ultimon.rom",0x4000, (void *)0x70c000);
		loadrom_indir(entries,"osbhias.rom",0x4000, (void *)0x710000);
		loadrom_indir(entries,"osborig.rom",0x2800, (void *)0x715800);
		loadrom_indir(entries,"osaorig.rom",0x2800, (void *)0x719800);*/

		loadrom_indir(entries,"ataribas.rom",0x2000,ROM_OFS);
		if (SimpleFile_OK == file_open_name_in_dir(entries, "atarixl.rom", files[5]))
		{
			loadosrom();
		}

#ifdef HAVE_FREEZER_ROM_MEM
		if (SimpleFile_OK == file_open_name_in_dir(entries, "freezer.rom", files[6]))
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
		} else {
			LOG("freezer.rom not found\n");
		}
#endif
		set_freezer_enable(freezer_rom_present);

		//ROM = xlorig.rom,0x4000, (void *)0x704000
		//ROM = xlhias.rom,0x4000, (void *)0x708000
		//ROM = ultimon.rom,0x4000, (void *)0x70c000
		//ROM = osbhias.rom,0x4000, (void *)0x710000
		//ROM = osborig.rom,0x2800, (void *)0x715800
		//ROM = osaorig.rom,0x2800, (void *)0x719800
		//
		//ROM = ataribas.rom,0x2000,(void *)0x700000

		//--SDRAM_BASIC_ROM_ADDR <= "111"&"000000"   &"00000000000000";
		//--SDRAM_OS_ROM_ADDR    <= "111"&rom_select &"00000000000000";
		reboot(1);
		run_drive_emulator();
	}
	else
	{
		//printf("DIR init failed\n");
	}
	reboot(1);
	for (;;) actions();
}

char const * get_ram()
{
	static char const * ram[] = 
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
	return ram[get_ram_select()];
	/*switch(get_ram_select())
	{
	case 0:
		return "64K";
	case 1:
		return "128K";
	case 2:
		return "320K(Compy)";
	case 3:
		return "320K(Rambo)";
	case 4:
		return "576K(Compy)";
	case 5:
		return "576K(Rambo)";
	case 6:
		return "1MB";
	case 7:
		return "4MB";
	}*/
}

int settings()
{
	struct joystick_status joy;
	joy.x_ = joy.y_ = joy.fire_ = 0;

	int row = 0;

	int done = 0;
	for (;!done;)
	{
		// Render
		clearscreen();
		debug_pos = 0;
		debug_adjust = 0;
		printf("Se");
		debug_adjust = 128;
		printf("ttings");
		debug_pos = 80;
		debug_adjust = row==0 ? 128 : 0;
		printf("Turbo:%dx", get_turbo_6502());
		debug_pos = 120;
		debug_adjust = row==1 ? 128 : 0;
		printf("Ram:%s", get_ram());
		debug_pos = 160;
		debug_adjust = row==2 ? 128 : 0;
		{
			printf("Rom:%s", file_name(files[5]));
		}
		debug_pos = 240;
		int i;
		for (i=1;i!=5;++i)
		{
			int temp = debug_pos;
			debug_adjust = row==i+2 ? 128 : 0;
			char buffer[20];
			describe_disk(i-1,&buffer[0]);
			printf("Drive %d:%s %s", i, file_name(files[i-1]), &buffer[0]);
			debug_pos = temp+40;
		}

		debug_pos = 400;
		debug_adjust = row==7 ? 128 : 0;
		printf("Cart: %s", get_cart_select() ? file_name(files[4]) : "NONE");

		debug_pos = 480;
		debug_adjust = row==8 ? 128 : 0;
		printf("Exit");

		// Slow it down a bit
		wait_us(100000);

		// move
		joystick_wait(&joy,WAIT_QUIET);
		joystick_wait(&joy,WAIT_EITHER);
		if (joy.escape_) break;

		row+=joy.y_;
		if (row<0) row = 0;
		if (row>8) row = 8;
		switch (row)
		{
		case 0:
			{
				int turbo = get_turbo_6502();
				if (joy.x_==1) turbo<<=1;
				if (joy.x_==-1) turbo>>=1;
				if (turbo>16) turbo = 16;
				if (turbo<1) turbo = 1;
				set_turbo_6502(turbo);
			}
			break;
		case 1:
			{
				int ram_select = get_ram_select();
				ram_select+=joy.x_;
				if (ram_select<0) ram_select = 0;
				if (ram_select>7) ram_select = 7;
				set_ram_select(ram_select);
			}
			break;
		case 2:
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
		case 3:
		case 4:
		case 5:
		case 6:
			{
				if (joy.x_>0)
				{
					// Choose new disk
					filter = filter_disks;
					file_selector(files[row-3]);
					set_drive_status(row-3,files[row-3]);
				}
				else if(joy.x_<0)
				{
					// Remove disk
					file_init(files[row-3]);
					set_drive_status(row-3,0);
				}
				else if (joy.fire_)
				{
					{
						// Swap files
						struct SimpleFile * temp = files[row-3];
						files[row-3] = files[0];
						files[0] = temp;
					}

					{
						// Swap disks
						struct SimpleFile * temp = get_drive_status(row-3);
						set_drive_status(row-3, get_drive_status(0));
						set_drive_status(0,temp);
					}
				}
			}
			break;
		case 7:
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
			break;
		case 8:
			if (joy.fire_)
			{
				done = 1;
			}
			break;
		}
	}

	return 0;
}



void actions()
{
#ifdef LINUX_BUILD
	check_keys();
#endif
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
	}
	else if (get_hotkey_settings())
	{
		set_pause_6502(1);
		set_freezer_enable(0);
		freeze();
		debug_pos = 0;	
		int do_reboot = settings();
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
		set_pause_6502(1);
		set_freezer_enable(0);
		freeze();
		filter = filter_disks;
		file_selector(files[0]);
		debug_pos = -1;
		restore();
		set_drive_status(0,files[0]);
		reboot(1);
	}
}


