#include "diskio.h"

#include "regs.h"

#include "printf.h"
extern int debug_pos;

void mmcReadCached(u32 sector);
u32 n_actual_mmc_sector;
unsigned char * mmc_sector_buffer;

void mmcReadCached(u32 sector)
{
	//debug("mmcReadCached");
	//plotnext(toatarichar(' '));
	//plotnextnumber(sector);
	//debug("\n");
	if(sector==n_actual_mmc_sector) return;
	//debug("mmcReadREAL");
	//plotnext(toatarichar(' '));
	//plotnextnumber(sector);
	//debug("\n");

	//u08 ret,retry;
	//predtim nez nacte jiny, musi ulozit soucasny
	// TODO mmcWriteCachedFlush();
	//az ted nacte novy
	//retry=0; //zkusi to maximalne 256x
	/*do
	{
		ret = mmcRead(sector);	//vraci 0 kdyz ok
		retry--;
	} while (ret && retry);
	while(ret); //a pokud se vubec nepovedlo, tady zustane zablokovany cely SDrive!
*/

	//printf("Reading sector:%d", sector);
	*zpu_out4 = sector|0x04000000;
	while (!*zpu_in4)
	{
		// Wait until ready
	}
	*zpu_out4 = 0;
	//printf(" RD1 ");
	while (*zpu_in4)
	{
		// Wait until ready cleared
	}

	//printf(" RD2 ");

	n_actual_mmc_sector=sector;
}


/*-----------------------------------------------------------------------*/
/* Initialize Disk Drive                                                 */
/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize (void)
{
	DSTATUS stat;

	n_actual_mmc_sector = 0xffffffff;
	//do
	//{
	//	mmcInit();
	//}
	//while(mmcReset());	//dokud nenulove, tak smycka (return 0 => ok!)

	//set_spi_clock_freq();

	// no longer in ram (yet!), misuse will break us...
	mmc_sector_buffer = (unsigned char *)0x4000;  // 512 bytes in the middle of memory space!

	stat = RES_OK;

	return stat;
}



/*-----------------------------------------------------------------------*/
/* Read Partial Sector                                                   */
/*-----------------------------------------------------------------------*/

DRESULT disk_readp (
	BYTE* dest,			/* Pointer to the destination object */
	DWORD sector,		/* Sector number (LBA) */
	WORD sofs,			/* Offset in the sector */
	WORD count			/* Byte count (bit15:destination) */
)
{
	DRESULT res;

	/*debug("readp:");
	plotnextnumber(sector);
	debug(" ");
	plotnextnumber((int)dest);
	debug(" ");
	plotnextnumber(sofs);
	debug(" ");
	plotnextnumber(count);
	debug(" ");
	plotnextnumber(atari_sector_buffer);
	debug(" ");
	plotnextnumber(mmc_sector_buffer);
	debug("\n");
	*/
	// Put your code here
	mmcReadCached(sector);
	for(;count>0;++sofs,--count)
	{
		unsigned char x = mmc_sector_buffer[sofs];
		//printf("char:%02x loc:%d", x,sofs);
		*dest++ = x;
	}

	res = RES_OK;

	return res;
}



/*-----------------------------------------------------------------------*/
/* Write Partial Sector                                                  */
/*-----------------------------------------------------------------------*/

DRESULT disk_writep (const BYTE* buff, DWORD sofs, DWORD count)
{
	DRESULT res;

	int i=sofs;
	int end=sofs+count;
	int pos = 0;

/*	debug_pos = 0;
	printf("WP:%x %d %d"),buff,sofs,count;
	debug_pos = -1;*/

	for (;i!=end;++i,++pos)
	{
                unsigned char temp = buff[pos];

                unsigned int volatile* addr = (unsigned int volatile *)&mmc_sector_buffer[i&~3];
                unsigned int prev = *(unsigned int volatile*)addr;
                ((char unsigned *)&prev)[i&3] = temp;
                *addr = prev;
		
		//mmc_sector_buffer[i] = buff[pos];
		//printf("char:%c loc:%d,", buff[pos],i);
	}

/*	debug_pos = 40;
	printf("WP DONE:%x %d %d"),buff,sofs,count;
	debug_pos = -1;*/

	res = RES_OK;

	return res;
}

void disk_writeflush()
{
/*	// Finalize write process
	int retry=16; //zkusi to maximalne 16x
	int ret;
	//printf(":WSECT:%d",n_actual_mmc_sector);
	do
	{
		ret = mmcWrite(n_actual_mmc_sector); //vraci 0 kdyz ok
		retry--;
	} while (ret && retry);
	//printf(":WD:");
*/

	/*debug_pos = 0;
	printf("WF");
	debug_pos = -1;*/

	//printf(" WTF:%d:%x ", n_actual_mmc_sector, ((unsigned int *)mmc_sector_buffer)[0]);

	*zpu_out4 = n_actual_mmc_sector|0x08000000;
	while (!*zpu_in4)
	{
		// Wait until ready
	}
	*zpu_out4 = 0;
	//printf(" PT1 ");
	while (*zpu_in4)
	{
		// Wait until ready cleared
	}

	//printf(" PT2 ");

	/*debug_pos = 40;
	printf("DONE");
	debug_pos = -1;*/
}

