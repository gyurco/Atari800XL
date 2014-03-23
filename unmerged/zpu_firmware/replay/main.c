#include "regs.h"
#include "led.h"

void
wait_us(int unsigned num)
{
	// 28ish
	int unsigned cycles = num*28;
	*zpu_pause = cycles;
}

void clear_64k_ram()
{
	int i=0;
	// sdram from 8MB to 16MB
	// sram from 0x200000 

	*zpu_ledr = 0xf0f0f0f0;
	*zpu_ledg = 0x0;
	//wait_us(200000);
	
	for (i=0x200000; i!=0x210000; i+=1)
	{
		// TODO - use short!
		*(unsigned char volatile *)(i) = 0x0000;
	}

	*zpu_ledr = 0x55555555;
	*zpu_ledg = 0x55555555;

	for (i=0x800000; i!=0x810000; i+=4)
	{
		*(unsigned int volatile *)(i) = 0x00000000;
	}

	*zpu_ledr = 0;
	*zpu_ledg = 0xf0f0f0f0;
	//wait_us(200000);
	return;
}

void reset_6502(unsigned int reset_n)
{
	int prev = *zpu_config;
	if (reset_n == 1)
		*zpu_config = prev&~(1<<7);
	else
		*zpu_config = prev|(1<<7);
	// USES ASHIFTLEFT even with it disabled!! *reset_6502 = reset_n<<7;
}

void pause_6502(unsigned int pause)
{
	int prev = *zpu_config;
	if (pause == 0)
		*zpu_config = prev&~(1<<6);
	else
		*zpu_config = prev|(1<<6);
	// USES ASHIFTLEFT even with it disabled!! *reset_6502 = reset_n<<7;
}

int main(void)
{
	unsigned int i=0;
	unsigned char temp = 0;
	pause_6502(1);

		//wait_us(200000);
		reset_6502(0);
		*atari_nmien = 0x00;
		clear_64k_ram();
		reset_6502(1);
		pause_6502(0);
	for(;;);
}
