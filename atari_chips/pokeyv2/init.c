#include "stdio.h"
#include "stdlib.h"

int main(void)
{
/*
SATURATE_NEXT <= flash_do(0));
        -- 1 reserved...
CHANNEL_MODE_NEXT <= flash_do(2);
IRQ_EN_NEXT <= flash_do(3);
DETECT_RIGHT_NEXT <= flash_do(4);
        -- 5-7 reserved
POST_DIVIDE_NEXT <= flash_do(15 downto 8);
GTIA_DIVIDE_NEXT <= flash_do(19 downto 16);
        -- 23 downto 20 reserved
PSG_FREQ_NEXT <= flash_do(25 downto 24);
PSG_STEREOMODE_NEXT <= flash_do(27 downto 26);
PSG_ENVELOPE16_NEXT <= flash_do(28);
        -- 31 downto 29 reserved
	*/
	/*	DETECT_RIGHT_REG <= '1';
		IRQ_EN_REG <= '0';
		CHANNEL_MODE_REG <= '0';
		SATURATE_REG <= '1';
		POST_DIVIDE_REG <= "10100000"; -- 1/2 5v, 3/4 1v
		GTIA_ENABLE_REG <= "1100"; -- external only
		CONFIG_ENABLE_REG <= '0';
		VERSION_LOC_REG <= (others=>'0');
		PSG_FREQ_REG <= "00"; --2MHz
		PSG_STEREOMODE_REG <= "01"; --Polish
		PSG_ENVELOPE16_REG <= '0'; --32 step
	*/

	char * buffer = (char *) malloc(32768);
	int i=0;
	for (i=0;i!=32768;++i)
		buffer[i] = 0;

	int saturate = 1;
	int channel_mode = 0;
	int irq_en = 0;
	int detect_right = 1;
	buffer[0] |= (saturate&3)<<0;
	buffer[0] |= (channel_mode&1)<<2;
	buffer[0] |= (irq_en&1)<<3;
	buffer[0] |= (detect_right&1)<<4;
	int post_divide = 0b10100000;
	buffer[1] |= (post_divide&0xff)<<0;
	int gtia_enable = 0b1100;
	buffer[2] |= (gtia_enable&0xf)<<0;
	int psg_freq = 0;
	int psg_stereomode = 1;
	int psg_envelope16 = 0;
	buffer[3] |= (psg_freq&3)<<0;
	buffer[3] |= (psg_stereomode&3)<<2;
	buffer[3] |= (psg_envelope16&1)<<4;

	FILE * x =fopen("init.bin","w");
		fwrite(&buffer[0],1,32768,x);
	fclose(x);

	return 0;
}

