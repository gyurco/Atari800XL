#include <conio.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

unsigned char * pokey = (unsigned char *) 0xd200;
unsigned char * config = (unsigned char *) 0xd210;

unsigned char has_flash()
{
	return ((config[1]&0x40) == 0x40);
}
unsigned long readFlash(unsigned long addr, unsigned char cfgarea)
{
	unsigned long res;
	unsigned char al;

	addr = addr<<2;

	al = addr&0xff;
	config[13] = al|3;
	config[14] = (addr>>8)&0xff;

	config[11] = (((addr>>16)&0x3)<<3)|cfgarea<<2|2|1;

	res = config[15];
	config[13] = al|2;
	res = res<<8;
	res |= config[15];
	config[13] = al|1;
	res = res<<8;
	res |= config[15];
	config[13] = al|0;
	res = res<<8;
	res |= config[15];

	return res;
}

void writeFlash(unsigned long addr, unsigned char cfgarea, unsigned long data)
{
	unsigned char al;

	addr = addr<<2;

	al = addr&0xff;
	config[13] = al|0;
	config[14] = (addr>>8)&0xff;

	config[15] = data&0xff;
	config[13] = al|1;
	data = data>>8;
	config[15] = data&0xff;
	config[13] = al|2;
	data = data>>8;
	config[15] = data&0xff;
	config[13] = al|3;
	data = data>>8;
	config[15] = data;

	config[11] = (((addr>>16)&0x3)<<3)|cfgarea<<2|2|0;
}

//void displayFlash(
//{
//	cprintf("%lx ",readFlash(config, 0x0, 0));
//	cprintf("%lx ",readFlash(config, 0x1, 0));
//	cprintf("%lx ",eadFlash(config, 0x2, 0));
//	cprintf("%lx ",readFlash(config, 0x3, 0));
//	cprintf("\r\n");
//	cprintf("%lx ",readFlash(config, 0x2000, 0));
//	cprintf("%lx ",readFlash(config, 0x2001, 0));
//	cprintf("%lx ",readFlash(config, 0x2002, 0));
//	cprintf("%lx ",readFlash(config, 0x2003, 0));
//	cprintf("\r\n");
//	cprintf("%lx ",readFlash(config, 0x0, 1));
//	cprintf("%lx ",readFlash(config, 0x1, 1));
//	cprintf("\r\n");
//	cprintf("%lx ",readFlash(config, 0x4000, 0));
//	cprintf("%lx ",readFlash(config, 0x4001, 0));
//	cprintf("%lx ",readFlash(config, 0x4002, 0));
//	cprintf("%lx ",readFlash(config, 0x4003, 0));
//	cprintf("\r\n");
//	cprintf("%lx ",readFlash(config, 0x6000, 0));
//	cprintf("%lx ",readFlash(config, 0x6001, 0));
//	cprintf("%lx ",readFlash(config, 0x6002, 0));
//	cprintf("%lx ",readFlash(config, 0x6003, 0));
//	cprintf("\r\n");
//}

void writeFlashContentsToFile()
{
	FILE * output;
	unsigned long addr;
	unsigned long * buffer = (unsigned long *)malloc(1024);

	output = fopen("d3:flash.bin","w");
	for (addr=0;addr!=0xe600;addr+=256)
	{
		unsigned short i;
		for (i=0;i!=256;++i)
			buffer[i] = readFlash(addr+i,0);
		fwrite(&buffer[0],1024,1,output);
	}

	fclose(output);

	free(buffer);
}

void writeProtect(unsigned char onoff)
{
	unsigned long data = readFlash(1, 1);
	unsigned long mask = 0x1f;
	mask = mask << 23;
	if (onoff)
		data = data|mask;
	else
		data = data&~mask;
	writeFlash(1,1,data);
}

void flashContentsFromFile()
{
	FILE * input;
	unsigned int addr;
	unsigned long * buffer = (unsigned long *)malloc(1024);

	writeProtect(0);

	input = fopen("d3:flash.bin","r");
	for (addr=0;addr!=0xe600;addr+=256)
	{
		unsigned short i;
		fread(&buffer[0],1024,1,input);
		for (i=0;i!=256;++i)
			writeFlash(addr+i,0,buffer[i]);
	}

	fclose(input);

	writeProtect(1);

	free(buffer);
}

void erasePageContainingAddress(unsigned long addr)
{
	unsigned long data;
	unsigned long sectormask = 0x7;
	unsigned long pagemask = 0xfffff;
	unsigned long status;
	sectormask = sectormask << 20;

	data = readFlash(1,1);
	data = data | sectormask;
	data = data&~pagemask;
	data = data|(addr>>11); //2k pages
	writeFlash(1,1,data);

	for(;;)
	{
		status = readFlash(0,1);
		if ((status&0x3)==0) break;
	}
}

void eraseSector(unsigned char sector)
{
	unsigned long data;
	unsigned long sectormask = 0x7;
	unsigned long pagemask = 0xfffff;
	unsigned long status;
	sectormask = sectormask << 20;

	data = readFlash(1,1);
	data = data | pagemask;
	data = data&~sectormask;
	data = data|(((unsigned long)sector)<<20);
	writeFlash(1,1,data);

	for(;;)
	{
		status = readFlash(0,1);
		if ((status&0x3)==0) break;
	}
}

void render(unsigned long * flash1, unsigned long * flash2, unsigned char line, unsigned char col)
{
    unsigned char pokeys;
    unsigned char val;
    unsigned char i;
    clrscr();
    bgcolor(0);
    bordercolor(0);
    //textcolor(0xa);
    chline(40);

    cprintf("Pokeymax config v0.3 ");

    cprintf(" Core:");
    for (i=0;i!=8;++i)
    {
	    config[4] = i;
	    cprintf("%c",config[4]);
    }
    cprintf("\r\n");
    val = config[1];
    pokeys = val&0x3;
    switch (pokeys)
    {
	    case 0:
		    pokeys = 1;
		    break;
	    case 1:
		    pokeys = 2;
		    break;
	    case 2:
		    pokeys = 4;
		    break;
    }
    cprintf("Pokey:%d sid:%d psg:%d covox:%d sample:%d\r\n",pokeys,(val&4)==4 ? 2 : 0,(val&8)==8 ? 2 : 0,(val&16)==16 ? 4 : 0,(val&32)==32 ? 1 : 0);
    chline(40);

    val = (*flash1)&0xff;
    revers(line==1);
    cprintf("Mixing        : %s\r\n",((val&1)==1) ? "Non-linear" : "Linear");
    revers(line==2);
    cprintf("Channel mode  : %s\r\n",((val&4)==4) ? "On" : "Off");
    revers(line==3);
    cprintf("IRQ           : %s\r\n",((val&8)==8) ? "All pokey chips" : "Pokey 1");
    revers(line==4);
    cprintf("Mono support  : %s\r\n",((val&16)==16) ? "Play on both channels" : "Left only");
    revers(line==5);
    cprintf("Post divide   : ");
    val = ((*flash1)>>8)&0xff;
    for (i=0;i!=4;++i)
    {
	    unsigned char pd = (val&0x3);
    		switch (pd)
    		{
    		        case 0:
    		    	    pd = 1;
    		    	    break;
    		        case 1:
    		    	    pd = 2;
    		    	    break;
    		        case 2:
    		    	    pd = 4;
    		    	    break;
    		        case 3:
    		    	    pd = 8;
    		    	    break;
    		}
	    revers(line==5 && col==i);
	    cprintf("%d=%d ",i+1,pd);
	    val = val>>2;
    }
    cprintf("\r\n");

    revers(line==6);
    cprintf("GTIA mixing   : ");
    val = ((*flash1)>>16)&0xff;
    for (i=0;i!=4;++i)
    {
	    unsigned char pd = (val&0x1);
	    revers(line==6 && col==i);
	    cprintf("%d=%d ",i+1,pd);
	    val = val>>1;
    }
    cprintf("\r\n");
    val = ((*flash1)>>24)&0xff;
    revers(line==7);
    cprintf("PSG frequency : ");
    switch (val&3)
    {
	case 0:
		cprintf("2MHz");
	    break;
	case 1:
		cprintf("1MHz");
	    break;
	case 2:
		cprintf("PHI2");
	    break;
   }
    cprintf("\r\n");
    revers(line==8);
    cprintf("PSG stereo    : ");
    switch ((val&12)>>2)
    {
    case 0:
	    cprintf("mono   (L:ABC R:ABC)");
	    break;
    case 1:
	    cprintf("polish (L:AB  R:BC )");
	    break;
    case 2:
	    cprintf("czech  (L:AC  R:BC )");
	    break;
    case 3:
	    cprintf("l/r    (L:111 R:222)");
	    break;
    }
    cprintf("\r\n");
    revers(line==9);
    cprintf("PSG envelope  : ");
    if ((val&16)==16)
	    cprintf("16 steps\r\n");
    else
	    cprintf("32 steps\r\n");

    revers(0);
    chline(40);

    cprintf("Options:\r\n");
    cprintf("  (A)pply config\r\n");
    if (has_flash())
    {
	    cprintf("  (S)tore config\r\n");
	    cprintf("  (U)pdate core\r\n");
    }
    cprintf("  (Q)uit\r\n");
    cprintf("Use arrows and enter to change config");

    *flash2; // silence warning
}

void changeValue(unsigned long * flash1, unsigned long * flash2, unsigned char line, unsigned char col)
{
    unsigned char shift;
    unsigned char mask=1;
    unsigned char max=1;

    unsigned char val;
    unsigned long tmp;

    *flash2; // silence warning

    switch(line)
    {
    case 1:
	    shift = 0;
	    break;
    case 2:
	    shift = 2;
	    break;
    case 3:
	    shift = 3;
	    break;
    case 4:
	    shift = 4;
	    break;
    case 5:
	    shift = 8 + (col<<1);
	    mask = 3;
	    max = 3;
	    break;
    case 6:
	    shift = 16 + col;
	    break;
    case 7:
	    mask = 3;
            shift = 24;
	    max = 2;
	    break;
    case 8:
	    mask = 3;
            shift = 26;
	    max = 3;
	    break;
    case 9:
            shift = 28;
	    break;
    }

    tmp = mask;
    tmp = tmp<<shift;
    val = ((*flash1)&tmp)>>shift;
    *flash1 = (*flash1)&~tmp;
    val = val+1;
    if (val>max) val=0;
    tmp = val;
    tmp = tmp<<shift;
    *flash1 |= tmp;
}

void applyConfig(unsigned long flash1, unsigned long flash2)
{
	config[0] = flash1&0xff;
	config[2] = (flash1>>8)&0xff;
	config[3] = (flash1>>16)&0xff;
	config[5] = (flash1>>24)&0xff;
	flash2 ==0;
//	                                   SATURATE_NEXT <= flash_do(0);
//                                        -- 1 reserved...
//                                CHANNEL_MODE_NEXT <= flash_do(2);
//                                IRQ_EN_NEXT <= flash_do(3);
//                                DETECT_RIGHT_NEXT <= flash_do(4);
//                                        -- 5-7 reserved
//                                POST_DIVIDE_NEXT <= flash_do(15 downto 8);
//                                GTIA_ENABLE_NEXT <= flash_do(19 downto 16);
//                                        -- 23 downto 20 reserved
//                                PSG_FREQ_NEXT <= flash_do(25 downto 24);
//                                PSG_STEREOMODE_NEXT <= flash_do(27 downto 26);
//                                PSG_ENVELOPE16_NEXT <= flash_do(28);
//                                        -- 31 downto 29 reserved
}

void saveConfig(unsigned long flash1, unsigned long flash2)
{
    clrscr();
    bgcolor(0x46);
    //textcolor(0xa);
    chline(40);
    cprintf("Saving config\r\n");
    chline(40);

    cprintf("Press Y to confirm\r\n");
    while(!kbhit());
    if (cgetc()=='y') 
    {
        unsigned long * buffer = (unsigned long *)malloc(2048);
	unsigned short i = 0;

	cprintf("Backing up page\r\n");
	for (i=2;i!=512;++i)
	{
		buffer[i] = readFlash(i,0);
	}
	writeProtect(0);
	cprintf("Erasing page\r\n");
	erasePageContainingAddress(0);
	cprintf("Writing new page\r\n");
	buffer[0] = flash1;
	buffer[1] = flash2;
	for (i=0;i!=512;++i)
	{
		writeFlash(i,0,buffer[i]);
	}
	writeProtect(1);

        free(buffer);
    }

    bgcolor(0x00);
}

void updateCore()
{
    unsigned long flash1 = readFlash(0,0);
    unsigned long flash2 = readFlash(1,0); //unused for now

    clrscr();
    bgcolor(0x34);
    //textcolor(0xa);
    chline(40);
    cprintf("Updating core\r\n");
    chline(40);

    cprintf("Please insert core.bin into D4\r\n");
    cprintf("Press Y to confirm core update\r\n");
    while(!kbhit());
    if (cgetc()=='y') 
    {
    	FILE * input = fopen("d4:core.bin","r");
    	if (!input)
    	{
    		cprintf("Failed to open file!\r\n");
    		sleep(3);
    	}
    	else
    	{
	    unsigned char version[8];
	    unsigned char valid;
	    unsigned char i;

	    cprintf("\r\n");
            chline(40);
            cprintf("DO NOT TURN OFF THE COMPUTER\r\n");
            chline(40);
	    cprintf("\r\n");

	    cprintf("File opened\r\n");
	    fread(&version[0],8,1,input);
	    // Verify validity!
	    valid = 0;
  	    for (i=3;i!=8;++i)
  	    {
  	            config[4] = i;
                    if (config[4]!=version[i])
	            {
	          	  cprintf("Invalid core");
			  sleep(3);
	          	  break;
	            }
		    valid = 1;
  	    }
	    if (valid)
	    {
	    	//fseek(input,0,SEEK_SET);
	        fclose(input);
		input = fopen("d4:core.bin","r");
	    	writeProtect(0);

	    	cprintf("Erasing");
	    	eraseSector(1);
	    	cputc('.');
	    	eraseSector(2);
	    	cputc('.');
	    	eraseSector(3);
	    	cputc('.');
	    	eraseSector(4);
	    	cprintf(" Done\r\n");

		config[4] = 5; //e.g 114M08QC 
		               //    01234567

	    	cprintf("Flashing M0%d... please wait",config[4]);
	    	{
	    	    unsigned long addr;
	    	    unsigned long maxaddr;
	    	    unsigned long * buffer = (unsigned long *)malloc(1024);
		    unsigned char t=0;

		    maxaddr = config[4]=='4' ? 0xd600 : 0xe600; // d600 for m04, e600 for m08. Default to 08 so DEVELPR works

	    	    for (addr=0;addr!=maxaddr;addr+=256) 
	    	    {
	    	    	unsigned long i;
			gotoxy(0,20);
			cprintf("%c  %d/%d      ",(t ? '/' : '\\'),(unsigned char)(1+(addr>>8)),(unsigned char)(maxaddr>>8));
			t = !t;

	    	    	fread(&buffer[0],1024,1,input);
	    	    	if (addr==0)
	    	    	{
				// keep our config...
	    	    		buffer[0] = flash1;
	    	    		buffer[1] = flash2;
	    	    	}
	    	    	for (i=0;i!=256;++i)
			{
				bordercolor(i);
	    	    		writeFlash(addr+i,0,buffer[i]);
			}
	    	    }

	    	    writeProtect(1);

	    	    free(buffer);
	    	}
	    }
    	}
    	fclose(input);
    }
    bgcolor(0x00);
    bordercolor(0x00);

    //writeFlashContentsToFile();
}

int main (void)
{
    unsigned char line,col,quit;
    unsigned long flash1;
    unsigned long flash2;
    if (pokey[12] != 1)
    {
	    cprintf("Pokeymax not found!");
	    sleep(5);
	    return -1;
    }

    pokey[12] = 0x3f; // select config area

    // We have just 8 bytes of data for config
    flash1 = 0; //readFlash(0,0);
    flash2 = 0; //readFlash(1,0); //unused for now

    flash1 = 
	    (((unsigned long)config[5])<<24) |
	    (((unsigned long)config[3])<<16) |
	    (((unsigned long)config[2])<<8) |
	    (((unsigned long)config[0]));

    line = 1;
    col = 0;
    quit = 0;

    while (!quit)
    {
        render(&flash1,&flash2,line,col);

	while (!kbhit());
        switch (cgetc())
	{
        case CH_CURS_UP:
		if (line>1)
		    line = line-1;
		col = 0;
		break;
        case CH_CURS_DOWN:
		if (line<9)
		    line = line+1;
		col = 0;
		break;
        case CH_CURS_LEFT:
		if (col>0)
			col =col-1;
		break;
        case CH_CURS_RIGHT:
		if (col<3)
			col =col+1;
		break;
        case CH_ENTER:
		changeValue(&flash1,&flash2,line,col);
		break;
        case 'a':
		// Apply config
		applyConfig(flash1,flash2);
		break;
        case 's':
		// Save config
                if (has_flash()) saveConfig(flash1,flash2);
		break;
        case 'u':
		// Update core
                if (has_flash()) updateCore();
		break;
        case 'q':
		quit = 1;
		break;
        }
    }

/*	    displayFlash(config);
	    //writeFlashContentsToFile(config);
	    //erasePageContainingAddress(config,0x0);
	    eraseSector(config,1);
	    eraseSector(config,2);
	    eraseSector(config,3);
	    eraseSector(config,4);
	    displayFlash(config);
	    flashContentsFromFile(config);
	    displayFlash(config);*/

    pokey[12] = 0x0; // deselect config area
    return EXIT_SUCCESS;
}


