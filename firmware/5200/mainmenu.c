static const int main_ram_size=16384;
#include "main.h" //!!!

void actions();

void loadosrom()
{
	int j=0;
	if (file_size(files[5]) == 0x0800)
	{
		int i=0;
		unsigned char * src = (unsigned char *)(ROM_OFS + 0x4000 + SDRAM_BASE);
		unsigned char * dest1 = (unsigned char *)(ROM_OFS + 0x4800 + SDRAM_BASE);
		loadromfile(files[5],0x0800, ROM_OFS + 0x4000);

		for (i=0; i!=0x800; ++i)
		{
			dest1[i] = src[i];
		}
	}
}

void mainmenu()
{
	if (SimpleFile_OK == dir_init((void *)DIR_INIT_MEM, DIR_INIT_MEMSIZE))
	{
		struct SimpleDirEntry * entries = dir_entries(ROM_DIR);
		
		if (SimpleFile_OK == file_open_name_in_dir(entries, "5200.rom", files[5]))
		{
			loadosrom();
		}

		loadrom_indir(entries,"acid5200.rom",0x8000,0x004000); // XXX - just for 5200 test... remove later
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
	return "16K";
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
		int i;

		debug_pos = 200;
		debug_adjust = row==3 ? 128 : 0;
		printf("Cartridge 32k");

		debug_pos = 240;
		debug_adjust = row==4 ? 128 : 0;
		printf("Cartridge 16k one chip");

		debug_pos = 280;
		debug_adjust = row==5 ? 128 : 0;
		printf("Cartridge 16k two chip");

		debug_pos = 320;
		debug_adjust = row==6 ? 128 : 0;
		printf("Exit");

		// Slow it down a bit
		wait_us(100000);

		// move
		joystick_wait(&joy,WAIT_QUIET);
		joystick_wait(&joy,WAIT_EITHER);

		row+=joy.y_;
		if (row<0) row = 0;
		if (row>6) row = 6;
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
					filter = filter_roms;
					file_selector(files[5]);
					loadosrom();
				}
			}
			break;
		case 3:
		case 4:
		case 5:
			{
				if (joy.fire_)
				{
					filter = filter_bins;
					file_selector(files[4]);
					//loadrom_indir(entries,"acid5200.rom",0x8000,(void *)0x004000); // XXX - just for 5200 test... do not commit!
					if (row == 3)
					{
						loadromfile(files[4],0x8000,0x004000);
					}
					else if (row == 4)
					{
						//*atari_colbk = 0x58;
						//wait_us(4000000);
						loadromfile(files[4],0x4000,0x008000);
						unsigned char * src = (unsigned char *)(0x8000 + SDRAM_BASE);
						unsigned char * dest1 = (unsigned char *)(0x4000 + SDRAM_BASE);
						int i = 0;
						for (i=0; i!=0x4000; ++i)
						{
							dest1[i] = src[i];
						}
					}
					else if (row == 5)
					{
						unsigned char * src = (unsigned char *)(0x4000 + SDRAM_BASE);
						unsigned char * dest1 = (unsigned char *)(0x6000 + SDRAM_BASE);
						unsigned char * src2 = (unsigned char *)(0x8000 + SDRAM_BASE);
						unsigned char * dest2 = (unsigned char *)(0xa000+ SDRAM_BASE);
						int i = 0;
						//*atari_colbk = 0x68;
						//wait_us(5000000);

						loadromfile(files[4],0x2000,0x004000);
						loadromfile(files[4],0x2000,0x008000);
				
						for (i=0; i!=0x2000; ++i)
						{
							dest1[i] = src[i];
							dest2[i] = src2[i];
						}
					}
					return 1;
				}
			}
			break;
		case 6:
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
		freeze();
		debug_pos = 0;	
		int do_reboot = settings();
		debug_pos = -1;
		restore();
		if (do_reboot)
			reboot(1);
		else
			set_pause_6502(0);
	}
	else if (get_hotkey_fileselect())
	{
		set_pause_6502(1);
		freeze();
		//filter = filter_disks;
		//file_selector(files[0]);
		debug_pos = -1;
		restore();
		//set_drive_status(0,files[0]);
		reboot(1);
	}
}
