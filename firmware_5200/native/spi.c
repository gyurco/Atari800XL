#include "spi.h"

#include "integer.h"

#include <stdio.h>

int spi_slow; // 1 is slow
int spi_chip_select_n; // 0 is selected
int display;

// access routines
void setSpiFast()
{
	fprintf(stderr,"SPI:Fast\n");
}

void setSpiSlow()
{
	fprintf(stderr,"SPI:Slow\n");
}

void set_spi_clock_freq() // avr handles spi clock?
{
	setSpiFast();
}

void spiInit()
{
	fprintf(stderr,"SPI:Init Slow,deselect\n");
}

void mmcChipSelect(int select)
{
	spi_chip_select_n = !select;
	fprintf(stderr,"SPI:%s\n",select? "Select":"deselect");
}

u08 spiTransferByte(u08 data)
{
	fprintf(stderr,"SPI:Send:%02x\n",data);

	return 0xff; // TODO...
}

u08 spiTransferFF()
{
	return spiTransferByte(0xFF);
}

void spiReceiveData(u08 * from, u08 * to)
{
	while (from!=to)
	{
		*from = spiTransferFF();
		++from;
	}
}

