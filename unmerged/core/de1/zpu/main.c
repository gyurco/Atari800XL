#include "types.h"
#include "regs.h"
#include "pause.h"
#include "debug.h"
#include "pff.h"
#include "diskio.h"

#define send_ACK()	USART_Transmit_Byte('A');
#define send_NACK()	USART_Transmit_Byte('N');
#define send_CMPL()	USART_Transmit_Byte('C');
#define send_ERR()	USART_Transmit_Byte('E');

/* BiboDos needs at least 50us delay before ACK */
#define DELAY_T2_MIN wait_us(100);

/* the QMEG OS needs at least 300usec delay between ACK and complete */
#define DELAY_T5_MIN wait_us(300);

/* QMEG OS 3 needs a delay of 150usec between complete and data */
#define DELAY_T3_PERIPH wait_us(150);

FATFS fatfs;
DIR dir;
FILINFO filinfo;
struct ATRHeader atr_header;
int selfileno;
int debugmode;
int validfile;
int speed;
#define speedslow 0x28
#define speedfast 0x6
#define XEX_SECTOR_SIZE 128

void
wait_us(int unsigned num)
{
	// 57.5MHz
	int unsigned cycles = num*57 + num/2;
	*zpu_pause = cycles;
}

void openfile(const char * filename);
void sdcard();
void mmcReadCached(u32 sector);
u32 n_actual_mmc_sector;
extern unsigned char mmc_sector_buffer[512];
unsigned char atari_sector_buffer[256];
unsigned char get_checksum(unsigned char* buffer, u16 len);

#define    TWOBYTESTOWORD(ptr,val)           (*((u08*)(ptr)) = val&0xff);(*(1+(u08*)(ptr)) = (val>>8)&0xff);

void USART_Send_cmpl_and_atari_sector_buffer_and_check_sum(unsigned short len);
void clearAtariSectorBuffer()
{
	int i=256;
	while (--i)
		atari_sector_buffer[i] = 0;
}

int
filesize(char const * filename)
{
	char const * tmp;
	char const * tmp2;
	if (FR_OK != pf_opendir(&dir,"/"))
	{
		return 0;
	}

	while (FR_OK == pf_readdir(&dir,&filinfo) && filinfo.fname[0]!='\0')
	{
		if (filinfo.fattrib & AM_SYS)
		{
			continue;
		}
		if (filinfo.fattrib & AM_HID)
		{
			continue;
		}
		if (filinfo.fattrib & AM_DIR)
		{
			continue;
		}
	
		tmp = filename;
		tmp2 = filinfo.fname;
		while (1)
		{
			if (*tmp == *tmp2)
			{
				if (*tmp == '\0')
				{
					return filinfo.fsize;
				}
				++tmp;
				++tmp2;
			}
			else
				break;
		}
	}
	return 0;
}

void clear_ram()
{
	int i=0;
	// sdram from 8MB to 16MB
	// sram from 0x200000 
	*zpu_ledr = 0xffffffff;
	*zpu_ledg = 0x0;
	wait_us(600);
	
	for (i=0x200000; i!=0x280000; i+=1)
	{
		// TODO - use short!
		*(unsigned char volatile *)(i) = 0x0000;
	}

	*zpu_ledr = 0x55555555;
	*zpu_ledg = 0x55555555;

	for (i=0x800000; i!=0x1000000; i+=4)
	{
		*(unsigned int volatile *)(i) = 0x00000000;
	}

	*zpu_ledr = 0;
	*zpu_ledg = 0xffffffff;
	wait_us(600);
	return;
}

void clear_64k_ram()
{
	int i=0;
	// sdram from 8MB to 16MB
	// sram from 0x200000 

	*zpu_ledr = 0xf0f0f0f0;
	*zpu_ledg = 0x0;
	wait_us(200000);
	
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
	wait_us(200000);
	return;
}

void reset_6502(unsigned int reset_n)
{
	unsigned int volatile * config_6502 = (unsigned int *)(0*4+regbase);

	if (reset_n == 1)
		*config_6502 = 0;
	else
		*config_6502 = 1<<7;
	// USES ASHIFTLEFT even with it disabled!! *reset_6502 = reset_n<<7;
}

void pause_6502(unsigned int pause)
{
	unsigned int volatile * config_6502 = (unsigned int *)(0*4+regbase);

	if (pause == 0)
		*config_6502 = 0;
	else
		*config_6502 = 1<<6;
	// USES ASHIFTLEFT even with it disabled!! *reset_6502 = reset_n<<7;
}

void actions()
{
	unsigned int i = 0;

	if ((1&*zpu_key) == 1)
	{
		// stop 6502
		pause_6502(1);

		// write a display list in page 6 (TODO, backup first...)
		*((volatile unsigned char *)(0x600 + 0x10000)) = 0x70;
		*((volatile unsigned char *)(0x601 + 0x10000)) = 0x70;
		*((volatile unsigned char *)(0x602 + 0x10000)) = 0x70;
		*((volatile unsigned char *)(0x603 + 0x10000)) = 0x42;
		*((volatile unsigned char *)(0x604 + 0x10000)) = 0x40;
		*((volatile unsigned char *)(0x605 + 0x10000)) = 0x06;
		*((volatile unsigned char *)(0x606 + 0x10000)) = 0x70;
		*((volatile unsigned char *)(0x607 + 0x10000)) = 0x2;
		*((volatile unsigned char *)(0x608 + 0x10000)) = 0x70;
		*((volatile unsigned char *)(0x609 + 0x10000)) = 0x2;
		*((volatile unsigned char *)(0x60a + 0x10000)) = 0x70;
		*((volatile unsigned char *)(0x60b + 0x10000)) = 0x2;
		*((volatile unsigned char *)(0x60c + 0x10000)) = 0x70;
		*((volatile unsigned char *)(0x60d + 0x10000)) = 0x70;
		*((volatile unsigned char *)(0x60e + 0x10000)) = 0x41;
		*((volatile unsigned char *)(0x60f + 0x10000)) = 0x00;
		*((volatile unsigned char *)(0x610 + 0x10000)) = 0x06;

		*((volatile unsigned char *)(0x640 + 0x10000)) = 'H';
		*((volatile unsigned char *)(0x641 + 0x10000)) = 'E';
		*((volatile unsigned char *)(0x642 + 0x10000)) = 'L';
		*((volatile unsigned char *)(0x643 + 0x10000)) = 'L';
		*((volatile unsigned char *)(0x644 + 0x10000)) = 'O';

		// point antic at my display list
		*atari_dlistl = 0x00;
		*atari_dlisth = 0x06;

		// wait 10 seconds
		for (i=0; i!=10000; ++i)
		{
			*atari_colbk = *atari_random;
			wait_us(1000);
		}

		// start 6502
		pause_6502(0);
	}

	if ((2&*zpu_key) == 2)
	{
		int i;
		int fileno;
		int skip;
		int plotted = 0;
		unsigned char volatile * mem;

		// OSD file selector...
		// stop 6502
		pause_6502(1);
		clear_64k_ram();
	
		char dl[] = {
			0x70,0x70,0x70,
			0x42,0x40,0x9c,
			0x2,0x2,0x2,0x2,0x2,
			0x2,0x2,0x2,0x2,0x2,
			0x2,0x2,0x2,0x2,0x2,
			0x2,0x2,0x2,0x2,0x2,
			0x2,0x2,0x2,
			0x70,
			0x41,0x00,0x06
		};
		mem = 0x600 + 0x10000;
		for (i=0; i!=sizeof(dl); ++i)
		{
			mem[i] = dl[i];
		}

		// point antic at my display list
		*atari_dlistl = 0x00;
		*atari_dlisth = 0x06;
		*atari_colbk = 0x00;
		*atari_colpf1 = 0x0f;
		*atari_colpf2 = 0x00;
		*atari_prior = 0x00;
		*atari_portb = 0xff;
		*atari_chbase = 0xe0;
		*atari_dmactl = 0x22;

		initdebug(1);

		for (;;)
		{
			int i = 0;
			int go = 0;
			fileno = 0;
			topofscreen();
			for (i=0; i!=(24*40); ++i)
			{
				*(unsigned char volatile *)(i+0x10000+40000) = 0x00;
			}
			if (FR_OK != pf_opendir(&dir,"/"))
			{
				debug("opendir failed\n");
				while(1);
			}

			plotted = 0;
			skip = 0;
			if (selfileno>20)
			{
				skip = selfileno-20;
				skip&=0xfffffffe;
			}
			if (selfileno<0)
			{
				selfileno = 0;
			}
			while (FR_OK == pf_readdir(&dir,&filinfo) && filinfo.fname[0]!='\0')
			{
				if (filinfo.fattrib & AM_SYS)
				{
					continue;
				}
				if (filinfo.fattrib & AM_HID)
				{
					continue;
				}
				if (filinfo.fattrib & AM_DIR)
				{
					debug("DIR ");
				}
				if (selfileno == fileno)
				{
					for (i=0;i!=256;++i)
					{
						atari_sector_buffer[i] = filinfo.fname[i];
						if (0==filinfo.fname[i]) break;
						filinfo.fname[i]+=128;
					}
				}
				if (--skip<0)
				{
					debug(filinfo.fname);
					++plotted;
					if (plotted&1)
					{
						setxpos(20);
					}
					else
					{
						debug("\n");
					}
					if (plotted==40)
					{
						break;
					}
				}
				fileno++;
			}
			debug("\n");
			setypos(21);
			openfile(atari_sector_buffer);
			for (;;)
			{
				unsigned char porta = *atari_porta;
				if (0==(porta&0x2)) // down
				{
					selfileno+=2;
					break;
				}
				else if (0==(porta&0x1)) // up
				{
					selfileno-=2;
					break;
				}
				else if (0==(porta&0x8)) // right
				{
					selfileno|=1;
					break;
				}
				else if (0==(porta&0x4)) // left
				{
					selfileno&=0xfffffffe;
					break;
				}
				else if (0==(*atari_trig0)) // fire
				{
					go = 1;
					break;
				}
				topofscreen();
				//plotnextnumber(porta);
				*atari_colbk = *atari_random;
				//wait_us(200);
			}
			if (go == 1)
			{
				debug("Booting...");
				wait_us(500000);

				// reset process
				reset_6502(0);
				*atari_nmien = 0x00;
				clear_64k_ram();
				reset_6502(1);
				break;
			}
			wait_us(80000);
		}
		initdebug(debugmode);
	}
	if ((4&*zpu_key) == 4)
	{
		// reset process
		reset_6502(0);
		reset_6502(1);
	}
	if ((8&*zpu_key) == 8)
	{
		// reset process
		reset_6502(0);
		*atari_nmien = 0x00;
		clear_64k_ram();
		reset_6502(1);
	}
}

int sdrive_main();
int main(void)
{
	unsigned int i=0;
	debugmode = 0;
	selfileno = 0;
	speed = speedslow;
	if (2==(2&(*zpu_switches)))
	{
		debugmode = 1;
	}

	initdebug(debugmode);

	if (debugmode)
	{
		reset_6502(0);
		*atari_nmien = 0x00;
		clear_64k_ram();
		reset_6502(1);

		wait_us(2000000);
	}

	if (1==(1&(*zpu_switches)))
	{
		sdcard();
	}

	reset_6502(0);
	*atari_nmien = 0x00;
	clear_64k_ram();
	reset_6502(1);

	while (1)
	{
		actions();
	}
	return 0;
}

/*-----------------------------------------------------------------------*/
/* Low level disk I/O module skeleton for Petit FatFs (C)ChaN, 2009      */
/*-----------------------------------------------------------------------*/

#include "diskio.h"



/*-----------------------------------------------------------------------*/
/* Initialize Disk Drive                                                 */
/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize (void)
{
	DSTATUS stat;

	n_actual_mmc_sector = 0xffffffff;
	do
	{
		mmcInit();
	}
	while(mmcReset());	//dokud nenulove, tak smycka (return 0 => ok!)

	set_spi_clock_freq();

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


struct ATRHeader
{
	u16 wMagic;
	u16 wPars;
	u16 wSecSize;
	u08 btParsHigh;
	u32 dwCRC;
} __attribute__((packed));
int offset;
int xex_loader;
int xex_size;
uint8_t xex_name[12];
uint8_t boot_xex_loader[179] = {
	0x72,0x02,0x5f,0x07,0xf8,0x07,0xa9,0x00,0x8d,0x04,0x03,0x8d,0x44,0x02,0xa9,0x07,
	0x8d,0x05,0x03,0xa9,0x70,0x8d,0x0a,0x03,0xa9,0x01,0x8d,0x0b,0x03,0x85,0x09,0x60,
	0x7d,0x8a,0x48,0x20,0x53,0xe4,0x88,0xd0,0xfa,0x68,0xaa,0x8c,0x8e,0x07,0xad,0x7d,
	0x07,0xee,0x8e,0x07,0x60,0xa9,0x93,0x8d,0xe2,0x02,0xa9,0x07,0x8d,0xe3,0x02,0xa2,
	0x02,0x20,0xda,0x07,0x95,0x43,0x20,0xda,0x07,0x95,0x44,0x35,0x43,0xc9,0xff,0xf0,
	0xf0,0xca,0xca,0x10,0xec,0x30,0x06,0xe6,0x45,0xd0,0x02,0xe6,0x46,0x20,0xda,0x07,
	0xa2,0x01,0x81,0x44,0xb5,0x45,0xd5,0x43,0xd0,0xed,0xca,0x10,0xf7,0x20,0xd2,0x07,
	0x4c,0x94,0x07,0xa9,0x03,0x8d,0x0f,0xd2,0x6c,0xe2,0x02,0xad,0x8e,0x07,0xcd,0x7f,
	0x07,0xd0,0xab,0xee,0x0a,0x03,0xd0,0x03,0xee,0x0b,0x03,0xad,0x7d,0x07,0x0d,0x7e,
	0x07,0xd0,0x8e,0x20,0xd2,0x07,0x6c,0xe0,0x02,0x20,0xda,0x07,0x8d,0xe0,0x02,0x20,
	0xda,0x07,0x8d,0xe1,0x02,0x2d,0xe0,0x02,0xc9,0xff,0xf0,0xed,0xa9,0x00,0x8d,0x8e,
	0x07,0xf0,0x82 };
//  relokacni tabulka neni potreba, meni se vsechny hodnoty 0x07
//  (melo by byt PRESNE 20 vyskytu! pokud je jich vic, pak bacha!!!)

void byteswap(WORD * inw)
{
	unsigned char * in = (unsigned char *)inw;
	unsigned char temp = in[0];
	in[0] = in[1];
	in[1] = temp;
}

struct command
{
	u08 deviceId;
	u08 command;
	u08 aux1;
	u08 aux2;
	u08 chksum;
} __attribute__((packed));
void getCommand(struct command * cmd)
{
	int expchk;

	//debug("Waiting for command\n");
	//USART_Data_Ready();
	while (0 == (1&(*zpu_sio)));
	//debug("Init:");
	//plotnextnumber(*zpu_sio);
	USART_Init(speed+6);
	//plotnextnumber(speed);
	//debug("\n");
	while (1 == (1&(*zpu_sio)))
	{
		actions();
	}
	cmd->deviceId = USART_Receive_Byte();
	cmd->command = USART_Receive_Byte();
	cmd->aux1 = USART_Receive_Byte();
	cmd->aux2 = USART_Receive_Byte();
	cmd->chksum = USART_Receive_Byte();
	while (0 == (1&(*zpu_sio)));
	debug("cmd:");
	//debug("Gone high\n");
	atari_sector_buffer[0] = cmd->deviceId;
	atari_sector_buffer[1] = cmd->command;
	atari_sector_buffer[2] = cmd->aux1;
	atari_sector_buffer[3] = cmd->aux2;
	expchk = get_checksum(&atari_sector_buffer[0],4);

	//debug("Device id:");
	plotnextnumber(cmd->deviceId);
	//debug("\n");
	//debug("command:");
	plotnextnumber(cmd->command);
	//debug("\n");
	//debug("aux1:");
	plotnextnumber(cmd->aux1);
	//debug("\n");
	//debug("aux2:");
	plotnextnumber(cmd->aux2);
	//debug("\n");
	//debug("chksum:");
	plotnextnumber(cmd->chksum);
	plotnextnumber(expchk);

	if (expchk!=cmd->chksum || USART_Framing_Error())
	{
		debug("ERR ");
		//wait_us(1000000);
		if (speed == speedslow)
		{
			speed = speedfast;
			debug("SPDF");
			plotnextnumber(speed);
		}
		else
		{
			speed = speedslow;
			debug("SPDS");
			plotnextnumber(speed);
		}
	}
	debug("\n");

	DELAY_T2_MIN;
}

void openfile(const char * filename)
{
	WORD read = 0;
	int dot = 0;
	int xfd = 0;
	validfile = 0;
	debug("Opening:");
	debug(filename);
	debug(":");
	if (FR_OK!=pf_open(filename))
	{
		debug("fail\n");
		return; //while(1);
		//while(1);
	}
	debug("ok\n");

	while (1)
	{
		if (filename[dot] == '\0')
			break;
		if (filename[dot] != '.')
		{
			++dot;
			continue;
		}
		if (filename[dot+1] == 'X' || filename[dot+1] == 'x')
			if (filename[dot+2] == 'F' || filename[dot+2] == 'f')
				if (filename[dot+3] == 'D' || filename[dot+3] == 'd')
				{
					xfd = 1;
					break;
				}
		break;
	}

	// Read header
	read = 0;
	pf_read(&atr_header, 16, &read);
	if (read!=16)
	{
		debug("Could not read header\n");
		return; //while(1);
	}
	byteswap(&atr_header.wMagic);
	byteswap(&atr_header.wPars);
	byteswap(&atr_header.wSecSize);
	/*debug("\nHeader:");
	plotnextnumber(atr_header.wMagic);
	plotnext(toatarichar(' '));
	plotnextnumber(atr_header.wPars);
	plotnext(toatarichar(' '));
	plotnextnumber(atr_header.wSecSize);
	plotnext(toatarichar(' '));
	plotnextnumber(atr_header.btParsHigh);
	plotnext(toatarichar(' '));
	plotnextnumber(atr_header.dwCRC);
	debug("\n");
	*/

	xex_loader = 0;
	if (xfd == 1)
	{
		debug("XFD ");
		// build a fake atr header
		offset = 0;
		atr_header.wMagic = 0x296;
		atr_header.wPars = filesize(filename)/16;
		atr_header.wSecSize = 0x80;
	}
	else if (atr_header.wMagic == 0xFFFF) // XEX
	{
		int i;
		debug("XEX ");
		offset = -256;
		xex_loader = 1;
		atr_header.wMagic = 0xffff;
		xex_size = filesize(filename);
		atr_header.wPars = xex_size/16;
		atr_header.wSecSize = XEX_SECTOR_SIZE;
		for (i=0;i!=12;++i)
			xex_name[i] = filename[i];
	}
	else if (atr_header.wMagic == 0x296) // ATR
	{
		debug("ATR ");
		offset = 16;
	}
	else
	{
		debug("Unknown file type");
		return;
	}

	if (atr_header.wSecSize == 0x80)
	{
		if (atr_header.wPars>(720*128/16))
			debug("MD ");
		else
			debug("SD ");
	}
	else if (atr_header.wSecSize == 0x100)
	{
		debug("DD ");
	}
	else if (atr_header.wSecSize < 0x100)
	{
		debug("XD ");
	}
	else
	{
		debug("BAD sector size");
		return;
	}	
	plotnextnumber(atr_header.wPars);
	debug("0\n");
	validfile = 1;
}

void sdcard()
{
	int i;
	int commandcount = 0;
	int badcommandcount = 0;
	WORD read;
	struct command command;
	int location;

	debug("sdcard\n");
	
	debug("disk_init:");
	if(disk_initialize()!=RES_OK)
	{
		debug("fail\n");
		return;
	}
	debug("ok\n");

	debug("mount:");
	if(pf_mount(&fatfs)!=FR_OK)
	{
		debug("fail\n");
		return;
	}
	debug("ok\n");

	debug("opendir:");
	if (FR_OK != pf_opendir(&dir,"/"))
	{
		debug("fail\n");
		return;
	}
	debug("ok\n");

	while (FR_OK == pf_readdir(&dir,&filinfo) && filinfo.fname[0]!='\0')
	{
		debug(filinfo.fname);
	}

	openfile("BOOT.ATR");

	reset_6502(0);
	*atari_nmien = 0x00;
	clear_64k_ram();
	reset_6502(1);
	
	USART_Init(speed+6);
	while (1)
	{
		getCommand(&command);
		++commandcount;
		if (commandcount==4 && (4==(4&(*zpu_switches))))
		{
			debug("Paused\n");
			pause_6502(1);
			while(1);
		}
		/*if (badcommandcount==8)
		{
			debug("Stuck?\n");
			pause_6502(1);
			while(1);
		}*/

  		if (command.deviceId == 0x31)
 	 	{
			int sent = 0;
			if (!validfile)
			{
				//USART_Transmit_Mode();
				//send_NACK();
				//USART_Wait_Transmit_Complete();
				//wait_us(100); // Wait for transmission to complete - Pokey bug, gets stuck active...
				//USART_Receive_Mode();
				continue;
			}

			switch (command.command)
			{
			case 0x3f:
				{
				debug("Speed:");
				int sector = ((int)command.aux1) + (((int)command.aux2&0x7f)<<8);
				USART_Transmit_Mode();
				send_ACK();
				clearAtariSectorBuffer();
				atari_sector_buffer[0] = speedfast;
				hexdump_pure(atari_sector_buffer,1);
				USART_Send_cmpl_and_atari_sector_buffer_and_check_sum(1);
				sent = 1;
		if (sector == 0)
		{
			speed = speedfast;
			debug("SPDF");
			plotnextnumber(speed);
		}
		else
		{
			speed = speedslow;
			debug("SPDS");
			plotnextnumber(speed);
		}
				}
			case 0x53:
				{
				unsigned char status;
				debug("Stat:");
				USART_Transmit_Mode();
				send_ACK();
				clearAtariSectorBuffer();

				status = 0x10; // Motor on;
				status |= 0x08; // write protected; // no write support yet...
				if (atr_header.wSecSize == 0x80) // normal sector size
				{
					if (atr_header.wPars>(720*128/16))
					{
						status |= 0x80; // medium density - or a strange one...
					}
				}
				else
				{
					status |= 0x20; // 256 byte sectors
				}
				atari_sector_buffer[0] = status;
				atari_sector_buffer[1] = 0xff;
				atari_sector_buffer[2] = 0xe0;
				atari_sector_buffer[3] = 0x0;
				hexdump_pure(atari_sector_buffer,4); // Somehow with this...
				USART_Send_cmpl_and_atari_sector_buffer_and_check_sum(4);
				sent = 1;
				plotnextnumber(atari_sector_buffer[0]); // and this... The wrong checksum is sent!!
				debug(":done\n");
				}
				break;
			case 0x50: // write
			case 0x57: // write with verify
			default:
				// TODO
				//USART_Transmit_Mode();
				//send_NACK();
				//USART_Wait_Transmit_Complete();
				//USART_Receive_Mode();
				break;
			case 0x52: // read
				{
				int sector = ((int)command.aux1) + (((int)command.aux2&0x7f)<<8);
				int sectorSize = 0;

				USART_Transmit_Mode();
				send_ACK();
				read = 0;
				debug("Sector:");
				plotnextnumber(sector);
				debug(":");
				if(xex_loader)         //n_sector>0 && //==0 se overuje hned na zacatku
				{
					//sektory xex bootloaderu, tj. 1 nebo 2
					u08 i,b;
					u08 *spt, *dpt;
					int file_sectors;

					//file_sectors se pouzije pro sektory $168 i $169 (optimalizace)
					//zarovnano nahoru, tj. =(size+124)/125
					file_sectors = ((xex_size+(u32)(XEX_SECTOR_SIZE-3-1))/((u32)XEX_SECTOR_SIZE-3));

					debug("XEX ");

					if (sector<=2)
					{
						debug("boot ");

						spt= &boot_xex_loader[(u16)(sector-1)*((u16)XEX_SECTOR_SIZE)];
						dpt= atari_sector_buffer;
						i=XEX_SECTOR_SIZE;
						do
						{
							b=*spt++;
							//relokace bootloaderu z $0700 na jine misto
							//TODO if (b==0x07) b+=bootloader_relocation;
							*dpt++=b;
							i--;
						} while(i);
					}
					else
					if(sector==0x168)
					{
						debug("numtobuffer ");
						//vrati pocet sektoru diskety
						//byty 1,2
						goto set_number_of_sectors_to_buffer_1_2;
					}
					else
					if(sector==0x169)
					{
						debug("name ");
						//fatGetDirEntry(FileInfo.vDisk.file_index,5,0);
						//fatGetDirEntry(FileInfo.vDisk.file_index,0); //ale musi to posunout o 5 bajtu doprava
			
						{
							u08 i,j;
							for(i=j=0;i<8+3;i++)
							{
								if( ((xex_name[i]>='A' && xex_name[i]<='Z') ||
									(xex_name[i]>='0' && xex_name[i]<='9')) )
								{
								  //znak je pouzitelny na Atari
								  atari_sector_buffer[j]=xex_name[i];
								  j++;
								}
								if ( (i==7) || (i==8+2) )
								{
									for(;j<=i;j++) atari_sector_buffer[j]=' ';
								}
							}
							//posune nazev z 0-10 na 5-15 (0-4 budou systemova adresarova data)
							//musi pozpatku
							for(i=15;i>=5;i--) atari_sector_buffer[i]=atari_sector_buffer[i-5];
							//a pak uklidi cely zbytek tohoto sektoru
							for(i=5+8+3;i<XEX_SECTOR_SIZE;i++)
								atari_sector_buffer[i]=0x00;
						}

						//teprve ted muze pridat prvnich 5 bytu na zacatek nulte adresarove polozky (pred nazev)
						//atari_sector_buffer[0]=0x42;							//0
						//jestlize soubor zasahuje do sektoru cislo 1024 a vic,
						//status souboru je $46 misto standardniho $42
						atari_sector_buffer[0]=(file_sectors>(0x400-0x171))? 0x46 : 0x42; //0

						TWOBYTESTOWORD(atari_sector_buffer+3,0x0171);			//3,4
set_number_of_sectors_to_buffer_1_2:
						TWOBYTESTOWORD(atari_sector_buffer+1,file_sectors);		//1,2
					}
					else
					if(sector>=0x171)
					{
						debug("data ");
						pf_lseek(((u32)sector-0x171)*((u32)XEX_SECTOR_SIZE-3));
						pf_read(&atari_sector_buffer[0], XEX_SECTOR_SIZE-3, &read);

						if(read<(XEX_SECTOR_SIZE-3))
							sector=0; //je to posledni sektor
						else
							sector++; //ukazatel na dalsi

						atari_sector_buffer[XEX_SECTOR_SIZE-3]=((sector)>>8); //nejdriv HB !!!
						atari_sector_buffer[XEX_SECTOR_SIZE-2]=((sector)&0xff); //pak DB!!! (je to HB,DB)
						atari_sector_buffer[XEX_SECTOR_SIZE-1]=read;
					}
					debug(" sending\n");

					sectorSize = XEX_SECTOR_SIZE;
				}
				else
				{
					location = offset;
					if (sector>3)
					{
						sector-=4;
						location += 128*3;
						location += sector*atr_header.wSecSize;
						sectorSize = atr_header.wSecSize;
					}
					else
					{
						location += 128*(sector-1);
						sectorSize = 128;
					}
					plotnextnumber(location);
					debug("\n");
					pf_lseek(location);
					pf_read(&atari_sector_buffer[0], sectorSize, &read);
				}

				//topofscreen();
				//hexdump_pure(atari_sector_buffer,sectorSize);
				//debug("Sending\n");
				USART_Send_cmpl_and_atari_sector_buffer_and_check_sum(sectorSize);
				sent = 1;
	
				//pause_6502(1);
				//hexdump_pure(0x10000+0x400,128);
				unsigned char chksumreceive = get_checksum(0x10000+0x400, sectorSize);
				debug(" receive:");
				plotnextnumber(chksumreceive);
				debug("\n");
				//pause_6502(1);
				//while(1);
				}
				
				break;
			}

			//wait_us(100); // Wait for transmission to complete - Pokey bug, gets stuck active...
	
			if (sent)
				USART_Wait_Transmit_Complete();
			USART_Receive_Mode();
		}
		else
		{
			++badcommandcount;
		}
	}
}
	
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

	u08 ret,retry;
	//predtim nez nacte jiny, musi ulozit soucasny
	// TODO mmcWriteCachedFlush();
	//az ted nacte novy
	retry=0; //zkusi to maximalne 256x
	do
	{
		ret = mmcRead(sector);	//vraci 0 kdyz ok
		retry--;
	} while (ret && retry);
	while(ret); //a pokud se vubec nepovedlo, tady zustane zablokovany cely SDrive!
	n_actual_mmc_sector=sector;
}

unsigned char get_checksum(unsigned char* buffer, u16 len)
{
	u16 i;
	u08 sumo,sum;
	sum=sumo=0;
	for(i=0;i<len;i++)
	{
		sum+=buffer[i];
		if(sum<sumo) sum++;
		sumo = sum;
	}
	return sum;
}

void USART_Send_Buffer(unsigned char *buff, u16 len)
{
	while(len>0) { USART_Transmit_Byte(*buff++); len--; }
}

void USART_Send_cmpl_and_atari_sector_buffer_and_check_sum(unsigned short len)
{
	u08 check_sum;
	debug("(send:");
	plotnextnumber(len);

	DELAY_T5_MIN;
	send_CMPL();

	// Hias: changed to 100us so that Qmeg3 works again with the
	// new bit-banging transmission code
	DELAY_T3_PERIPH;

	check_sum = 0;
	USART_Send_Buffer(atari_sector_buffer,len);
	// tx_checksum is updated by bit-banging USART_Transmit_Byte,
	// so we can skip separate calculation
	check_sum = get_checksum(atari_sector_buffer,len);
	USART_Transmit_Byte(check_sum);
	//hexdump_pure(atari_sector_buffer,len);
	debug(":chk:");
	plotnextnumber(check_sum);
	debug(")");
}
