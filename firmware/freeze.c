#include "freeze.h"

#include "regs.h"

unsigned char store_portb;
unsigned volatile char * store_mem;
unsigned volatile char * custom_mirror;
unsigned volatile char * atari_base;

void freeze_init(void * memory)
{
	store_mem = (unsigned volatile char *)memory;

	custom_mirror = (unsigned volatile char *)atari_regmirror;
	atari_base = (unsigned volatile char *)atari_regbase;
}

void freeze()
{
	int i;
	// store custom chips
	store_portb = *atari_portb;
	{
		//gtia
		for (i=0xd000; i!=0xd020; i++)
		{
			store_mem[i] = custom_mirror[i];
			atari_base[i] = 0;
		}
		//pokey1/2
		for (i=0xd200; i!=0xd220; i++)
		{
			store_mem[i] = custom_mirror[i];
			atari_base[i] = 0;
		}
		//antic
		for (i=0xd400; i!=0xd410; i++)
		{
			store_mem[i] = custom_mirror[i];
			atari_base[i] = 0;
		}
	}

	*atari_portb = 0xff;

	// Copy 64k ram to sdram
	// Atari screen memory...
	for (i=0x0; i!=0xd000; ++i)
	{
		store_mem[i] = atari_base[i];
	}
	for (i=0xd800; i!=0x10000; ++i)
	{
		store_mem[i] = atari_base[i];
	}

	//Clear, except dl (first 0x40 bytes)
	for (i=0x9c40; i!=(0x9c40+1024); i++)
	{
		atari_base[i] = 0;
	}

	// Put custom chips in a safe state
	// write a display list at 9c00
	char dl[] = {
		0x70,0x70,0x70,
		0x42,0x40,0x9c,
		0x2,0x2,0x2,0x2,0x2,
		0x2,0x2,0x2,0x2,0x2,
		0x2,0x2,0x2,0x2,0x2,
		0x2,0x2,0x2,0x2,0x2,
		0x2,0x2,0x2,
		0x70,
		0x41,0x00,0x9c
	};
	int j = 0;
	for (i=0x9c00; j!=sizeof(dl); ++i,++j)
	{
		atari_base[i] = dl[j];
	}

	// point antic at my display list
	*atari_dlistl = 0x00;
	*atari_dlisth = 0x9c;
	*atari_colbk = 0x00;
	*atari_colpf1 = 0x0f;
	*atari_colpf2 = 0x00;
	*atari_prior = 0x00;
	*atari_chbase = 0xe0;
	*atari_dmactl = 0x22;
	*atari_skctl = 0x3;
	*atari_chactl = 0x2;
}

void restore()
{
	int i;

	// Restore memory
	for (i=0x0; i!=0xd000; ++i)
	{
		atari_base[i] = store_mem[i];
	}
	for (i=0xd800; i!=0x10000; ++i)
	{
		atari_base[i] = store_mem[i];
	}

	// Restore custom chips
	{
		//gtia
		for (i=0xd000; i!=0xd020; i++)
		{
			atari_base[i] = store_mem[i];
		}
		//pokey1/2
		for (i=0xd200; i!=0xd220; i++)
		{
			atari_base[i] = store_mem[i];
		}
		//antic
		for (i=0xd400; i!=0xd410; i++)
		{
			atari_base[i] = store_mem[i];
		}
	}

	*atari_portb = store_portb;
}

