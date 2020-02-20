#ifndef PLL_H
#define PLL_H

typedef enum {MODE_NTSC_5994=0,MODE_NTSC_60=1,MODE_PAL_50=2,MODE_PAL_ORIG=3,MODE_NTSC_ORIG=4} video_pll_mode;
void set_pll(video_pll_mode mode);

#endif

