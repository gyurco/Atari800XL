#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <byteswap.h>

typedef enum {MODE_NTSC_5994=0,MODE_NTSC_60=1,MODE_PAL_50=2,MODE_PAL_ORIG=3,MODE_NTSC_ORIG=4} video_pll_mode;

char const * mode_description[] = 
{
	"1440x576 50Hz interlace",
	"720x576 50Hz",
	"1280x720 50Hz",
	"1920x1080 50Hz interlace",
	"1440x480 59.94Hz interlace",
	"720x480 59.94Hz",
	"1280x720 60Hz",
	"1920x1080 60Hz interlace"
};

typedef unsigned short uint16_t;

uint16_t crtc_registers[] =
{
	/*pal576i*/
	126,    /*h_syncLen*/
	138,   /*h_preActiveLen*/
	1440,  /*h_activeLen*/
	24,    /*h_postActiveLen*/
	3,     /*v_syncLen*/
	19,    /*v_preActiveLen*/
	288,   /*v_activeLen*/
	2,     /*v_postActiveLen*/
	1,     /*v_interlace*/
	864,   /*v_interlaceDelayLen*/
	21,    /*mode */
	3,      /*clock select - 27MHz or 74.25MHz - TODO*/

	/*pal576p*/
	64,    /*h_syncLen*/
	68,   /*h_preActiveLen*/
	720,  /*h_activeLen*/
	12,   /*h_postActiveLen*/
	5,     /*v_syncLen*/
	39,    /*v_preActiveLen*/
	576,   /*v_activeLen*/
	5,     /*v_postActiveLen*/
	0,     /*v_interlace*/
	0,     /*v_interlaceDelayLen*/
	17,    /*mode */
	3,      /*clock select - 27MHz or 74.25MHz - TODO*/

	/*pal720p*/
	40,    /*h_syncLen*/
	220,   /*h_preActiveLen*/
	1280,  /*h_activeLen*/
	440,   /*h_postActiveLen*/
	5,     /*v_syncLen*/
	20,    /*v_preActiveLen*/
	720,   /*v_activeLen*/
	5,     /*v_postActiveLen*/
	0,     /*v_interlace*/
	0,     /*v_interlaceDelayLen*/
	19,    /*mode */
	2,      /*clock select - 27MHz or 74.25MHz - TODO*/


	/* pal 1080i */
	44,    /*h_syncLen*/
	148,   /*h_preActiveLen*/
	1920,  /*h_activeLen*/
	528,   /*h_postActiveLen*/
	5,     /*v_syncLen*/
	15,    /*v_preActiveLen*/
	540,   /*v_activeLen*/
	2,     /*v_postActiveLen*/
	1,     /*v_interlace*/
	1320,  /*v_interlaceDelayLen*/
	20,    /*mode*/
	2,      /*clock select - 27MHz or 74.25MHz - TODO*/

	/*ntsc480i*/
	124,    /*h_syncLen*/
	114,   /*h_preActiveLen*/
	1440,  /*h_activeLen*/
	38,   /*h_postActiveLen*/
	3,     /*v_syncLen*/
	15,    /*v_preActiveLen*/
	240,   /*v_activeLen*/
	4,     /*v_postActiveLen*/
	1,     /*v_interlace*/
	858,     /*v_interlaceDelayLen*/
	6,      /*mode */
	3,     /*clock select - 27MHz or 74.25MHz - TODO*/


	/*ntsc480p*/
	62,    /*h_syncLen*/
	60,   /*h_preActiveLen*/
	720,  /*h_activeLen*/
	16,   /*h_postActiveLen*/
	6,     /*v_syncLen*/
	30,    /*v_preActiveLen*/
	480,   /*v_activeLen*/
	9,     /*v_postActiveLen*/
	0,     /*v_interlace*/
	0,     /*v_interlaceDelayLen*/
	2,     /*mode */
	3,     /*clock select - 27MHz or 74.25MHz - TODO*/


	/* ntsc720p*/
	40,    /*h_syncLen*/
	220,   /*h_preActiveLen*/
	1280,  /*h_activeLen*/
	110,   /*h_postActiveLen*/
	5,     /*v_syncLen*/
	20,    /*v_preActiveLen*/
	720,   /*v_activeLen*/
	5,     /*v_postActiveLen*/
	0,     /*v_interlace*/
	0,     /*v_interlaceDelayLen*/
	4,     /*mode */
	2,     /*clock select - 27MHz or 74.25MHz - TODO*/


	/* ntsc 1080i */
	44,    /*h_syncLen*/
	148,   /*h_preActiveLen*/
	1920,  /*h_activeLen*/
	88,   /*h_postActiveLen*/
	5,     /*v_syncLen*/
	15,    /*v_preActiveLen*/
	540,   /*v_activeLen*/
	2,     /*v_postActiveLen*/
	1,     /*v_interlace*/
	1100,  /*v_interlaceDelayLen*/
	5,     /*mode */
	2      /*clock select - 27MHz or 74.25MHz - TODO*/

};

uint16_t  scaler_registers[] = 
{
400,400,328,164,328,1, /*pal576i*/
1024,1024,1,
400,400,328,164,164,2, /*pal576p*/
1024,512,2,
400,225,700,291,291,2, /*pal720p*/
576,426,2,
400,300,786,218,436,1, /*pal1080i*/
768,568,1,
400,400,328,164,328,1, /*ntsc480i*/
1024,1024,1,
400,400,328,164,164,2, /*ntsc480p*/
1024,512,2,
400,225,834,291,291,2, /*ntsc720p*/
576,358,2,
400,300,936,218,436,1, /*ntsc1080i*/
768,478,1
};

video_pll_mode const mode_freqs[] = 
{
	MODE_PAL_50,
	MODE_PAL_50,
	MODE_PAL_50,
	MODE_PAL_50,
	MODE_NTSC_5994,
	MODE_NTSC_5994,
	MODE_NTSC_60,
	MODE_NTSC_60
};

/* mode layout 
 * 0  :name
   64 :crtc
   128:scaler
   192:freq  
 */
int main(void)
{
	int nummodes = 8;
	char * buffer = malloc(nummodes*256);
	memset(buffer,0,nummodes*256);

	for (int i=0;i!=nummodes*12;++i)
		crtc_registers[i] = __bswap_16 (crtc_registers[i]);

	for (int i=0;i!=nummodes*9;++i)
		scaler_registers[i] = __bswap_16 (scaler_registers[i]);

	for (int i=0;i!=nummodes;++i)
	{
		char * base = buffer+i*256;
		strcpy(base,mode_description[i]);
		memcpy(base+64,crtc_registers+(12*i),12*2);
		memcpy(base+128,scaler_registers+(9*i),9*2);
		memcpy(base+192,&mode_freqs[i],1);
	}

	FILE * f = fopen("video_modes.rom","w");
	fwrite(buffer,1,nummodes*256,f);
	fclose(f);

	return 0;
}


