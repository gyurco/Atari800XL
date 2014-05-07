
void file_select(void (*filter) (char const *), char const * path, struct SimpleFile * file)
{
	// Read in the whole dir

	// Write it to screen memory

	// Allow user to scroll around with hotkeys/joystick

	// If user selects dir, then we 

	int fileno;
	int skip;
	int plotted = 0;
	wait_us(200000);
	for(;;)
	{
		int i = 0;
		int go = 0;
		fileno = 0;
		topofscreen();
		for (i=0; i!=(24*40); ++i)
		{
			*(unsigned char volatile *)(i+0x10000+40000) = 0x00;
		}
		if (FR_OK != pf_opendir(&dir,"/"))
		{
			debug("opendir failed\n");
			mmcReadCached(0);
			hexdump_pure(mmc_sector_buffer,512);
			
			while(1);
		}

		plotted = 0;
		skip = 0;
		if (selfileno>20)
		{
			skip = selfileno-20;
			skip&=0xfffffffe;
		}
		if (selfileno<0)
		{
			selfileno = 0;
		}
		while (FR_OK == pf_readdir(&dir,&filinfo) && filinfo.fname[0]!='\0')
		{
			if (filinfo.fattrib & AM_SYS)
			{
				continue;
			}
			if (filinfo.fattrib & AM_HID)
			{
				continue;
			}
			if (filinfo.fattrib & AM_DIR)
			{
				debug("DIR ");
			}
			if (selfileno == fileno)
			{
				for (i=0;i!=15;++i)
				{
					filename[i] = filinfo.fname[i];
					if (0==filinfo.fname[i]) break;
					filinfo.fname[i]+=128;
				}
			}
			if (--skip<0)
			{
				debug(filinfo.fname);
				++plotted;
				if (plotted&1)
				{
					setxpos(20);
				}
				else
				{
					debug("\n");
				}
				if (plotted==40)
				{
					break;
				}
			}
			fileno++;
		}
		debug("\n");
		setypos(21);
		opendrive = 0;
		openfile(filename);
		for (;;)
		{
			unsigned char porta = *atari_porta;
			if (0==(porta&0x2)) // down
			{
				selfileno+=2;
				break;
			}
			else if (0==(porta&0x1)) // up
			{
				selfileno-=2;
				break;
			}
			else if (0==(porta&0x8)) // right
			{
				selfileno|=1;
				break;
			}
			else if (0==(porta&0x4)) // left
			{
				selfileno&=0xfffffffe;
				break;
			}
			else if (0==(*atari_trig0)) // fire
			{
				go = 1;
				while(0==(*atari_trig0));
				break;
			}
			topofscreen();
			//plotnextnumber(porta);
			*atari_colbk = *atari_random;
			//wait_us(200);
		}
		if (go == 1)
		{
			wait_us(200000);
			return validfile; // TODO, another way to quit without selecting...
		}
		wait_us(80000);
	}
	return 0;
}


