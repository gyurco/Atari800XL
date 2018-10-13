#include "spiflash.h"
#include "spi.h"

void readFlash(int address, int bytes, u08 * dest)
{
}

// TODO, come up with a scheme to avoid erase each time, e.g. write to next location 
void writeFlash(int address, int bytes, u08 * dest)
{
}

void readFlashId(int *id1, int *id2)
{
	*id1 = 0;
	*id2 = 0;
}

void eraseFlash(int address, int bytes)
{
}

int flashSectorSize()
{
	return 65536;
}


