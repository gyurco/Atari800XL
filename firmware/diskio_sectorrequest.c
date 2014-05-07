#include "diskio.h"

#include "regs.h"

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

	*zpu_out4 = (sector<<8)|0xa5;
	while (*zpu_in4 != *zpu_out4)
	{
		// Wait until ready
	}

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
	mmc_sector_buffer = (unsigned char *)0x8000;  // 512 bytes in the middle of memory space!

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

DRESULT disk_writep (const BYTE* buff, DWORD sc)
{
	DRESULT res;


	if (!buff) {
		if (sc) {

			// Initiate write process

		} else {

			// Finalize write process

		}
	} else {

		// Send data to the disk

	}

	return res;
}

