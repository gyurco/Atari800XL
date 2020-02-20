#include "pll2.h"
#include "Si5351A-RevB-Registers.h"
#include "regs.h"
#include "pll.h"
#include "integer.h"
#include "spibase.h"

void set_pll2()
{
	//wait_us(5000000);
	int i;
	unsigned int slave = 0x60; 
	unsigned int read = 0x1;
	unsigned int write = 0x0;

	if (1==*zpu_board)
		return;

	for (i=0;i!=SI5351A_REVB_REG_CONFIG_NUM_REGS;++i)
	{
		unsigned int addr = si5351a_revb_registers[i].address;
		unsigned int value = si5351a_revb_registers[i].value;

		*zpu_i2c_0 = (slave<<9) | write<<8 | addr;  // write addr (blocks until accepted)
		*zpu_i2c_0 = (slave<<9) | write<<8 | value; // write data (blocks until accepted)

		while ((*zpu_i2c_0)&0x100); // wait until busy not asserted
	}
}

void program_i2c_lh(unsigned int slave, int reg, uint8_t l, uint8_t h)
{
	unsigned int write = 0x0;
	*zpu_i2c_0 = (slave<<9) | write<<8 | 0xf0 | reg;  // write addr (blocks until accepted)
	*zpu_i2c_0 = (slave<<9) | write<<8 | l; // write data (blocks until accepted)
	*zpu_i2c_0 = (slave<<9) | write<<8 | h; // write data (blocks until accepted)

	while ((*zpu_i2c_0)&0x100); // wait until busy not asserted
}

void read16(uint16_t const * addr, uint8_t * l, uint8_t * h)
{
	uint8_t const * addr8 = (uint8_t const *)addr;
	*l = addr8[1];
	*h = addr8[0];
}

void program_i2c_videomode(unsigned int slave, uint16_t const * regs, unsigned int from, unsigned int noRegs)
{
	int i;
	for (i=from;i!=noRegs;++i)
	{
		uint8_t l,h;
		read16(regs+i,&l,&h);

		program_i2c_lh(slave, i, l, h);
	}
}

void set_crtc(uint16_t const * crtc_regs)
{
	program_i2c_lh(2,12,0,0); // disable576p


	uint8_t l,h;
	read16(crtc_regs+11,&l,&h);

	program_i2c_lh(2,11,l,h); // set the clock!
	program_i2c_lh(2,11,l,h); // set the clock again (looks like this transaction is lost after a clock change)

	program_i2c_videomode(2,crtc_regs,0,10);
	//program_i2c_lh(2,10,crtc_regs[10]); // set scaler and mode*/
	int scal = get_scaler();
	read16(crtc_regs+10,&l,&h);
	program_i2c_lh(2,10,l,scal); // set scaler and mode*/
	program_i2c_lh(2,12,1,0); // enable
}

void set_scale(uint16_t const * scale_regs)
{
	program_i2c_videomode(1,scale_regs,0,6);
	program_i2c_videomode(3,scale_regs+6,0,3);
}

void set_scaler_mode(int mode)
{
	readFlash(romstart+0x30000,2048,SCRATCH_MEM);
	uint8_t * addr = SCRATCH_MEM;
	addr = addr + (mode<<8);

	set_pll((video_pll_mode)*(addr+192));
	set_crtc(addr+64);
	set_scale(addr+128);
/* mode layout
 * 0  :name
   64 :crtc
   128:scaler
   192:freq
 */
}

