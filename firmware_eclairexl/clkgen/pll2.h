#ifndef PLL2_H
#define PLL2_H

void set_pll2();

void set_scaler(int type);

void set_scaler_mode(int modeno);
/*
 * 0-3 PAL,4-7 NTSC
 * 0=1400x576i
 * 1=720x576p
 * 2=1280x720p
 * 3=1920x1080i
 * etc
 * Note that 720 and 1280 are <100% horiz scaling, so skip every other pixel
 */

#endif

