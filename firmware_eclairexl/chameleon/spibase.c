#include "spibase.h"

#include "regs.h"

void init_romstart()
{
	int flashslot = (*zpu_in2)<<20;
	char memtmp[4];
	readFlash(flashslot,3,&memtmp[0]);
	int corelen =  (memtmp[0]<<16)+(memtmp[1]<<8)+(memtmp[2]);
	romstart = flashslot+corelen;
	
	/*uint32_t infolen;
	uint32_t infooff;
	readFlash(romstart-8,4,&infolen);
	readFlash(romstart-4,4,&infooff);
	uint32_t magic;
	readFlash(romstart-infolen,4,&magic);*/
	
	romstart = romstart+262144;
}
