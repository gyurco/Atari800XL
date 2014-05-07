#include "freeze.h"

void freeze()
{
	// Copy base 64k to ...

	unsigned volatile char * store  = 0xf80000; // SRAM...
	unsigned volatile char * store2 = 0xfc0000; // custom chips...

	mem = 0x9c00 + 0x10000;
	// Copy 1k from 0x$9c00 to sdram
	// 0x200000; sram
	// 0x800000; sdram (always use...)
	for (i=0x0; i!=1024; i++)
	{
		store[i] = mem[i];
	}
	for (i=0x40; i!=1024; i++)
	{
		mem[i] = 0;
	}

	// store custom chips
	store_portb = *atari_portb;
	{
		//gtia
		mem2 = 0x20000;
		mem3 = 0x10000;
		for (i=0xd000; i!=0xd01f; i++)
		{
			store2[i] = mem2[i];
			mem3[i] = 0;
		}
		//pokey1/2
		for (i=0xd200; i!=0xd21f; i++)
		{
			store2[i] = mem2[i];
			mem3[i] = 0;
		}
		//antic
		for (i=0xd400; i!=0xd40f; i++)
		{
			store2[i] = mem2[i];
			mem3[i] = 0;
		}
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
	for (i=0; i!=sizeof(dl); ++i)
	{
		mem[i] = dl[i];
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
	*atari_portb = 0xff;
	*atari_skctl = 0x3;
	*atari_chactl = 0x2;
}

void restore()
{
	// Restore memory
	mem = 0x9c00 + 0x10000;
	for (i=0x040; i!=1024; i++)
	{
		mem[i] = store[i];
	}

	// Restore custom chips
	{
		//gtia
		mem3 = 0x10000;
		for (i=0xd000; i!=0xd01f; i++)
		{
			mem3[i] = store2[i];
		}
		//pokey1/2
		for (i=0xd200; i!=0xd21f; i++)
		{
			mem3[i] = store2[i];
		}
		//antic
		for (i=0xd400; i!=0xd40f; i++)
		{
			mem3[i] = store2[i];
		}
	}

	*atari_portb = store_portb;
}

