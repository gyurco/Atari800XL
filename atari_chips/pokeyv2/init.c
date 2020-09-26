#include "stdio.h"
#include "stdlib.h"
#include <math.h>

int ima_step_table[89] = {
  7, 8, 9, 10, 11, 12, 13, 14, 16, 17,
  19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
  50, 55, 60, 66, 73, 80, 88, 97, 107, 118,
  130, 143, 157, 173, 190, 209, 230, 253, 279, 307,
  337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
  876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066,
  2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358,
  5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899,
  15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
};

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

	buffer[4] = 0; // 8580 filter
	buffer[5] = 0xff; // enable_all

	// 0x80(0x200 8-bit) adpcm step table - 90
	for (i=0x0; i!=89; ++i)
	{
		buffer[((0x80+i)<<2) + 0] = ima_step_table[i]&0xff;
		buffer[((0x80+i)<<2) + 1] = (ima_step_table[i]>>8)&0xff;
		buffer[((0x80+i)<<2) + 2] = (ima_step_table[i]>>16)&0xff;
		buffer[((0x80+i)<<2) + 3] = (ima_step_table[i]>>24)&0xff;
	}

	// 0x100(0x400 8-bit) psg volume table - 128
	int psgvoltablebase = 0x400;
	unsigned int * psgvoltable[4];
	psgvoltable[0] = (unsigned int *)(buffer+psgvoltablebase);
	psgvoltable[1] = (unsigned int *)(buffer+psgvoltablebase+(32*4));
	psgvoltable[2] = (unsigned int *)(buffer+psgvoltablebase+(64*4));
	psgvoltable[3] = (unsigned int *)(buffer+psgvoltablebase+(96*4));
	i = 0;
	psgvoltable[0][i++] = 0b0000000000000000; //ym2149 from octave capture I think (CONFIRM!!)
	psgvoltable[0][i++] = 0b0000000000011100;
	psgvoltable[0][i++] = 0b0000000000111101;
	psgvoltable[0][i++] = 0b0000000001100110;
	psgvoltable[0][i++] = 0b0000000010011001;
	psgvoltable[0][i++] = 0b0000000011010111;
	psgvoltable[0][i++] = 0b0000000100100011;
	psgvoltable[0][i++] = 0b0000000110000000;
	psgvoltable[0][i++] = 0b0000000111110001;
	psgvoltable[0][i++] = 0b0000001001111101;
	psgvoltable[0][i++] = 0b0000001100100111;
	psgvoltable[0][i++] = 0b0000001111111000;
	psgvoltable[0][i++] = 0b0000010011111000;
	psgvoltable[0][i++] = 0b0000011000110001;
	psgvoltable[0][i++] = 0b0000011110110001;
	psgvoltable[0][i++] = 0b0000100110000111;
	psgvoltable[0][i++] = 0b0000101111000111;
	psgvoltable[0][i++] = 0b0000111010001000;
	psgvoltable[0][i++] = 0b0001000111101000;
	psgvoltable[0][i++] = 0b0001011000001010;
	psgvoltable[0][i++] = 0b0001101100011001;
	psgvoltable[0][i++] = 0b0010000101001100;
	psgvoltable[0][i++] = 0b0010100011100011;
	psgvoltable[0][i++] = 0b0011001000101111;
	psgvoltable[0][i++] = 0b0011110110010010;
	psgvoltable[0][i++] = 0b0100101110000100;
	psgvoltable[0][i++] = 0b0101110010011000;
	psgvoltable[0][i++] = 0b0111000110000011;
	psgvoltable[0][i++] = 0b1000101100100001;
	psgvoltable[0][i++] = 0b1010101010000001;
	psgvoltable[0][i++] = 0b1101000011101111;
	psgvoltable[0][i++] = 0b1111111111111111;
	for (i=0;i!=32;++i)
	{
		//psgvoltable[1][i] = psgvoltable[0][i]; //ym2149
		psgvoltable[1][i] = psgvoltable[0][i]; //ay3 TODO
		psgvoltable[2][i] = (256*(pow(sqrt(2),i)/pow(sqrt(2),15)))-1; //datasheet of ym2149!
		psgvoltable[3][i] = i<<11; //linear
	}

	for (i=0;i!=32;++i)
	{
		printf("psg:%d:%ld:%ld:%ld:%ld\n",i,psgvoltable[0][i],psgvoltable[1][i],psgvoltable[2][i],psgvoltable[3][i]);
	}

	// 0x180(0x600 8-bit) pokey volume table - 128
	int pokeyvoltablebase = 0x600;
	unsigned int * pokeyvoltable[2];
	pokeyvoltable[0] = (unsigned int *)(buffer+pokeyvoltablebase);
	pokeyvoltable[1] = (unsigned int *)(buffer+pokeyvoltablebase+(64*4));
	i = 0;
	pokeyvoltable[1][i++] = 0x0022;
	pokeyvoltable[1][i++] = 0x0993;
	pokeyvoltable[1][i++] = 0x135E;
	pokeyvoltable[1][i++] = 0x1D9A;
	pokeyvoltable[1][i++] = 0x2842;
	pokeyvoltable[1][i++] = 0x3345;
	pokeyvoltable[1][i++] = 0x3E84;
	pokeyvoltable[1][i++] = 0x49E0;
	pokeyvoltable[1][i++] = 0x5538;
	pokeyvoltable[1][i++] = 0x606E;
	pokeyvoltable[1][i++] = 0x6B69;
	pokeyvoltable[1][i++] = 0x7612;
	pokeyvoltable[1][i++] = 0x805A;
	pokeyvoltable[1][i++] = 0x8A34;
	pokeyvoltable[1][i++] = 0x9399;
	pokeyvoltable[1][i++] = 0x9C84;
	pokeyvoltable[1][i++] = 0xA4F4;
	pokeyvoltable[1][i++] = 0xACEA;
	pokeyvoltable[1][i++] = 0xB468;
	pokeyvoltable[1][i++] = 0xBB70;
	pokeyvoltable[1][i++] = 0xC207;
	pokeyvoltable[1][i++] = 0xC830;
	pokeyvoltable[1][i++] = 0xCDEE;
	pokeyvoltable[1][i++] = 0xD343;
	pokeyvoltable[1][i++] = 0xD833;
	pokeyvoltable[1][i++] = 0xDCC0;
	pokeyvoltable[1][i++] = 0xE0EB;
	pokeyvoltable[1][i++] = 0xE4B6;
	pokeyvoltable[1][i++] = 0xE824;
	pokeyvoltable[1][i++] = 0xEB36;
	pokeyvoltable[1][i++] = 0xEDEF;
	pokeyvoltable[1][i++] = 0xF053;
	pokeyvoltable[1][i++] = 0xF265;
	pokeyvoltable[1][i++] = 0xF42B;
	pokeyvoltable[1][i++] = 0xF5AB;
	pokeyvoltable[1][i++] = 0xF6E9;
	pokeyvoltable[1][i++] = 0xF7EF;
	pokeyvoltable[1][i++] = 0xF8C3;
	pokeyvoltable[1][i++] = 0xF96D;
	pokeyvoltable[1][i++] = 0xF9F4;
	pokeyvoltable[1][i++] = 0xFA61;
	pokeyvoltable[1][i++] = 0xFABB;
	pokeyvoltable[1][i++] = 0xFB07;
	pokeyvoltable[1][i++] = 0xFB4C;
	pokeyvoltable[1][i++] = 0xFB8D;
	pokeyvoltable[1][i++] = 0xFBCE;
	pokeyvoltable[1][i++] = 0xFC11;
	pokeyvoltable[1][i++] = 0xFC56;
	pokeyvoltable[1][i++] = 0xFC9F;
	pokeyvoltable[1][i++] = 0xFCEA;
	pokeyvoltable[1][i++] = 0xFD37;
	pokeyvoltable[1][i++] = 0xFD85;
	pokeyvoltable[1][i++] = 0xFDD5;
	pokeyvoltable[1][i++] = 0xFE28;
	pokeyvoltable[1][i++] = 0xFE82;
	pokeyvoltable[1][i++] = 0xFEE7;
	pokeyvoltable[1][i++] = 0xFF5D;
	pokeyvoltable[1][i++] = 0xFFEB;
	pokeyvoltable[1][i++] = 0xFFFF;
	pokeyvoltable[1][i++] = 0xFFFF;
	pokeyvoltable[1][i++] = 0xFFFF;		
	for (i=0;i!=64;++i)
	{
		//pokeyvoltable[1][i] = pokeyvoltable[0][i]; //ym2149
		pokeyvoltable[0][i] = i<<10; //linear
	}

	for (i=0;i!=64;++i)
	{
		printf("pokey:%d:%d:%d\n",i,pokeyvoltable[0][i],pokeyvoltable[1][i]);
	}

	// 0x100(0x400 8-bit) sid tables --TODO!!
	// to store: 
	// i) 6581 channel mixing:
	// 	wire [7:0] wave__st[4096]; (sawtooth + triangle)
	// 	wire [7:0] wave_p_t[2048]; (pulse + triangle - symmetric)
	// 	wire [7:0] wave_ps_[4096]; (pulse + sawtooth)
	// 	wire [7:0] wave_pst[4096]; (pulse + sawtooth + triangle)
	// 	        _st_out <= wave__st[sawtooth]; 
        //		p_t_out <= wave_p_t[triangle[11:1]];
        //		ps__out <= wave_ps_[sawtooth];
        //		pst_out <= wave_pst[sawtooth];
	//	              4'b0001: wave_out = triangle;
        //  		      4'b0010: wave_out = sawtooth;
        //  		      4'b0011: wave_out = {_st_out, 4'b0000};
        //  		      4'b0100: wave_out = pulse;
        //  		      4'b0101: wave_out = {p_t_out, 4'b0000} & pulse;
        //  		      4'b0110: wave_out = {ps__out, 4'b0000} & pulse;
        //  		      4'b0111: wave_out = {pst_out, 4'b0000} & pulse;
        //  		      4'b1000: wave_out = noise;
        //  		      default: wave_out = 0;
	// ii) 8580 channel mixing: just and?
	// iii) linear filter
	// iv) 6581 filter frequency table
	// v) 8580 filter frequency table
	// vi) 6581 volume non-linearity filter adjustment
	
//      CLKSPEED : IN integer; --In Hz 58333333
//      FMIN : IN integer;   --In Hz (30)
//      FMAX : IN integer   --In Hz (12500 on 8580)
//      process(CUTOFF_FREQUENCY)
//              constant f_min : real := 2.0*sin(MATH_PI*real(FMIN)/real(CLKSPEED));
//              constant f_max : real := 2.0*sin(MATH_PI*real(FMAX)/real(CLKSPEED));
//
//              variable f_offset : unsigned(17 downto 0); --0.21(000,18)
//              variable f_scale : unsigned(17 downto 0); --0.21(000,18)
//
//              variable F_MULT : UNSIGNED(35 DOWNTO 0);
//      begin
//              --f = 2*sin(pi*10000/inrate);
//              --CUTOFF_FREQUENCY : IN STD_LOGIC_VECTOR(10 downto 0);
//              --CLKSPEED : IN integer; --In Hz
//              --FMIN : IN integer;   --In Hz
//              --FMAX : IN integer;   --In Hz
//
//              f_offset := to_unsigned(integer(f_min*2.0**21.0),18);
//              f_scale  := to_unsigned(integer(2.0**21.0*((f_max-f_min)/2.0**11.0)),18);
//
//              -- TODO: Could use a real curve captured from a chip? Lets start with it correctly then...
//              f_mult := f_scale * resize(unsigned(CUTOFF_FREQUENCY),18);
//              f_next <= f_mult(17 downto 0) + f_offset;
//      end process;

	// 0x400(0x1000 8-bit) sid frequency tables
	int sidfreqtablebase = 2048*2;
	unsigned short * sidfreqtable = (unsigned short *)(buffer+sidfreqtablebase);

	// Lets write 2 tables...
	// i) linear
        double CLKSPEED = 58333333.0;
	double FMIN = 30;
	double FMAX = 12500;
	double f_min = 2.0*sin(M_PI*FMIN/CLKSPEED);
	double f_max = 2.0*sin(M_PI*FMAX/CLKSPEED);
	for (int i=0;i!=2048;++i)
	{
		double f_offset = f_min*pow(2,21);
		double f_scale  = pow(2,21)*((f_max-f_min)/pow(2,11));
		double f_mult = f_scale*((double)i);
		double f_next = f_mult+f_offset;
	//	printf("%d:%f:%f\n",i,f_next,round(f_next));
		sidfreqtable[i] = (unsigned short)round(f_next);
	}
	// i) 8580 (which?)
	FILE * f;
//       	f = fopen("8580.csv","r"); //fc-curves/Trurl_Ext/8580R5_3691.txt
//	for (int i=0;i!=2048;++i)
//	{
//		double freqval;
//		fscanf(f,"%lf",&freqval);
//
//		double freq = 2.0*sin(M_PI*freqval/CLKSPEED);
//
//		double f_next  = pow(2,21)*(freq);
////		printf("%d:%f:%f\n",i,f_next,round(f_next));
//		sidfreqtable[i] = (unsigned short)round(f_next);
//	}
//	fclose(f);
	
	// ii) 6581 (which?)
	//printf("%f - %f\n",f_min,f_max);
       	f = fopen("6581.csv","r"); //fc-curves/Trurl_Ext/6581R4AR_3789.txt
	for (int i=0;i!=2048;++i)
	{
		double freqval;
		fscanf(f,"%lf",&freqval);

		double freq = 2.0*sin(M_PI*freqval/CLKSPEED);
	//	printf("freqval %lf - freq %lf\n",freqval,freq);

		double f_next  = pow(2,21)*(freq);
	//	printf("%d:%f:%f\n",i,f_next,round(f_next));
		sidfreqtable[i+2048] = (unsigned short)round(f_next);
	}
	fclose(f);

	FILE * x =fopen("init.bin","w");
		fwrite(&buffer[0],1,32768,x);
	fclose(x);

	return 0;
}

