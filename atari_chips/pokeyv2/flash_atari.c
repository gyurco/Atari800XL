#include <stdio.h>
#include <stdlib.h>

extern const char text[];       /* In text.s */

unsigned long readFlash(unsigned char * config, unsigned long addr, unsigned char cfgarea)
{
	unsigned long res;
	unsigned char al;
	addr = addr<<2;

	al = addr&0xff;
	config[13] = al|3;
	config[14] = (addr>>8)&0xff;

	config[11] = (((addr>>16)&0x3)<<3)|cfgarea<<2|2|1;

/*	CPU_FLASH_ADDR_NEXT(17 downto 15) <= WRITE_DATA(5 downto 3);

       CPU_FLASH_CFG_NEXT <= WRITE_DATA(2);
      CPU_FLASH_REQUEST_NEXT <= WRITE_DATA(1);
     CPU_FLASH_WRITE_N_NEXT <= WRITE_DATA(0);*/

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

void dumpFlash(unsigned char * config)
{
	FILE * output;
	unsigned int addr;
	unsigned long * buffer = (unsigned long *)malloc(1024);

	printf("%lx ",readFlash(config, 0x0, 0));
	printf("%lx ",readFlash(config, 0x1, 0));
	printf("%lx ",readFlash(config, 0x2, 0));
	printf("%lx ",readFlash(config, 0x3, 0));
	printf("\n");
	printf("%lx ",readFlash(config, 0x2000, 0));
	printf("%lx ",readFlash(config, 0x2001, 0));
	printf("%lx ",readFlash(config, 0x2002, 0));
	printf("%lx ",readFlash(config, 0x2003, 0));
	printf("\n");
	printf("%lx ",readFlash(config, 0x0, 1));
	printf("%lx ",readFlash(config, 0x1, 1));
	printf("\n");
	printf("%lx ",readFlash(config, 0x4000, 0));
	printf("%lx ",readFlash(config, 0x4001, 0));
	printf("%lx ",readFlash(config, 0x4002, 0));
	printf("%lx ",readFlash(config, 0x4003, 0));
	printf("\n");
	printf("%lx ",readFlash(config, 0x6000, 0));
	printf("%lx ",readFlash(config, 0x6001, 0));
	printf("%lx ",readFlash(config, 0x6002, 0));
	printf("%lx ",readFlash(config, 0x6003, 0));
	printf("\n");

	output = fopen("d3:flash.bin","w");
	for (addr=0;addr!=0xe600;addr+=256)
	{
		unsigned short i;
		for (i=0;i!=256;++i)
			buffer[i] = readFlash(config,addr+i,0);
		fwrite(&buffer[0],1024,1,output);
	}

	fclose(output);

	free(buffer);
}

int main (void)
{
    unsigned char * pokey = (unsigned char *) 0xd200;

    printf("Pokeymax ");
    if (pokey[12] == 1)
    {
	    unsigned char * config = pokey+16;
	    unsigned char val;
	    unsigned char pokeys;
	    unsigned char i;

	    printf("detected!");

	    pokey[12] = 0x3f; // select config area

	    printf("version:");
	    for (i=0;i!=8;++i)
	    {
		    config[4] = i;
		    printf("%c",config[4]);
	    }
	    printf("\n");

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
	    printf("Pokey:%d sid:%d psg:%d covox:%d sample:%d\n",pokeys,(val&4)==4 ? 2 : 0,(val&8)==8 ? 2 : 0,(val&16)==16 ? 4 : 0,(val&32)==32 ? 1 : 0);
	    val = config[0];
	    printf("%s\n",((val&0)==0) ? "Non-linear" : "Linear");
	    printf("%s\n",((val&4)==4) ? "Per channel" : "Per pokey");
	    printf("%s\n",((val&8)==8) ? "Multiple irq lines" : "Only pokey 1 has irq");
	    printf("%s\n",((val&16)==16) ? "Play left on right, if right silent" : "Play left on left, right on right!");
	    val = config[2];
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
		    printf("channel %d uses 1/%d of the range per ic",i,pd);
		    val = val>>2;
		    printf("\n");
	    }
	    val = config[3];
	    for (i=0;i!=4;++i)
	    {
		    unsigned char pd = (val&0x1);
		    printf("channel %d %s gtia",i,pd ? "includes" : "excludes");
		    val = val>>1;
		    printf("\n");
	    }
	    val = config[5];	    
	    printf("PSG:");
	    switch (val&3)
	    {
		case 0:
			printf(" 2MHz");
		    break;
		case 1:
			printf(" 1MHz");
		    break;
		case 2:
			printf(" PHI2");
		    break;
	   }
	    switch ((val&12)>>2)
	    {
	    case 0:
		    printf(" mono");
		    break;
	    case 1:
		    printf(" polish");
		    break;
	    case 2:
		    printf(" czech");
		    break;
	    case 3:
		    printf(" l/r");
		    break;
	    }
	    if ((val&16)==16)
		    printf(" 16 step\n");
	    else
		    printf(" 32 step\n");

	    dumpFlash(config);
    }
    else
    {
	    printf("not found");
    }

    for (;;);
    return EXIT_SUCCESS;
}


